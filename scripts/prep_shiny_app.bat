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
copy shiny_app.r shiny_deploy\app.R 2>nul
xcopy /E /Y R\*.R shiny_deploy\R\ 2>nul
if exist data xcopy /E /Y data\*.* shiny_deploy\data\ 2>nul
if exist inst\shiny\www xcopy /E /Y inst\shiny\www\*.* shiny_deploy\www\ 2>nul

echo.
echo [3/4] Preparing app.R for production...
Rscript -e "
# Read the original shiny app
app_content <- readLines('shiny_app.r')

# Modify for production deployment
app_content[1] <- '# escalatoR Shiny Application - Production Deployment'

# Add package installation check at the top
install_check <- c(
  '',
  '# Check and install required packages',
  'required_packages <- c(',
  '  \"shiny\", \"shinydashboard\", \"shinyWidgets\", \"DT\", \"plotly\",',
  '  \"tidyverse\", \"fredr\", \"forecast\", \"openxlsx\"',
  ')',
  '',
  'missing_packages <- required_packages[!required_packages %in% installed.packages()[,\"Package\"]]',
  'if(length(missing_packages) > 0) {',
  '  install.packages(missing_packages, repos = \"https://cran.r-project.org/\")',
  '}',
  ''
)

# Insert after the first few lines
final_content <- c(app_content[1:10], install_check, app_content[11:length(app_content)])
writeLines(final_content, 'shiny_deploy/app.R')
cat('✓ Production app.R created\n')
"

echo.
echo [4/4] Ready for deployment!
echo.
echo Deployment directory prepared: shiny_deploy\
echo.
echo To deploy manually:
echo 1. Install rsconnect: install.packages('rsconnect')
echo 2. Configure account: rsconnect::setAccountInfo(name, token, secret)
echo 3. Deploy: rsconnect::deployApp('shiny_deploy')
echo.
echo Or run: scripts\deploy_shiny.bat
echo.
pause