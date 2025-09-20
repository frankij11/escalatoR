@echo off
echo ========================================
echo escalatoR Package Check
echo ========================================

cd /d "%~dp0.."

echo.
echo [1/5] Installing development dependencies...
Rscript -e "if (!require(devtools)) install.packages('devtools'); devtools::install_dev_deps()"

echo.
echo [2/5] Updating documentation...
Rscript -e "devtools::document()"

echo.
echo [3/5] Running R CMD check...
Rscript -e "devtools::check()"

echo.
echo [4/5] Checking spelling...
Rscript -e "if (!require(spelling)) install.packages('spelling'); spelling::spell_check_package()"

echo.
echo [5/5] Checking URLs...
Rscript -e "if (!require(urlchecker)) install.packages('urlchecker'); urlchecker::url_check()"

echo.
echo Package check complete!
echo Review any warnings or errors above before proceeding.
pause