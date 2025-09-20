@echo off
echo ========================================
echo Deploy escalatoR Shiny App
echo ========================================

cd /d "%~dp0.."

echo.
echo First, let's prepare the app for deployment...
call scripts\prep_shiny_app.bat

cd shiny_deploy

echo.
echo [1/4] Checking rsconnect installation...
Rscript -e "
if (!require(rsconnect, quietly = TRUE)) {
  cat('Installing rsconnect...\n')
  install.packages('rsconnect', repos = 'https://cran.r-project.org/')
}
cat('✓ rsconnect is ready\n')
"

echo.
echo [2/4] Checking account configuration...
Rscript -e "
accounts <- rsconnect::accounts()
if (nrow(accounts) == 0) {
  cat('⚠ No deployment accounts configured.\n')
  cat('Please run the following commands in R:\n')
  cat('1. For shinyapps.io:\n')
  cat('   rsconnect::setAccountInfo(name=\"your-account\", token=\"your-token\", secret=\"your-secret\")\n')
  cat('2. For Posit Connect:\n')
  cat('   rsconnect::connectUser(account=\"your-account\", server=\"your-server\")\n')
  cat('\nGet your credentials from:\n')
  cat('- shinyapps.io: https://www.shinyapps.io/admin/#/tokens\n')
  cat('- Posit Connect: Your admin dashboard\n')
  stop('Account configuration required')
} else {
  cat('✓ Found configured accounts:\n')
  print(accounts[c('name', 'server')])
}
"

echo.
echo [3/4] Testing app locally (optional - press Ctrl+C to skip)...
timeout /t 5 /nobreak >nul 2>&1
Rscript -e "
cat('Testing app locally on port 3838...\n')
cat('Open http://localhost:3838 to test\n')
cat('Press Ctrl+C to stop and continue with deployment\n')
try(shiny::runApp(port = 3838), silent = TRUE)
"

echo.
echo [4/4] Deploying to hosting service...
set /p deploy_choice="Deploy to (1) shinyapps.io or (2) Posit Connect? Enter 1 or 2: "

if "%deploy_choice%"=="1" goto deploy_shinyapps
if "%deploy_choice%"=="2" goto deploy_posit

:deploy_shinyapps
echo.
echo Deploying to shinyapps.io...
Rscript -e "
rsconnect::deployApp(
  appDir = '.',
  appName = 'escalator-dod-cost-analysis',
  appTitle = 'escalatoR: DoD Cost Escalation Analysis',
  launch.browser = TRUE,
  forceUpdate = TRUE
)
"
goto deploy_complete

:deploy_posit
echo.
echo Deploying to Posit Connect...
Rscript -e "
rsconnect::deployApp(
  appDir = '.',
  appName = 'escalator-dod-cost-analysis',
  appTitle = 'escalatoR: DoD Cost Escalation Analysis',
  launch.browser = TRUE,
  forceUpdate = TRUE
)
"
goto deploy_complete

:deploy_complete
echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Your escalatoR Shiny app should now be live!
echo The app should have opened in your browser automatically.
echo.
echo To manage your deployed app:
echo - shinyapps.io: https://www.shinyapps.io/admin/
echo - Posit Connect: Your server's admin dashboard
echo.

cd ..
pause