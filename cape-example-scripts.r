# ============================================================================
# Example Usage Scripts for CAPE Escalation Analysis System
# ============================================================================

# File: examples/basic_escalation.R
# ============================================================================
# Basic example of creating an escalation index

# Load required libraries
library(tidyverse)
library(fredr)
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")
source("R/forecasting.R")
source("R/export_functions.R")

# Example 1: Simple Aircraft Manufacturing Escalation
# ============================================================================

create_basic_escalation <- function() {
  
  # Step 1: Initialize FRED API
  init_fred_api()  # Assumes FRED_API_KEY is set in environment
  
  # Step 2: Download Aircraft Manufacturing PPI
  cat("Downloading Aircraft Manufacturing PPI...\n")
  aircraft_data <- download_ppi_index(
    series_id = "PCU3364133641",
    start_date = "2010-01-01",
    end_date = "2024-12-31"
  )
  
  # Step 3: Fill missing values
  cat("Processing data...\n")
  aircraft_data <- fill_missing_values(aircraft_data, method = "linear")
  
  # Step 4: Convert to fiscal year
  fy_data <- convert_to_fiscal_year(
    aircraft_data,
    fy_start_month = 10,
    aggregation = "end"
  )
  
  # Step 5: Calculate escalation rates
  escalation_data <- calculate_escalation_rates(fy_data)
  
  # Step 6: Normalize to base year 2024
  normalized_data <- normalize_base_year(escalation_data, base_year = 2024)
  
  # Step 7: Forecast 5 years with 2.5% annual escalation
  forecast_data <- forecast_user_defined(
    normalized_data,
    forecast_years = 5,
    rates = 2.5  # Single rate for all years
  )
  
  # Step 8: Export to CSV
  metadata <- list(
    series_id = "PCU3364133641",
    series_name = "Aircraft Manufacturing",
    base_year = 2024,
    forecast_method = "user_defined",
    forecast_rate = 2.5
  )
  
  export_to_csv(
    forecast_data,
    metadata,
    "output/aircraft_escalation_basic.csv"
  )
  
  cat("✓ Basic escalation complete! File saved to output/aircraft_escalation_basic.csv\n")
  
  return(forecast_data)
}

# Run example
if(interactive()) {
  result <- create_basic_escalation()
  
  # Plot results
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

# File: examples/advanced_forecasting.R
# ============================================================================
# Advanced forecasting with multiple methods and comparison

# Example 2: Multi-Method Forecasting Comparison
# ============================================================================

compare_forecast_methods <- function() {
  
  # Load historical data (using example data if FRED not available)
  if(file.exists("data/example_indices.rds")) {
    cat("Using example data...\n")
    raw_data <- readRDS("data/example_indices.rds")
    
    # Convert to expected format
    aircraft_data <- data.frame(
      date = raw_data$date,
      value = raw_data$PCU3364133641,
      series_id = "PCU3364133641"
    )
  } else {
    # Download from FRED
    init_fred_api()
    aircraft_data <- download_ppi_index("PCU3364133641")
  }
  
  # Process data
  aircraft_data <- aircraft_data %>%
    fill_missing_values() %>%
    convert_to_fiscal_year() %>%
    calculate_escalation_rates() %>%
    normalize_base_year(base_year = 2024)
  
  # Method 1: User-defined rates (conservative)
  forecast_conservative <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(2.0, 2.0, 2.2, 2.2, 2.3, 2.3, 2.4, 2.4, 2.5, 2.5)
  ) %>%
    mutate(method = "Conservative")
  
  # Method 2: User-defined rates (moderate)
  forecast_moderate <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(2.5, 2.6, 2.7, 2.8, 2.9, 3.0, 3.0, 3.0, 3.1, 3.2)
  ) %>%
    mutate(method = "Moderate")
  
  # Method 3: ARIMA forecast
  forecast_arima_result <- forecast_arima(
    aircraft_data,
    forecast_years = 10,
    confidence_level = 0.95
  ) %>%
    mutate(method = "ARIMA")
  
  # Method 4: Aggressive scenario
  forecast_aggressive <- forecast_user_defined(
    aircraft_data,
    forecast_years = 10,
    rates = c(3.5, 3.7, 3.9, 4.0, 4.0, 4.1, 4.2, 4.3, 4.4, 4.5)
  ) %>%
    mutate(method = "Aggressive")
  
  # Combine all forecasts
  all_forecasts <- bind_rows(
    forecast_conservative,
    forecast_moderate,
    forecast_arima_result,
    forecast_aggressive
  )
  
  # Create comparison plot
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
  
  # Calculate summary statistics
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

