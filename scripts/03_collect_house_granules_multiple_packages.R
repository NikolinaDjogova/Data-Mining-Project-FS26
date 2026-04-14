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

# Testing small set of Congressional Record packages
test_packages <- c(
"CREC-2026-02-11", 
"CREC-2026-02-12",
"CREC-2026-02-13"
)

# Collecting House granules from all test packages
all_house_granules <- purrr::map_dfr(test_packages, ~ get_house_granules(.x, api_key))
all_house_granules <- dplyr::bind_rows(all_house_granules)

# Filtering out procedural entries
filtered_house_granules <- all_house_granules |>
  dplyr::filter(!title %in% excluded_titles)

# Small testing sample
test_granules <- filtered_house_granules |>
  dplyr::slice(1:12)

# Building a small test dataset
house_dataset <- tibble::tibble(
  date = test_granules$dateIssued,
  granule_id = test_granules$granuleId,
  title = test_granules$title,
  type = test_granules$granuleClass,
  text = purrr::map_chr(
    test_granules$granuleLink,
    ~ get_granule_text(.x, api_key)
  )
)

house_dataset

# Saving the dataset 
readr::write_csv(
  house_dataset,
  here::here("output", "checks", "house_granules_multiple_packages.csv")
)
