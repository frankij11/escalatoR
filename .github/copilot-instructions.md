# escalatoR: DoD Cost Escalation Analysis System

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Environment Setup
- Install R and development tools:
  ```bash
  # Install R 4.3+ (required)
  sudo apt-get update
  sudo apt-get install -y software-properties-common dirmngr
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
  sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
  sudo apt-get update
  sudo apt-get install -y r-base r-base-dev
  ```
  - **NEVER CANCEL**: R installation takes 10-15 minutes. Set timeout to 30+ minutes.

- Install system R packages:
  ```bash
  sudo apt-get install -y r-cran-devtools r-cran-testthat r-cran-covr r-cran-shiny r-cran-tidyverse r-cran-forecast r-cran-lubridate r-cran-zoo r-cran-plotly r-cran-dt
  ```
  - **NEVER CANCEL**: Package installation takes 15-25 minutes. Set timeout to 45+ minutes.

### Package Development Workflow
- Generate documentation:
  ```bash
  cd /path/to/escalatoR
  Rscript -e "library(devtools); devtools::document()"
  ```
  - Takes 1-2 minutes when dependencies available
  - **LIMITATION**: Fails if required packages (shinydashboard, shinyWidgets, fredr) are missing

- Run package checks:
  ```bash
  # Basic structure check (always works)
  ls -la R/ inst/ tests/
  
  # Package check (may fail due to missing dependencies)
  Rscript -e "library(devtools); devtools::check()"
  ```
  - **NEVER CANCEL**: R CMD check takes 3-10 minutes. Set timeout to 20+ minutes.
  - **KNOWN ISSUE**: Full check fails due to missing fredr, shinydashboard, shinyWidgets packages not available in Ubuntu repos

### Testing
- Run tests:
  ```bash
  cd /path/to/escalatoR
  Rscript -e "library(testthat); test_dir('tests/testthat')"
  ```
  - Takes 30-60 seconds for basic tests
  - **KNOWN ISSUE**: Current tests fail due to missing setup functions and dependencies

### FRED API Configuration (CRITICAL)
- **REQUIRED**: Get FRED API key from https://fred.stlouisfed.org/docs/api/api_key.html
- Configure environment:
  ```bash
  # Copy example environment file
  cp .Renviron.example .Renviron
  # Edit .Renviron and add your key:
  # FRED_API_KEY=your_actual_api_key_here
  ```
- **VALIDATION**: Test API access:
  ```bash
  Rscript -e "library(fredr); fredr_set_key('your_key'); fredr('GDP')"
  ```
  - **LIMITATION**: fredr package not available in system repos, requires CRAN installation

## Application Deployment

### Shiny Application
- **Location**: `shiny_app.r` (main Shiny application)
- **Dependencies**: Located in `R/` directory (sourced at runtime)
- **Launch**: 
  ```bash
  # With full dependencies (when available)
  Rscript -e "library(shiny); shiny::runApp('shiny_app.r', port=3838, host='0.0.0.0')"
  
  # Test structure without launch
  head -50 shiny_app.r  # Check file structure
  ```
  - **NEVER CANCEL**: Shiny startup takes 2-5 minutes. Set timeout to 15+ minutes.
  - **LIMITATION**: Currently fails due to missing shinydashboard, shinyWidgets packages

### Windows vs Linux Environment
- **Repository designed for Windows**: Many scripts are `.bat` files
- **Linux equivalents**:
  ```bash
  # Instead of scripts/run_tests.bat
  Rscript -e "library(testthat); test_dir('tests/testthat')"
  
  # Instead of scripts/check_package.bat  
  Rscript -e "library(devtools); devtools::check()"
  
  # Instead of scripts/deploy_shiny.bat
  # Use manual deployment or GitHub Actions
  ```

## Validation Scenarios

### Essential Validation Steps
1. **R Version Check**:
   ```bash
   R --version  # Should show 4.3.3+
   ```

2. **Package Structure Validation**:
   ```bash
   # Verify key directories exist
   ls -la R/ inst/shiny/ tests/testthat/ docs/
   
   # Check DESCRIPTION file
   cat DESCRIPTION
   ```

