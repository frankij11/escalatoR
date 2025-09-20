#' Launch CAPE Escalation Analysis Application
#' @export
launch_cape_app <- function(port = 3838, host = '127.0.0.1', launch.browser = TRUE) {
  required_packages <- c('shiny', 'shinydashboard', 'tidyverse', 'fredr')
  missing_packages <- required_packages[!required_packages %in% installed.packages()[,'Package']]
  if(length(missing_packages) > 0) stop('Missing required packages: ', paste(missing_packages, collapse = ', '))
  app_dir <- system.file('shiny', package = 'capeEscalation')
  if(app_dir == '') app_dir <- 'inst/shiny'
  shiny::runApp(appDir = app_dir, port = port, host = host, launch.browser = launch.browser)
}

