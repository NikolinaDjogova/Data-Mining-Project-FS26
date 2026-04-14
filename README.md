#Linguistic Complexity in U.S House Floor Speech Over Time

This repository contains code and documentation for a data mining project developed as part of the course:

**Data Access and Data Mining for Social Sciences**

University of Lucerne

Student Nikolina Djogova  
Term: Spring 2026

## Project Goal
The goal of this project is to build a reproducible data pipeline in R to collect, process, and analyze speech data from the U.S. House of Representatives.

## Research Question

Do members of the U.S. House of Representatives use less linguistically complex language in more strategic forms of floor speech than in regular floor speech, and has linguistic complexity in House speech changed over time?

## Data Source

Source: U.S. Congressional Record / GovInfo
Access method: API requests (HTTP GET)
Format: JSON / text
Unit of analysis: individual speech

## Measures 

Flesch-Kincaid readability
average sentence length
average word length
lexical diversity measures where available in the scripts

## Repository Structure

scripts/          R scripts for data collection, cleaning, and analysis 
data/raw/         raw downloaded data (not tracked by Git) 
data/interim/     intermediate files (not tracked by Git) 
data/processed/   processed datasets (not tracked by Git) 
output/           figures, tables, logs, and checks (not tracked by Git) 
README.md         project description


## Reproducibility

To reproduce this project:

Clone the repository
Add required API credentials to .env or .Renviron
Install the required R packages
Run the scripts in the project workflow order

All data files used for analysis are generated programmatically by the scripts. Raw data and credentials are not stored in the repository.


## Data Management and Security

raw data is not pushed to GitHub
processed data is not pushed to GitHub
API keys are stored outside the repository
.gitignore excludes sensitive files and generated outputs

## Limitations
This project focuses on House speech available through the selected data pipeline. Linguistic complexity measures capture only certain aspects of political communication and do not directly measure democratic quality, intent, or persuasion. Where speech types differ, these differences may also reflect institutional format rather than audience adaptation alone.