# Starting with a clean environment 
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Testing small set of Congressional Record packages
test_packages <- c(
"CREC-2026-02-11", 
"CREC-2026-02-12",
"CREC-2026-02-13"
)

# Function to get text from one granule
get_granule_text <- function(granule_link, api_key) {
  granule_url <- paste0(granule_link, "?api_key=", api_key)
  granule_response <- httr::GET(granule_url)
  
  granule_json <- jsonlite::fromJSON(
    httr::content(granule_response, as = "text", encoding = "UTF-8")
  )
  
  text_url <- paste0(granule_json$download$txtLink, "?api_key=", api_key)
  text_response <- httr::GET(text_url)
  
  raw_text <- httr::content(text_response, as = "text", encoding = "UTF-8")
  
  clean_text <- raw_text |>
    xml2::read_html() |>
    rvest::html_element("pre") |>
    rvest::html_text()
  
  return(clean_text)
}

# Function to get House granules from one package
get_house_granules <- function(package_id, api_key) {
  base_url <- "https://api.govinfo.gov/packages"
  summary_url <- paste0(base_url, "/", package_id, "/summary?api_key=", api_key)
  response <- httr::GET(summary_url)
  content_json <- jsonlite::fromJSON(
    httr::content(response, as = "text", encoding = "UTF-8")
  )
  granules_url <- paste0(content_json$granulesLink, "&api_key=", api_key)
  granules_response <- httr::GET(granules_url)
  granules_json <- jsonlite::fromJSON(
    httr::content(granules_response, as = "text", encoding = "UTF-8")
  )
  house_granules <- granules_json$granules |>
    dplyr::filter(granuleClass == "HOUSE") 
  return(house_granules)
}

# Collecting House granules from all test packages
all_house_granules <- purrr::map_dfr(test_packages, ~ get_house_granules(.x, api_key))
all_house_granules <- dplyr::bind_rows(all_house_granules)

# Keeping a few relevant columns 
filtered_house_granules <- all_house_granules |>
  dplyr::filter(
    !title %in% c(
      "House of Representatives",
      "PRAYER",
      "THE JOURNAL",
      "PLEDGE OF ALLEGIANCE",
      "ADJOURNMENT",
      "RECESS",
      "AFTER RECESS",
      "MESSAGES FROM THE PRESIDENT",
      "EXECUTIVE COMMUNICATIONS, ETC.",
      "REPORTS OF COMMITTEES ON PUBLIC BILLS AND RESOLUTIONS",
      "PUBLIC BILLS AND RESOLUTIONS",
      "ADDITIONAL SPONSORS",
      "DISCHARGE PETITIONS",
      "DISCHARGE PETITIONS-- ADDITIONS AND WITHDRAWALS"
    )
  )

# Small testing sample
test_granules <- filtered_house_granules |>
  dplyr::slice(1:12)

# Building a small test dataset
house_dataset <- tibble::tibble(
  date = test_granules$dateIssued,
  granule_id = test_granules$granuleId,
  title = test_granules$title,
  type = test_granules$granuleClass,
  text = purrr::map_chr(
    test_granules$granuleLink,
    ~ get_granule_text(.x, api_key)
  )
)
