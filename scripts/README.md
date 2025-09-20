# escalatoR Deployment Scripts

This directory contains Windows batch files for automating the deployment of the escalatoR package to CRAN and the Shiny application to hosting services.

## Quick Start

### One-Click Deployment
```batch
scripts\deploy_all.bat
```
Runs the complete deployment pipeline: checks, CRAN prep, Shiny deployment, and Git operations.

### Interactive Workflow Menu
```batch
scripts\dev_workflow.bat
```
Interactive menu for all development and deployment tasks.

## Individual Scripts

### Package Development
- **`check_package.bat`** - Run R CMD check, spelling, and URL validation
- **`run_tests.bat`** - Execute test suite and generate coverage reports
- **`prep_cran_submission.bat`** - Prepare package for CRAN submission

### Shiny App Deployment
- **`prep_shiny_app.bat`** - Prepare Shiny app for deployment
- **`deploy_shiny.bat`** - Deploy to shinyapps.io or Posit Connect

## Setup Instructions

### Prerequisites
1. Install R 4.3.0 or higher
2. Install required R packages:
   ```r
   install.packages(c("devtools", "roxygen2", "testthat", "rsconnect"))
   ```

### For Shiny Deployment
1. Create account at https://shinyapps.io/ or Posit Connect
2. Get deployment credentials
3. Configure with:
   ```r
   rsconnect::setAccountInfo(name="account", token="token", secret="secret")
   ```

### For GitHub Actions (CI/CD)
1. Add repository secrets in GitHub:
   - `SHINYAPPS_ACCOUNT`
   - `SHINYAPPS_TOKEN` 
   - `SHINYAPPS_SECRET`

## Usage Examples

### Daily Development
```batch
# Check package quality
scripts\check_package.bat

# Run tests
scripts\run_tests.bat
```

### Pre-Release
```batch
# Complete CRAN preparation
scripts\prep_cran_submission.bat

# Deploy updated Shiny app
scripts\deploy_shiny.bat
```

### Production Release
```batch
# Full deployment pipeline
scripts\deploy_all.bat
```

## GitHub Actions

The repository includes automated workflows:

- **R-CMD-check.yml** - Automated testing on push/PR
- **deploy-shiny.yml** - Auto-deploy Shiny app on main branch changes
- **cran-prep.yml** - Manual workflow for CRAN preparation

Trigger CRAN preparation workflow:
1. Go to GitHub Actions tab
2. Select "CRAN Preparation" workflow
3. Click "Run workflow"
4. Enter version number

## Troubleshooting

### Common Issues
1. **R CMD check failures** - Review output from `check_package.bat`
2. **Shiny deployment fails** - Verify account credentials with `rsconnect::accounts()`
3. **GitHub Actions fail** - Check repository secrets configuration

### Getting Help
- Review `DEPLOYMENT_GUIDE.md` for detailed instructions
- Check GitHub Issues for known problems
- Contact maintainer for support

## File Descriptions

| Script | Purpose | Prerequisites |
|--------|---------|---------------|
| `deploy_all.bat` | Complete deployment pipeline | All tools installed |
| `dev_workflow.bat` | Interactive development menu | Basic R setup |
| `check_package.bat` | Package quality checks | devtools, spelling |
| `run_tests.bat` | Test execution and coverage | testthat, covr |
| `prep_cran_submission.bat` | CRAN submission prep | devtools |
| `prep_shiny_app.bat` | Shiny app preparation | Basic setup |
| `deploy_shiny.bat` | Shiny deployment | rsconnect configured |

All scripts are designed to be run from the repository root directory and will automatically navigate to the correct locations.