# Run example
if(interactive()) {
  comparison_results <- compare_forecast_methods()
}

# File: examples/portfolio_analysis.R
# ============================================================================
# Portfolio-level weighted escalation analysis

# Example 3: Multi-Index Portfolio with Weighted Escalation
# ============================================================================

source("R/outlay_profiles.R")
source("R/weighted_indices.R")

create_portfolio_escalation <- function() {
  
  cat("Creating portfolio escalation analysis...\n")
  
  # Define portfolio components
  portfolio_components <- list(
    aircraft = list(
      series_id = "PCU3364133641",
      name = "Aircraft Manufacturing",
      weight = 0.40  # 40% of program
    ),
    engines = list(
      series_id = "PCU336411336411", 
      name = "Aircraft Engines",
      weight = 0.25  # 25% of program
    ),
    electronics = list(
      series_id = "PCU334511334511",
      name = "Navigation/Electronics",
      weight = 0.20  # 20% of program
    ),
    services = list(
      series_id = "PPIENG",
      name = "Engineering Services",
      weight = 0.15  # 15% of program
    )
  )
  
  # Load or generate data for each component
  portfolio_data <- list()
  
  for(comp_name in names(portfolio_components)) {
    comp <- portfolio_components[[comp_name]]
    cat(sprintf("Processing %s (%s)...\n", comp$name, comp$series_id))
    
    # Use example data or download
    if(file.exists("data/example_indices.rds")) {
      raw_data <- readRDS("data/example_indices.rds")
      
      if(comp$series_id %in% names(raw_data)) {
        series_data <- data.frame(
          date = raw_data$date,
          value = raw_data[[comp$series_id]],
          series_id = comp$series_id
        )
      } else {
        # Generate synthetic data for demo
        dates <- seq(as.Date("2010-01-01"), as.Date("2024-12-01"), by = "month")
        series_data <- data.frame(
          date = dates,
          value = 100 * (1.025)^(as.numeric(dates - dates[1])/365.25) + 
                  rnorm(length(dates), 0, 2),
          series_id = comp$series_id
        )
      }
    } else {
      # Download from FRED
      series_data <- download_ppi_index(comp$series_id)
    }
    
    # Process each component
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
  
  # Combine portfolio components
  full_portfolio <- bind_rows(portfolio_data)
  
  # Calculate weighted portfolio escalation
  weighted_portfolio <- full_portfolio %>%
    group_by(fiscal_year, forecast_type) %>%
    summarise(
      portfolio_index = sum(normalized_index * component_weight),
      portfolio_rate = sum(escalation_rate * component_weight, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Apply outlay profile
  cat("\nApplying F-35 style outlay profile...\n")
  
  # Create F-35 style profile (long development + production)
  f35_profile <- create_custom_profile(
    outlays = c(5, 8, 10, 12, 15, 15, 12, 10, 8, 5) / 100,
    profile_name = "F-35 Program"
  )
  
  # Calculate weighted index with outlay profile
  weighted_with_outlay <- calculate_weighted_index(
    weighted_portfolio,
    f35_profile,
    start_year = 2025
  )
  
  # Create visualization
  library(ggplot2)
  
  # Plot 1: Component indices
  p1 <- ggplot(full_portfolio %>% filter(fiscal_year >= 2020),
               aes(x = fiscal_year, y = normalized_index)) +
    geom_line(aes(color = component, linetype = forecast_type), size = 1) +
    labs(
      title = "Portfolio Component Escalation Indices",
      x = "Fiscal Year",
      y = "Normalized Index (2024 = 100)"
    ) +
    theme_minimal()
  
  # Plot 2: Weighted portfolio
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
  
  # Plot 3: Outlay profile
  p3 <- ggplot(f35_profile, aes(x = year_offset, y = outlay_pct * 100)) +
    geom_col(fill = "steelblue", alpha = 0.7) +
    labs(
      title = "F-35 Style Outlay Profile",
      x = "Year from Start",
      y = "Percentage of Total"
    ) +
    theme_minimal()
  
  # Display plots
  print(p1)
  print(p2)
  print(p3)
  
  # Export results
  cat("\nExporting portfolio results...\n")
  
  # Create comprehensive export
  export_data <- list(
    components = full_portfolio,
    portfolio = weighted_portfolio,
    weighted_results = weighted_with_outlay$composite,
    outlay_profile = f35_profile
  )
  
  # Save as Excel with multiple sheets
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
  
  # Print summary
  cat("\nPortfolio Summary:\n")
  cat("================\n")
  summary_stats <- weighted_with_outlay$composite
  cat(sprintf("Composite Weighted Index: %.2f\n", summary_stats$composite_index))
  cat(sprintf("Composite Escalation Rate: %.2f%%\n", summary_stats$composite_rate))
  cat(sprintf("Years Included: %d\n", summary_stats$years_included))
  
  return(export_data)
}

# Run example
if(interactive()) {
  portfolio_results <- create_portfolio_escalation()
}

# File: docs/quick_start.md
# ============================================================================
# CAPE Escalation Analysis System - Quick Start Guide
# ============================================================================

# 🚀 Quick Start Guide

## 5-Minute Setup

### 1. Install Package

```r
# Option A: From GitHub (recommended)
devtools::install_github("your-org/cape-escalation")

# Option B: Local installation
source("setup.R")
run_setup()
```

### 2. Get FRED API Key

1. Go to https://fred.stlouisfed.org/docs/api/api_key.html
2. Create free account
3. Copy your API key

### 3. Configure Environment

```r
# Set API key
Sys.setenv(FRED_API_KEY = "your_key_here")

# Or save permanently in .Renviron
usethis::edit_r_environ()
# Add: FRED_API_KEY=your_key_here
```

### 4. Launch Application

```r
library(capeEscalation)
launch_cape_app()
```

## 🎯 Common Use Cases

### Quick Aircraft Escalation

```r
# 1. Load functions
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")

# 2. Get data
init_fred_api()
data <- download_ppi_index("PCU3364133641")  # Aircraft Manufacturing

# 3. Process
processed <- data %>%
  fill_missing_values() %>%
  convert_to_fiscal_year() %>%
  calculate_escalation_rates() %>%
  normalize_base_year(2024)

# 4. Forecast
forecast <- forecast_user_defined(processed, 5, rates = 2.5)

# 5. Export
export_to_csv(forecast, list(index = "Aircraft"), "aircraft.csv")
```

### Apply Outlay Profile

```r
# Load profile
source("R/outlay_profiles.R")
profile <- load_default_profiles()$aircraft_development

# Calculate weighted
source("R/weighted_indices.R")
weighted <- calculate_weighted_index(forecast, profile, 2025)

# View results
print(weighted$composite)
```

## 📊 Using the Shiny App

### Step-by-Step Workflow

1. **Connect to FRED**
   - Enter API key in sidebar
   - Click "Connect"

2. **Select Index**
   - Go to "Data Selection" tab
   - Search for index (e.g., "aircraft")
   - Select from results
   - Click "Download Data"

3. **Process Data**
   - Go to "Processing" tab
   - Choose interpolation method
   - Set base year (usually current year)
   - Click "Process Data"

4. **Generate Forecast**
   - Go to "Forecasting" tab
   - Choose method:
     - User Defined: Enter your rates
     - ARIMA: Statistical forecast
   - Set forecast years
   - Click "Generate Forecast"

5. **Apply Outlay**
   - Go to "Outlay Profiles" tab
   - Select default or create custom
   - Click "Apply Profile"

6. **Calculate Weighted**
   - Go to "Weighted Index" tab
   - Set start year
   - Click "Calculate"

7. **Export Results**
   - Go to "Export" tab
   - Choose format (Excel recommended)
   - Click "Download"

## 🛠 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| "FRED API key required" | Set key in environment or app |
| "Insufficient data" | Need minimum 24 months |
| "Base year not found" | Choose year within data range |
| "Shiny app won't start" | Run `source("setup.R")` first |

### Getting Help

- **Documentation**: See `docs/` folder
- **Examples**: Run scripts in `examples/`
- **Issues**: GitHub issues page
- **Email**: cape-support@your-org.mil

## 📈 Best Practices

### Index Selection
✅ Use NAICS-specific indices
✅ Validate with SMEs
❌ Don't default to generic

### Forecasting
✅ Compare multiple methods
✅ Document assumptions
❌ Don't forecast >10 years

### Documentation
✅ Record all parameters
✅ Export with metadata
❌ Don't skip validation

## 🎓 Next Steps

1. Read [CAPE Methodology](cape_methodology.md)
2. Review [Best Practices](best_practices.md)
3. Try [Example Scripts](../examples/)
4. Join training sessions

---

*Need help? Contact CAPE Support Team*