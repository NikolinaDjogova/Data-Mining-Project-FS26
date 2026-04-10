rm(list = ls())
source(here::here("scripts", "00_setup.R"))

# Making sure the interim floor speeches exist
if (!dir.exists(interim_floor_speeches_path)) {
  stop("Interim floor speeches folder does not exist")
}
