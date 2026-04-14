# Function: get_house_granules
## Retrieves all granules for a given package and keeps only the ones from the House of Reps.

get_house_granules <- function(package_id, api_key) {
  summary_url <- paste0(
    "https://api.govinfo.gov/packages/",
    package_id,
    "/summary?api_key=",
    api_key
  )
  summary_json <- jsonlite::fromJSON(
    httr::content(httr::GET(summary_url), as = "text", encoding = "UTF-8")
  )
  granules_url <- paste0(summary_json$granulesLink, "&api_key=", api_key)
  granules_json <- jsonlite::fromJSON(
    httr::content(httr::GET(granules_url), as = "text", encoding = "UTF-8")
  )
  granules_json$granules |>
    dplyr::filter(granuleClass == "HOUSE") |>
    dplyr::mutate(package_id = package_id)
}
  
# Function: get_granule_text
## Retrieves and cleans the full text of one granule.
get_granule_text <- function(granule_link, api_key) {
  granule_url <- paste0(granule_link, "?api_key=", api_key)
  granule_json <- jsonlite::fromJSON(
    httr::content(httr::GET(granule_url), as = "text", encoding = "UTF-8")
  )
  
  text_url <- paste0(granule_json$download$txtLink, "?api_key=", api_key)
  
  raw_text <- httr::content(
    httr::GET(text_url),
    as = "text",
    encoding = "UTF-8"
  )
  
  html <- xml2::read_html(raw_text)
  pre_node <- rvest::html_element(html, "pre")
  
  clean_text <- if (!is.na(pre_node) && length(pre_node) > 0) {
    rvest::html_text(pre_node)
  } else {
    rvest::html_text(html)
  }
  
  stringr::str_squish(clean_text)
}

# Excluded titles that are not relevant for the analysis (procedural, ceremonial, etc.)
excluded_titles <- c(
  "House of Representatives",
  "PRAYER",
  "THE JOURNAL",
  "PLEDGE OF ALLEGIANCE",
  "ADJOURNMENT",
  "RECESS",
  "AFTER RECESS",
  "MESSAGES FROM THE PRESIDENT",
  "EXECUTIVE COMMUNICATIONS, ETC.",
  "REPORTS OF COMMITTEES ON PUBLIC BILLS AND RESOLUTIONS",
  "PUBLIC BILLS AND RESOLUTIONS",
  "ADDITIONAL SPONSORS",
  "DISCHARGE PETITIONS",
  "DISCHARGE PETITIONS-- ADDITIONS AND WITHDRAWALS"
)

# Wrapper: get_house_granules_wrapper
get_house_granules_wrapper <- function(package_id, api_key) {
  tryCatch(
    get_house_granules(package_id, api_key),
    error = function(e) {
      message(paste("Error in package:", package_id, "-", e$message))
      return(tibble::tibble())
    }
  )
}

# Wrapper: get_granule_text_wrapper
get_granule_text_wrapper <- function(granule_link, api_key) {
  tryCatch(
    get_granule_text(granule_link, api_key),
    error = function(e) {
      message(paste("Error in granule link:", granule_link, "-", e$message))
      return(NA_character_)
    }
  )
}

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

###Plots 
# Creating my aesthetic theme for all plots 

project_theme <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 15, hjust = 0),
      plot.subtitle = element_text(size = 11, hjust = 0),
      plot.caption = element_text(size = 9, hjust = 1, color = "gray40"),
      axis.title = element_text(face = "bold"),
      axis.text = element_text(color = "gray20"),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(linewidth = 0.3, color = "gray85"),
      plot.margin = margin(12, 16, 12, 12)
    )
}

# Number of speeches over time 
plot_speeches <- ggplot(speeches_per_year, aes(x = year, y = num_speeches)) +
  geom_area(alpha = 0.30) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq(min(speeches_per_year$year), max(speeches_per_year$year), by = 1)) +
  labs(
    title = "Number of House Floor Speeches per Year",
    subtitle = "Analysis-ready speeches, 2010–2025",
    x = "Year",
    y = "Number of speeches",
    caption = "Source: U.S. Congressional Record"
  ) +
  project_theme()

# Average Flesch-Kincaid grade level over time 
plot_fk <- ggplot(fk_by_year, aes(x = year, y = avg_fk_grade)) +
  geom_ribbon(
    aes(ymin = p25_fk_grade, ymax = p75_fk_grade),
    alpha = 0.18
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq(min(fk_by_year$year), max(fk_by_year$year), by = 1)) +
  labs(
    title = "Average Flesch-Kincaid Grade Level by Year",
    subtitle = "Higher values indicate more difficult or more structurally demanding texts",
    x = "Year",
    y = "Average Flesch-Kincaid Grade Level",
    caption = "Ribbon shows the 25th–75th percentile range"
  ) +
  project_theme()
plot_fk

# Average sentence length over time 
plot_sentence_length <- ggplot(sentence_complexity_by_year, aes(x = year, y = avg_sentence_length)) +
  geom_ribbon(
    aes(ymin = p25_sentence_length, ymax = p75_sentence_length),
    alpha = 0.18
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq(min(sentence_complexity_by_year$year), max(sentence_complexity_by_year$year), by = 1)) +
  labs(
    title = "Average Sentence Length by Year",
    subtitle = "Measured as average words per sentence in each year",
    x = "Year",
    y = "Average words per sentence",
    caption = "Ribbon shows the 25th–75th percentile range"
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

# Regressions 
model_fk <- lm(fk_grade ~ year, data = analysis_data)
model_sentence_length <- lm(avg_sentence_length ~ year, data = analysis_data)
model_word_count <- lm(word_count ~ year, data = analysis_data)

# Extracting coefficients
model_coefficients <- dplyr::bind_rows(
  bDroom::tidy(model_fk) |>
    dplyr::mutate(model = "flesch_kincaid"),
  broom::tidy(model_sentence_length) |>
    dplyr::mutate(model = "sentence_length"),
  broom::tidy(model_word_count) |>
    dplyr::mutate(model = "word_count")
)

# Extracting model fit statistics
model_fit <- dplyr::bind_rows(
  broom::glance(model_fk) |>
    dplyr::mutate(model = "flesch_kincaid"),
  broom::glance(model_sentence_length) |>
    dplyr::mutate(model = "sentence_length"),
  broom::glance(model_word_count) |>
    dplyr::mutate(model = "word_count")
)

readr::write_csv(
  model_coefficients,
  file.path(output_tables_path, "09_model_coefficients.csv")
)

readr::write_csv(
  model_fit,
  file.path(output_tables_path, "09_model_fit.csv")
)

print(model_coefficients |> dplyr::filter(term == "year"))
print(model_fit |> dplyr::select(model, r.squared, adj.r.squared, sigma, statistic, p.value))





