rm(list = ls())

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Ensuring output folders exist
dir.create(raw_congressional_record_path, recursive = TRUE, showWarnings = FALSE)
dir.create(interim_floor_speeches_path, recursive = TRUE, showWarnings = FALSE)

# Loading the already-saved raw metadata for 2020-2025
all_house_granules_recent <- readr::read_csv(
  file.path(raw_congressional_record_path, "house_granules_2020_2025_raw.csv"),
  show_col_types = FALSE
)

