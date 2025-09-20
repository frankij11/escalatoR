# escalatoR Deployment Guide: CRAN Submission and Shiny App Hosting

## Overview

This guide provides step-by-step instructions for:
1. **CRAN Package Submission** - Publishing escalatoR to the Comprehensive R Archive Network
2. **Shiny App Deployment** - Hosting the interactive application on Posit Connect (free tier)
3. **CI/CD Automation** - Automated workflows using GitHub Actions and Windows batch files

## Part 1: CRAN Package Submission

### Prerequisites

#### Software Requirements
- R 4.3.0 or higher
- RStudio (recommended)
- Git for Windows
- Rtools (for Windows package building)

#### R Packages Required
```r
install.packages(c(
  "devtools", "roxygen2", "testthat", "knitr", "rmarkdown",
  "pkgdown", "covr", "rhub", "spelling", "urlchecker"
))
```

### Step 1: Package Preparation

#### 1.1 Run Initial Package Check
Create `scripts/check_package.bat`:
```batch
@echo off
echo ========================================
echo escalatoR Package Check
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/5] Installing development dependencies...
Rscript -e "devtools::install_dev_deps()"

echo.
echo [2/5] Updating documentation...
Rscript -e "devtools::document()"

echo.
echo [3/5] Running R CMD check...
Rscript -e "devtools::check()"

echo.
echo [4/5] Checking spelling...
Rscript -e "spelling::spell_check_package()"

echo.
echo [5/5] Checking URLs...
Rscript -e "urlchecker::url_check()"

echo.
echo Package check complete!
pause
```

#### 1.2 Build Comprehensive Tests
Create test files structure:
```
tests/
├── testthat/
│   ├── test-fred-api.R
│   ├── test-escalation-calc.R
│   ├── test-forecasting.R
│   ├── test-validation.R
│   ├── test-export.R
│   └── test-shiny-app.R
└── testthat.R
```

Run tests with `scripts/run_tests.bat`:
```batch
@echo off
echo ========================================
echo escalatoR Test Suite
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/3] Running unit tests...
Rscript -e "devtools::test()"

echo.
echo [2/3] Checking test coverage...
Rscript -e "covr::package_coverage()"

echo.
echo [3/3] Creating coverage report...
Rscript -e "covr::report()"

echo.
echo Test suite complete!
pause
```

#### 1.3 Create Vignettes
Create `vignettes/` directory with:

**vignettes/getting-started.Rmd**:
```yaml
---
title: "Getting Started with escalatoR"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with escalatoR}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

**vignettes/cape-methodology.Rmd**:
```yaml
---
title: "CAPE Methodology Implementation"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{CAPE Methodology Implementation}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

Build vignettes with `scripts/build_vignettes.bat`:
```batch
@echo off
echo ========================================
echo Building escalatoR Vignettes
echo ========================================

cd /d "%~dp0.."

echo.
echo Building vignettes...
Rscript -e "devtools::build_vignettes()"

echo.
echo Creating package website...
Rscript -e "pkgdown::build_site()"

echo.
echo Vignettes complete!
pause
```

### Step 2: CRAN Pre-Submission Checks

#### 2.1 Multi-Platform Testing
Create `scripts/cran_checks.bat`:
```batch
@echo off
echo ========================================
echo CRAN Pre-Submission Checks
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/6] Local R CMD check...
Rscript -e "devtools::check()"

echo.
echo [2/6] Checking on Windows (rhub)...
Rscript -e "rhub::check_on_windows()"

echo.
echo [3/6] Checking on Linux (rhub)...
Rscript -e "rhub::check_on_linux()"

echo.
echo [4/6] Checking on macOS (rhub)...
Rscript -e "rhub::check_on_macos()"

echo.
echo [5/6] Checking for CRAN...
Rscript -e "rhub::check_for_cran()"

echo.
echo [6/6] Validating email...
Rscript -e "rhub::validate_email()"

echo.
echo CRAN checks complete!
echo Review all results before submitting.
pause
```

