# escalatoR: DoD Cost Escalation Analysis

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.3.0-blue)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-1.7.0-green)](https://shiny.rstudio.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![CRAN Status](https://www.r-pkg.org/badges/version/escalatoR)](https://cran.r-project.org/package=escalatoR)

## Overview

<img src="man/figures/logo.png" align="left" />


**escalatoR** provides DoD cost estimators with a comprehensive, CAPE-compliant tool for generating custom inflation indices. The package includes both programmatic functions and an interactive Shiny application for escalation analysis following official DoD Cost Analysis and Program Evaluation (CAPE) methodology.

## Quick Start

### Installation

#### From CRAN (Recommended)
```r
install.packages("escalatoR")
```

#### From GitHub (Development Version)
```r
# Install from GitHub
devtools::install_github("frankij11/escalatoR")
```

#### Local Development
```r
# Clone repository and run setup
source("setup.R")
run_setup()
```

### Basic Usage

#### Programmatic Interface
```r
library(escalatoR)

# Get available PPI indices
available_indices <- get_fred_series_info()

# Calculate escalation rates
escalation_data <- calculate_escalation_rates(
  series_id = "PCUOMFGOMFG",
  start_year = 2020,
  end_year = 2024
)

# Generate forecasts
forecast_data <- generate_escalation_forecast(
  historical_data = escalation_data,
  forecast_years = 5,
  method = "arima"
)
```

#### Interactive Shiny Application
```r
library(escalatoR)

# Launch the interactive web application
launch_escalator_app()
```

The Shiny application provides:
- **Interactive Data Selection**: Browse and select from 600+ Producer Price Index (PPI) series
- **Real-time FRED Integration**: Automatic data retrieval and updates
- **Custom Escalation Calculations**: Generate year-over-year and compound annual growth rates
- **Advanced Forecasting**: Multiple forecasting methods including ARIMA and user-defined rates
- **Portfolio Analysis**: Create weighted indices for complex cost structures
- **Export Capabilities**: Download results in CSV, Excel, or JSON formats
- **Visualization Tools**: Interactive charts and trend analysis

## Key Features

### 1. **FRED API Integration**
- Automated PPI index discovery and retrieval
- Caching for performance
- Rate limiting compliance

### 2. **Data Processing Pipeline**
- Missing value interpolation
- Monthly to Fiscal Year conversion
- Historical data validation

### 3. **Escalation Calculations**
- Year-over-year rates
- Compound annual growth rates
- Base year normalization

### 4. **Forecasting Methods**
- User-defined rates
- ARIMA time series
- Machine learning ensemble

### 5. **Outlay Profile Management**
- Pre-defined DoD profiles
- Custom profile creation
- Multi-year spreading

### 6. **Weighted Index Generation**
- Portfolio-level aggregation
- Risk-adjusted weighting
- Uncertainty quantification

### 7. **Interactive Shiny Interface**
- User-friendly web application
- Real-time data visualization
- Guided workflow for non-R users
- Collaborative analysis sharing

### 8. **Export Capabilities**
- CSV with metadata
- Excel with documentation sheets
- API-ready JSON format

## Documentation

- [Quick Start Guide](docs/quick_start.md)
- [User Guide](docs/user_guide.md)
- [CAPE Methodology](docs/cape_methodology.md)
- [API Reference](docs/api_reference.md)
- [Best Practices](docs/best_practices.md)

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Support

- Report bugs or request features: [GitHub Issues](https://github.com/frankij11/escalatoR/issues)
- Documentation: [Package Website](https://frankij11.github.io/escalatoR/)
- Contact: maintainer@example.com

## License
MIT License - See [LICENSE](LICENSE) file for details.

