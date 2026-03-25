# Removing everything that's currently in my environment
rm(list = ls())

# Loading packages I might need 
library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)
library(here)

# Making sure that text is not automatically turned into factors
options(stringsAsFactors = FALSE)
# Reducting scientific notation in printed numbers
options(scipen = 999)

# Project paths 
## Creating objects storing the path to folders
data_raw_path <- here("data", "raw")
data_interim_path <- here("data", "interim")
data_processed_path <- here("data", "processed")

raw_congressional_record_path <- here("data", "raw", "congressional_record")
raw_press_releases_path <- here("data", "raw", "press_releases")

interim_floor_speeches_path <- here("data", "interim", "floor_speeches_clean")
interim_press_releases_path <- here("data", "interim", "press_releases_clean")
matched_members_path <- here("data", "interim", "matched_members")

output_figures_path <- here("output", "figures")
output_tables_path <- here("output", "tables")
output_logs_path <- here("output", "logs")
output_checks_path <- here("output", "checks")

# Confirmation
message("Setup complete.")
message("Project root: ", here())
