# ============================================================================
# Results Module for Modern Escalation Analyzer
# Interactive results display and visualization
# ============================================================================

#' Results Module UI
#' @param id Module namespace ID
mod_results_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Results available check
    conditionalPanel(
      condition = "output['results_module-results_available']",
      
      fluidRow(
        # Results summary
        bs4Card(
          title = "Results Summary",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          # Summary statistics boxes
          fluidRow(
            modern_info_box(
              title = "Total Data Points",
              value = textOutput(ns("summary_total_points"), inline = TRUE),
              icon = "database",
              color = "primary",
              width = 3
            ),
            modern_info_box(
              title = "Forecast Horizon",
              value = textOutput(ns("summary_forecast_years"), inline = TRUE),
              icon = "calendar-alt",
              color = "info", 
              width = 3
            ),
            modern_info_box(
              title = "Avg Escalation",
              value = textOutput(ns("summary_avg_escalation"), inline = TRUE),
              icon = "trending-up",
              color = "success",
              width = 3
            ),
            modern_info_box(
              title = "Final Index Value",
              value = textOutput(ns("summary_final_value"), inline = TRUE),
              icon = "chart-line",
              color = "warning",
              width = 3
            )
          )
        )
      ),
      
      fluidRow(
        # Interactive data table
        bs4Card(
          title = "Detailed Results",
          status = "primary",
          solidHeader = TRUE,
          width = 8,
          
          # Table controls
          fluidRow(
            column(4,
              selectInput(
                ns("table_view"),
                "View:",
                choices = list(
                  "All Data" = "all",
                  "Historical Only" = "historical",
                  "Forecast Only" = "forecast"
                ),
                selected = "all"
              )
            ),
            column(4,
              numericInput(
                ns("table_rows"),
                "Rows to Display:",
                value = 25,
                min = 10,
                max = 100,
                step = 5
              )
            ),
            column(4,
              br(),
              downloadButton(
                ns("download_table"),
                "Download CSV",
                class = "btn btn-outline-primary"
              )
            )
          ),
          
          hr(),
          
          # Interactive table
          DT::dataTableOutput(ns("results_table"))
        ),
        
        # Chart controls and mini charts
        bs4Card(
          title = "Chart Controls",
          status = "info",
          solidHeader = TRUE,
          width = 4,
          
          # Chart type selection
          selectInput(
            ns("mini_chart_type"),
            "Mini Chart Type:",
            choices = list(
              "Escalation Rates" = "rates",
              "Index Values" = "index",
              "Year-over-Year" = "yoy"
            ),
            selected = "rates"
          ),
          
          # Mini chart
          modern_chart_container(
            ns("mini_chart"),
            height = "200px"
          ),
          
          br(),
          
          # Chart export options
          h6("Export Options:"),
          fluidRow(
            column(6,
              downloadButton(
                ns("download_png"),
                "PNG",
                class = "btn btn-outline-secondary btn-sm btn-block"
              )
            ),
            column(6,
              downloadButton(
                ns("download_pdf"),
                "PDF", 
                class = "btn btn-outline-secondary btn-sm btn-block"
              )
            )
          )
        )
      ),
      
      fluidRow(
        # Main visualization
        bs4Card(
          title = "Interactive Visualization",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          # Visualization controls
          fluidRow(
            column(3,
              selectInput(
                ns("viz_type"),
                "Visualization Type:",
                choices = list(
                  "Time Series" = "timeseries",
                  "Bar Chart" = "bar",
                  "Heatmap" = "heatmap",
                  "Distribution" = "distribution"
                ),
                selected = "timeseries"
              )
            ),
            column(3,
              selectInput(
                ns("color_scheme"),
                "Color Scheme:",
                choices = list(
                  "Professional" = "professional",
                  "Viridis" = "viridis",
                  "Blues" = "blues",
                  "Custom" = "custom"
                ),
                selected = "professional"
              )
            ),
            column(3,
              checkboxInput(
                ns("interactive_mode"),
                "Interactive Mode",
                value = TRUE
              )
            ),
            column(3,
              actionButton(
                ns("refresh_chart"),
                "Refresh Chart",
                icon = icon("sync"),
                class = "btn btn-outline-primary btn-block"
              )
            )
          ),
          
          hr(),
          
          # Main chart
          modern_chart_container(
            ns("main_visualization"),
            height = "500px"
          )
        )
      )
    ),
    
    # No results available state
    conditionalPanel(
      condition = "!output['results_module-results_available']",
      
      fluidRow(
        bs4Card(
          title = "No Results Available",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          
          div(
            style = "text-align: center; padding: 60px; color: #6c757d;",
            icon("chart-bar", class = "fa-4x", style = "margin-bottom: 20px;"),
            h3("No Analysis Results"),
            p("Run an analysis from the Analysis tab to view results here."),
            br(),
            actionButton(
              "goto_analysis",
              "Go to Analysis",
              icon = icon("arrow-right"),
              class = "btn btn-primary",
              onclick = "$('#sidebar_menu a[data-value=\"analysis\"]').click();"
            )
          )
        )
      )
    )
  )
}

