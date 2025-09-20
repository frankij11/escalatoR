# Portfolio-level weighted escalation analysis

source("R/outlay_profiles.R")
source("R/weighted_indices.R")

create_portfolio_escalation <- function() {
  cat("Creating portfolio escalation analysis...\n")
  portfolio_components <- list(
    aircraft = list(
      series_id = "PCU3364133641",
      name = "Aircraft Manufacturing",
      weight = 0.40
    ),
    engines = list(
      series_id = "PCU336411336411", 
      name = "Aircraft Engines",
      weight = 0.25
    ),
    electronics = list(
      series_id = "PCU334511334511",
      name = "Navigation/Electronics",
      weight = 0.20
    ),
    services = list(
      series_id = "PPIENG",
      name = "Engineering Services",
      weight = 0.15
    )
  )
  portfolio_data <- list()
  for(comp_name in names(portfolio_components)) {
    comp <- portfolio_components[[comp_name]]
    cat(sprintf("Processing %s (%s)...\n", comp$name, comp$series_id))
    if(file.exists("data/example_indices.rds")) {
      raw_data <- readRDS("data/example_indices.rds")
      if(comp$series_id %in% names(raw_data)) {
        series_data <- data.frame(
          date = raw_data$date,
          value = raw_data[[comp$series_id]],
          series_id = comp$series_id
        )
      } else {
        dates <- seq(as.Date("2010-01-01"), as.Date("2024-12-01"), by = "month")
        series_data <- data.frame(
          date = dates,
          value = 100 * (1.025)^(as.numeric(dates - dates[1])/365.25) + 
                  rnorm(length(dates), 0, 2),
          series_id = comp$series_id
        )
      }
    } else {
      series_data <- download_ppi_index(comp$series_id)
    }
    processed <- series_data %>%
      fill_missing_values() %>%
      convert_to_fiscal_year() %>%
      calculate_escalation_rates() %>%
      normalize_base_year(base_year = 2024) %>%
      forecast_arima(forecast_years = 10) %>%
      mutate(
        component = comp_name,
        component_weight = comp$weight
      )
    portfolio_data[[comp_name]] <- processed
  }
  full_portfolio <- bind_rows(portfolio_data)
  weighted_portfolio <- full_portfolio %>%
    group_by(fiscal_year, forecast_type) %>%
    summarise(
      portfolio_index = sum(normalized_index * component_weight),
      portfolio_rate = sum(escalation_rate * component_weight, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("\nApplying F-35 style outlay profile...\n")
  f35_profile <- create_custom_profile(
    outlays = c(5, 8, 10, 12, 15, 15, 12, 10, 8, 5) / 100,
    profile_name = "F-35 Program"
  )
  weighted_with_outlay <- calculate_weighted_index(
    weighted_portfolio,
    f35_profile,
    start_year = 2025
  )
  library(ggplot2)
  p1 <- ggplot(full_portfolio %>% filter(fiscal_year >= 2020),
               aes(x = fiscal_year, y = normalized_index)) +
    geom_line(aes(color = component, linetype = forecast_type), size = 1) +
    labs(
      title = "Portfolio Component Escalation Indices",
      x = "Fiscal Year",
      y = "Normalized Index (2024 = 100)"
    ) +
    theme_minimal()
  p2 <- ggplot(weighted_portfolio %>% filter(fiscal_year >= 2020),
               aes(x = fiscal_year, y = portfolio_index)) +
    geom_line(aes(linetype = forecast_type), size = 1.5, color = "darkblue") +
    labs(
      title = "Weighted Portfolio Escalation Index",
      subtitle = sprintf("Composite of %d indices", length(portfolio_components)),
      x = "Fiscal Year",
      y = "Portfolio Index (2024 = 100)"
    ) +
    theme_minimal()
  p3 <- ggplot(f35_profile, aes(x = year_offset, y = outlay_pct * 100)) +
    geom_col(fill = "steelblue", alpha = 0.7) +
    labs(
      title = "F-35 Style Outlay Profile",
      x = "Year from Start",
      y = "Percentage of Total"
    ) +
    theme_minimal()
  print(p1)
  print(p2)
  print(p3)
  cat("\nExporting portfolio results...\n")
  export_data <- list(
    components = full_portfolio,
    portfolio = weighted_portfolio,
    weighted_results = weighted_with_outlay$composite,
    outlay_profile = f35_profile
  )
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Portfolio_Index")
  openxlsx::writeData(wb, "Portfolio_Index", weighted_portfolio)
  openxlsx::addWorksheet(wb, "Components")
  openxlsx::writeData(wb, "Components", full_portfolio)
  openxlsx::addWorksheet(wb, "Weighted_Results")
  openxlsx::writeData(wb, "Weighted_Results", weighted_with_outlay$composite)
  openxlsx::addWorksheet(wb, "Outlay_Profile")
  openxlsx::writeData(wb, "Outlay_Profile", f35_profile)
  openxlsx::saveWorkbook(wb, "output/portfolio_escalation.xlsx", overwrite = TRUE)
  cat("✓ Portfolio analysis complete! Results saved to output/portfolio_escalation.xlsx\n")
  cat("\nPortfolio Summary:\n")
  cat("================\n")
  summary_stats <- weighted_with_outlay$composite
  cat(sprintf("Composite Weighted Index: %.2f\n", summary_stats$composite_index))
  cat(sprintf("Composite Escalation Rate: %.2f%%\n", summary_stats$composite_rate))
  cat(sprintf("Years Included: %d\n", summary_stats$years_included))
  return(export_data)
}

if(interactive()) {
  portfolio_results <- create_portfolio_escalation()
}
