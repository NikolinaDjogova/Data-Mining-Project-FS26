# Starting with a clean environment
rm(list = ls())

# Loading project setup
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "functions_congressional_record.R"))

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

# Collecting all House granules from selected packages
  ## map_dfr runs the hekper function for each package ID and combines the results into a single data frame
all_house_granules <- purrr::map_dfr(
  package_ids, 
  ~ get_house_granules(.x, api_key)
)

# Filtering out procedural granules
kept_granules <- all_house_granules |>
  dplyr::filter(!title %in% excluded_titles)

# Building clean floor speech dataset 
floor_speeches <- kept_granules |>
  dplyr::transmute(
    date = as.Date(dateIssued),
    package_id,
    granule_id = granuleId,
    title,
    type = granuleClass,
    text = purrr::map_chr(granuleLink, ~ get_granule_text(.x, api_key))
    ) |>
      dplyr::mutate(
        word_count = stringr::str_count(text, "\\S+")
      ) |>
      dplyr::filter(word_count >= 50) |>
      dplyr::distinct(granule_id, .keep_all = TRUE) |>
      dplyr::arrange(date, granule_id)

# Saving the cleaned corpus
readr::write_csv(
  floor_speeches,
  file.path(interim_floor_speeches_path, "floor_speeches_clean.csv")
)

# Creating a small check table 
 ##I want to get a quick summary of how many rows were collected and kept at each stage
checks <- tibble::tibble(
 metric = c(
   "packages",
   "house_granules",
   "after_title_filter",
   "final_floor_speeches"
 ),
 value = c(
   length(package_ids),
   nrow(all_house_granules),
   nrow(kept_granules),
   nrow(floor_speeches)
  )
 )

# Saving the table 
readr::write_csv(
  checks, 
  file.path(output_checks_path, "04_floor_speeches_checks.csv")
)

nrow(kept_granules)