#' Results Module Server
#' @param id Module namespace ID
#' @param values Global reactive values
mod_results_server <- function(id, values) {
  moduleServer(id, function(input, output, session) {
    
    # Check if results are available
    results_available <- reactive({
      !is.null(values$forecast_data)
    })
    
    # Summary statistics
    output$summary_total_points <- renderText({
      req(values$forecast_data)
      format(nrow(values$forecast_data), big.mark = ",")
    })
    
    output$summary_forecast_years <- renderText({
      req(values$forecast_data)
      forecast_count <- sum(values$forecast_data$forecast_type != "historical")
      as.character(forecast_count)
    })
    
    output$summary_avg_escalation <- renderText({
      req(values$forecast_data)
      avg_rate <- mean(values$forecast_data$escalation_rate, na.rm = TRUE)
      paste0(round(avg_rate, 2), "%")
    })
    
    output$summary_final_value <- renderText({
      req(values$forecast_data)
      final_value <- tail(values$forecast_data$normalized_index, 1)
      round(final_value, 2)
    })
    
    # Filtered data for table
    filtered_data <- reactive({
      req(values$forecast_data)
      
      data <- values$forecast_data
      
      if (input$table_view == "historical") {
        data <- data[data$forecast_type == "historical", ]
      } else if (input$table_view == "forecast") {
        data <- data[data$forecast_type != "historical", ]
      }
      
      return(data)
    })
    
    # Results table
    output$results_table <- DT::renderDataTable({
      req(filtered_data())
      
      # Format data for display
      display_data <- filtered_data() %>%
        select(
          `Fiscal Year` = fiscal_year,
          `Index Value` = normalized_index,
          `Escalation Rate (%)` = escalation_rate,
          `Type` = forecast_type
        ) %>%
        mutate(
          `Index Value` = round(`Index Value`, 3),
          `Escalation Rate (%)` = round(`Escalation Rate (%)`, 2)
        )
      
      modern_data_table(
        display_data,
        selection = "none",
        options = list(
          pageLength = input$table_rows,
          scrollX = TRUE,
          columnDefs = list(
            list(className = "dt-right", targets = c(1, 2))
          )
        )
      )
    })
    
    # Mini chart
    output$mini_chart <- renderPlotly({
      req(values$forecast_data)
      
      data <- values$forecast_data
      
      if (input$mini_chart_type == "rates") {
        p <- plot_ly(
          data = data,
          x = ~fiscal_year,
          y = ~escalation_rate,
          type = "scatter",
          mode = "lines",
          line = list(color = "#667eea")
        ) %>%
          layout(
            title = list(text = "Escalation Rates", font = list(size = 12)),
            showlegend = FALSE,
            margin = list(t = 30, b = 30, l = 40, r = 20)
          )
      } else if (input$mini_chart_type == "index") {
        p <- plot_ly(
          data = data,
          x = ~fiscal_year,
          y = ~normalized_index,
          type = "scatter",
          mode = "lines",
          line = list(color = "#764ba2")
        ) %>%
          layout(
            title = list(text = "Index Values", font = list(size = 12)),
            showlegend = FALSE,
            margin = list(t = 30, b = 30, l = 40, r = 20)
          )
      } else {
        # Year-over-year change
        data$yoy_change <- c(NA, diff(data$normalized_index))
        p <- plot_ly(
          data = data,
          x = ~fiscal_year,
          y = ~yoy_change,
          type = "bar",
          marker = list(color = "#06d6a0")
        ) %>%
          layout(
            title = list(text = "Year-over-Year", font = list(size = 12)),
            showlegend = FALSE,
            margin = list(t = 30, b = 30, l = 40, r = 20)
          )
      }
      
      p %>% config(displayModeBar = FALSE)
    })
    
    # Main visualization
    output$main_visualization <- renderPlotly({
      req(values$forecast_data)
      
      data <- values$forecast_data
      
      if (input$viz_type == "timeseries") {
        p <- plot_ly(data = data, x = ~fiscal_year) %>%
          add_trace(
            y = ~normalized_index,
            color = ~forecast_type,
            type = "scatter",
            mode = "lines+markers",
            colors = c("#667eea", "#764ba2")
          ) %>%
          layout(
            title = "Escalation Index Time Series",
            xaxis = list(title = "Fiscal Year"),
            yaxis = list(title = "Normalized Index")
          )
      } else if (input$viz_type == "bar") {
        recent_data <- tail(data, 20)
        p <- plot_ly(
          data = recent_data,
          x = ~fiscal_year,
          y = ~escalation_rate,
          type = "bar",
          marker = list(color = "#667eea")
        ) %>%
          layout(
            title = "Recent Escalation Rates",
            xaxis = list(title = "Fiscal Year"),
            yaxis = list(title = "Escalation Rate (%)")
          )
      } else {
        # Default to time series
        p <- plot_ly(data = data, x = ~fiscal_year, y = ~normalized_index) %>%
          add_trace(type = "scatter", mode = "lines") %>%
          layout(title = "Index Visualization")
      }
      
      p %>% config(
        displayModeBar = input$interactive_mode,
        responsive = TRUE
      )
    })
    
    # Download handlers
    output$download_table <- downloadHandler(
      filename = function() {
        paste0("escalation_results_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(filtered_data(), file, row.names = FALSE)
      }
    )
    
    # Output reactive for conditional panels
    output$results_available <- reactive({
      results_available()
    })
    outputOptions(output, "results_available", suspendWhenHidden = FALSE)
  })
}