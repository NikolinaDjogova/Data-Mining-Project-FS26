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
  granulate_json <- jsonlite::fromJSON(
    httr::content(granule_response, as = "text", encoding = "UTF-8")
    )
  clean_text <- granulate_text |>
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
