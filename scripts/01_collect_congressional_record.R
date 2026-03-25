# Making sure I start with a clean environment
rm(list = ls())

# Loading project setup 
source(here::here("scripts", "00_setup.R"))

# Acquired the API key, credentials are being kept in the R environment.

api_key <- Sys.getenv("GOVINFO_API_KEY")
if (api_key == "") {
  stop("API key is missing from the R environment")
} else {
  message("It works! API key successfully retrieved.")
}

# Defining one test package 
test_package <- "CREC-2026-02-11"

# Building request URL
base_url <- "https://api.govinfo.gov/packages"
summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=", api_key)

# Safe version for checking the structure
safe_summary_url <- paste0(base_url, "/", test_package, "/summary?api_key=hidden")
safe_summary_url

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

# Extracting the text link
text_url <- paste0(example_json$download$txtLink, "?api_key=", api_key)
text_response <- httr::GET(text_url)
httr::status_code(text_response)
granule_text <- httr::content(text_response, as = "text", encoding = "UTF-8")
granule_text
 ##I found the actual text, but it's not in a very structured format.

# Parsing the returned html
granule_html <- xml2::read_html(granule_text)

# Extraxting the main preformatted text block
clean_text <- granule_html |>
  rvest::html_element("pre") |>
  rvest::html_text()

clean_text

# Inspecting the titles 
house_granules$title
## The titles are not very informative.

#Inspecting one substantive House granule 
example_url <- paste0(house_granules$granuleLink[9], "?api_key=", api_key)
example_response <- httr::GET(example_url)
example_json <- jsonlite::fromJSON(
  httr::content(example_response, as = "text", encoding = "UTF-8")
)
str(example_json)
 ##Finally, I see real progress, this granule is a speech, includes members, speaker, discussion window, title..

# Extracting the text link
text_url <- paste0(example_json$download$txtLink, "?api_key=", api_key)
text_response <- httr::GET(text_url)
httr::status_code(text_response)

# Parsing the returned text 
granule_text <- httr::content(text_response, as = "text", encoding = "UTF-8")
granule_html <- xml2::read_html(granule_text)
clean_text <- granule_html |>
  rvest::html_element("pre") |>
  rvest::html_text()
clean_text
 ##The full pipeline works. A useful House granule does have substantial legislative debate text.

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
 
# Function to retrieve text from one granule
get_granule_text <- function(granule_link, api_key) {
  granule_url <- paste0(granule_link, "?api_key=", api_key)
  granule_response <- httr::GET(granule_url)
  granule_json <- jsonlite::fromJSON(
    httr::content(granule_response, as = "text", encoding = "UTF-8")
  )
  text_url <- paste0(granule_json$download$txtLink, "?api_key=", api_key)
  text_response <- httr::GET(text_url)
  granule_text <- httr::content(text_response, as = "text", encoding = "UTF-8")
  granule_html <- xml2::read_html(granule_text)
  clean_text <- granule_html |>
    rvest::html_element("pre") |>
    rvest::html_text()
  return(clean_text)
}

# Testing the function
example_text <- get_granule_text(house_granules$granuleLink[9], api_key)
example_text

# Testing the function on a few granules to make sure it works 
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
