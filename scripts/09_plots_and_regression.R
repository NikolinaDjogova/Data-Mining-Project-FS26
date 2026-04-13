rm(list = ls())

source(here::here("scripts", "00_setup.R"))

dir.create(output_tables_path, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures_path, recursive = TRUE, showWarnings = FALSE)

library(dplyr)
library(readr)
library(ggplot2)
library(broom)

