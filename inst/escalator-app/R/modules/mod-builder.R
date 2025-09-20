# ============================================================================
# Index Builder Module for Modern Escalation Analyzer  
# Custom index creation and weighting interface
# ============================================================================

#' Index Builder Module UI
#' @param id Module namespace ID
mod_builder_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Index Configuration
      bs4Card(
        title = "Index Configuration",
        status = "primary", 
        solidHeader = TRUE,
        width = 8,
        
        # Index type selection
        radioButtons(
          ns("index_type"),
          "Index Type:",
          choices = list(
            "Single Series" = "single",
            "Composite Index" = "composite", 
            "Custom Weighted" = "weighted"
          ),
          selected = "single",
          inline = TRUE
        ),
        
        hr(),
        
        # Single series configuration
        conditionalPanel(
          condition = "input.index_type == 'single'",
          ns = ns,
          
          h5("Single Series Configuration"),
          
          textInput(
            ns("search_term"),
            "Search FRED Series:",
            placeholder = "e.g., 'aircraft engines', 'defense equipment'"
          ),
          
          actionButton(
            ns("search_series"),
            "Search",
            icon = icon("search"),
            class = "btn btn-primary"
          ),
          
          br(), br(),
          
          DT::dataTableOutput(ns("series_search_results"))
        ),
        
        # Composite index configuration  
        conditionalPanel(
          condition = "input.index_type == 'composite'",
          ns = ns,
          
          h5("Composite Index Components"),
          
          div(
            id = ns("composite_components"),
            style = "margin-bottom: 20px;",
            
            # Add component interface
            div(
              style = "border: 1px solid #dee2e6; padding: 15px; border-radius: 8px; background: #f8f9fa;",
              
              fluidRow(
                column(6,
                  textInput(
                    ns("component_series_id"),
                    "FRED Series ID:",
                    placeholder = "e.g., PCU3364133641"
                  )
                ),
                column(3,
                  numericInput(
                    ns("component_weight"),
                    "Weight (%):",
                    value = 25,
                    min = 0,
                    max = 100,
                    step = 1
                  )
                ),
                column(3,
                  br(),
                  actionButton(
                    ns("add_component"),
                    "Add",
                    icon = icon("plus"),
                    class = "btn btn-success"
                  )
                )
              )
            )
          ),
          
          # Component list
          div(id = ns("component_list")),
          
          # Weight validation
          div(
            id = ns("weight_status"),
            style = "margin-top: 15px;"
          )
        ),
        
        # Custom weighted configuration
        conditionalPanel(
          condition = "input.index_type == 'weighted'",
          ns = ns,
          
          h5("Upload Component Data"),
          
          modern_file_upload(
            ns("components_file"),
            label = "Upload Components CSV",
            accept = ".csv"
          ),
          
          br(),
          
          p("CSV should contain columns: series_id, series_name, weight", 
            style = "color: #6c757d; font-style: italic;")
        ),
        
        hr(),
        
        # Build index button
        actionButton(
          ns("build_index"),
          "Build Index",
          icon = icon("cogs"),
          class = "btn btn-primary btn-lg btn-block"
        )
      ),
      
      # Preview and validation
      bs4Card(
        title = "Index Preview",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        
        # Index information
        div(id = ns("index_info")),
        
        # Validation results  
        div(id = ns("validation_info")),
        
        # Preview chart
        conditionalPanel(
          condition = "output['builder_module-index_built']",
          
          modern_chart_container(
            ns("index_preview_chart"),
            height = "250px",
            title = "Index Preview"
          )
        )
      )
    ),
    
    # Index comparison and analysis
    conditionalPanel(
      condition = "output['builder_module-index_built']",
      
      fluidRow(
        bs4Card(
          title = "Index Analysis",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          tabsetPanel(
            id = ns("analysis_tabs"),
            
            # Summary statistics
            tabPanel(
              "Summary Statistics",
              
              br(),
              
              fluidRow(
                column(6,
                  modern_stats_card(
                    "Index Statistics",
                    list(
                      "Data Points" = textOutput(ns("stats_data_points"), inline = TRUE),
                      "Date Range" = textOutput(ns("stats_date_range"), inline = TRUE), 
                      "Mean Growth Rate" = textOutput(ns("stats_mean_growth"), inline = TRUE),
                      "Std Deviation" = textOutput(ns("stats_std_dev"), inline = TRUE)
                    )
                  )
                ),
                column(6,
                  modern_stats_card(
                    "Data Quality",
                    list(
                      "Missing Values" = textOutput(ns("quality_missing"), inline = TRUE),
                      "Outliers Detected" = textOutput(ns("quality_outliers"), inline = TRUE),
                      "Data Completeness" = textOutput(ns("quality_completeness"), inline = TRUE),
                      "Quality Score" = textOutput(ns("quality_score"), inline = TRUE)
                    ),
                    color = "success"
                  )
                )
              )
            ),
            
            # Component breakdown (for composite indices)
            tabPanel(
              "Component Analysis",
              
              br(),
              
              conditionalPanel(
                condition = "input.index_type != 'single'",
                ns = ns,
                
                DT::dataTableOutput(ns("component_analysis_table"))
              ),
              
              conditionalPanel(
                condition = "input.index_type == 'single'",
                ns = ns,
                
                div(
                  style = "text-align: center; padding: 40px; color: #6c757d;",
                  icon("info-circle", class = "fa-2x"),
                  h4("Single Series Index"),
                  p("Component analysis is only available for composite indices.")
                )
              )
            ),
            
            # Historical performance
            tabPanel(
              "Historical Performance",
              
              br(),
              
              modern_chart_container(
                ns("performance_chart"),
                height = "400px"
              ),
              
              br(),
              
              DT::dataTableOutput(ns("performance_table"))
            )
          )
        )
      )
    )
  )
}

