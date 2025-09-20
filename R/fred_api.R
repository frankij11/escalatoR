#' FRED API Connection and Data Retrieval Functions
#' @description Functions to connect to FRED API and retrieve PPI indices

#' Initialize FRED API connection
#' @param api_key FRED API key (get from https://fred.stlouisfed.org/docs/api/api_key.html)
#' @return TRUE if successful
#' @export
init_fred_api <- function(api_key = NULL) {
  if (is.null(api_key)) {
    api_key <- Sys.getenv("FRED_API_KEY")
    fredr::fredr_set_key(api_key)
     message("✓ FRED API connection initialized")
    return(TRUE)

  }
    if (api_key == "") {
    readline(prompt = "FRED API key required. Press Enter to exit.")
    fredr::fredr_set_key(api_key)
    message("✓ FRED API connection initialized")
    return(TRUE)
  } else {
    stop("FRED API key required. Set FRED_API_KEY environment variable or pass api_key parameter.")
  }
  fredr::fredr_set_key(api_key)
  message("✓ FRED API connection initialized")
  return(TRUE)
}

#' Search for PPI indices matching criteria
#' @param search_text Search terms (e.g., "aircraft", "electronics")
#' @param category Defense sector category filter
#' @return Data frame of matching series
#' @export
search_ppi_indices <- function(search_text, category = NULL) {
  defense_categories <- list(
    aircraft = c("PCU3364133641", "PCU336411336411", "PCU336412336412"),
    missiles = c("PCU336414336414", "PCU336415336415"),
    naval = c("PCU336612336612"),
    electronics = c("PCU334511334511"),
    munitions = c("PCU332992332992", "PCU332993332993"),
    services = c("PPIENG"),
    reference = c("PPIACO", "PPIFGS")
  )
  results <- fredr::fredr_series_search_text(
    search_text = paste("PPI", search_text),
    limit = 100
  )
  if (!is.null(category) && category %in% names(defense_categories)) {
    relevant_ids <- defense_categories[[category]]
    results <- results %>%
      dplyr::filter(id %in% relevant_ids)
  }
  results <- results %>%
    dplyr::mutate(
      defense_category = dplyr::case_when(
        id %in% defense_categories$aircraft ~ "Aircraft",
        id %in% defense_categories$missiles ~ "Missiles",
        id %in% defense_categories$naval ~ "Naval",
        id %in% defense_categories$electronics ~ "Electronics",
        id %in% defense_categories$munitions ~ "Munitions",
        id %in% defense_categories$services ~ "Services",
        TRUE ~ "Other"
      ),
      cape_recommended = defense_category != "Other"
    )
  return(results)
}

#' Download PPI index data from FRED
#' @param series_id FRED series ID (e.g., "PCU3364133641")
#' @param start_date Start date for data retrieval
#' @param end_date End date for data retrieval
#' @return Data frame with index values
#' @export
download_ppi_index <- function(series_id, 
                              start_date = "1990-01-01",
                              end_date = Sys.Date()) {
  data <- fredr::fredr(
    series_id = series_id,
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)
  )
  series_info <- fredr::fredr_series(series_id)
  data <- data %>%
    dplyr::mutate(
      series_name = series_info$title[1],
      units = series_info$units[1],
      frequency = series_info$frequency[1],
      last_updated = series_info$last_updated[1]
    )
  return(data)
}