#### 2.2 Final Package Preparation
Create `scripts/prep_cran_submission.bat`:
```batch
@echo off
echo ========================================
echo Preparing CRAN Submission
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/5] Updating version and date...
Rscript -e "
desc <- readLines('DESCRIPTION')
desc[grep('^Date:', desc)] <- paste('Date:', Sys.Date())
writeLines(desc, 'DESCRIPTION')
"

echo.
echo [2/5] Final documentation update...
Rscript -e "devtools::document()"

echo.
echo [3/5] Building source package...
Rscript -e "devtools::build()"

echo.
echo [4/5] Final check...
Rscript -e "devtools::check(cran = TRUE)"

echo.
echo [5/5] Creating submission files...
if not exist "submission" mkdir submission
copy *.tar.gz submission\
copy cran-comments.md submission\
copy NEWS.md submission\

echo.
echo CRAN submission package ready in submission/ directory!
echo.
echo Next steps:
echo 1. Review all check results
echo 2. Submit to CRAN via: https://cran.r-project.org/submit.html
echo 3. Upload the .tar.gz file and cran-comments.md
pause
```

### Step 3: CRAN Submission Process

#### 3.1 Manual Submission
1. Go to https://cran.r-project.org/submit.html
2. Upload your `escalatoR_1.0.0.tar.gz` file
3. Upload your `cran-comments.md` file
4. Fill out the submission form
5. Wait for automated checks (usually 30-60 minutes)
6. Respond to any feedback from CRAN maintainers

#### 3.2 Post-Submission Tracking
Create `scripts/track_cran_status.bat`:
```batch
@echo off
echo ========================================
echo CRAN Submission Status Tracker
echo ========================================

echo.
echo Checking CRAN status for escalatoR...
echo.

echo CRAN Submission Page:
echo https://cran.r-project.org/web/checks/check_results_escalatoR.html
echo.

echo CRAN Package Page (after acceptance):
echo https://cran.r-project.org/package=escalatoR
echo.

echo To check programmatically:
Rscript -e "
if ('escalatoR' %in% available.packages()[,1]) {
  cat('✓ escalatoR is available on CRAN\n')
  cat('Version:', packageDescription('escalatoR', lib.loc = NULL)$Version, '\n')
} else {
  cat('✗ escalatoR not yet on CRAN\n')
}
"

pause
```

## Part 2: Shiny App Deployment to Posit Connect

### Prerequisites for Shiny Deployment

#### Account Setup
1. Create free account at https://posit.cloud/
2. Alternative: Use https://shinyapps.io/ (also free tier available)
3. Install deployment packages:
```r
install.packages(c("rsconnect", "packrat", "renv"))
```

### Step 1: Prepare Shiny Application

#### 1.1 Create Standalone Shiny App
Create `scripts/prep_shiny_app.bat`:
```batch
@echo off
echo ========================================
echo Preparing Shiny App for Deployment
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/4] Creating deployment directory...
if not exist "shiny_deploy" mkdir shiny_deploy
if not exist "shiny_deploy\R" mkdir shiny_deploy\R
if not exist "shiny_deploy\data" mkdir shiny_deploy\data
if not exist "shiny_deploy\www" mkdir shiny_deploy\www

echo.
echo [2/4] Copying necessary files...
copy shiny_app.r shiny_deploy\app.R
xcopy /E /I R\*.R shiny_deploy\R\
xcopy /E /I data\*.* shiny_deploy\data\
xcopy /E /I inst\shiny\www\*.* shiny_deploy\www\

echo.
echo [3/4] Creating renv.lock for dependencies...
cd shiny_deploy
Rscript -e "
renv::init()
renv::snapshot()
"

echo.
echo [4/4] Testing app locally...
Rscript -e "shiny::runApp(port = 3838)"

cd ..
echo.
echo Shiny app prepared for deployment!
pause
```

