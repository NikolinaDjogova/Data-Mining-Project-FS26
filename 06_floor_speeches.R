rm(list = ls())
source(here::here("scripts", "00_setup.R"))

# Making sure the interim floor speeches exist
if (!dir.exists(interim_floor_speeches_path)) {
  stop("Interim floor speeches folder does not exist")
}

# Get all chunk files
chunk_files <- list.files(
  interim_floor_speeches_path,
  pattern = "^floor_speeches_chunk_[0-9]+\\.csv$",
  full.names = TRUE
)

# Sorting files by chunk number
chunk_numbers <- stringr::str_extract(basename(chunk_files), "[0-9]+") |>
  as.integer()

chunk_files <- chunk_files[order(chunk_numbers)]

# Combining all chunk files
floor_speeches <- purrr::map_dfr(
  chunk_files,
  readr::read_csv,
  show_col_types = FALSE
)