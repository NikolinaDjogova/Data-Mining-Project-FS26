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
 
# Loading packages
library(dplyr)
library(stringr)
library(lubridate)
library(ggplot2)
install.packages("quanteda")
library(quanteda)
install.packages("quanteda.textstats")
library(quanteda.textstats)
library(broom)

# Basic type checks
analysis_data <- analysis_data |>
  dplyr::mutate(
    date = as.Date(date),
    year = lubridate::year(date),
    word_count = as.numeric(word_count),
    text = stringr::str_squish(text)
  )

### Creating linguistic complexity measures 

# Sentence count based on punctuation
analysis_data <- analysis_data |>
  dplyr::mutate(
    sentence_count = stringr::str_count(text, "[.!?]+"),
    sentence_count = dplyr::if_else(sentence_count == 0, NA_integer_, sentence_count),
    avg_sentence_length = word_count / sentence_count
  )

# Flesch-Kincaid Grade Level
fk_scores <- quanteda.textstats::textstat_readability(
  analysis_data$text,
  measure = "Flesch.Kincaid"
)

analysis_data <- analysis_data |>
  dplyr::mutate(
    fk_grade = fk_scores$Flesch.Kincaid
  )

# Speech type categories
analysis_data <- analysis_data |>
  dplyr::mutate(
    speech_type = dplyr::case_when(
      word_count < 200 ~ "short",
      word_count < 1000 ~ "medium",
      TRUE ~ "long"
    )
  )

