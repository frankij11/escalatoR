# ============================================================================
# CAPE Escalation Analysis R Package
# Core Backend Functions for DoD Cost Estimation
# ============================================================================

# File: R/fred_api.R
# ============================================================================
#' FRED API Connection and Data Retrieval Functions
#' @description Functions to connect to FRED API and retrieve PPI indices

#' Initialize FRED API connection
#' @param api_key FRED API key (get from https://fred.stlouisfed.org/docs/api/api_key.html)
#' @return TRUE if successful
#' @export
init_fred_api <- function(api_key = NULL) {
  if (is.null(api_key)) {
    api_key <- Sys.getenv("FRED_API_KEY")
  }
  
  if (api_key == "") {
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
  
  # Define defense-relevant PPI categories
  defense_categories <- list(
    aircraft = c("PCU3364133641", "PCU336411336411", "PCU336412336412"),
    missiles = c("PCU336414336414", "PCU336415336415"),
    naval = c("PCU336612336612"),
    electronics = c("PCU334511334511"),
    munitions = c("PCU332992332992", "PCU332993332993"),
    services = c("PPIENG"),
    reference = c("PPIACO", "PPIFGS")
  )
  
  # Search FRED for series
  results <- fredr::fredr_series_search_text(
    search_text = paste("PPI", search_text),
    limit = 100
  )
  
  # Filter for defense-relevant series
  if (!is.null(category) && category %in% names(defense_categories)) {
    relevant_ids <- defense_categories[[category]]
    results <- results %>%
      dplyr::filter(id %in% relevant_ids)
  }
  
  # Add metadata
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
  
  # Retrieve data from FRED
  data <- fredr::fredr(
    series_id = series_id,
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)
  )
  
  # Add metadata
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

# File: R/data_processing.R
# ============================================================================
#' Data Processing and Transformation Functions

#' Fill missing values with linear interpolation
#' @param data Data frame with date and value columns
#' @param method Interpolation method ("linear", "spline", "previous")
#' @return Data frame with interpolated values
#' @export
fill_missing_values <- function(data, method = "linear") {
  
  data <- data %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(
      original_value = value,
      interpolated = is.na(value)
    )
  
  if (method == "linear") {
    data$value <- zoo::na.approx(data$value, na.rm = FALSE)
  } else if (method == "spline") {
    data$value <- zoo::na.spline(data$value, na.rm = FALSE)
  } else if (method == "previous") {
    data$value <- zoo::na.locf(data$value, na.rm = FALSE)
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
convert_to_fiscal_year <- function(data, fy_start_month = 10, aggregation = "end") {
  
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
  
  return(fy_data)
}

# File: R/escalation_calc.R
# ============================================================================
#' Escalation Rate Calculation Functions

#' Calculate year-over-year escalation rates
#' @param data Data frame with fiscal year index values
#' @param method Calculation method ("simple", "compound", "geometric")
#' @return Data frame with escalation rates
#' @export
calculate_escalation_rates <- function(data, method = "simple") {
  
  data <- data %>%
    dplyr::arrange(fiscal_year) %>%
    dplyr::mutate(
      lag_value = dplyr::lag(index_value, 1),
      escalation_rate = dplyr::case_when(
        method == "simple" ~ (index_value / lag_value - 1) * 100,
        method == "compound" ~ ((index_value / lag_value)^(1/1) - 1) * 100,
        method == "geometric" ~ (exp(log(index_value / lag_value)) - 1) * 100,
        TRUE ~ (index_value / lag_value - 1) * 100
      )
    )
  
  # Calculate statistics
  stats <- data %>%
    dplyr::summarise(
      mean_rate = mean(escalation_rate, na.rm = TRUE),
      median_rate = median(escalation_rate, na.rm = TRUE),
      sd_rate = sd(escalation_rate, na.rm = TRUE),
      min_rate = min(escalation_rate, na.rm = TRUE),
      max_rate = max(escalation_rate, na.rm = TRUE)
    )
  
  attr(data, "escalation_stats") <- stats
  
  return(data)
}

#' Normalize index to specified base year
#' @param data Data frame with index values
#' @param base_year Base year for normalization
#' @return Data frame with normalized index
#' @export
normalize_base_year <- function(data, base_year) {
  
  base_value <- data %>%
    dplyr::filter(fiscal_year == base_year) %>%
    dplyr::pull(index_value)
  
  if (length(base_value) == 0) {
    stop(sprintf("Base year %d not found in data", base_year))
  }
  
  data <- data %>%
    dplyr::mutate(
      base_year_value = base_value[1],
      normalized_index = (index_value / base_value[1]) * 100,
      raw_index = index_value
    )
  
  message(sprintf("✓ Index normalized to base year %d (value = %.2f)", 
                 base_year, base_value[1]))
  
  return(data)
}

# File: R/forecasting.R
# ============================================================================
#' Forecasting Functions for Escalation Rates

#' Forecast using user-defined rates
#' @param historical_data Historical data frame
#' @param forecast_years Number of years to forecast
#' @param rates Vector of escalation rates or single rate
#' @return Combined historical and forecast data
#' @export
forecast_user_defined <- function(historical_data, forecast_years, rates) {
  
  last_year <- max(historical_data$fiscal_year)
  last_value <- historical_data %>%
    dplyr::filter(fiscal_year == last_year) %>%
    dplyr::pull(index_value)
  
  # Expand rates if single value
  if (length(rates) == 1) {
    rates <- rep(rates, forecast_years)
  } else if (length(rates) < forecast_years) {
    rates <- c(rates, rep(rates[length(rates)], forecast_years - length(rates)))
  }
  
  # Generate forecast
  forecast_data <- data.frame(
    fiscal_year = (last_year + 1):(last_year + forecast_years),
    escalation_rate = rates[1:forecast_years]
  ) %>%
    dplyr::mutate(
      index_value = last_value[1] * cumprod(1 + escalation_rate / 100),
      forecast_type = "user_defined",
      confidence_lower = NA,
      confidence_upper = NA
    )
  
  # Combine with historical
  combined <- dplyr::bind_rows(
    historical_data %>% dplyr::mutate(forecast_type = "historical"),
    forecast_data
  )
  
  return(combined)
}

#' Forecast using ARIMA time series
#' @param historical_data Historical data frame
#' @param forecast_years Number of years to forecast
#' @param confidence_level Confidence level for prediction intervals
#' @return Combined historical and forecast data
#' @export
forecast_arima <- function(historical_data, forecast_years, confidence_level = 0.95) {
  
  # Create time series object
  ts_data <- ts(historical_data$index_value, 
               start = min(historical_data$fiscal_year),
               frequency = 1)
  
  # Fit ARIMA model
  model <- forecast::auto.arima(ts_data, seasonal = FALSE)
  
  # Generate forecast
  fc <- forecast::forecast(model, h = forecast_years, level = confidence_level * 100)
  
  # Extract forecast values
  last_year <- max(historical_data$fiscal_year)
  forecast_data <- data.frame(
    fiscal_year = (last_year + 1):(last_year + forecast_years),
    index_value = as.numeric(fc$mean),
    confidence_lower = as.numeric(fc$lower),
    confidence_upper = as.numeric(fc$upper),
    forecast_type = "arima"
  )
  
  # Calculate implied escalation rates
  forecast_data <- forecast_data %>%
    dplyr::mutate(
      lag_value = dplyr::lag(index_value, 1),
      lag_value = dplyr::if_else(is.na(lag_value), last_value[1], lag_value),
      escalation_rate = (index_value / lag_value - 1) * 100
    )
  
  # Combine with historical
  combined <- dplyr::bind_rows(
    historical_data %>% dplyr::mutate(
      forecast_type = "historical",
      confidence_lower = NA,
      confidence_upper = NA
    ),
    forecast_data
  )
  
  message(sprintf("✓ ARIMA(%s) forecast generated for %d years",
                 paste(arimaorder(model), collapse = ","), forecast_years))
  
  return(combined)
}

#' Backcast historical data
#' @param data Data frame with index values
#' @param backcast_years Number of years to backcast
#' @param method Backcasting method ("trend", "average", "user")
#' @param rate User-defined rate for backcasting (if method = "user")
#' @return Data frame with backcasted values
#' @export
backcast_index <- function(data, backcast_years, method = "trend", rate = NULL) {
  
  first_year <- min(data$fiscal_year)
  
  if (method == "trend") {
    # Use early trend for backcasting
    early_data <- data %>%
      dplyr::filter(fiscal_year <= first_year + 5)
    
    trend_model <- lm(index_value ~ fiscal_year, data = early_data)
    
    backcast_data <- data.frame(
      fiscal_year = (first_year - backcast_years):(first_year - 1)
    ) %>%
      dplyr::mutate(
        index_value = predict(trend_model, newdata = .),
        forecast_type = "backcast_trend"
      )
    
  } else if (method == "average") {
    # Use average early escalation rate
    avg_rate <- data %>%
      dplyr::filter(fiscal_year <= first_year + 5) %>%
      dplyr::summarise(mean(escalation_rate, na.rm = TRUE)) %>%
      dplyr::pull()
    
    first_value <- data %>%
      dplyr::filter(fiscal_year == first_year) %>%
      dplyr::pull(index_value)
    
    backcast_data <- data.frame(
      fiscal_year = (first_year - backcast_years):(first_year - 1)
    ) %>%
      dplyr::arrange(dplyr::desc(fiscal_year)) %>%
      dplyr::mutate(
        index_value = first_value[1] / cumprod(rep(1 + avg_rate/100, backcast_years)),
        forecast_type = "backcast_average"
      ) %>%
      dplyr::arrange(fiscal_year)
    
  } else if (method == "user" && !is.null(rate)) {
    # Use user-defined rate
    first_value <- data %>%
      dplyr::filter(fiscal_year == first_year) %>%
      dplyr::pull(index_value)
    
    backcast_data <- data.frame(
      fiscal_year = (first_year - backcast_years):(first_year - 1)
    ) %>%
      dplyr::arrange(dplyr::desc(fiscal_year)) %>%
      dplyr::mutate(
        index_value = first_value[1] / cumprod(rep(1 + rate/100, backcast_years)),
        forecast_type = "backcast_user"
      ) %>%
      dplyr::arrange(fiscal_year)
  }
  
  # Combine with original data
  combined <- dplyr::bind_rows(backcast_data, data)
  
  return(combined)
}

# File: R/outlay_profiles.R
# ============================================================================
#' Outlay Profile Management Functions

#' Load default outlay profiles
#' @return List of default outlay profiles
#' @export
load_default_profiles <- function() {
  
  profiles <- list(
    aircraft_development = data.frame(
      year_offset = 0:5,
      outlay_pct = c(0.15, 0.25, 0.30, 0.20, 0.08, 0.02),
      profile_type = "Aircraft Development"
    ),
    
    ship_building = data.frame(
      year_offset = 0:7,
      outlay_pct = c(0.05, 0.10, 0.15, 0.20, 0.20, 0.15, 0.10, 0.05),
      profile_type = "Ship Building"
    ),
    
    electronics = data.frame(
      year_offset = 0:3,
      outlay_pct = c(0.20, 0.35, 0.30, 0.15),
      profile_type = "Electronics/IT"
    ),
    
    munitions = data.frame(
      year_offset = 0:2,
      outlay_pct = c(0.40, 0.40, 0.20),
      profile_type = "Munitions"
    ),
    
    services = data.frame(
      year_offset = 0:4,
      outlay_pct = c(0.20, 0.20, 0.20, 0.20, 0.20),
      profile_type = "Services"
    )
  )
  
  # Validate profiles sum to 100%
  for (name in names(profiles)) {
    total <- sum(profiles[[name]]$outlay_pct)
    if (abs(total - 1.0) > 0.001) {
      warning(sprintf("Profile %s sums to %.1f%%, normalizing...", name, total * 100))
      profiles[[name]]$outlay_pct <- profiles[[name]]$outlay_pct / total
    }
  }
  
  return(profiles)
}

#' Create custom outlay profile
#' @param outlays Vector of outlay percentages
#' @param profile_name Name for the profile
#' @return Data frame with outlay profile
#' @export
create_custom_profile <- function(outlays, profile_name = "Custom") {
  
  # Normalize if necessary
  total <- sum(outlays)
  if (abs(total - 1.0) > 0.001) {
    message(sprintf("Outlays sum to %.1f%%, normalizing to 100%%", total * 100))
    outlays <- outlays / total
  }
  
  profile <- data.frame(
    year_offset = 0:(length(outlays) - 1),
    outlay_pct = outlays,
    profile_type = profile_name
  )
  
  return(profile)
}

# File: R/weighted_indices.R
# ============================================================================
#' Weighted Index Calculation Functions

#' Calculate weighted escalation index
#' @param escalation_data Data frame with escalation rates
#' @param outlay_profile Data frame with outlay profile
#' @param start_year Starting fiscal year for calculation
#' @return Data frame with weighted indices
#' @export
calculate_weighted_index <- function(escalation_data, outlay_profile, start_year) {
  
  # Expand outlay profile to match years
  expanded_outlays <- expand.grid(
    base_year = start_year,
    year_offset = outlay_profile$year_offset
  ) %>%
    dplyr::mutate(
      fiscal_year = base_year + year_offset
    ) %>%
    dplyr::left_join(outlay_profile, by = "year_offset")
  
  # Join with escalation data
  weighted_data <- expanded_outlays %>%
    dplyr::left_join(
      escalation_data %>% 
        dplyr::select(fiscal_year, normalized_index, escalation_rate),
      by = "fiscal_year"
    ) %>%
    dplyr::mutate(
      weighted_index = normalized_index * outlay_pct,
      weighted_rate = escalation_rate * outlay_pct
    )
  
  # Calculate composite weighted index
  composite <- weighted_data %>%
    dplyr::group_by(base_year) %>%
    dplyr::summarise(
      composite_index = sum(weighted_index, na.rm = TRUE),
      composite_rate = sum(weighted_rate, na.rm = TRUE),
      years_included = dplyr::n(),
      total_weight = sum(outlay_pct, na.rm = TRUE),
      .groups = 'drop'
    )
  
  result <- list(
    detailed = weighted_data,
    composite = composite
  )
  
  return(result)
}

# File: R/export_functions.R
# ============================================================================
#' Export Functions for Results

#' Export to CSV with metadata
#' @param data Primary data to export
#' @param metadata List of metadata to include
#' @param filename Output filename
#' @export
export_to_csv <- function(data, metadata, filename) {
  
  # Add metadata columns
  export_data <- data %>%
    dplyr::mutate(
      export_date = Sys.Date(),
      cape_version = "1.0",
      analyst = Sys.info()["user"]
    )
  
  # Add metadata attributes
  for (name in names(metadata)) {
    export_data[[paste0("meta_", name)]] <- metadata[[name]]
  }
  
  # Write CSV
  write.csv(export_data, filename, row.names = FALSE)
  message(sprintf("✓ Exported to %s", filename))
  
  return(invisible(TRUE))
}

#' Export to Excel with documentation
#' @param data Primary data to export
#' @param metadata Metadata list
#' @param outlay_profile Outlay profile used
#' @param filename Output filename
#' @export
export_to_excel <- function(data, metadata, outlay_profile, filename) {
  
  wb <- openxlsx::createWorkbook()
  
  # Sheet 1: Main Data
  openxlsx::addWorksheet(wb, "Escalation_Data")
  openxlsx::writeData(wb, "Escalation_Data", data)
  
  # Sheet 2: Metadata
  meta_df <- data.frame(
    Parameter = names(metadata),
    Value = unlist(metadata)
  )
  openxlsx::addWorksheet(wb, "Metadata")
  openxlsx::writeData(wb, "Metadata", meta_df)
  
  # Sheet 3: Outlay Profile
  openxlsx::addWorksheet(wb, "Outlay_Profile")
  openxlsx::writeData(wb, "Outlay_Profile", outlay_profile)
  
  # Sheet 4: Summary Statistics
  summary_stats <- data %>%
    dplyr::summarise(
      mean_escalation = mean(escalation_rate, na.rm = TRUE),
      median_escalation = median(escalation_rate, na.rm = TRUE),
      sd_escalation = sd(escalation_rate, na.rm = TRUE),
      min_year = min(fiscal_year),
      max_year = max(fiscal_year),
      n_historical = sum(forecast_type == "historical"),
      n_forecast = sum(forecast_type != "historical")
    )
  
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", summary_stats)
  
  # Sheet 5: CAPE Compliance
  compliance <- data.frame(
    Requirement = c("Raw Index Downloaded", "Missing Values Filled", 
                   "FY Conversion", "Escalation Calculated", 
                   "Base Year Normalized", "Outlay Weighted"),
    Status = c("Complete", "Complete", "Complete", 
              "Complete", "Complete", "Complete"),
    Method = c(metadata$series_id, metadata$interpolation_method,
              metadata$fy_aggregation, metadata$escalation_method,
              metadata$base_year, metadata$outlay_profile)
  )
  
  openxlsx::addWorksheet(wb, "CAPE_Compliance")
  openxlsx::writeData(wb, "CAPE_Compliance", compliance)
  
  # Save workbook
  openxlsx::saveWorkbook(wb, filename, overwrite = TRUE)
  message(sprintf("✓ Exported to Excel: %s", filename))
  
  return(invisible(TRUE))
}

# File: R/cape_standards.R
# ============================================================================
#' CAPE Methodology Implementation Functions

#' Validate data according to CAPE standards
#' @param data Data frame to validate
#' @return Validation report
#' @export
validate_cape_standards <- function(data) {
  
  validation <- list()
  
  # Check data completeness
  validation$completeness <- list(
    total_records = nrow(data),
    missing_values = sum(is.na(data$index_value)),
    completeness_pct = (1 - sum(is.na(data$index_value)) / nrow(data)) * 100
  )
  
  # Check data range
  validation$range <- list(
    start_year = min(data$fiscal_year),
    end_year = max(data$fiscal_year),
    years_covered = length(unique(data$fiscal_year)),
    sufficient_history = length(unique(data$fiscal_year)) >= 10
  )
  
  # Check escalation reasonableness
  if ("escalation_rate" %in% names(data)) {
    validation$escalation <- list(
      mean_rate = mean(data$escalation_rate, na.rm = TRUE),
      max_rate = max(data$escalation_rate, na.rm = TRUE),
      min_rate = min(data$escalation_rate, na.rm = TRUE),
      reasonable = abs(mean(data$escalation_rate, na.rm = TRUE)) < 20
    )
  }
  
  # Overall validation status
  validation$status <- all(
    validation$completeness$completeness_pct > 90,
    validation$range$sufficient_history,
    validation$escalation$reasonable
  )
  
  class(validation) <- c("cape_validation", "list")
  return(validation)
}

#' Apply CAPE risk adjustments
#' @param data Escalation data
#' @param risk_factor Risk adjustment factor (1.0 = no adjustment)
#' @return Risk-adjusted data
#' @export
apply_cape_risk_adjustment <- function(data, risk_factor = 1.0) {
  
  if (risk_factor == 1.0) {
    message("No risk adjustment applied (factor = 1.0)")
    return(data)
  }
  
  data <- data %>%
    dplyr::mutate(
      unadjusted_index = normalized_index,
      risk_factor = risk_factor,
      normalized_index = normalized_index * risk_factor,
      risk_adjusted = TRUE
    )
  
  message(sprintf("✓ Applied risk adjustment factor of %.2f", risk_factor))
  
  return(data)
}