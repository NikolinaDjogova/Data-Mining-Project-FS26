get_house_granules <- function(package_id, api_key) {
  summary_url <- paste0(
    "https://api.govinfo.gov/packages/",
    package_id,
    "/summary?api_key=",
    api_key
  )
  summary_json <- jsonlite::fromJSON(
    httr::content(httr::GET(summary_url), as = "text", encoding = "UTF-8")
  )
  granules_url <- paste0(summary_json$granulesLink, "&api_key=", api_key)
  granules_json <- jsonlite::fromJSON(
    httr::content(httr::GET(granules_url), as = "text", encoding = "UTF-8")
  )
  granules_json$granules |>
    dplyr::filter(granuleClass == "HOUSE") |>
    dplyr::mutate(package_id = package_id)
}
  
  
get_granule_text <- function(granule_link, api_key) {
  granule_url <- paste0(granule_link, "?api_key=", api_key)
  granule_json <- jsonlite::fromJSON(
    httr::content(httr::GET(granule_url), as = "text", encoding = "UTF-8")
  )
  
  text_url <- paste0(granule_json$download$txtLink, "?api_key=", api_key)
  raw_text <- httr::content(httr::GET(text_url), as = "text", encoding = "UTF-8")
  raw_text |>
    xml2::read_html() |>
    rvest::html_element("pre") |>
    rvest::html_text() |>
    stringr::str_squish()
}

excluded_titles <- c(
  "House of Representatives",
  "PRAYER",
  "THE JOURNAL",
  "PLEDGE OF ALLEGIANCE",
  "ADJOURNMENT",
  "RECESS",
  "AFTER RECESS",
  "MESSAGES FROM THE PRESIDENT",
  "EXECUTIVE COMMUNICATIONS, ETC.",
  "REPORTS OF COMMITTEES ON PUBLIC BILLS AND RESOLUTIONS",
  "PUBLIC BILLS AND RESOLUTIONS",
  "ADDITIONAL SPONSORS",
  "DISCHARGE PETITIONS",
  "DISCHARGE PETITIONS-- ADDITIONS AND WITHDRAWALS"
)

get_house_granules_wrapper <- function(package_id, api_key) {
  tryCatch(
    get_house_granules(package_id, api_key),
    error = function(e) {
      message(paste("Error in package:", package_id, "-", e$message))
      return(tibble::tibble())
    }
  )
}

get_granule_text_wrapper <- function(granule_link, api_key) {
  tryCatch(
    get_granule_text(granule_link, api_key),
    error = function(e) {
      message(paste("Error in granule link:", granule_link, "-", e$message))
      return(NA_character_)
    }
  )
}