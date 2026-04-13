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

# Some basic cleaning 
floor_speeches_clean <- floor_speeches |>
  dplyr::mutate(
    date = as.Date(date),
    year = lubridate::year(date),
    word_count = as.numeric(word_count),
    text = dplyr::if_else(is.na(text), NA_character_, stringr::str_squish(text))
  ) |>
  dplyr::filter(
    !is.na(date),
    !is.na(granule_id)
  ) |>
  dplyr::distinct(granule_id, .keep_all = TRUE) |>
  dplyr::arrange(date, granule_id)

# Creating diagnostic flags
floor_speeches_clean <- floor_speeches_clean |>
  dplyr::mutate(
    text_missing = is.na(text) | text == "",
    zero_word = is.na(word_count) | word_count == 0,
    short_text = !is.na(word_count) & word_count < 50
  )

# Creating analysis-ready dataset
analysis_data <- floor_speeches_clean |>
  dplyr::filter(
    !text_missing,
    !zero_word,
    !short_text
  )

# Saving cleaned full dataset
readr::write_csv(
  floor_speeches_clean,
  file.path(interim_floor_speeches_path, "floor_speeches_cleaned.csv")
)

# Saving analysiws-ready dataset
readr::write_csv(
  analysis_data,
  file.path(interim_floor_speeches_path, "floor_speeches_analysis_ready.csv")
)