#### 1.2 Configure App for Production
Create `shiny_deploy/app.R` (modified version):
```r
# escalatoR Shiny Application - Production Version
# Deployed to Posit Connect

# Check and install required packages
required_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "DT", "plotly",
  "tidyverse", "fredr", "forecast", "openxlsx"
)

missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
if(length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cran.r-project.org/")
}

# Load libraries
library(shiny)
library(shinydashboard)
# ... other libraries

# Source functions
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")
source("R/forecasting.R")
source("R/outlay_profiles.R")
source("R/weighted_indices.R")
source("R/export_functions.R")
source("R/cape_standards.R")

# Your existing Shiny app code here...
```

### Step 2: Deploy to Posit Connect

#### 2.1 Setup Deployment Configuration
Create `scripts/deploy_shiny.bat`:
```batch
@echo off
echo ========================================
echo Deploy escalatoR Shiny App
echo ========================================

cd /d "%~dp0..\shiny_deploy"

echo.
echo [1/4] Setting up rsconnect...
Rscript -e "
# Configure your account (run once)
# rsconnect::setAccountInfo(name='your-account', token='your-token', secret='your-secret')

# Check current account
rsconnect::accounts()
"

echo.
echo [2/4] Checking app dependencies...
Rscript -e "
# Check that all dependencies are available
required_pkgs <- c('shiny', 'shinydashboard', 'shinyWidgets', 'DT', 'plotly', 'tidyverse', 'fredr', 'forecast', 'openxlsx')
missing <- required_pkgs[!required_pkgs %in% installed.packages()[,'Package']]
if(length(missing) > 0) {
  cat('Missing packages:', paste(missing, collapse=', '), '\n')
  cat('Installing missing packages...\n')
  install.packages(missing)
} else {
  cat('All required packages are available.\n')
}
"

echo.
echo [3/4] Deploying to Posit Connect...
Rscript -e "
rsconnect::deployApp(
  appDir = '.',
  appName = 'escalator-dod-cost-analysis',
  appTitle = 'escalatoR: DoD Cost Escalation Analysis',
  launch.browser = TRUE,
  forceUpdate = TRUE
)
"

echo.
echo [4/4] Deployment complete!
echo Your app should open in your browser automatically.
pause
```

#### 2.2 Configure for shinyapps.io (Alternative)
Create `scripts/deploy_shinyapps_io.bat`:
```batch
@echo off
echo ========================================
echo Deploy to shinyapps.io
echo ========================================

cd /d "%~dp0..\shiny_deploy"

echo.
echo [1/3] Configure shinyapps.io account...
echo Please run this command in R and follow the instructions:
echo rsconnect::setAccountInfo(name='account', token='token', secret='secret')
echo.
pause

echo.
echo [2/3] Deploying to shinyapps.io...
Rscript -e "
rsconnect::deployApp(
  appDir = '.',
  appName = 'escalator-dod-cost-analysis',
  account = 'your-account-name',
  server = 'shinyapps.io',
  launch.browser = TRUE
)
"

echo.
echo [3/3] Deployment complete!
pause
```

## Part 3: CI/CD Automation

### Step 1: GitHub Actions Setup

