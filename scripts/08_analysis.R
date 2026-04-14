rm(list = ls())

source(here::here("scripts", "00_setup.R"))

dir.create(interim_floor_speeches_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_checks_path, recursive = TRUE, showWarnings = FALSE)
dir.create(data_processed_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_tables_path, recursive = TRUE, showWarnings = FALSE)

analysis_data <- readr::read_csv(
  file.path(data_processed_path, "floor_speeches_analysis_ready.csv"),
  show_col_types = FALSE
)
 
# Loading packages
library(dplyr)
library(stringr)
library(lubridate)
library(quanteda)
library(quanteda.textstats)

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
  file.path(data_processed_path, "floor_speeches_with_measures.csv")
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

### Yearly summaries 
# Number of speeches per year
speeches_per_year <- analysis_data |>
  dplyr::count(year, name = "num_speeches")

# Flesch-Kincaid by year
fk_by_year <- analysis_data |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    avg_fk_grade = mean(fk_grade, na.rm = TRUE),
    median_fk_grade = median(fk_grade, na.rm = TRUE),
    sd_fk_grade = sd(fk_grade, na.rm = TRUE),
    p25_fk_grade = quantile(fk_grade, 0.25, na.rm = TRUE),
    p75_fk_grade = quantile(fk_grade, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# Sentence complexity by year
sentence_complexity_by_year <- analysis_data |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    avg_sentence_count = mean(sentence_count, na.rm = TRUE),
    median_sentence_count = median(sentence_count, na.rm = TRUE),
    avg_sentence_length = mean(avg_sentence_length, na.rm = TRUE),
    median_sentence_length = median(avg_sentence_length, na.rm = TRUE),
    sd_sentence_length = sd(avg_sentence_length, na.rm = TRUE),
    p25_sentence_length = quantile(avg_sentence_length, 0.25, na.rm = TRUE),
    p75_sentence_length = quantile(avg_sentence_length, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# Word count by year
wordcount_by_year <- analysis_data |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    avg_word_count = mean(word_count, na.rm = TRUE),
    median_word_count = median(word_count, na.rm = TRUE),
    sd_word_count = sd(word_count, na.rm = TRUE),
    p25_word_count = quantile(word_count, 0.25, na.rm = TRUE),
    p75_word_count = quantile(word_count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# Clean combined yearly summary
yearly_summary <- speeches_per_year |>
  dplyr::left_join(fk_by_year, by = "year") |>
  dplyr::left_join(sentence_complexity_by_year, by = "year") |>
  dplyr::left_join(wordcount_by_year, by = "year")

# Saving output tables 
readr::write_csv(
  fk_by_year,
  file.path(output_tables_path, "08_fk_by_year.csv")
)

readr::write_csv(
  sentence_complexity_by_year,
  file.path(output_tables_path, "08_sentence_complexity_by_year.csv")
)

readr::write_csv(
  wordcount_by_year,
  file.path(output_tables_path, "08_wordcount_by_year.csv")
)

readr::write_csv(
  yearly_summary,
  file.path(output_tables_path, "08_yearly_summary.csv")
)

readr::write_csv(
  overall_summary,
  file.path(output_tables_path, "08_overall_summary.csv")
)

readr::write_csv(
  speeches_per_year,
  file.path(output_tables_path, "08_speeches_per_year.csv")
)

####Additional Analysis
# Distributional change over time 
distribution_by_year <- analysis_data |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    fk_p10 = quantile(fk_grade, 0.10, na.rm = TRUE),
    fk_p25 = quantile(fk_grade, 0.25, na.rm = TRUE),
    fk_p50 = quantile(fk_grade, 0.50, na.rm = TRUE),
    fk_p75 = quantile(fk_grade, 0.75, na.rm = TRUE),
    fk_p90 = quantile(fk_grade, 0.90, na.rm = TRUE),
    
    sentence_p10 = quantile(avg_sentence_length, 0.10, na.rm = TRUE),
    sentence_p25 = quantile(avg_sentence_length, 0.25, na.rm = TRUE),
    sentence_p50 = quantile(avg_sentence_length, 0.50, na.rm = TRUE),
    sentence_p75 = quantile(avg_sentence_length, 0.75, na.rm = TRUE),
    sentence_p90 = quantile(avg_sentence_length, 0.90, na.rm = TRUE),
    
    wordcount_p10 = quantile(word_count, 0.10, na.rm = TRUE),
    wordcount_p25 = quantile(word_count, 0.25, na.rm = TRUE),
    wordcount_p50 = quantile(word_count, 0.50, na.rm = TRUE),
    wordcount_p75 = quantile(word_count, 0.75, na.rm = TRUE),
    wordcount_p90 = quantile(word_count, 0.90, na.rm = TRUE),
    .groups = "drop"
  )

# comparison by period 
analysis_data <- analysis_data |>
  dplyr::mutate(
    period = dplyr::case_when(
      year >= 2010 & year <= 2014 ~ "2010-2014",
      year >= 2015 & year <= 2019 ~ "2015-2019",
      year >= 2020 & year <= 2025 ~ "2020-2025",
      TRUE ~ NA_character_
    )
  )

period_summary <- analysis_data |>
  dplyr::group_by(period) |>
  dplyr::summarise(
    num_speeches = dplyr::n(),
    avg_fk_grade = mean(fk_grade, na.rm = TRUE),
    median_fk_grade = median(fk_grade, na.rm = TRUE),
    sd_fk_grade = sd(fk_grade, na.rm = TRUE),
    
    avg_sentence_length = mean(avg_sentence_length, na.rm = TRUE),
    median_sentence_length = median(avg_sentence_length, na.rm = TRUE),
    sd_sentence_length = sd(avg_sentence_length, na.rm = TRUE),
    
    avg_word_count = mean(word_count, na.rm = TRUE),
    median_word_count = median(word_count, na.rm = TRUE),
    sd_word_count = sd(word_count, na.rm = TRUE),
    .groups = "drop"
  )

# Speech type composition over time
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

# correlation among measures 
correlation_summary <- tibble::tibble(
  measure_pair = c(
    "fk_grade_and_avg_sentence_length",
    "fk_grade_and_word_count",
    "avg_sentence_length_and_word_count"
  ),
  correlation = c(
    cor(analysis_data$fk_grade, analysis_data$avg_sentence_length, use = "complete.obs"),
    cor(analysis_data$fk_grade, analysis_data$word_count, use = "complete.obs"),
    cor(analysis_data$avg_sentence_length, analysis_data$word_count, use = "complete.obs")
  )
)

# Saving these tables 
readr::write_csv(
  distribution_by_year,
  file.path(output_tables_path, "08_distribution_by_year.csv")
)

readr::write_csv(
  period_summary,
  file.path(output_tables_path, "08_period_summary.csv")
)

readr::write_csv(
  speech_type_distribution,
  file.path(output_tables_path, "08_speech_type_distribution.csv")
)

readr::write_csv(
  correlation_summary,
  file.path(output_tables_path, "08_correlation_summary.csv")
)

  # checks 
  checks <- tibble::tibble(
    metric = c(
      "rows_in_analysis_data",
      "missing_sentence_count",
      "missing_avg_sentence_length",
      "missing_fk_grade",
      "min_year",
      "max_year"
    ),
    value = c(
      nrow(analysis_data),
      sum(is.na(analysis_data$sentence_count)),
      sum(is.na(analysis_data$avg_sentence_length)),
      sum(is.na(analysis_data$fk_grade)),
      min(analysis_data$year, na.rm = TRUE),
      max(analysis_data$year, na.rm = TRUE)
    )
  )
  

  readr::write_csv(
    checks,
    file.path(output_checks_path, "08_measurement_checks.csv")
  )
  
  print(overall_summary)
  print(yearly_summary)
  print(checks)
  print(fk_by_year)
  print(wordcount_by_year)
  
  
  