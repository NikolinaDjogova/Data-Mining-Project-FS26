rm(list = ls())

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

dir.create(output_figures_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_checks_path, recursive = TRUE, showWarnings = FALSE)

library(dplyr)
library(readr)
library(ggplot2)
library(scales)

# Loading datasets from the last script
analysis_data <- readr::read_csv(
  file.path(data_processed_path, "floor_speeches_with_measures.csv"),
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

distribution_by_year <- readr::read_csv(
  file.path(output_tables_path, "08_distribution_by_year.csv"),
  show_col_types = FALSE
)

# Some basic checks 
analysis_data <- analysis_data |>
  dplyr::mutate(
    year = as.numeric(year),
    fk_grade = as.numeric(fk_grade),
    avg_sentence_length = as.numeric(avg_sentence_length),
    word_count = as.numeric(word_count),
    period = dplyr::case_when(
      year >= 2010 & year <= 2014 ~ "2010-2014",
      year >= 2015 & year <= 2019 ~ "2015-2019",
      year >= 2020 & year <= 2025 ~ "2020-2025",
      TRUE ~ NA_character_
    ),
    period = factor(period, levels = c("2010-2014", "2015-2019", "2020-2025"))

###Plots

# Shared x-axis formatting for yearly plots
year_scale <- scale_x_continuous(
  breaks = c(2010, 2015, 2020, 2025),
  expand = expansion(mult = c(0.01, 0.03))
)

# Number of speeches over time 
plot_speeches <- ggplot(speeches_per_year, aes(x = year, y = num_speeches)) +
  geom_area(fill = blue_mid, alpha = 0.55) +
  geom_line(color = blue_dark, linewidth = 1) +
  geom_point(color = blue_dark, size = 2) +
year_scale+
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Number of House Floor Speeches per Year",
    subtitle = "Analysis-ready speeches, 2010–2025",
    x = "Year",
    y = "Number of speeches",
    caption = "Source: U.S. Congressional Record"
  ) +
  project_theme()
plot_speeches

# Average Flesch-Kincaid grade level over time 
plot_fk <- ggplot(fk_by_year, aes(x = year, y = avg_fk_grade)) +
  geom_ribbon(
    aes(ymin = p25_fk_grade, ymax = p75_fk_grade),
    fill = blue_light,
    alpha = 0.35
  ) +
  geom_line(color = blue_dark, linewidth = 1.1) +
  geom_point(color = blue_dark, size = 2.2) +
  year_scale +
  labs(
    title = "Average Flesch-Kincaid Grade Level by Year",
    subtitle = "Higher values indicate more structurally demanding texts",
    x = NULL,
    y = "Flesch-Kincaid grade level",
    caption = "Ribbon shows the 25th–75th percentile range"
  ) +
  project_theme()

# Distributional change in fk over time
plot_fk_distribution <- ggplot(distribution_by_year, aes(x = year)) +
  geom_ribbon(
    aes(ymin = fk_p25, ymax = fk_p75),
    fill = blue_fill,
    alpha = 0.7
  ) +
  geom_line(aes(y = fk_p50), color = blue_dark, linewidth = 1.1) +
  geom_line(aes(y = fk_p90), color = blue_mid, linetype = "dashed", linewidth = 0.8) +
  geom_line(aes(y = fk_p10), color = blue_mid, linetype = "dashed", linewidth = 0.8) +
  year_scale+
  labs(
    title = "Distributional Change in Flesch-Kincaid Scores Over Time",
    subtitle = "Median and upper/lower quantiles show how readability shifted across the distribution",
    x = "Year",
    y = "Flesch-Kincaid Grade Level",
    caption = "Ribbon shows interquartile range; dashed lines show 10th and 90th percentiles"
  ) +
  project_theme()

# Average sentence length over time 
plot_sentence_length <- ggplot(sentence_complexity_by_year, aes(x = year, y = avg_sentence_length)) +
  geom_segment(
    aes(x = year, xend = year, y = 0, yend = avg_sentence_length),
    color = blue_light,
    linewidth = 1
  ) +
  geom_point(size = 1, color = blue_dark) +
  year_scale +
  labs(
    title = "Average Sentence Length by Year",
    subtitle = "Measured as average words per sentence",
    x = NULL,
    y = "Average words per sentence",
    caption = "Yearly averages from the analysis-ready corpus"
  ) +
  project_theme()

plot_sentence_length

# Average word count over time
plot_word_count <- ggplot(wordcount_by_year, aes(x = year, y = avg_word_count)) +
  geom_ribbon(
    aes(ymin = p25_word_count, ymax = p75_word_count),
    alpha = 0.18
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq(min(wordcount_by_year$year), max(wordcount_by_year$year), by = 1)) +
  labs(
    title = "Average Word Count by Year",
    subtitle = "Supporting indicator of structural variation",
    x = "Year",
    y = "Average word count",
    caption = "Ribbon shows the 25th–7w5th percentile range"
  ) +
  project_theme()


# Saving plots 
ggsave(
  filename = file.path(output_figures_path, "09_num_speeches_per_year.png"),
  plot = plot_speeches,
  width = 9,
  height = 5.5,
  dpi = 300
)

ggsave(
  filename = file.path(output_figures_path, "09_avg_fk_by_year.png"),
  plot = plot_fk,
  width = 9,
  height = 5.5,
  dpi = 300
)

ggsave(
  filename = file.path(output_figures_path, "09_avg_sentence_length_by_year.png"),
  plot = plot_sentence_length,
  width = 9,
  height = 5.5,
  dpi = 300
)

ggsave(
  filename = file.path(output_figures_path, "09_avg_word_count_by_year.png"),
  plot = plot_word_count,
  width = 9,
  height = 5.5,
  dpi = 300
)




