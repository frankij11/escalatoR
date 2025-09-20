# Advanced forecasting with multiple methods and comparison
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")
source("R/forecasting.R")

library(dplyr)



compare_forecast_methods <- function() {
  if(file.exists("data/example_indices.rds")) {
    cat("Using example data...\n")
    raw_data <- readRDS("data/example_indices.rds")
    aircraft_data <- data.frame(
      date = raw_data$date,
      value = raw_data$PCU3364133641,
      series_id = "PCU3364133641"
    )
  } else {
    init_fred_api()
    aircraft_data <- download_ppi_index("PCU3364133641")
  }
  aircraft_data <- aircraft_data %>%
    fill_missing_values() %>%
    convert_to_fiscal_year() %>%
    calculate_escalation_rates() #%>%
    #normalize_base_year(base_year = 2024)
  
  forecast_conservative <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(2.0, 2.0, 2.2, 2.2, 2.3, 2.3, 2.4, 2.4, 2.5, 2.5)
  ) %>% mutate(method = "Conservative") %>% normalize_base_year(base_year = 2024)
  cat("Conservative Forecast:\n")
  print(tail(forecast_conservative))

  forecast_moderate <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(2.5, 2.6, 2.7, 2.8, 2.9, 3.0, 3.0, 3.0, 3.1, 3.2)
  ) %>% mutate(method = "Moderate") %>% normalize_base_year(base_year = 2024)
  
  cat("Moderate Forecast:\n")
  print(tail(forecast_moderate))

  forecast_arima_result <- forecast_arima(
    aircraft_data,
    forecast_years = 10,
    confidence_level = 0.95
  ) %>% mutate(method = "ARIMA") %>% normalize_base_year(base_year = 2024)

  cat("ARIMA Forecast:\n")
  print(tail(forecast_arima_result))

  forecast_aggressive <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(3.5, 3.7, 3.9, 4.0, 4.0, 4.1, 4.2, 4.3, 4.4, 4.5)
  ) %>% mutate(method = "Aggressive") %>% normalize_base_year(base_year = 2024)

  cat("Aggressive Forecast:\n")
  print(head(forecast_aggressive))


  all_forecasts <- bind_rows(
    forecast_conservative,
    forecast_moderate,
    forecast_arima_result,
    forecast_aggressive
  ) 
  library(ggplot2)
  p <- ggplot(all_forecasts %>% filter(fiscal_year >= 2020), 
              aes(x = fiscal_year, y = normalized_index)) +
    geom_line(aes(color = method, linetype = forecast_type), size = 1) +
    geom_ribbon(
      data = forecast_arima_result %>% filter(forecast_type != "historical"),
      aes(ymin = confidence_lower, ymax = confidence_upper),
      alpha = 0.2, fill = "blue"
    ) +
    scale_linetype_manual(values = c("historical" = "solid", 
                                    "user_defined" = "dashed",
                                    "arima" = "dashed")) +
    labs(
      title = "Multi-Method Escalation Forecast Comparison",
      subtitle = "Aircraft Manufacturing PPI with 10-Year Forecasts",
      x = "Fiscal Year",
      y = "Normalized Index (2024 = 100)",
      color = "Method",
      linetype = "Data Type"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  print(p)
  forecast_summary <- all_forecasts %>%
    filter(forecast_type != "historical") %>%
    group_by(method) %>%
    summarise(
      avg_escalation = mean(escalation_rate, na.rm = TRUE),
      total_escalation = (last(normalized_index) / first(normalized_index) - 1) * 100,
      final_index = last(normalized_index),
      .groups = 'drop'
    )
  cat("\nForecast Method Comparison:\n")
  print(forecast_summary)
  return(all_forecasts)
}

if(interactive()) {
  comparison_results <- compare_forecast_methods()
}
