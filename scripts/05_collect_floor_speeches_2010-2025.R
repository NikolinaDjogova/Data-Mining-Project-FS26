# Starting with a clean environment 
rm(list = ls())

# Loading project setup 
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

# Getting the API key
api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Ensuring output folders exist
dir.create(raw_congressional_record_path, recursive = TRUE, showWarnings = FALSE)
dir.create(interim_floor_speeches_path, recursive = TRUE, showWarnings = FALSE)

# Defining the full date range 
all_dates <- seq.Date(
  from = as.Date ("2010-01-01"),
  to = as.Date("2025-12-31"),
  by = "day"
)

# Building package IDs for the full date range
package_ids <- paste0("CREC-", all_dates)

# Wrapper for packages 
get_house_granules_wrapper <- function(package_id, api_key) {
  tryCatch(
    get_house_granules(package_id, api_key),
    error = function(e) {
      message(paste("Error in package:", package_id, " - ", e$message))
      return(tibble::tibble())
    }
  )
}

# Wrapper for granules 
get_granule_text_wrapper <- function(granule_link, api_key) {
  tryCatch(
    get_granule_text(granule_link, api_key),
    error = function(e) {
      message(paste("Error in granule link:", granule_link, " - ", e$message))
      return(NA_character_)
    }
  )
}

# Collecting House granules data from all package ids
  ##this will probably take long, so I want to know when it starts and ends 

message("Starting package collection")

all_house_granules <- purrr::map_dfr(
  package_ids,
  function(pkg){
    message("Processing package:", pkg)
    Sys.sleep(0.2)
    get_house_granules_wrapper(pkg, api_key)
  }
)

message("Finished package collection")

# Saving the raw House granule metadata 
readr::write_csv(
  all_house_granules,
  file.path(raw_congressional_record_path, "house_granules_2010_2025_raw.csv")
)

# Filtering out procedural items 
kept_granules <- all_house_granules |>
  dplyr::filter(
    !title %in% excluded_titles
  )

# Splitting the data into chunks of 100 granules each
chunk_size <- 100

granule_chunks <- split(
  kept_granules,
  ceiling(seq_len(nrow(kept_granules)) / chunk_size)
)

# Creating an empty list to store chunk results
floor_speeches_chunks <- vector("list", length(granule_chunks))

message("Starting chunked text collection")

for (i in seq_along(granule_chunks)) {
  
  message("Processing chunk ", i, " of ", length(granule_chunks))
  
  chunk_data <- granule_chunks[[i]]
  
  floor_speeches_chunks[[i]] <- chunk_data |>
    dplyr::transmute(
      date = as.Date(dateIssued),
      package_id,
      granule_id = granuleId,
      title,
      type = granuleClass,
      text = purrr::map_chr(
        seq_along(granuleLink),
        function(j) {
          message("  Granule ", j, " of ", nrow(chunk_data), " in chunk ", i)
          Sys.sleep(0.2)
          get_granule_text_wrapper(granuleLink[j], api_key)
        }
      )
    ) |>
    dplyr::mutate(
      word_count = stringr::str_count(text, "\\S+")
    ) |>
    dplyr::filter(!is.na(text), word_count >= 50) |>
    dplyr::distinct(granule_id, .keep_all = TRUE) |>
    dplyr::arrange(date, granule_id)
  
  # Saving each chunk immediately
  readr::write_csv(
    floor_speeches_chunks[[i]],
    file.path(
      interim_floor_speeches_path,
      paste0("floor_speeches_chunk_", i, ".csv")
    )
  )
}

message("Finished chunked text collection")


