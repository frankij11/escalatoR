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
  if (length(rates) == 1) {
    rates <- rep(rates, forecast_years)
  } else if (length(rates) < forecast_years) {
    rates <- c(rates, rep(rates[length(rates)], forecast_years - length(rates)))
  }
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
  ts_data <- ts(historical_data$index_value, 
               start = min(historical_data$fiscal_year),
               frequency = 1)
  model <- forecast::auto.arima(ts_data, seasonal = FALSE)
  fc <- forecast::forecast(model, h = forecast_years, level = confidence_level * 100)
  last_year <- max(historical_data$fiscal_year)
  last_value <- historical_data %>%
    dplyr::filter(fiscal_year == last_year) %>%
    dplyr::pull(index_value)


  forecast_data <- data.frame(
    fiscal_year = (last_year + 1):(last_year + forecast_years),
    index_value = as.numeric(fc$mean),
    confidence_lower = as.numeric(fc$lower),
    confidence_upper = as.numeric(fc$upper),
    forecast_type = "arima"
  )
  forecast_data <- forecast_data %>%
    dplyr::mutate(
      lag_value = dplyr::lag(index_value, 1),
      lag_value = dplyr::if_else(is.na(lag_value), last_value[1], lag_value),
      escalation_rate = (index_value / lag_value - 1) * 100
    )
  combined <- dplyr::bind_rows(
    historical_data %>% dplyr::mutate(
      forecast_type = "historical",
      confidence_lower = NA,
      confidence_upper = NA
    ),
    forecast_data
  )
  message(sprintf("✓ ARIMA(%s) forecast generated for %d years",
                 paste(forecast::arimaorder(model), collapse = ","), forecast_years))
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
  combined <- dplyr::bind_rows(backcast_data, data)
  return(combined)
}