#### 3.1 Create GitHub Actions Workflows
Create `.github/workflows/R-CMD-check.yml`:
```yaml
name: R-CMD-check

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 8 * * 1'  # Weekly on Monday

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}
    
    name: ${{ matrix.config.os }} (${{ matrix.config.r }})
    
    strategy:
      fail-fast: false
      matrix:
        config:
          - {os: windows-latest, r: 'release'}
          - {os: macOS-latest, r: 'release'}
          - {os: ubuntu-20.04, r: 'release', rspm: "https://packagemanager.rstudio.com/cran/__linux__/focal/latest"}
          - {os: ubuntu-20.04, r: 'devel', rspm: "https://packagemanager.rstudio.com/cran/__linux__/focal/latest"}
    
    env:
      R_REMOTES_NO_ERRORS_FROM_WARNINGS: true
      RSPM: ${{ matrix.config.rspm }}
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          http-user-agent: ${{ matrix.config.http-user-agent }}
          use-public-rspm: true
      
      - uses: r-lib/actions/setup-pandoc@v2
      
      - name: Query dependencies
        run: |
          install.packages('remotes')
          saveRDS(remotes::dev_package_deps(dependencies = TRUE), ".github/depends.Rds", version = 2)
          writeLines(sprintf("R-%i.%i", getRversion()$major, getRversion()$minor), ".github/R-version")
        shell: Rscript {0}
      
      - name: Cache R packages
        if: runner.os != 'Windows'
        uses: actions/cache@v2
        with:
          path: ${{ env.R_LIBS_USER }}
          key: ${{ runner.os }}-${{ hashFiles('.github/R-version') }}-1-${{ hashFiles('.github/depends.Rds') }}
          restore-keys: ${{ runner.os }}-${{ hashFiles('.github/R-version') }}-1-
      
      - name: Install dependencies
        run: |
          remotes::install_deps(dependencies = TRUE)
          remotes::install_cran("rcmdcheck")
        shell: Rscript {0}
      
      - name: Check
        env:
          _R_CHECK_CRAN_INCOMING_REMOTE_: false
        run: rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "warning", check_dir = "check")
        shell: Rscript {0}
      
      - name: Upload check results
        if: failure()
        uses: actions/upload-artifact@main
        with:
          name: ${{ runner.os }}-r${{ matrix.config.r }}-results
          path: check
```

#### 3.2 Create Automated CRAN Preparation Workflow
Create `.github/workflows/cran-prep.yml`:
```yaml
name: CRAN Preparation

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Package version (e.g., 1.0.0)'
        required: true
        default: '1.0.0'

jobs:
  cran-prep:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
      
      - name: Install dependencies
        run: |
          install.packages(c('devtools', 'roxygen2', 'testthat', 'rhub', 'pkgdown'))
          remotes::install_deps(dependencies = TRUE)
        shell: Rscript {0}
      
      - name: Update version
        run: |
          desc <- readLines('DESCRIPTION')
          desc[grep('^Version:', desc)] <- paste('Version:', '${{ github.event.inputs.version }}')
          desc[grep('^Date:', desc)] <- paste('Date:', Sys.Date())
          writeLines(desc, 'DESCRIPTION')
        shell: Rscript {0}
      
      - name: Document
        run: devtools::document()
        shell: Rscript {0}
      
      - name: Build package
        run: devtools::build()
        shell: Rscript {0}
      
      - name: Check package
        run: devtools::check(cran = TRUE)
        shell: Rscript {0}
      
      - name: Upload package
        uses: actions/upload-artifact@v3
        with:
          name: cran-submission
          path: |
            *.tar.gz
            cran-comments.md
            NEWS.md
```

#### 3.3 Create Shiny App Deployment Workflow
Create `.github/workflows/deploy-shiny.yml`:
```yaml
name: Deploy Shiny App

on:
  push:
    branches: [ main ]
    paths: 
      - 'shiny_app.r'
      - 'R/**'
      - 'inst/shiny/**'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: r-lib/actions/setup-r@v2
      
      - name: Install dependencies
        run: |
          install.packages(c('rsconnect', 'renv'))
          remotes::install_deps(dependencies = TRUE)
        shell: Rscript {0}
      
      - name: Authorize and deploy
        env:
          SHINYAPPS_ACCOUNT: ${{ secrets.SHINYAPPS_ACCOUNT }}
          SHINYAPPS_TOKEN: ${{ secrets.SHINYAPPS_TOKEN }}
          SHINYAPPS_SECRET: ${{ secrets.SHINYAPPS_SECRET }}
        run: |
          rsconnect::setAccountInfo(
            name = Sys.getenv('SHINYAPPS_ACCOUNT'),
            token = Sys.getenv('SHINYAPPS_TOKEN'),
            secret = Sys.getenv('SHINYAPPS_SECRET')
          )
          
          # Prepare deployment directory
          if (!dir.exists('shiny_deploy')) dir.create('shiny_deploy')
          file.copy('shiny_app.r', 'shiny_deploy/app.R', overwrite = TRUE)
          file.copy('R', 'shiny_deploy/', recursive = TRUE)
          if (dir.exists('data')) file.copy('data', 'shiny_deploy/', recursive = TRUE)
          
          # Deploy
          rsconnect::deployApp(
            appDir = 'shiny_deploy',
            appName = 'escalator-dod-cost-analysis',
            forceUpdate = TRUE
          )
        shell: Rscript {0}
```

