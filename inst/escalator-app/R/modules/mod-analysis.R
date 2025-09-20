# ============================================================================
# Analysis Module for Modern Escalation Analyzer
# Forecasting and statistical analysis interface  
# ============================================================================

#' Analysis Module UI
#' @param id Module namespace ID
mod_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Analysis Configuration
      bs4Card(
        title = "Analysis Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        # Analysis method selection
        selectInput(
          ns("forecast_method"),
          "Forecast Method:",
          choices = list(
            "ARIMA Time Series" = "arima",
            "User Defined Rates" = "user",
            "Machine Learning" = "ml"
          ),
          selected = "arima"
        ),
        
        br(),
        
        # Forecast parameters
        numericInput(
          ns("forecast_years"),
          "Forecast Years:",
          value = 10,
          min = 1,
          max = 20,
          step = 1
        ),
        
        numericInput(
          ns("confidence_level"),
          "Confidence Level (%):",
          value = 95,
          min = 80,
          max = 99,
          step = 1
        ),
        
        # Method-specific options
        conditionalPanel(
          condition = "input.forecast_method == 'user'",
          ns = ns,
          
          h5("User Defined Rates"),
          numericInput(
            ns("user_rate"),
            "Annual Escalation Rate (%):",
            value = 3.0,
            min = -10,
            max = 20,
            step = 0.1
          )
        ),
        
        conditionalPanel(
          condition = "input.forecast_method == 'ml'",
          ns = ns,
          
          h5("Machine Learning Options"),
          selectInput(
            ns("ml_method"),
            "Algorithm:",
            choices = list(
              "Random Forest" = "rf",
              "Neural Network" = "nn",
              "Ensemble" = "ensemble"
            ),
            selected = "rf"
          )
        ),
        
        hr(),
        
        # Run analysis button
        actionButton(
          ns("run_analysis"),
          "Run Analysis",
          icon = icon("play"),
          class = "btn btn-success btn-lg btn-block"
        )
      ),
      
      # Analysis Status
      bs4Card(
        title = "Analysis Status", 
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        # Progress indicators
        div(id = ns("analysis_progress")),
        
        # Status messages
        div(id = ns("analysis_status")),
        
        # Quick preview
        conditionalPanel(
          condition = "output['analysis_module-analysis_complete']",
          
          modern_chart_container(
            ns("quick_forecast_chart"),
            height = "300px",
            title = "Forecast Preview"
          )
        )
      )
    ),
    
    # Detailed Results
    conditionalPanel(
      condition = "output['analysis_module-analysis_complete']",
      
      fluidRow(
        bs4Card(
          title = "Forecast Results",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          tabsetPanel(
            id = ns("results_tabs"),
            
            # Forecast visualization
            tabPanel(
              "Forecast Chart",
              
              br(),
              
              modern_chart_container(
                ns("main_forecast_chart"),
                height = "500px"
              ),
              
              br(),
              
              # Chart controls
              fluidRow(
                column(3,
                  selectInput(
                    ns("chart_type"),
                    "Chart Type:",
                    choices = list(
                      "Line Chart" = "line",
                      "Area Chart" = "area",
                      "Candlestick" = "candlestick"
                    ),
                    selected = "line"
                  )
                ),
                column(3,
                  checkboxInput(
                    ns("show_confidence"),
                    "Show Confidence Bands",
                    value = TRUE
                  )
                ),
                column(3,
                  checkboxInput(
                    ns("show_historical"),
                    "Show Historical Data", 
                    value = TRUE
                  )
                ),
                column(3,
                  downloadButton(
                    ns("download_chart"),
                    "Download Chart",
                    class = "btn btn-outline-primary"
                  )
                )
              )
            ),
            
            # Statistical summary
            tabPanel(
              "Statistical Summary",
              
              br(),
              
              fluidRow(
                column(6,
                  modern_stats_card(
                    "Forecast Statistics",
                    list(
                      "Mean Rate" = textOutput(ns("forecast_mean_rate"), inline = TRUE),
                      "Std Deviation" = textOutput(ns("forecast_std_dev"), inline = TRUE),
                      "Min Value" = textOutput(ns("forecast_min"), inline = TRUE),
                      "Max Value" = textOutput(ns("forecast_max"), inline = TRUE)
                    )
                  )
                ),
                column(6,
                  modern_stats_card(
                    "Model Performance",
                    list(
                      "Model Type" = textOutput(ns("model_type"), inline = TRUE),
                      "R-Squared" = textOutput(ns("model_r_squared"), inline = TRUE),
                      "RMSE" = textOutput(ns("model_rmse"), inline = TRUE),
                      "AIC" = textOutput(ns("model_aic"), inline = TRUE)
                    ),
                    color = "info"
                  )
                )
              ),
              
              br(),
              
              # Detailed statistics table
              DT::dataTableOutput(ns("forecast_summary_table"))
            ),
            
            # Model diagnostics
            tabPanel(
              "Model Diagnostics",
              
              br(),
              
              fluidRow(
                column(6,
                  modern_chart_container(
                    ns("residuals_chart"),
                    height = "300px",
                    title = "Residuals Analysis"
                  )
                ),
                column(6,
                  modern_chart_container(
                    ns("qq_plot"),
                    height = "300px", 
                    title = "Q-Q Plot"
                  )
                )
              ),
              
              br(),
              
              fluidRow(
                column(12,
                  modern_chart_container(
                    ns("autocorrelation_chart"),
                    height = "300px",
                    title = "Autocorrelation Function"
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

#' Analysis Module Server
#' @param id Module namespace ID
#' @param values Global reactive values
mod_analysis_server <- function(id, values) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    local_values <- reactiveValues(
      forecast_results = NULL,
      model_diagnostics = NULL,
      analysis_complete = FALSE
    )
    
    # Run analysis
    observeEvent(input$run_analysis, {
      req(values$processed_data)
      
      # Show analysis progress
      waiter::waiter_show(
        html = tagList(
          h3("Running Escalation Analysis..."),
          div(class = "spinner-border", role = "status"),
          p("This may take a few moments...")
        ),
        color = "rgba(102, 126, 234, 0.8)"
      )
      
      tryCatch({
        
        # Prepare data
        historical_data <- values$processed_data
        
        # Run forecast based on selected method
        if (input$forecast_method == "arima") {
          
          forecast_data <- forecast_arima(
            historical_data = historical_data,
            forecast_years = input$forecast_years,
            confidence_level = input$confidence_level / 100
          )
          
        } else if (input$forecast_method == "user") {
          
          # Convert percentage to decimal
          annual_rate <- input$user_rate / 100
          
          forecast_data <- forecast_user_defined(
            historical_data = historical_data,
            forecast_years = input$forecast_years,
            rates = rep(annual_rate, input$forecast_years)
          )
          
        } else if (input$forecast_method == "ml") {
          
          # Placeholder for ML forecasting
          forecast_data <- forecast_arima(
            historical_data = historical_data,
            forecast_years = input$forecast_years,
            confidence_level = input$confidence_level / 100
          )
          
          modern_notify(
            "ML forecasting is under development. Using ARIMA instead.",
            type = "info"
          )
        }
        
        # Store results
        local_values$forecast_results <- forecast_data
        values$forecast_data <- forecast_data
        values$forecast_method <- input$forecast_method
        values$forecast_years <- input$forecast_years
        values$last_updated <- Sys.time()
        
        local_values$analysis_complete <- TRUE
        
        waiter::waiter_hide()
        
        modern_notify(
          "Analysis completed successfully! 🎉", 
          type = "success"
        )
        
      }, error = function(e) {
        waiter::waiter_hide()
        modern_notify(
          paste("Analysis failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Main forecast chart
    output$main_forecast_chart <- renderPlotly({
      req(local_values$forecast_results)
      
      data <- local_values$forecast_results
      
      # Create base plot
      p <- plot_ly(data = data, x = ~fiscal_year) %>%
        layout(
          title = "Escalation Forecast Analysis",
          xaxis = list(title = "Fiscal Year"),
          yaxis = list(title = "Normalized Index"),
          hovermode = "x unified"
        )
      
      # Add historical data
      if (input$show_historical) {
        historical <- data[data$forecast_type == "historical", ]
        p <- p %>% add_trace(
          data = historical,
          y = ~normalized_index,
          name = "Historical",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#667eea"),
          marker = list(color = "#667eea")
        )
      }
      
      # Add forecast
      forecast <- data[data$forecast_type != "historical", ]
      p <- p %>% add_trace(
        data = forecast,
        y = ~normalized_index,
        name = "Forecast",
        type = "scatter",
        mode = "lines+markers",
        line = list(color = "#764ba2", dash = "dash"),
        marker = list(color = "#764ba2")
      )
      
      # Add confidence bands if available and requested
      if (input$show_confidence && "confidence_lower" %in% names(data)) {
        p <- p %>%
          add_ribbons(
            data = forecast,
            ymin = ~confidence_lower,
            ymax = ~confidence_upper,
            name = "Confidence Band",
            fillcolor = "rgba(118, 75, 162, 0.2)",
            line = list(color = "transparent")
          )
      }
      
      p %>% config(displayModeBar = TRUE, responsive = TRUE)
    })
    
    # Quick preview chart
    output$quick_forecast_chart <- renderPlotly({
      req(local_values$forecast_results)
      
      local_values$forecast_results %>%
        plot_ly(
          x = ~fiscal_year,
          y = ~normalized_index,
          color = ~forecast_type,
          type = "scatter",
          mode = "lines",
          colors = c("#667eea", "#764ba2")
        ) %>%
        layout(
          title = "Forecast Overview",
          showlegend = FALSE,
          margin = list(t = 30, b = 30, l = 30, r = 30)
        ) %>%
        config(displayModeBar = FALSE)
    })
    
    # Statistics outputs
    output$forecast_mean_rate <- renderText({
      req(local_values$forecast_results)
      forecast_data <- local_values$forecast_results[local_values$forecast_results$forecast_type != "historical", ]
      paste0(round(mean(forecast_data$escalation_rate, na.rm = TRUE), 2), "%")
    })
    
    output$model_type <- renderText({
      paste("ARIMA -", input$forecast_method)
    })
    
    # Output reactive for conditional panels  
    output$analysis_complete <- reactive({
      local_values$analysis_complete
    })
    outputOptions(output, "analysis_complete", suspendWhenHidden = FALSE)
  })
}