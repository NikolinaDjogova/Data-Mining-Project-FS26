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
      return(tibble::tibble())
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

# Collecting House granules data from all package ids
  ##this will probably take long, so I want to know when it starts and ends 

message("Starting package collection")

all_house_granules <- purrr::map_dfr(
  package_ids,
  function(pkg){
    message("Processing package:", pkg)
    Sys.sleep(0.2)
    get_house_granules_wrapper(pkg, api_key)
  }
)

message("Finished package collection")

# Saving the raw House granule metadata 
readr::write_csv(
  all_house_granules,
  file.path(raw_congressional_record_path, "house_granules_2010_2025_raw.csv")
)
