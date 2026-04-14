#Linguistic Complexity in U.S House Floor Speech Over Time

This repository contains code and documentation for a data mining project developed as part of the course:

**Data Access and Data Mining for Social Sciences**

University of Lucerne

Student Nikolina Djogova  
Term: Spring 2026

## Project Goal
The goal of this project is to build a reproducible data pipeline in R to collect, process, and analyze speech data from the U.S. House of Representatives.

## Research Question

Has linguistic complexity in U.S. House floor speeches changed over time between 2010 and 2025?

## Data Source

Source: U.S. Congressional Record / GovInfo
Access method: API requests (HTTP GET)
Format: JSON / text
Unit of analysis: individual speech

## Measures 

- Flesch-Kincaid readability
- Average sentence length
- Average word length
- Additional text-based measures where implemented in the scripts 

## Repository Structure

scripts/          R scripts for data collection, cleaning, and analysis 
data/raw/         raw downloaded data (not tracked by Git) 
data/interim/     intermediate files (not tracked by Git) 
data/processed/   processed datasets (not tracked by Git) 
output/           figures, tables, logs, and checks (not tracked by Git) 
README.md         project description


## Reproducibility

To reproduce this project:

- Clone the repository  
- Add API credentials to `.Renviron`  
- Install required R packages  
- Run scripts in sequential order 

All data files used for analysis are generated programmatically by the scripts. Raw data and credentials are not stored in the repository.

## Data Management and Security

- Raw data is not pushed to GitHub
- Processed data is not pushed to GitHub
- API keys are stored outside the repository
- .gitignore excludes sensitive files and generated outputs

## Limitations
This project focuses on House floor speech collected through the GovInfo API. Linguistic complexity measures capture only certain dimensions of political communication and do not directly measure meaning, persuasion, or intent. Observed differences over time may also reflect institutional factors, topic variation, or data limitations rather than purely changes in communication strategy.