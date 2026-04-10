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

# Cleaning the combined dataset
floor_speeches <- floor_speeches |>
  dplyr::mutate(
    date = as.Date(date)
  ) |>
  dplyr::distinct(granule_id, .keep_all = TRUE) |>
  dplyr::arrange(date, granule_id)

# Saving the final combined dataset
readr::write_csv(
  floor_speeches,
  file.path(interim_floor_speeches_path, "floor_speeches_2010_2025_combined.csv")
)

# Creating a checks table
checks <- tibble::tibble(
  metric = c(
    "chunk_files_found",
    "combined_rows",
    "unique_granule_ids"
  ),
  value = c(
    length(chunk_files),
    nrow(floor_speeches),
    dplyr::n_distinct(floor_speeches$granule_id)
  )
)

# Saving the checks table
readr::write_csv(
  checks,
  file.path(output_checks_path, "06_combine_floor_speeches_checks.csv")
)

