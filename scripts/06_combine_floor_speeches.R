rm(list = ls())

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

# Making sure the interim folder exists
if (!dir.exists(interim_floor_speeches_path)) {
  stop("Interim floor speeches folder does not exist")
}

# Getting all chunk files
all_chunk_files <- list.files(
  interim_floor_speeches_path,
  pattern = "^floor_speeches(_recent)?_chunk_[0-9]+\\.csv$",
  full.names = TRUE
)

# Stop if no chunk files are found
if (length(all_chunk_files) == 0) {
  stop("No chunk files were found")
}

# Sorting files for readability and consistency
chunk_names <- basename(all_chunk_files)

chunk_type <- ifelse(
  stringr::str_detect(chunk_names, "recent"),
  "recent",
  "original"
)

chunk_number <- stringr::str_extract(chunk_names, "[0-9]+") |>
  as.integer()

all_chunk_files <- all_chunk_files[order(chunk_type, chunk_number)]

# Reading and combining all chunk files
floor_speeches <- purrr::map_dfr(
  all_chunk_files,
  readr::read_csv,
  show_col_types = FALSE
)

# Cleaning combined dataset
floor_speeches <- floor_speeches |>
  dplyr::mutate(
    date = as.Date(date),
    year = lubridate::year(date)
  ) |>
  dplyr::distinct(granule_id, .keep_all = TRUE) |>
  dplyr::arrange(date, granule_id)

# Saving final combined dataset
readr::write_csv(
  floor_speeches,
  file.path(interim_floor_speeches_path, "floor_speeches_FINAL.csv")
)
