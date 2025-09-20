# Basic example of creating an escalation index

# Load required libraries
library(tidyverse)
library(fredr)
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")
source("R/forecasting.R")
source("R/export_functions.R")

create_basic_escalation <- function() {
  init_fred_api()
  cat("Downloading Aircraft Manufacturing PPI...\n")
  aircraft_data <- download_ppi_index(
    series_id = "PCU3364133641",
    start_date = "2009-10-01",
    end_date = "2025-09-30"
  )
  print(head(aircraft_data))

  cat("Processing data...\n")
  aircraft_data <- fill_missing_values(aircraft_data, method = "linear")
  fy_data <- convert_to_fiscal_year(
    aircraft_data,
    fy_start_month = 10,
    aggregation = "end",
    handle_partial = "extrapolate"
  )
  escalation_data <- calculate_escalation_rates(fy_data)
  normalized_data <- normalize_base_year(escalation_data, base_year = 2024)
  forecast_data <- forecast_user_defined(
    normalized_data,
    forecast_years = 5,
    rates = 2.5
  )
  metadata <- list(
    series_id = "PCU3364133641",
    series_name = "Aircraft Manufacturing",
    base_year = 2024,
    forecast_method = "user_defined",
    forecast_rate = 2.5
  )
  cat("Exporting results...\n")
  print(head(forecast_data))
  export_to_csv(
    forecast_data,
    metadata,
    "examples/output/basic_escalation/aircraft_escalation_basic.csv"
  )
  cat("✓ Basic escalation complete! File saved to examples/output/aircraft_escalation_basic.csv\n")
  return(forecast_data)
}

if(interactive()) {
  result <- create_basic_escalation()
  library(ggplot2)
  ggplot(result, aes(x = fiscal_year, y = normalized_index)) +
    geom_line(aes(color = forecast_type), size = 1) +
    geom_point(aes(color = forecast_type)) +
    scale_color_manual(values = c("historical" = "blue", "user_defined" = "red")) +
    labs(
      title = "Aircraft Manufacturing Escalation Index",
      subtitle = "Historical + 5-Year Forecast at 2.5% Annual",
      x = "Fiscal Year",
      y = "Index (Base Year 2024 = 100)"
    ) +
    theme_minimal()
}
