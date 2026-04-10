rm(list = ls())
source(here::here("scripts", "00_setup.R"))

# Making sure the interim floor speeches exist
if (!dir.exists(interim_floor_speeches_path)) {
  stop("Interim floor speeches folder does not exist")
}

# Get all chunk files
chunk_files <- list.files(
  interim_floor_speeches_path,
  pattern = "^floor_speeches_chunk_[0-9]+\\.csv$",
  full.names = TRUE
)

