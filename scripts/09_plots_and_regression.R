rm(list = ls())

source(here::here("scripts", "00_setup.R"))

dir.create(output_tables_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures_path, recursive = TRUE, showWarnings = FALSE)

library(dplyr)
library(readr)
library(ggplot2)
library(broom)

# Loading datasets from the last script
analysis_data <- readr::read_csv(
  file.path(interim_floor_speeches_path, "floor_speeches_with_measures.csv"),
  show_col_types = FALSE
)

speeches_per_year <- readr::read_csv(
  file.path(output_tables_path, "08_speeches_per_year.csv"),
  show_col_types = FALSE
)

fk_by_year <- readr::read_csv(
  file.path(output_tables_path, "08_fk_by_year.csv"),
  show_col_types = FALSE
)

sentence_complexity_by_year <- readr::read_csv(
  file.path(output_tables_path, "08_sentence_complexity_by_year.csv"),
  show_col_types = FALSE
)

wordcount_by_year <- readr::read_csv(
  file.path(output_tables_path, "08_wordcount_by_year.csv"),
  show_col_types = FALSE
)

yearly_summary <- readr::read_csv(
  file.path(output_tables_path, "08_yearly_summary.csv"),
  show_col_types = FALSE
)

# Some basic checks 
analysis_data <- analysis_data |>
  dplyr::mutate(
    year = as.numeric(year),
    fk_grade = as.numeric(fk_grade),
    avg_sentence_length = as.numeric(avg_sentence_length),
    word_count = as.numeric(word_count)
  )