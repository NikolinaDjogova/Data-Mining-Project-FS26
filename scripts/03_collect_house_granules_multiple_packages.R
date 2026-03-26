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

