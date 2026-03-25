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