### Step 2: Local Automation Scripts

#### 3.1 Complete Development Workflow
Create `scripts/dev_workflow.bat`:
```batch
@echo off
echo ========================================
echo escalatoR Development Workflow
echo ========================================

cd /d "%~dp0.."

echo.
echo What would you like to do?
echo 1. Run package checks
echo 2. Run tests and coverage
echo 3. Build documentation
echo 4. Prepare CRAN submission
echo 5. Deploy Shiny app
echo 6. Complete CI/CD pipeline
echo 7. Exit
echo.

set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto package_checks
if "%choice%"=="2" goto tests
if "%choice%"=="3" goto documentation
if "%choice%"=="4" goto cran_prep
if "%choice%"=="5" goto shiny_deploy
if "%choice%"=="6" goto cicd_pipeline
if "%choice%"=="7" goto exit

:package_checks
echo.
echo Running package checks...
call scripts\check_package.bat
goto end

:tests
echo.
echo Running tests and coverage...
call scripts\run_tests.bat
goto end

:documentation
echo.
echo Building documentation...
call scripts\build_vignettes.bat
goto end

:cran_prep
echo.
echo Preparing CRAN submission...
call scripts\prep_cran_submission.bat
goto end

:shiny_deploy
echo.
echo Deploying Shiny app...
call scripts\deploy_shiny.bat
goto end

:cicd_pipeline
echo.
echo Running complete CI/CD pipeline...
echo [1/5] Package checks...
call scripts\check_package.bat
echo [2/5] Tests...
call scripts\run_tests.bat
echo [3/5] Documentation...
call scripts\build_vignettes.bat
echo [4/5] CRAN preparation...
call scripts\prep_cran_submission.bat
echo [5/5] Shiny deployment...
call scripts\deploy_shiny.bat
echo Complete CI/CD pipeline finished!
goto end

:exit
echo Goodbye!
goto end

:end
pause
```

#### 3.2 Release Management
Create `scripts/release.bat`:
```batch
@echo off
echo ========================================
echo escalatoR Release Manager
echo ========================================

set /p version="Enter version number (e.g., 1.0.0): "
set /p release_notes="Enter release notes file (or press Enter for NEWS.md): "

if "%release_notes%"=="" set release_notes=NEWS.md

cd /d "%~dp0.."

echo.
echo [1/8] Updating version in DESCRIPTION...
Rscript -e "
desc <- readLines('DESCRIPTION')
desc[grep('^Version:', desc)] <- paste('Version:', '%version%')
desc[grep('^Date:', desc)] <- paste('Date:', Sys.Date())
writeLines(desc, 'DESCRIPTION')
cat('✓ Version updated to %version%\n')
"

echo.
echo [2/8] Running final tests...
Rscript -e "devtools::test()"

echo.
echo [3/8] Updating documentation...
Rscript -e "devtools::document()"

echo.
echo [4/8] Building package...
Rscript -e "devtools::build()"

echo.
echo [5/8] Final CRAN check...
Rscript -e "devtools::check(cran = TRUE)"

echo.
echo [6/8] Creating Git tag...
git add .
git commit -m "Release version %version%"
git tag -a v%version% -m "Release version %version%"

echo.
echo [7/8] Pushing to GitHub...
git push origin main
git push origin v%version%

echo.
echo [8/8] Creating GitHub release...
echo Manual step: Go to https://github.com/frankij11/escalatoR/releases
echo Click "Create a new release"
echo Select tag v%version%
echo Upload the .tar.gz file from the root directory
echo Add release notes from %release_notes%

echo.
echo Release %version% preparation complete!
echo Next: Submit to CRAN manually or wait for automated deployment.
pause
```

