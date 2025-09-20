@echo off
echo ========================================
echo escalatoR One-Click Deployment
echo ========================================

cd /d "%~dp0.."

echo.
echo This script will:
echo 1. Run package checks
echo 2. Prepare CRAN submission
echo 3. Deploy Shiny app
echo 4. Commit and push to GitHub
echo.

set /p confirm="Continue with full deployment? (y/n): "
if /i not "%confirm%"=="y" goto exit

echo.
echo [1/4] Running package checks...
call scripts\check_package.bat

echo.
echo [2/4] Preparing CRAN submission...
call scripts\prep_cran_submission.bat

echo.
echo [3/4] Deploying Shiny app...
call scripts\deploy_shiny.bat

echo.
echo [4/4] Committing to Git...
git add .
git status
echo.

set /p git_confirm="Commit and push changes? (y/n): "
if /i "%git_confirm%"=="y" (
    set /p commit_msg="Enter commit message: "
    if "!commit_msg!"=="" set commit_msg="Automated deployment update"
    git commit -m "!commit_msg!"
    git push origin main
    echo ✓ Changes committed and pushed to GitHub
) else (
    echo Skipping Git operations
)

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Summary:
echo ✓ Package checks completed
echo ✓ CRAN submission files ready in submission/
echo ✓ Shiny app deployed
echo ✓ Changes committed to Git
echo.
echo Next steps:
echo 1. Review submission/ directory
echo 2. Submit to CRAN at: https://cran.r-project.org/submit.html
echo 3. Monitor your Shiny app deployment
echo.

:exit
pause