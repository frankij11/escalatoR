@echo off
echo ========================================
echo escalatoR Development Workflow
echo ========================================

cd /d "%~dp0.."

:menu
echo.
echo What would you like to do?
echo.
echo 1. Run package checks
echo 2. Run tests and coverage
echo 3. Build documentation and website
echo 4. Prepare CRAN submission
echo 5. Deploy Shiny app
echo 6. Complete CI/CD pipeline
echo 7. Release management
echo 8. Monitor deployments
echo 9. Exit
echo.

set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto package_checks
if "%choice%"=="2" goto tests
if "%choice%"=="3" goto documentation
if "%choice%"=="4" goto cran_prep
if "%choice%"=="5" goto shiny_deploy
if "%choice%"=="6" goto cicd_pipeline
if "%choice%"=="7" goto release_mgmt
if "%choice%"=="8" goto monitor
if "%choice%"=="9" goto exit

echo Invalid choice. Please try again.
goto menu

:package_checks
echo.
echo Running package checks...
call scripts\check_package.bat
goto menu

:tests
echo.
echo Running tests and coverage...
call scripts\run_tests.bat
goto menu

:documentation
echo.
echo Building documentation and website...
Rscript -e "
if (!require(pkgdown)) install.packages('pkgdown')
devtools::document()
pkgdown::build_site()
cat('✓ Documentation website built\n')
cat('View at: docs/index.html\n')
"
goto menu

:cran_prep
echo.
echo Preparing CRAN submission...
call scripts\prep_cran_submission.bat
goto menu

:shiny_deploy
echo.
echo Deploying Shiny app...
call scripts\deploy_shiny.bat
goto menu

:cicd_pipeline
echo.
echo Running complete CI/CD pipeline...
echo.
echo [1/5] Package checks...
call scripts\check_package.bat
echo.
echo [2/5] Tests and coverage...
call scripts\run_tests.bat
echo.
echo [3/5] Documentation...
Rscript -e "devtools::document(); pkgdown::build_site()"
echo.
echo [4/5] CRAN preparation...
call scripts\prep_cran_submission.bat
echo.
echo [5/5] Shiny deployment...
call scripts\deploy_shiny.bat
echo.
echo ========================================
echo Complete CI/CD pipeline finished!
echo ========================================
goto menu

:release_mgmt
echo.
echo Release Management...
set /p version="Enter version number (e.g., 1.0.1): "
if "%version%"=="" goto menu

echo.
echo Preparing release %version%...
Rscript -e "
# Update DESCRIPTION
desc <- readLines('DESCRIPTION')
desc[grep('^Version:', desc)] <- paste('Version:', '%version%')
desc[grep('^Date:', desc)] <- paste('Date:', Sys.Date())
writeLines(desc, 'DESCRIPTION')

# Update documentation
devtools::document()

# Run final checks
devtools::check()

cat('✓ Release %version% prepared\n')
cat('Next: Commit changes and create git tag\n')
"

set /p git_confirm="Commit changes and create git tag? (y/n): "
if /i "%git_confirm%"=="y" (
    git add .
    git commit -m "Release version %version%"
    git tag -a v%version% -m "Release version %version%"
    git push origin main
    git push origin v%version%
    echo ✓ Git tag v%version% created and pushed
)
goto menu

:monitor
echo.
echo Deployment Monitoring...
echo.
echo [1/2] Checking CRAN status...
Rscript -e "
if ('escalatoR' %in% available.packages()[,1]) {
  cat('✓ escalatoR is available on CRAN\n')
  version <- packageDescription('escalatoR', fields = 'Version')
  cat('Current CRAN version:', version, '\n')
} else {
  cat('✗ escalatoR not found on CRAN\n')
}
"

echo.
echo [2/2] Shiny app URLs:
echo - shinyapps.io: https://your-account.shinyapps.io/escalator-dod-cost-analysis/
echo - GitHub: https://github.com/frankij11/escalatoR
echo - CRAN checks: https://cran.r-project.org/web/checks/check_results_escalatoR.html
echo.
goto menu

:exit
echo.
echo Thank you for using the escalatoR development workflow!
echo.
pause
exit

:end