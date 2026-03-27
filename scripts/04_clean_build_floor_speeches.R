# Starting with a clean environment
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# small set of packages 
package_ids <- c(
  "CREC-2026-02-11", 
  "CREC-2026-02-12",
  "CREC-2026-02-13"
)

