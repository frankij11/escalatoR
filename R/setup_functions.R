#' Check R version
check_r_version <- function() {
  r_version <- as.numeric(paste0(R.version$major, '.', R.version$minor))
  if (r_version < 4.3) {
    stop('R version 4.3.0 or higher required. Current version: ', r_version)
  }
}

#' Install required packages
install_packages <- function() {
  cran_packages <- c(
    'shiny', 'shinydashboard', 'shinyWidgets',
    'tidyverse', 'lubridate', 'zoo',
    'fredr', 'httr', 'jsonlite',
    'forecast', 'tseries', 'prophet',
    'randomForest', 'xgboost', 'caret',
    'plotly', 'DT', 'corrplot', 'viridis',
    'openxlsx', 'knitr', 'rmarkdown',
    'devtools', 'testthat', 'roxygen2', 'renv'
  )
  new_packages <- cran_packages[!(cran_packages %in% installed.packages()[,'Package'])]
  if(length(new_packages) > 0) install.packages(new_packages, repos = 'https://cloud.r-project.org/')
}

