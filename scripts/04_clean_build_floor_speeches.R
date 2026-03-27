# Starting with a clean environment
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Small set of packages 
package_ids <- c(
  "CREC-2026-02-11", 
  "CREC-2026-02-12",
  "CREC-2026-02-13"
)

# Creating a list of precedural titles 
excluded_titles <- c(
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
  ##These are House granules that are not likely to contain substantive speeches for my project 

