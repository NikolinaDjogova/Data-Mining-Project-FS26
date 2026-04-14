---
editor_options: 
  markdown: 
    wrap: 72
---

# Linguistic Complexity in U.S House Floor Speech Over Time

This repository contains code and documentation for a data mining
project developed as part of the course:

**Data Access and Data Mining for Social Sciences**

University of Lucerne

Student Nikolina Djogova\
Term: Spring 2026

## Project Goal

This project examines whether linguistic complexity in U.S. House floor
speeches has changed over time. Using a computational text analysis
approach, it analyzes speeches from 2010 to 2025 to identify patterns in
speech length, sentence structure, and readability.

The goal is to assess whether institutional political language has
become simpler, more complex, or remained stable, and what this reveals
about broader changes in political communication.

## Research Question

Has linguistic complexity in U.S. House floor speeches changed over time
between 2010 and 2025?

## Data Source

Source: U.S. Congressional Record / GovInfo\
Access method: API requests (HTTP GET)\
Format: JSON / text\
Unit of analysis: individual speech

## Methodological Approach

1\. Collect Congressional Record data via the GovInfo API\
2. Extract and filter House-related speech content\
3. Clean and preprocess text data\
4. Construct measures of linguistic complexity\
5. Analyze trends over time

## Measures

-   Flesch-Kincaid readability
-   Average sentence length
-   Word count
-   Additional text-based measures where implemented in the scripts

These measures capture different dimensions of complexity, including
readability, structural variation, and speech length.

## Repository Structure

scripts/ R scripts for data collection, cleaning, and analysis\
data/raw/ raw downloaded data (not tracked by Git)\
data/interim/ intermediate files (not tracked by Git) data/processed/
processed datasets (not tracked by Git) output/ figures, tables, logs,
and checks (not tracked by Git)\
README.md project description

## Reproducibility

To reproduce this project please run scripts in sequential order
(starting from \`00_setup.R\`)\
\
All data used in the analysis is generated programmatically.\
\
Raw data and API credentials are not stored in the repository.

## Data Management and Security

-   Raw data is not pushed to GitHub
-   Processed data is not pushed to GitHub
-   API keys are stored outside the repository
-   .gitignore excludes sensitive files and generated outputs

## Limitations

This project focuses on House floor speech collected through the GovInfo
API. Linguistic complexity measures capture only certain dimensions of
political communication and do not directly measure meaning, persuasion,
or intent. Observed differences over time may also reflect institutional
factors, topic variation, or data limitations rather than purely changes
in communication strategy.
