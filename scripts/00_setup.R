# Loading packages I might need 

library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)
library(lubridate)
installed.packages("here")
library(here)

#Setting reproducible paths
data_raw_path <- here("data", "raw")
data_interim_path <- here("data", "interim")
data_processed_path <- here("data", "processed")

# Setting options
options(stringsAsFactors = FALSE)

