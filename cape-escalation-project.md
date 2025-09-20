# CAPE Escalation Analysis System
## Complete Project Structure for DoD Cost Estimation

```
cape-escalation/
│
├── README.md                    # Project overview and setup instructions
├── DESCRIPTION                  # R package description
├── NAMESPACE                    # R package namespace
├── .Rprofile                    # R profile for project
├── renv.lock                    # Package dependencies lock file
│
├── R/                          # R Package (Backend)
│   ├── fred_api.R             # FRED API connection and data retrieval
│   ├── data_processing.R      # Data cleaning and transformation
│   ├── escalation_calc.R      # Escalation rate calculations
│   ├── forecasting.R          # Time series and ML forecasting
│   ├── outlay_profiles.R      # Outlay profile management
│   ├── weighted_indices.R     # Weighted index calculations
│   ├── export_functions.R     # CSV and Excel export utilities
│   ├── utils.R               # Helper functions
│   └── cape_standards.R      # CAPE methodology implementations
│
├── inst/
│   ├── shiny/                 # Shiny App (Frontend)
│   │   ├── app.R             # Main Shiny application
│   │   ├── ui.R              # User interface definition
│   │   ├── server.R          # Server logic
│   │   ├── modules/          # Shiny modules
│   │   │   ├── data_module.R
│   │   │   ├── forecast_module.R
│   │   │   ├── outlay_module.R
│   │   │   └── export_module.R
│   │   └── www/              # Static assets
│   │       ├── styles.css
│   │       └── cape_logo.png
│   │
│   └── outlay_profiles/       # Default outlay profiles
│       ├── aircraft.csv
│       ├── shipbuilding.csv
│       ├── electronics.csv
│       └── munitions.csv
│
├── data/                       # Package data
│   ├── default_indices.rda    # Default PPI indices
│   └── cape_metadata.rda      # CAPE methodology metadata
│
├── tests/                      # Unit tests
│   ├── testthat/
│   │   ├── test-fred_api.R
│   │   ├── test-escalation.R
│   │   └── test-forecasting.R
│   └── testthat.R
│
├── docs/                       # Documentation
│   ├── cape_methodology.md    # CAPE best practices
│   ├── user_guide.md         # User documentation
│   ├── api_reference.md      # Function reference
│   └── deployment.md         # Deployment instructions
│
├── examples/                   # Example scripts
│   ├── basic_escalation.R
│   ├── advanced_forecasting.R
│   └── portfolio_analysis.R
│
└── deploy/                     # Deployment configurations
    ├── shinyapps.io/          # ShinyApps.io deployment
    ├── docker/                # Docker configuration
    └── huggingface/          # Hugging Face Spaces config
```

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
- CAPE-compliant methodologies

### 5. **Outlay Profile Management**
- Pre-defined DoD profiles
- Custom profile creation
- Multi-year spreading

### 6. **Weighted Index Generation**
- Portfolio-level aggregation
- Risk-adjusted weighting
- Uncertainty quantification

### 7. **Export Capabilities**
- CSV with metadata
- Excel with documentation sheets
- API-ready JSON format

## Technology Stack

- **Backend**: R 4.3+
- **Frontend**: Shiny 1.7+
- **Data Source**: FRED API
- **Deployment**: ShinyApps.io (free tier)
- **Version Control**: Git/GitHub
- **Package Management**: renv
- **Testing**: testthat
- **Documentation**: roxygen2