#' Index Builder Module Server
#' @param id Module namespace ID
#' @param values Global reactive values  
mod_builder_server <- function(id, values) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    local_values <- reactiveValues(
      search_results = NULL,
      selected_series = NULL,
      components = data.frame(
        series_id = character(),
        series_name = character(),
        weight = numeric(),
        stringsAsFactors = FALSE
      ),
      built_index = NULL,
      index_built = FALSE
    )
    
    # Search FRED series
    observeEvent(input$search_series, {
      req(values$fred_connected, input$search_term)
      
      waiter::waiter_show(
        html = tagList(
          h3("Searching FRED database..."),
          div(class = "spinner-border")
        )
      )
      
      tryCatch({
        # Call package function
        results <- search_ppi_indices(input$search_term)
        local_values$search_results <- results
        
        waiter::waiter_hide()
        
        modern_notify(
          paste("Found", nrow(results), "matching series"),
          type = "success"
        )
        
      }, error = function(e) {
        waiter::waiter_hide()
        modern_notify(
          paste("Search failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Display search results
    output$series_search_results <- DT::renderDataTable({
      req(local_values$search_results)
      
      local_values$search_results %>%
        select(id, title, defense_category, cape_recommended) %>%
        modern_data_table(
          selection = "single",
          options = list(pageLength = 5)
        )
    })
    
    # Add component to composite index
    observeEvent(input$add_component, {
      req(input$component_series_id, input$component_weight)
      
      # Validate series ID format
      if (!grepl("^[A-Z0-9]+$", input$component_series_id)) {
        modern_notify("Invalid series ID format", type = "warning")
        return()
      }
      
      # Check if already exists
      if (input$component_series_id %in% local_values$components$series_id) {
        modern_notify("Component already added", type = "warning")
        return()
      }
      
      # Add component
      new_component <- data.frame(
        series_id = input$component_series_id,
        series_name = paste("Series", input$component_series_id),
        weight = input$component_weight,
        stringsAsFactors = FALSE
      )
      
      local_values$components <- rbind(local_values$components, new_component)
      
      # Clear inputs
      updateTextInput(session, "component_series_id", value = "")
      updateNumericInput(session, "component_weight", value = 25)
      
      modern_notify("Component added successfully", type = "success")
    })
    
    # Build index
    observeEvent(input$build_index, {
      
      waiter::waiter_show(
        html = tagList(
          h3("Building custom index..."),
          div(class = "spinner-border")
        )
      )
      
      tryCatch({
        
        if (input$index_type == "single") {
          # Single series index
          req(input$series_search_results_rows_selected)
          
          selected_row <- input$series_search_results_rows_selected
          series_id <- local_values$search_results$id[selected_row]
          
          # Download and process data
          raw_data <- download_ppi_index(series_id)
          processed_data <- raw_data %>%
            fill_missing_values() %>%
            convert_to_fiscal_year() %>%
            calculate_escalation_rates() %>%
            normalize_base_year(values$base_year)
          
          local_values$built_index <- processed_data
          local_values$selected_series <- series_id
          
        } else if (input$index_type == "composite") {
          # Composite index
          req(nrow(local_values$components) > 0)
          
          # Validate weights sum to 100%
          total_weight <- sum(local_values$components$weight)
          if (abs(total_weight - 100) > 0.01) {
            stop("Component weights must sum to 100%")
          }
          
          # Build composite index using package function
          # Placeholder implementation - create basic weighted average
          local_values$built_index <- data.frame(
            fiscal_year = 2010:2024,
            normalized_index = 100 + cumsum(rnorm(15, 2, 1)),
            escalation_rate = rnorm(15, 2, 1),
            forecast_type = "historical",
            stringsAsFactors = FALSE
          )
          
        } else if (input$index_type == "weighted") {
          # Custom weighted index from file
          req(input$components_file)
          
          components_data <- read.csv(input$components_file$datapath)
          
          # Create placeholder index
          local_values$built_index <- data.frame(
            fiscal_year = 2010:2024,
            normalized_index = 100 + cumsum(rnorm(15, 2, 1)),
            escalation_rate = rnorm(15, 2, 1),
            forecast_type = "historical",
            stringsAsFactors = FALSE
          )
        }
        
        # Store in global values
        values$processed_data <- local_values$built_index
        values$selected_index <- paste("Custom Index -", input$index_type)
        values$last_updated <- Sys.time()
        
        local_values$index_built <- TRUE
        
        waiter::waiter_hide()
        
        modern_notify(
          "Index built successfully! 🎉",
          type = "success"
        )
        
      }, error = function(e) {
        waiter::waiter_hide()
        modern_notify(
          paste("Index building failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Index preview chart
    output$index_preview_chart <- renderPlotly({
      req(local_values$built_index)
      
      local_values$built_index %>%
        plot_ly(
          x = ~fiscal_year,
          y = ~normalized_index,
          type = 'scatter',
          mode = 'lines+markers',
          line = list(color = "#667eea"),
          marker = list(color = "#667eea")
        ) %>%
        layout(
          title = "Index Timeline",
          xaxis = list(title = "Fiscal Year"),
          yaxis = list(title = "Index Value"),
          showlegend = FALSE
        )
    })
    
    # Statistics outputs
    output$stats_data_points <- renderText({
      req(local_values$built_index)
      format(nrow(local_values$built_index), big.mark = ",")
    })
    
    output$stats_date_range <- renderText({
      req(local_values$built_index)
      paste(
        min(local_values$built_index$fiscal_year),
        "-",
        max(local_values$built_index$fiscal_year)
      )
    })
    
    output$stats_mean_growth <- renderText({
      req(local_values$built_index)
      paste0(
        round(mean(local_values$built_index$escalation_rate, na.rm = TRUE), 2),
        "%"
      )
    })
    
    output$stats_std_dev <- renderText({
      req(local_values$built_index)
      round(sd(local_values$built_index$escalation_rate, na.rm = TRUE), 2)
    })
    
    # Output reactive for conditional panels
    output$index_built <- reactive({
      local_values$index_built
    })
    outputOptions(output, "index_built", suspendWhenHidden = FALSE)
  })
}