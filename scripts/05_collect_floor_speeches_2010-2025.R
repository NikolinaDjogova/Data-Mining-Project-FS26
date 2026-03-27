# Starting with a clean environment 
rm(list = ls())

# Loading project setup 
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Defining the full date range 
all_dates <- seq.Date(
  from = as.Date ("2010-01-01"),
  to = as.Date("2025-12-31"),
  by = "day"
)

# Building package IDs for the full date range
package_ids <- paste0("CREC-", all_dates)

# Wrapper for packages 
get_house_granules_wrapper <- function(package_id, api_key) {
  tryCatch(
    get_house_granules(package_id, api_key),
    error = function(e) {
      message(paste("Error in package:", package_id, " - ", e$message))
      return("tibble::tibble()")
    }
  )
}

# Wrapper for granules 
get_granule_text_wrapper <- function(granule_link, api_key) {
  tryCatch(
    get_granule_text(granule_link, api_key),
    error = function(e) {
      message(paste("Error in granule link:", granule_link, " - ", e$message))
      return(NA_character_)
    }
  )
}