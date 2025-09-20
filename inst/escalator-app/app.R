# ============================================================================
# Modern Escalation Analyzer - Main Application Entry Point
# Shiny App for DoD Cost Escalation Analysis Following CAPE Methodology
# ============================================================================

# Load required libraries for modern UI
library(shiny)
library(bs4Dash)
library(fresh)
library(shinyWidgets)
library(waiter)
library(shinycssloaders)
library(reactable)
library(plotly)
library(echarts4r)
library(shinyjs)
library(tippy)
library(shinypop)
library(shinyFeedback)

# Load escalatoR package (in development, source functions)
if (file.exists("../R")) {
  # Development mode - source package functions
  source("../R/fred_api.R")
  source("../R/data_processing.R")
  source("../R/escalation_calc.R")
  source("../R/forecasting.R")
  source("../R/outlay_profiles.R")
  source("../R/weighted_indices.R")
  source("../R/export_functions.R")
  source("../R/cape_standards.R")
} else {
  # Production mode - load package
  library(escalatoR)
}

# Source application components
source("R/ui.R")
source("R/server.R")
source("R/theme.R")
source("R/utils-ui.R")

# Source modules
source("R/modules/mod-upload.R")
source("R/modules/mod-builder.R")
source("R/modules/mod-analysis.R")
source("R/modules/mod-results.R")
source("R/modules/mod-export.R")

# Create and run the application
shinyApp(ui = ui, server = server)