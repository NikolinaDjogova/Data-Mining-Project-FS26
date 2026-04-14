# Making sure I start with a clean environment
rm(list = ls())

# Loading project setup 
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "reusables.R"))

# Acquired the API key, credentials are being kept in the R environment.

api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("API key is missing from the R environment")
} 

# Defining one test package 
test_package <- "CREC-2026-02-11"

# Building request URL
base_url <- "https://api.govinfo.gov/packages"
summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=", api_key)

# Sending a GET request 
response <- httr::GET(summary_url)

# Checking the status 
httr::status_code(response)

# Extracting content as text 
content_text <- httr::content(response, as = "text", encoding = "UTF-8")

# Converting JSON to an R object
content_json <- jsonlite::fromJSON(content_text)

# Inspecting the structure
str(content_json)

# Getting the granules link 
granules_url <- paste0(content_json$granulesLink, "&api_key=", api_key)

# Sending a GET request to the granules endpoint
granules_response <- httr::GET(granules_url)

# Checking the status
httr::status_code(granules_response)

# Parsing JSON
granules_text <- httr::content(granules_response, as = "text", encoding = "UTF-8")
granules_json <- jsonlite::fromJSON(granules_text)

# Inspecting the structure
str(granules_json)

# Checking the first few granules 
head(granules_json$granules)

# Checking their classes 
table(granules_json$granules$granuleClass)
 ##I'll need to filter for only House of Reps relevant material.

# Filtering only the House of Representatives material 
house_granules <- granules_json$granules |>
  dplyr::filter(granuleClass == "HOUSE")

# Inspecting 
nrow(house_granules)
head(house_granules)
 ##Granulates aren't always speeches, they include procedural items too.

# Example House granule
example_url <- paste0(house_granules$granuleLink[1], "?api_key=", api_key)
example_response <- httr::GET(example_url)
example_json <- jsonlite::fromJSON(
  httr::content(example_response, as = "text", encoding = "UTF-8")
  )
str(example_json)
 ##the summary includes metadata, and doesn't give me the actual text yet. 

#Inspecting one substantive House granule 
example_url <- paste0(house_granules$granuleLink[9], "?api_key=", api_key)
example_response <- httr::GET(example_url)
example_json <- jsonlite::fromJSON(
  httr::content(example_response, as = "text", encoding = "UTF-8")
)
str(example_json)
 ##Finally, I see real progress, this granule is a speech, includes members, speaker, discussion window, title..

# Using the reusable function to retrieve clean text
clean_text <- get_granule_text(house_granules$granuleLink[9], api_key)

clean_text

# Creating a small df from one speech for testing
example_granule_df <- tibble::tibble(
  date = example_json$dateIssued,
  package_id = example_json$packageId,
  granule_id = example_json$granuleId,
  title = example_json$title,
  type = example_json$granuleClass,
  subtype = example_json$subGranuleClass,
  text = stringr::str_squish(clean_text)
)

example_granule_df

# Saving this as a test file for now
readr::write_csv(
  example_granule_df, 
  here::here("output", "checks", "example_house_granule.csv")
  )

# Testing the reusable text function on a few granules to make sure it works 
test_text_1 <- get_granule_text(house_granules$granuleLink[8], api_key)
test_text_2 <- get_granule_text(house_granules$granuleLink[9], api_key)
test_text_3 <- get_granule_text(house_granules$granuleLink[12], api_key)

# Checking the first part of each text
substr(test_text_1, 1, 500)
substr(test_text_2, 1, 500)
substr(test_text_3, 1, 500)

# Creating small dataset from a few granules 
example_dataset <- tibble::tibble(
  date = c(
    house_granules$dateIssued[8],
    house_granules$dateIssued[9],
    house_granules$dateIssued[12]
  ),
  granule_id = c(
    house_granules$granuleId[8],
    house_granules$granuleId[9],
    house_granules$granuleId[12]
  ),
  title = c(
    house_granules$title[8],
    house_granules$title[9],
    house_granules$title[12]
  ),
  type = c(
    house_granules$granuleClass[8],
    house_granules$granuleClass[9],
    house_granules$granuleClass[12]
  ),
  text = c(test_text_1, test_text_2, test_text_3)
)

example_dataset

# Saving the test dataset
readr::write_csv(
  example_dataset,
  here::here("output", "checks", "example_house_granules.csv")
)
