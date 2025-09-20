#' Launch escalatoR Escalation Analysis Application
#' @param modern Use modern UI (TRUE) or legacy UI (FALSE)
#' @export
launch_escalator_app <- function(port = 3838, host = '127.0.0.1', launch.browser = TRUE, modern = TRUE) {
  required_packages <- c('shiny', 'shinydashboard', 'tidyverse', 'fredr')
  missing_packages <- required_packages[!required_packages %in% installed.packages()[,'Package']]
  if(length(missing_packages) > 0) stop('Missing required packages: ', paste(missing_packages, collapse = ', '))
  
  if (modern) {
    # Use new modern escalator-app
    app_dir <- system.file('escalator-app', package = 'escalatoR')
    if(app_dir == '' || !dir.exists(app_dir)) {
      # Development mode - run from source
      app_dir <- file.path(getwd(), 'escalator-app')
      if (!dir.exists(app_dir)) {
        stop('Modern app directory not found. Please ensure escalator-app/ exists.')
      }
    }
  } else {
    # Use legacy shiny app
    app_dir <- system.file('shiny', package = 'escalatoR')
    if(app_dir == '') app_dir <- 'inst/shiny'
  }
  
  message(paste('Launching', if(modern) 'Modern' else 'Legacy', 'Escalation Analyzer...'))
  shiny::runApp(appDir = app_dir, port = port, host = host, launch.browser = launch.browser)
}

