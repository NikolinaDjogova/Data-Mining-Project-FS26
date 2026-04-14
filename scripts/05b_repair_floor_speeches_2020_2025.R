rm(list = ls())

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("The key is missing from the environment")
}

# Ensuring output folders exist
dir.create(raw_congressional_record_path, recursive = TRUE, showWarnings = FALSE)
dir.create(interim_floor_speeches_path, recursive = TRUE, showWarnings = FALSE)

# Checking that the required raw metadata file exists
raw_recent_file <- file.path(
  raw_congressional_record_path,
  "house_granules_2020_2025_raw.csv"
)

if (!file.exists(raw_recent_file)) {
  stop("Required raw metadata file for 2020-2025 does not exist")
}

# Loading the already-saved raw metadata for 2020-2025
all_house_granules_recent <- readr::read_csv(
  file.path(raw_congressional_record_path, "house_granules_2020_2025_raw.csv"),
  show_col_types = FALSE
)

# Filtering out procedural items
kept_granules_recent <- all_house_granules_recent |>
  dplyr::filter(!title %in% excluded_titles)

# Splitting into chunks of 100
chunk_size <- 100

granule_chunks_recent <- split(
  kept_granules_recent,
  ceiling(seq_len(nrow(kept_granules_recent)) / chunk_size)
)

# Text collection for missing years 
 ### I'm reusing the same code just adjusting the years 
message("Starting chunked text collection for 2020-2025")

for (i in seq_along(granule_chunks_recent)) {
  
  output_file <- file.path(
    interim_floor_speeches_path,
    paste0("floor_speeches_recent_chunk_", i, ".csv")
  )
  
  if (file.exists(output_file)) {
    message("Skipping existing recent chunk ", i)
    next
  }
  
  message("Processing recent chunk ", i, " of ", length(granule_chunks_recent))
  
  chunk_data <- granule_chunks_recent[[i]]
  
  chunk_result <- chunk_data |>
    dplyr::transmute(
      date = as.Date(dateIssued),
      package_id,
      granule_id = granuleId,
      title,
      type = granuleClass,
      text = purrr::map_chr(
        seq_along(granuleLink),
        function(j) {
          message("  Granule ", j, " of ", nrow(chunk_data), " in recent chunk ", i)
          Sys.sleep(0.2)
          get_granule_text_wrapper(granuleLink[j], api_key)
        }
      )
    ) |>
    dplyr::mutate(
      word_count = stringr::str_count(text, "\\S+"),
      text_missing = is.na(text),
      short_text = word_count < 50
    ) |>
    dplyr::distinct(granule_id, .keep_all = TRUE) |>
    dplyr::arrange(date, granule_id)
  
  readr::write_csv(
    chunk_result,
    output_file
  )
}

message("Finished chunked text collection for 2020-2025")