## Part 4: Monitoring and Maintenance

### CRAN Package Monitoring
Create `scripts/monitor_cran.bat`:
```batch
@echo off
echo ========================================
echo CRAN Package Monitoring
echo ========================================

echo.
echo [1/4] Checking CRAN status...
Rscript -e "
if ('escalatoR' %in% available.packages()[,1]) {
  cat('✓ escalatoR is available on CRAN\n')
  installed_version <- packageDescription('escalatoR', fields = 'Version')
  cat('Current CRAN version:', installed_version, '\n')
} else {
  cat('✗ escalatoR not found on CRAN\n')
}
"

echo.
echo [2/4] Checking package health...
echo CRAN check results: https://cran.r-project.org/web/checks/check_results_escalatoR.html

echo.
echo [3/4] Download statistics...
Rscript -e "
if (require(cranlogs, quietly = TRUE)) {
  downloads <- cranlogs::cran_downloads('escalatoR', from = Sys.Date() - 30)
  cat('Downloads in last 30 days:', sum(downloads$count), '\n')
} else {
  cat('Install cranlogs package to see download statistics\n')
}
"

echo.
echo [4/4] Checking for user issues...
echo GitHub Issues: https://github.com/frankij11/escalatoR/issues

pause
```

### Shiny App Monitoring
Create `scripts/monitor_shiny.bat`:
```batch
@echo off
echo ========================================
echo Shiny App Monitoring
echo ========================================

echo.
echo [1/3] Checking app status...
Rscript -e "
app_url <- 'https://your-account.shinyapps.io/escalator-dod-cost-analysis/'
cat('App URL:', app_url, '\n')

# Try to access the app
response <- try(httr::GET(app_url), silent = TRUE)
if (inherits(response, 'try-error')) {
  cat('✗ Cannot access app\n')
} else if (httr::status_code(response) == 200) {
  cat('✓ App is running\n')
} else {
  cat('⚠ App returned status:', httr::status_code(response), '\n')
}
"

echo.
echo [2/3] Checking app logs...
echo Visit your shinyapps.io dashboard to view detailed logs and metrics

echo.
echo [3/3] Usage statistics...
echo Check your shinyapps.io dashboard for usage analytics

pause
```

## Quick Reference Commands

### One-Command Deployment
For experienced users, create `scripts/deploy_all.bat`:
```batch
@echo off
echo Deploying escalatoR package and Shiny app...

:: Package checks and CRAN prep
call scripts\prep_cran_submission.bat

:: Shiny app deployment
call scripts\deploy_shiny.bat

:: Git operations
git add .
git commit -m "Automated deployment update"
git push

echo All deployments complete!
pause
```

## Troubleshooting

### Common Issues and Solutions

1. **CRAN Check Failures**
   - Run `scripts\cran_checks.bat` to identify issues
   - Check `man/` directory for documentation errors
   - Ensure all examples are executable

2. **Shiny Deployment Failures**
   - Check package dependencies in `shiny_deploy/`
   - Verify FRED API key configuration
   - Test app locally before deploying

3. **GitHub Actions Failures**
   - Check secrets configuration in GitHub repository
   - Verify workflow YAML syntax
   - Review action logs for specific errors

### Support Resources
- CRAN Repository Policy: https://cran.r-project.org/web/packages/policies.html
- Shinyapps.io Documentation: https://docs.rstudio.com/shinyapps.io/
- GitHub Actions Documentation: https://docs.github.com/en/actions

This comprehensive guide should get your escalatoR package published to CRAN and your Shiny app hosted on Posit Connect with full CI/CD automation!