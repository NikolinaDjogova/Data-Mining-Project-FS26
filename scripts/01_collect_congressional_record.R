# Making sure I start with a clean environment
rm(list = ls())

# Loading project setup 
source(here::here("scripts", "00_setup.R"))

# Acquired the API key, credentials are being kept in the R environment.

api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("API key is missing from the R environment")
} else {
  message("It works! API key successfully retrieved.")
}

# Defining one test package 
test_package <- "CREC-2026-03-20"

# Building request URL
base_url <- "https://api.govinfo.gov/packages"
summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=", api_key)

# Safe version for checking the structure
safe_summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=hidden")
safe_summary_url

# Sending a GET request 
response <- httr::GET(summary_url)

# Checking the status 
httr::status_code(response)

# Extracting content as text 
content_text <- httr::content(response, as = "text", encoding = "UTF-8")

# Converting JSON to an R object
content_json <- jsonlite::fromJSON(content_text)



