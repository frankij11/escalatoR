@echo off
echo ========================================
echo escalatoR Test Suite
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/3] Running unit tests...
Rscript -e "if (!require(testthat)) install.packages('testthat'); devtools::test()"

echo.
echo [2/3] Checking test coverage...
Rscript -e "if (!require(covr)) install.packages('covr'); covr::package_coverage()"

echo.
echo [3/3] Creating coverage report...
Rscript -e "covr::report()"

echo.
echo Test suite complete!
echo Check coverage report that should open in your browser.
pause