rm(list = ls())

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

dir.create(interim_floor_speeches_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_checks_path, recursive = TRUE, showWarnings = FALSE)

# Loading combined dataset 
floor_speeches <- readr::read_csv(
  file.path(interim_floor_speeches_path, "floor_speeches_FINAL.csv"),
  show_col_types = FALSE
)
 