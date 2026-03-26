# Starting with a clean environment 
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))

# Getting the API key 
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Testing one Congressional Record package 
test_package <- "CREC-2026-02-11"

# Function to get text from one granule
get_granule_text <- function(granule_link, api_key) {
  granule_url <- paste0(granule_link, "?api_key=", api_key)
  granule_response <- httr::GET(granule_url)
  granule_json <- jsonlite::fromJSON(
    httr::content(granule_response, as = "text", encoding = "UTF-8")
    )
  text_url <- paste0(granule_json$download$txtLink, "?api_key=", api_key)
  text_response <- httr::GET(text_url)
  raw_text <-   httr::content(text_response, as = "text", encoding = "UTF-8")
  clean_text <- raw_text |>
    xml2::read_html() |>
    rvest::html_element("pre") |>
    rvest::html_text()
  return(clean_text)
}

# Requesting package summary 
base_url <- "https://api.govinfo.gov/packages"
summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=", api_key)

response <- httr::GET(summary_url)

content_json <- jsonlite::fromJSON(
  httr::content(response, as = "text", encoding = "UTF-8")
)

# Requesting the granules list 
granules_url <- paste0(content_json$granulesLink, "&api_key=", api_key)
granules_response <- httr::GET(granules_url)
granules_json <- jsonlite::fromJSON(
  httr::content(granules_response, as = "text", encoding = "UTF-8")
)

# Keeping only House granules 
house_granules <- granules_json$granules |>
  dplyr::filter(granuleClass == "HOUSE")

example_rows <- c(8, 9, 12)

# Building a small test dataset 
example_dataset <- tibble::tibble(
  date = house_granules$dateIssued[example_rows],
  granule_id = house_granules$granuleId[example_rows],
  title = house_granules$title[example_rows],
  type = house_granules$granuleClass[example_rows],
  text = purrr::map_chr(
    house_granules$granuleLink[example_rows],
    ~ get_granule_text(.x, api_key)
  )
)

example_dataset

# Saving the test dataset 
readr::write_csv(
  example_dataset,
  here::here("output", "checks", "example_house_granules.csv")
)

