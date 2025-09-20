#' Data Processing and Transformation Functions

#' Fill missing values with linear interpolation
#' @param data Data frame with date and value columns
#' @param method Interpolation method ("linear", "spline", "previous")
#' @return Data frame with interpolated values
#' @export
 #' @importFrom dplyr arrange left_join
 #' @importFrom tibble tibble
 #' @importFrom zoo na.approx
 fill_missing_values <- function(data, method = "linear") {
  # Generate complete monthly date sequence
  # find the month associated with the start of the fiscal year
  min_date <- min(data$date)
  max_date <- max(data$date)
  all_dates <- tibble::tibble(date = seq(min_date, max_date, by = "month"))

   # Assumes 'date' column is Date type
   data <- all_dates %>%
     dplyr::left_join(data, by = "date") %>%
     dplyr::arrange(date) %>%
     dplyr::mutate(
       original_value = value,
       interpolated = is.na(value)
     )
  
   # Interpolate missing values
   if (method == "linear") {
     data <- data %>%
       dplyr::mutate(value = zoo::na.approx(value, na.rm = FALSE))
   } else if (method == "spline") {
     data <- data %>%
       dplyr::mutate(value = zoo::na.spline(value, na.rm = FALSE))
   } else if (method == "previous") {
     data <- data %>%
       dplyr::mutate(value = zoo::na.locf(value, na.rm = FALSE))
   }

   # Fill remaining NAs at boundaries
  data$value <- zoo::na.locf(data$value, fromLast = TRUE, na.rm = FALSE)
  data$value <- zoo::na.locf(data$value, na.rm = FALSE)
  
  message(sprintf("✓ Filled %d missing values using %s interpolation",
                 sum(data$interpolated, na.rm = TRUE), method))

   return(data)
 }

#' Convert monthly data to fiscal year
#' @param data Data frame with monthly data
#' @param fy_start_month Starting month of fiscal year (default 10 for October)
#' @param aggregation Aggregation method ("mean", "end", "start")
#' @return Data frame with fiscal year data
#' @export
 #' @importFrom dplyr mutate group_by summarise filter pull bind_rows ungroup arrange slice_tail n across
 #' @importFrom lubridate month year
 convert_to_fiscal_year <- function(data, fy_start_month = 10, aggregation = "end", handle_partial = "drop") {
   # Add fiscal year column
  data <- data %>%
    dplyr::mutate(
      calendar_year = lubridate::year(date),
      calendar_month = lubridate::month(date),
      fiscal_year = dplyr::if_else(
        calendar_month >= fy_start_month,
        calendar_year + 1,
        calendar_year
      )
    )
  
  # Aggregate by fiscal year
  fy_data <- data %>%
    dplyr::group_by(fiscal_year, series_id) %>%
    dplyr::summarise(
      n_months = dplyr::n(),
      start_date = min(date),
      end_date = max(date),
      index_value = dplyr::case_when(
        aggregation == "mean" ~ mean(value, na.rm = TRUE),
        aggregation == "end" ~ dplyr::last(value),
        aggregation == "start" ~ dplyr::first(value),
        TRUE ~ mean(value, na.rm = TRUE)
      ),
      .groups = 'drop'
    )

  # Handle partial fiscal years
  if (handle_partial == "drop") {
    fy_data <- fy_data %>%
      dplyr::filter(n_months == 12)

  }else if (handle_partial == "extrapolate") {
     # Extrapolate partial fiscal years to full year
     fy_data <- fy_data %>%
       dplyr::mutate(
         index_value = ifelse(
           n_months < 12,
           index_value + ((index_value - lag(index_value)) * (12 / n_months)),
           index_value
         )
       )
    
  }
  
  return(fy_data)
   }