3. **Source Code Validation**:
   ```bash
   # Test basic R function loading
   Rscript -e "source('R/setup_functions.R'); ls()"
   
   # Check Shiny app structure
   head -20 shiny_app.r
   ```

4. **CI/CD Pipeline Validation**:
   ```bash
   # Check GitHub Actions workflows
   ls -la .github/workflows/
   cat .github/workflows/R-CMD-check.yml
   ```

### Manual Testing Scenarios
- **CRITICAL**: Since full application cannot run due to missing dependencies, validate changes by:
  1. Source code review of R functions in R/ directory
  2. DESCRIPTION file validation for dependencies
  3. Documentation structure verification
  4. Test file structure examination
  5. GitHub Actions workflow validation

## Known Limitations and Workarounds

### Package Dependencies
- **ISSUE**: Required packages (fredr, shinydashboard, shinyWidgets) not available in Ubuntu system repos
- **WORKAROUND**: 
  - Use system packages where available (tidyverse, shiny, DT, plotly)
  - Document missing dependencies clearly
  - Test structure and syntax without running full application

### FRED API Integration
- **ISSUE**: Requires external API key and internet access to Federal Reserve data
- **WORKAROUND**: 
  - Always document API key requirement
  - Test code structure without actual API calls
  - Use mock data for validation when possible

### Build System
- **ISSUE**: Windows batch scripts don't work on Linux
- **WORKAROUND**: Use direct R commands instead of batch files

## File Locations and Navigation

### Key Source Files
- **R/fred_api.R**: FRED data retrieval functions
- **R/escalation_calc.R**: Core escalation calculations  
- **R/forecasting.R**: Forecasting methods
- **R/data_processing.R**: Data manipulation functions
- **R/export_functions.R**: Export and output functions
- **shiny_app.r**: Main Shiny application interface

### Configuration Files
- **DESCRIPTION**: Package metadata and dependencies
- **.Renviron.example**: Environment variables template
- **NAMESPACE**: Export definitions (auto-generated)

### Documentation
- **docs/**: Comprehensive documentation directory
- **README.md**: Package overview and quick start
- **DEPLOYMENT_GUIDE.md**: Deployment instructions  
- **CRAN_CHECKLIST.md**: CRAN submission preparation

### Testing and CI/CD
- **tests/testthat/**: Test files directory
- **.github/workflows/**: GitHub Actions CI/CD pipelines
- **scripts/**: Windows deployment scripts (reference only on Linux)

## Timing Expectations

### Build Operations
- **R installation**: 10-15 minutes (NEVER CANCEL - set 30+ minute timeout)
- **System package installation**: 15-25 minutes (NEVER CANCEL - set 45+ minute timeout)  
- **R CMD check**: 3-10 minutes (NEVER CANCEL - set 20+ minute timeout)
- **Documentation generation**: 1-2 minutes
- **Test execution**: 30-60 seconds
- **Shiny app startup**: 2-5 minutes (NEVER CANCEL - set 15+ minute timeout)

### Common Operations
- **Source file loading**: 10-30 seconds
- **DESCRIPTION validation**: Immediate
- **Directory structure check**: Immediate
- **GitHub Actions workflow validation**: Immediate

## Pre-commit Checklist
Always run these before committing changes:
1. Verify R code syntax: `Rscript -e "source('R/your_file.R')"`
2. Check DESCRIPTION file format: `cat DESCRIPTION`
3. Validate test structure: `ls -la tests/testthat/`
4. Review documentation changes: `ls -la docs/`
5. Verify no Windows-specific paths in Linux environment

## Support Resources
- **GitHub Repository**: https://github.com/frankij11/escalatoR
- **FRED API Documentation**: https://fred.stlouisfed.org/docs/api/
- **R Package Development**: https://r-pkgs.org/
- **Shiny Documentation**: https://shiny.rstudio.com/

---

**IMPORTANT**: This is an R package designed for DoD cost escalation analysis. Always consider security implications of API keys and data handling when making changes.