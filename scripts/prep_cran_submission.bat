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
cat('✓ Date updated in DESCRIPTION\n')
"

echo.
echo [2/5] Final documentation update...
Rscript -e "devtools::document()"

echo.
echo [3/5] Building source package...
Rscript -e "devtools::build()"

echo.
echo [4/5] Final CRAN check...
Rscript -e "devtools::check(cran = TRUE)"

echo.
echo [5/5] Creating submission files...
if not exist "submission" mkdir submission
copy *.tar.gz submission\ 2>nul
copy cran-comments.md submission\ 2>nul
copy NEWS.md submission\ 2>nul

echo.
echo ========================================
echo CRAN submission package ready!
echo ========================================
echo.
echo Files prepared in submission/ directory:
dir submission\
echo.
echo Next steps:
echo 1. Review all check results above
echo 2. Go to: https://cran.r-project.org/submit.html
echo 3. Upload the .tar.gz file and cran-comments.md
echo 4. Fill out the submission form
echo.
pause