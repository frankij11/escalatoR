# ============================================================================
# escalatoR: DoD Cost Escalation Analysis Shiny Application
# Interactive User Interface for Cost Estimation Following CAPE Methodology
# ============================================================================

# Load required libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DT)
library(plotly)
library(tidyverse)
library(fredr)

# Source R package functions (in production, this would be library(escalatoR))
source("R/fred_api.R")
source("R/data_processing.R")
source("R/escalation_calc.R")
source("R/forecasting.R")
source("R/outlay_profiles.R")
source("R/weighted_indices.R")
source("R/export_functions.R")
source("R/cape_standards.R")

# ============================================================================
# USER INTERFACE
# ============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "CAPE Escalation Analysis System",
    titleWidth = 300,
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        tags$img(src = "cape_logo.png", height = "40px", style = "padding: 5px;")
      )
    )
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar",
      
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Selection", tabName = "data", icon = icon("database")),
      menuItem("Processing", tabName = "processing", icon = icon("cogs")),
      menuItem("Forecasting", tabName = "forecasting", icon = icon("chart-line")),
      menuItem("Outlay Profiles", tabName = "outlay", icon = icon("layer-group")),
      menuItem("Weighted Index", tabName = "weighted", icon = icon("calculator")),
      menuItem("Export Results", tabName = "export", icon = icon("download")),
      menuItem("Documentation", tabName = "docs", icon = icon("book")),
      
      hr(),
      
      # FRED API Key input
      div(style = "padding: 10px;",
        passwordInput("fred_api_key", "FRED API Key:",
                     placeholder = "Enter your API key"),
        actionButton("connect_fred", "Connect", 
                    class = "btn-primary btn-block"),
        br(),
        textOutput("connection_status")
      )
    )
  ),
  
  # Body
  dashboardBody(
    
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .box-primary {
          border-top-color: #004b87;
        }
        .btn-primary {
          background-color: #004b87;
          border-color: #004b87;
        }
        .progress-bar {
          background-color: #004b87;
        }
      "))
    ),
    
    tabItems(
      
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        
        fluidRow(
          # Status boxes
          valueBoxOutput("data_status"),
          valueBoxOutput("forecast_status"),
          valueBoxOutput("export_status")
        ),
        
        fluidRow(
          # Current analysis summary
          box(
            title = "Current Analysis Summary",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                h4("Selected Index:"),
                textOutput("current_index_name"),
                br(),
                h4("Date Range:"),
                textOutput("current_date_range")
              ),
              column(4,
                h4("Base Year:"),
                textOutput("current_base_year"),
                br(),
                h4("Forecast Method:"),
                textOutput("current_forecast_method")
              ),
              column(4,
                h4("Outlay Profile:"),
                textOutput("current_outlay_profile"),
                br(),
                h4("Weighted Index:"),
                textOutput("weighted_index_status")
              )
            )
          )
        ),
        
        fluidRow(
          # Quick visualization
          box(
            title = "Escalation Index Preview",
            status = "primary",
            width = 12,
            plotlyOutput("dashboard_plot", height = "400px")
          )
        )
      ),
      
      # Data Selection Tab
      tabItem(
        tabName = "data",
        
        fluidRow(
          box(
            title = "Search and Select PPI Index",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                textInput("search_text", "Search Terms:",
                         placeholder = "e.g., aircraft, electronics"),
                
                selectInput("category_filter", "Category Filter:",
                           choices = c("All" = "all",
                                     "Aircraft" = "aircraft",
                                     "Missiles" = "missiles",
                                     "Naval" = "naval",
                                     "Electronics" = "electronics",
                                     "Munitions" = "munitions",
                                     "Services" = "services",
                                     "Reference" = "reference")),
                
                actionButton("search_indices", "Search", 
                           icon = icon("search"),
                           class = "btn-primary")
              ),
              
              column(8,
                h4("Available Indices:"),
                DT::dataTableOutput("search_results")
              )
            ),
            
            hr(),
            
            fluidRow(
              column(6,
                h4("Selected Index:"),
                textInput("selected_series_id", "Series ID:",
                         placeholder = "e.g., PCU3364133641"),
                
                dateRangeInput("date_range", "Date Range:",
                             start = "1990-01-01",
                             end = Sys.Date()),
                
                actionButton("download_data", "Download Data",
                           icon = icon("download"),
                           class = "btn-success")
              ),
              
              column(6,
                h4("Data Preview:"),
                plotlyOutput("data_preview_plot", height = "300px")
              )
            )
          )
        )
      ),
      
      # Processing Tab
      tabItem(
        tabName = "processing",
        
        fluidRow(
          box(
            title = "Data Processing Options",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            h4("Missing Value Interpolation"),
            radioButtons("interpolation_method", "Method:",
                        choices = c("Linear" = "linear",
                                  "Spline" = "spline",
                                  "Previous Value" = "previous")),
            
            hr(),
            
            h4("Fiscal Year Conversion"),
            numericInput("fy_start_month", "FY Start Month:",
                        value = 10, min = 1, max = 12),
            
            radioButtons("fy_aggregation", "Aggregation Method:",
                        choices = c("End of Year" = "end",
                                  "Average" = "mean",
                                  "Start of Year" = "start")),
            
            hr(),
            
            h4("Base Year Normalization"),
            numericInput("base_year", "Base Year:",
                        value = 2024, min = 1990, max = 2050),
            
            hr(),
            
            actionButton("process_data", "Process Data",
                        icon = icon("cogs"),
                        class = "btn-primary btn-block")
          ),
          
          box(
            title = "Processing Results",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            
            h4("Processing Summary:"),
            verbatimTextOutput("processing_summary"),
            
            hr(),
            
            h4("Escalation Statistics:"),
            tableOutput("escalation_stats"),
            
            hr(),
            
            h4("CAPE Validation:"),
            verbatimTextOutput("cape_validation")
          )
        ),
        
        fluidRow(
          box(
            title = "Processed Data View",
            status = "info",
            width = 12,
            
            tabsetPanel(
              tabPanel("Table View",
                      DT::dataTableOutput("processed_data_table")),
              tabPanel("Chart View",
                      plotlyOutput("processed_data_chart", height = "400px"))
            )
          )
        )
      ),
      
      # Forecasting Tab
      tabItem(
        tabName = "forecasting",
        
        fluidRow(
          box(
            title = "Forecasting Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                h4("Forecast Method:"),
                radioButtons("forecast_method", NULL,
                           choices = c("User Defined Rates" = "user",
                                     "ARIMA Time Series" = "arima",
                                     "Machine Learning" = "ml",
                                     "CAPE Average" = "cape_avg")),
                
                conditionalPanel(
                  condition = "input.forecast_method == 'user'",
                  h4("Enter Escalation Rates:"),
                  textAreaInput("user_rates", NULL,
                               placeholder = "Enter rates separated by commas\ne.g., 2.5, 3.0, 2.8, 2.5",
                               rows = 3)
                ),
                
                conditionalPanel(
                  condition = "input.forecast_method != 'user'",
                  h4("Model Parameters:"),
                  sliderInput("confidence_level", "Confidence Level:",
                             min = 0.80, max = 0.99, value = 0.95, step = 0.01)
                )
              ),
              
              column(4,
                h4("Forecast Period:"),
                numericInput("forecast_years", "Years to Forecast:",
                           value = 5, min = 1, max = 30),
                
                h4("Backcasting:"),
                checkboxInput("enable_backcast", "Enable Backcasting"),
                
                conditionalPanel(
                  condition = "input.enable_backcast",
                  numericInput("backcast_years", "Years to Backcast:",
                             value = 5, min = 1, max = 20),
                  radioButtons("backcast_method", "Method:",
                             choices = c("Trend" = "trend",
                                       "Average" = "average",
                                       "User Rate" = "user"))
                )
              ),
              
              column(4,
                h4("Risk Adjustment:"),
                checkboxInput("apply_risk", "Apply Risk Factor"),
                
                conditionalPanel(
                  condition = "input.apply_risk",
                  sliderInput("risk_factor", "Risk Factor:",
                             min = 0.5, max = 2.0, value = 1.0, step = 0.05)
                ),
                
                br(),
                actionButton("generate_forecast", "Generate Forecast",
                           icon = icon("chart-line"),
                           class = "btn-success btn-lg")
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Forecast Results",
            status = "success",
            width = 12,
            
            plotlyOutput("forecast_plot", height = "500px"),
            
            hr(),
            
            h4("Forecast Summary:"),
            tableOutput("forecast_summary")
          )
        )
      ),
      
      # Outlay Profiles Tab
      tabItem(
        tabName = "outlay",
        
        fluidRow(
          box(
            title = "Outlay Profile Selection",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            h4("Select Profile:"),
            radioButtons("profile_source", NULL,
                        choices = c("Default Profiles" = "default",
                                  "Custom Profile" = "custom",
                                  "Upload Profile" = "upload")),
            
            conditionalPanel(
              condition = "input.profile_source == 'default'",
              selectInput("default_profile", "Choose Profile:",
                         choices = c("Aircraft Development" = "aircraft_development",
                                   "Ship Building" = "ship_building",
                                   "Electronics/IT" = "electronics",
                                   "Munitions" = "munitions",
                                   "Services" = "services"))
            ),
            
            conditionalPanel(
              condition = "input.profile_source == 'custom'",
              h4("Enter Outlay Percentages:"),
              p("Enter percentages for each year (must sum to 100%)"),
              textAreaInput("custom_outlays", NULL,
                           placeholder = "Year 1: 20\nYear 2: 30\nYear 3: 25\nYear 4: 15\nYear 5: 10",
                           rows = 6),
              textInput("custom_profile_name", "Profile Name:",
                       placeholder = "My Custom Profile")
            ),
            
            conditionalPanel(
              condition = "input.profile_source == 'upload'",
              fileInput("upload_profile", "Upload CSV:",
                       accept = c(".csv")),
              p("CSV should have columns: year_offset, outlay_pct")
            ),
            
            br(),
            actionButton("apply_profile", "Apply Profile",
                        icon = icon("check"),
                        class = "btn-primary btn-block")
          ),
          
          box(
            title = "Profile Visualization",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            plotlyOutput("profile_plot", height = "300px"),
            
            hr(),
            
            h4("Profile Details:"),
            tableOutput("profile_table")
          )
        )
      ),
      
      # Weighted Index Tab
      tabItem(
        tabName = "weighted",
        
        fluidRow(
          box(
            title = "Weighted Index Calculation",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                h4("Configuration:"),
                numericInput("weight_start_year", "Start Year:",
                           value = 2024, min = 1990, max = 2050),
                
                h4("Calculation Options:"),
                checkboxInput("include_confidence", "Include Confidence Bounds"),
                checkboxInput("portfolio_mode", "Portfolio Mode (Multiple Indices)")
              ),
              
              column(8,
                h4("Weighted Index Preview:"),
                plotlyOutput("weighted_preview", height = "300px")
              )
            ),
            
            hr(),
            
            actionButton("calculate_weighted", "Calculate Weighted Index",
                        icon = icon("calculator"),
                        class = "btn-success btn-block")
          )
        ),
        
        fluidRow(
          box(
            title = "Weighted Index Results",
            status = "success",
            width = 12,
            
            tabsetPanel(
              tabPanel("Detailed View",
                      DT::dataTableOutput("weighted_detailed")),
              tabPanel("Composite View",
                      tableOutput("weighted_composite")),
              tabPanel("Visualization",
                      plotlyOutput("weighted_chart", height = "400px"))
            )
          )
        )
      ),
      
      # Export Tab
      tabItem(
        tabName = "export",
        
        fluidRow(
          box(
            title = "Export Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            h4("Export Format:"),
            radioButtons("export_format", NULL,
                        choices = c("CSV" = "csv",
                                  "Excel with Documentation" = "excel",
                                  "JSON (API-ready)" = "json")),
            
            h4("Include in Export:"),
            checkboxGroupInput("export_includes", NULL,
                             choices = c("Raw Data" = "raw",
                                       "Processed Data" = "processed",
                                       "Forecast Data" = "forecast",
                                       "Outlay Profile" = "outlay",
                                       "Weighted Index" = "weighted",
                                       "Metadata" = "metadata",
                                       "CAPE Compliance" = "compliance"),
                             selected = c("processed", "forecast", "weighted", "metadata")),
            
            h4("File Name:"),
            textInput("export_filename", NULL,
                     value = paste0("CAPE_Escalation_", Sys.Date())),
            
            br(),
            
            downloadButton("download_results", "Download Results",
                          class = "btn-success btn-block")
          ),
          
          box(
            title = "Export Preview",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            h4("Export Summary:"),
            verbatimTextOutput("export_summary"),
            
            hr(),
            
            h4("Metadata to Include:"),
            tableOutput("export_metadata")
          )
        )
      ),
      
      # Documentation Tab
      tabItem(
        tabName = "docs",
        
        fluidRow(
          box(
            title = "CAPE Escalation Analysis Documentation",
            status = "primary",
            width = 12,
            
            tabsetPanel(
              tabPanel("Quick Start",
                      includeMarkdown("docs/quick_start.md")),
              
              tabPanel("CAPE Documentation",
                      includeMarkdown("docs/cape_documentation.md")),
              
              #tabPanel("User Guide",
              #        includeMarkdown("docs/user_guide.md")),
              
              #tabPanel("API Reference",
              #        includeMarkdown("docs/api_reference.md")),
              
              #tabPanel("Best Practices",
              #        includeMarkdown("docs/best_practices.md")),
              
              #tabPanel("FAQ",
              #        includeMarkdown("docs/faq.md"))
            )
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER LOGIC
# ============================================================================

server <- function(input, output, session) {
  
  # Reactive values to store data throughout the session
  values <- reactiveValues(
    fred_connected = FALSE,
    raw_data = NULL,
    processed_data = NULL,
    forecast_data = NULL,
    outlay_profile = NULL,
    weighted_index = NULL,
    current_index_info = NULL
  )
  
  # FRED API Connection
  observeEvent(input$connect_fred, {
    tryCatch({
      init_fred_api(input$fred_api_key)
      values$fred_connected <- TRUE
      output$connection_status <- renderText("✓ Connected to FRED")
      showNotification("Successfully connected to FRED API", type = "success")
    }, error = function(e) {
      output$connection_status <- renderText("✗ Not connected")
      showNotification(paste("Connection failed:", e$message), type = "error")
    })
  })
  
  # Search indices
  observeEvent(input$search_indices, {
    req(values$fred_connected)
    
    results <- search_ppi_indices(
      input$search_text,
      if(input$category_filter != "all") input$category_filter else NULL
    )
    
    output$search_results <- DT::renderDataTable({
      results %>%
        select(id, title, defense_category, cape_recommended) %>%
        DT::datatable(
          selection = 'single',
          options = list(pageLength = 5)
        )
    })
  })
  
  # Download data
  observeEvent(input$download_data, {
    req(input$selected_series_id)
    
    withProgress(message = 'Downloading data...', {
      tryCatch({
        values$raw_data <- download_ppi_index(
          input$selected_series_id,
          as.character(input$date_range[1]),
          as.character(input$date_range[2])
        )
        
        values$current_index_info <- list(
          series_id = input$selected_series_id,
          series_name = values$raw_data$series_name[1]
        )
        
        showNotification("Data downloaded successfully", type = "success")
        
        # Update preview plot
        output$data_preview_plot <- renderPlotly({
          plot_ly(values$raw_data, x = ~date, y = ~value, type = 'scatter', mode = 'lines',
                 name = 'Index Value') %>%
            layout(title = "Raw Index Data",
                  xaxis = list(title = "Date"),
                  yaxis = list(title = "Index Value"))
        })
        
      }, error = function(e) {
        showNotification(paste("Download failed:", e$message), type = "error")
      })
    })
  })
  
  # Process data
  observeEvent(input$process_data, {
    req(values$raw_data)
    
    withProgress(message = 'Processing data...', {
      
      # Fill missing values
      setProgress(0.2, detail = "Interpolating missing values...")
      filled_data <- fill_missing_values(values$raw_data, input$interpolation_method)
      
      # Convert to fiscal year
      setProgress(0.4, detail = "Converting to fiscal year...")
      fy_data <- convert_to_fiscal_year(filled_data, input$fy_start_month, input$fy_aggregation)
      
      # Calculate escalation rates
      setProgress(0.6, detail = "Calculating escalation rates...")
      escalation_data <- calculate_escalation_rates(fy_data)
      
      # Normalize to base year
      setProgress(0.8, detail = "Normalizing to base year...")
      normalized_data <- normalize_base_year(escalation_data, input$base_year)
      
      # Validate CAPE standards
      setProgress(0.9, detail = "Validating CAPE standards...")
      validation <- validate_cape_standards(normalized_data)
      
      values$processed_data <- normalized_data
      
      setProgress(1.0, detail = "Complete!")
      showNotification("Data processing complete", type = "success")
      
      # Update outputs
      output$processing_summary <- renderPrint({
        cat("Processing Complete\n")
        cat("Records processed:", nrow(values$processed_data), "\n")
        cat("Fiscal years:", min(values$processed_data$fiscal_year), "-", 
            max(values$processed_data$fiscal_year), "\n")
      })
      
      output$escalation_stats <- renderTable({
        attr(values$processed_data, "escalation_stats")
      })
      
      output$cape_validation <- renderPrint({
        print(validation)
      })
      
      output$processed_data_table <- DT::renderDataTable({
        values$processed_data %>%
          select(fiscal_year, index_value, escalation_rate, normalized_index) %>%
          DT::datatable(options = list(pageLength = 10))
      })
      
      output$processed_data_chart <- renderPlotly({
        plot_ly(values$processed_data, x = ~fiscal_year, y = ~normalized_index,
               type = 'scatter', mode = 'lines+markers', name = 'Normalized Index') %>%
          layout(title = "Processed Escalation Index",
                xaxis = list(title = "Fiscal Year"),
                yaxis = list(title = "Normalized Index"))
      })
    })
  })
  
  # Generate forecast
  observeEvent(input$generate_forecast, {
    req(values$processed_data)
    
    withProgress(message = 'Generating forecast...', {
      
      # Apply backcasting if enabled
      if (input$enable_backcast) {
        setProgress(0.2, detail = "Backcasting historical data...")
        backcast_data <- backcast_index(
          values$processed_data,
          input$backcast_years,
          input$backcast_method
        )
      } else {
        backcast_data <- values$processed_data
      }
      
      # Generate forecast based on method
      setProgress(0.5, detail = "Forecasting future values...")
      
      if (input$forecast_method == "user") {
        rates <- as.numeric(unlist(strsplit(input$user_rates, ",")))
        forecast_data <- forecast_user_defined(backcast_data, input$forecast_years, rates)
      } else if (input$forecast_method == "arima") {
        forecast_data <- forecast_arima(backcast_data, input$forecast_years, input$confidence_level)
      } else {
        # Default to user-defined with 2.5% rate
        forecast_data <- forecast_user_defined(backcast_data, input$forecast_years, 2.5)
      }
      
      # Apply risk adjustment if enabled
      if (input$apply_risk) {
        setProgress(0.8, detail = "Applying risk adjustment...")
        forecast_data <- apply_cape_risk_adjustment(forecast_data, input$risk_factor)
      }
      
      values$forecast_data <- forecast_data
      
      setProgress(1.0, detail = "Complete!")
      showNotification("Forecast generated successfully", type = "success")
      
      # Update forecast plot
      output$forecast_plot <- renderPlotly({
        p <- plot_ly()
        
        # Historical data
        historical <- forecast_data %>% filter(forecast_type == "historical")
        p <- p %>% add_trace(data = historical, x = ~fiscal_year, y = ~normalized_index,
                           type = 'scatter', mode = 'lines+markers',
                           name = 'Historical', line = list(color = 'blue'))
        
        # Forecast data
        forecast <- forecast_data %>% filter(forecast_type != "historical")
        p <- p %>% add_trace(data = forecast, x = ~fiscal_year, y = ~normalized_index,
                           type = 'scatter', mode = 'lines+markers',
                           name = 'Forecast', line = list(color = 'red', dash = 'dash'))
        
        # Confidence bounds if available
        if ("confidence_lower" %in% names(forecast_data)) {
          p <- p %>% add_trace(data = forecast, x = ~fiscal_year, y = ~confidence_lower,
                             type = 'scatter', mode = 'lines',
                             name = 'Lower Bound', line = list(color = 'gray', dash = 'dot'))
          p <- p %>% add_trace(data = forecast, x = ~fiscal_year, y = ~confidence_upper,
                             type = 'scatter', mode = 'lines',
                             name = 'Upper Bound', line = list(color = 'gray', dash = 'dot'))
        }
        
        p %>% layout(title = "Escalation Forecast",
                    xaxis = list(title = "Fiscal Year"),
                    yaxis = list(title = "Normalized Index"))
      })
      
      # Update forecast summary
      output$forecast_summary <- renderTable({
        forecast_data %>%
          filter(forecast_type != "historical") %>%
          summarise(
            `Forecast Years` = n(),
            `Mean Escalation Rate` = round(mean(escalation_rate, na.rm = TRUE), 2),
            `Min Index` = round(min(normalized_index, na.rm = TRUE), 2),
            `Max Index` = round(max(normalized_index, na.rm = TRUE), 2)
          )
      })
    })
  })
  
  # Apply outlay profile
  observeEvent(input$apply_profile, {
    
    if (input$profile_source == "default") {
      profiles <- load_default_profiles()
      values$outlay_profile <- profiles[[input$default_profile]]
    } else if (input$profile_source == "custom") {
      outlays <- as.numeric(unlist(strsplit(input$custom_outlays, "\n")))
      outlays <- outlays / 100  # Convert percentages to decimals
      values$outlay_profile <- create_custom_profile(outlays, input$custom_profile_name)
    }
    
    showNotification("Outlay profile applied", type = "success")
    
    # Update profile visualization
    output$profile_plot <- renderPlotly({
      plot_ly(values$outlay_profile, x = ~year_offset, y = ~outlay_pct * 100,
             type = 'bar', name = 'Outlay %') %>%
        layout(title = "Outlay Profile",
              xaxis = list(title = "Year Offset"),
              yaxis = list(title = "Percentage"))
    })
    
    output$profile_table <- renderTable({
      values$outlay_profile %>%
        mutate(outlay_pct = paste0(round(outlay_pct * 100, 1), "%"))
    })
  })
  
  # Calculate weighted index
  observeEvent(input$calculate_weighted, {
    req(values$forecast_data, values$outlay_profile)
    
    withProgress(message = 'Calculating weighted index...', {
      
      values$weighted_index <- calculate_weighted_index(
        values$forecast_data,
        values$outlay_profile,
        input$weight_start_year
      )
      
      showNotification("Weighted index calculated", type = "success")
      
      # Update outputs
      output$weighted_detailed <- DT::renderDataTable({
        values$weighted_index$detailed %>%
          DT::datatable(options = list(pageLength = 10))
      })
      
      output$weighted_composite <- renderTable({
        values$weighted_index$composite
      })
      
      output$weighted_chart <- renderPlotly({
        plot_ly(values$weighted_index$detailed, x = ~fiscal_year, y = ~weighted_index,
               type = 'scatter', mode = 'lines+markers',
               name = 'Weighted Index') %>%
          layout(title = "Weighted Escalation Index",
                xaxis = list(title = "Fiscal Year"),
                yaxis = list(title = "Weighted Index"))
      })
    })
  })
  
  # Download handler
  output$download_results <- downloadHandler(
    filename = function() {
      paste0(input$export_filename, ".", input$export_format)
    },
    content = function(file) {
      
      # Prepare metadata
      metadata <- list(
        series_id = values$current_index_info$series_id,
        series_name = values$current_index_info$series_name,
        base_year = input$base_year,
        forecast_method = input$forecast_method,
        forecast_years = input$forecast_years,
        interpolation_method = input$interpolation_method,
        fy_aggregation = input$fy_aggregation,
        escalation_method = "simple",
        outlay_profile = input$default_profile,
        export_date = Sys.Date(),
        analyst = Sys.info()["user"]
      )
      
      # Export based on format
      if (input$export_format == "csv") {
        export_to_csv(values$forecast_data, metadata, file)
      } else if (input$export_format == "excel") {
        export_to_excel(values$forecast_data, metadata, values$outlay_profile, file)
      }
    }
  )
  
  # Dashboard outputs
  output$data_status <- renderValueBox({
    valueBox(
      value = if(!is.null(values$raw_data)) "Ready" else "No Data",
      subtitle = "Data Status",
      icon = icon("database"),
      color = if(!is.null(values$raw_data)) "green" else "red"
    )
  })
  
  output$forecast_status <- renderValueBox({
    valueBox(
      value = if(!is.null(values$forecast_data)) "Complete" else "Pending",
      subtitle = "Forecast Status",
      icon = icon("chart-line"),
      color = if(!is.null(values$forecast_data)) "green" else "yellow"
    )
  })
  
  output$export_status <- renderValueBox({
    valueBox(
      value = if(!is.null(values$weighted_index)) "Ready" else "Incomplete",
      subtitle = "Export Status",
      icon = icon("download"),
      color = if(!is.null(values$weighted_index)) "green" else "orange"
    )
  })
  
  # Dashboard plot
  output$dashboard_plot <- renderPlotly({
    if (!is.null(values$forecast_data)) {
      plot_ly(values$forecast_data, x = ~fiscal_year, y = ~normalized_index,
             type = 'scatter', mode = 'lines',
             color = ~forecast_type) %>%
        layout(title = "Current Analysis",
              xaxis = list(title = "Fiscal Year"),
              yaxis = list(title = "Index"))
    } else {
      plotly_empty()
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)