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

# Saving dataset with measures 
readr::write_csv(
  analysis_data,
  file.path(interim_floor_speeches_path, "floor_speeches_with_measures.csv")
)

# Descriptive summary
overall_summary <- tibble::tibble(
  metric = c(
    "total_speeches",
    "mean_word_count",
    "median_word_count",
    "sd_word_count",
    "mean_sentence_count",
    "median_sentence_count",
    "mean_avg_sentence_length",
    "median_avg_sentence_length",
    "mean_fk_grade",
    "median_fk_grade"
  ),
  value = c(
    nrow(analysis_data),
    mean(analysis_data$word_count, na.rm = TRUE),
    median(analysis_data$word_count, na.rm = TRUE),
    sd(analysis_data$word_count, na.rm = TRUE),
    mean(analysis_data$sentence_count, na.rm = TRUE),
    median(analysis_data$sentence_count, na.rm = TRUE),
    mean(analysis_data$avg_sentence_length, na.rm = TRUE),
    median(analysis_data$avg_sentence_length, na.rm = TRUE),
    mean(analysis_data$fk_grade, na.rm = TRUE),
    median(analysis_data$fk_grade, na.rm = TRUE)
  )
)

# Yearly summaries 
speeches_per_year <- analysis_data |>
  dplyr::count(year, name = "num_speeches")

complexity_by_year <- analysis_data |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    avg_word_count = mean(word_count, na.rm = TRUE),
    median_word_count = median(word_count, na.rm = TRUE),
    sd_word_count = sd(word_count, na.rm = TRUE),
    p25_word_count = quantile(word_count, 0.25, na.rm = TRUE),
    p75_word_count = quantile(word_count, 0.75, na.rm = TRUE),
    
    avg_sentence_count = mean(sentence_count, na.rm = TRUE),
    median_sentence_count = median(sentence_count, na.rm = TRUE),
    
    avg_sentence_length = mean(avg_sentence_length, na.rm = TRUE),
    median_sentence_length = median(avg_sentence_length, na.rm = TRUE),
    sd_sentence_length = sd(avg_sentence_length, na.rm = TRUE),
    
    avg_fk_grade = mean(fk_grade, na.rm = TRUE),
    median_fk_grade = median(fk_grade, na.rm = TRUE),
    sd_fk_grade = sd(fk_grade, na.rm = TRUE),
    
    .groups = "drop"
  )

yearly_summary <- speeches_per_year |>
  dplyr::left_join(complexity_by_year, by = "year")

# Speech length cat distribution by year
speech_type_distribution <- analysis_data |>
  dplyr::group_by(year, speech_type) |>
  dplyr::summarise(
    n = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::group_by(year) |>
  dplyr::mutate(
    proportion = n / sum(n)
  ) |>
  dplyr::ungroup()
