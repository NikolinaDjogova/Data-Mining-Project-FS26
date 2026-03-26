# Starting with a clean environment
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}
