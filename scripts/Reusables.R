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

# Plotting palette
blue_dark <- "#16324F"
blue_mid <- "#2F6690"
blue_light <- "#77A6C6"
blue_fill <- "#D9EAF4"
black_soft <- "#1F1F1F"
gray_soft <- "#6B7280"

# Reusable project theme
project_theme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", size = 15, hjust = 0, color = black_soft
      ),
      plot.subtitle = ggplot2::element_text(
        size = 11, hjust = 0, color = gray_soft
      ),
      plot.caption = ggplot2::element_text(
        size = 9, hjust = 1, color = "gray40"
      ),
      axis.title = ggplot2::element_text(
        face = "bold", color = black_soft
      ),
      axis.text = ggplot2::element_text(color = "gray20"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(
        linewidth = 0.3, color = "gray85"
      ),
      plot.margin = ggplot2::margin(12, 16, 12, 12)
    )
}
