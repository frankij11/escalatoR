# ============================================================================
# Export Module for Modern Escalation Analyzer
# Multi-format export and report generation
# ============================================================================

#' Export Module UI
#' @param id Module namespace ID
mod_export_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Export availability check
    conditionalPanel(
      condition = "output['export_module-export_available']",
      
      fluidRow(
        # Export configuration
        bs4Card(
          title = "Export Configuration",
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          
          # Export format selection
          radioButtons(
            ns("export_format"),
            "Export Format:",
            choices = list(
              "CSV (Data Only)" = "csv",
              "Excel (Multi-sheet)" = "excel", 
              "PDF Report" = "pdf",
              "Complete Package" = "package"
            ),
            selected = "excel"
          ),
          
          hr(),
          
          # Export options
          h5("Export Options"),
          
          checkboxInput(
            ns("include_metadata"),
            "Include Analysis Metadata",
            value = TRUE
          ),
          
          checkboxInput(
            ns("include_charts"),
            "Include Visualizations",
            value = TRUE
          ),
          
          conditionalPanel(
            condition = "input.export_format == 'pdf' || input.export_format == 'package'",
            ns = ns,
            
            checkboxInput(
              ns("include_methodology"),
              "Include CAPE Methodology",
              value = TRUE
            )
          ),
          
          conditionalPanel(
            condition = "input.export_format == 'excel' || input.export_format == 'package'",
            ns = ns,
            
            checkboxInput(
              ns("include_raw_data"),
              "Include Raw Data Sheet",
              value = FALSE
            )
          ),
          
          hr(),
          
          # File naming
          textInput(
            ns("export_filename"),
            "Custom Filename:",
            placeholder = "escalation_analysis"
          ),
          
          p("Leave blank for auto-generated name", 
            style = "color: #6c757d; font-size: 12px;")
        ),
        
        # Export preview and status
        bs4Card(
          title = "Export Preview",
          status = "info",
          solidHeader = TRUE,
          width = 6,
          
          # Export summary
          div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
            h6("Export Summary"),
            div(id = ns("export_summary"))
          ),
          
          # Quick stats
          fluidRow(
            modern_info_box(
              title = "Data Rows",
              value = textOutput(ns("export_rows"), inline = TRUE),
              icon = "table",
              color = "primary",
              width = 6
            ),
            modern_info_box(
              title = "File Size Est.",
              value = textOutput(ns("export_size"), inline = TRUE),
              icon = "file",
              color = "info",
              width = 6
            )
          ),
          
          br(),
          
          # Export button
          actionButton(
            ns("export_data"),
            "Generate Export",
            icon = icon("download"),
            class = "btn btn-success btn-lg btn-block"
          )
        )
      ),
      
      fluidRow(
        # Export history and downloads
        bs4Card(
          title = "Recent Exports",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          # Download progress
          div(id = ns("export_progress")),
          
          # Export history table
          DT::dataTableOutput(ns("export_history"))
        )
      )
    ),
    
    # No data available state
    conditionalPanel(
      condition = "!output['export_module-export_available']",
      
      fluidRow(
        bs4Card(
          title = "Export Not Available",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          
          div(
            style = "text-align: center; padding: 60px; color: #6c757d;",
            icon("download", class = "fa-4x", style = "margin-bottom: 20px;"),
            h3("No Data to Export"),
            p("Complete an analysis to enable data export functionality."),
            br(),
            div(
              style = "display: flex; justify-content: center; gap: 10px;",
              actionButton(
                "goto_upload",
                "Upload Data",
                icon = icon("upload"),
                class = "btn btn-outline-primary",
                onclick = "$('#sidebar_menu a[data-value=\"upload\"]').click();"
              ),
              actionButton(
                "goto_analysis",
                "Run Analysis", 
                icon = icon("play"),
                class = "btn btn-primary",
                onclick = "$('#sidebar_menu a[data-value=\"analysis\"]').click();"
              )
            )
          )
        )
      )
    )
  )
}

#' Export Module Server
#' @param id Module namespace ID
#' @param values Global reactive values
mod_export_server <- function(id, values) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values for export history
    local_values <- reactiveValues(
      export_history = data.frame(
        timestamp = character(),
        filename = character(),
        format = character(),
        size = character(),
        status = character(),
        stringsAsFactors = FALSE
      )
    )
    
    # Check if export is available
    export_available <- reactive({
      !is.null(values$forecast_data)
    })
    
    # Export summary
    output$export_summary <- renderUI({
      req(values$forecast_data)
      
      tagList(
        p(strong("Data Range: "), 
          paste(min(values$forecast_data$fiscal_year), "-", max(values$forecast_data$fiscal_year))),
        p(strong("Analysis Method: "), values$forecast_method %||% "Unknown"),
        p(strong("Base Year: "), values$base_year %||% "Not specified"),
        p(strong("Last Updated: "), format(values$last_updated %||% Sys.time(), "%Y-%m-%d %H:%M"))
      )
    })
    
    # Export statistics
    output$export_rows <- renderText({
      req(values$forecast_data)
      format(nrow(values$forecast_data), big.mark = ",")
    })
    
    output$export_size <- renderText({
      req(values$forecast_data)
      
      # Estimate file size based on format
      base_size <- object.size(values$forecast_data)
      
      multiplier <- switch(input$export_format,
        "csv" = 1.2,
        "excel" = 2.5,
        "pdf" = 0.8,
        "package" = 4.0,
        1.5
      )
      
      estimated_size <- as.numeric(base_size) * multiplier
      
      if (estimated_size > 1024^2) {
        paste(round(estimated_size / 1024^2, 1), "MB")
      } else {
        paste(round(estimated_size / 1024, 1), "KB")
      }
    })
    
    # Generate filename
    generate_filename <- reactive({
      base_name <- if (input$export_filename != "") {
        input$export_filename
      } else {
        "escalation_analysis"
      }
      
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      
      extension <- switch(input$export_format,
        "csv" = ".csv",
        "excel" = ".xlsx", 
        "pdf" = ".pdf",
        "package" = ".zip",
        ".csv"
      )
      
      paste0(base_name, "_", timestamp, extension)
    })
    
    # Export data handler
    observeEvent(input$export_data, {
      req(values$forecast_data)
      
      # Show export progress
      waiter::waiter_show(
        html = tagList(
          h3("Generating Export..."),
          div(class = "spinner-border", role = "status"),
          p("Please wait while we prepare your download...")
        ),
        color = "rgba(40, 167, 69, 0.8)"
      )
      
      tryCatch({
        
        filename <- generate_filename()
        
        # Prepare metadata
        metadata <- list(
          analysis_date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          base_year = values$base_year,
          forecast_method = values$forecast_method,
          forecast_years = values$forecast_years,
          data_source = values$selected_index,
          analyst = Sys.info()[["user"]],
          escalatoR_version = "1.0.0"
        )
        
        # Export based on format
        if (input$export_format == "csv") {
          
          # Simple CSV export
          temp_file <- file.path(tempdir(), filename)
          export_to_csv(
            data = values$forecast_data,
            metadata = if(input$include_metadata) metadata else list(),
            filename = temp_file
          )
          
        } else if (input$export_format == "excel") {
          
          # Multi-sheet Excel export
          temp_file <- file.path(tempdir(), filename)
          export_to_excel(
            data = values$forecast_data,
            metadata = metadata,
            outlay_profile = values$outlay_profile,
            filename = temp_file
          )
          
        } else if (input$export_format == "pdf") {
          
          # PDF report export (placeholder)
          temp_file <- file.path(tempdir(), filename)
          
          # Create a simple PDF report
          pdf(temp_file, width = 8.5, height = 11)
          plot(1:10, main = "Escalation Analysis Report")
          text(5, 5, "PDF Report Generation\nComing Soon!", cex = 2)
          dev.off()
          
        } else if (input$export_format == "package") {
          
          # Complete package export
          temp_file <- file.path(tempdir(), filename)
          
          # Create temporary directory for package contents
          temp_dir <- file.path(tempdir(), "export_package")
          dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
          
          # Export main data
          export_to_excel(
            data = values$forecast_data,
            metadata = metadata,
            outlay_profile = values$outlay_profile,
            filename = file.path(temp_dir, "escalation_analysis.xlsx")
          )
          
          # Add CSV version
          write.csv(values$forecast_data, 
                   file.path(temp_dir, "escalation_data.csv"), 
                   row.names = FALSE)
          
          # Create ZIP package
          zip(temp_file, temp_dir, flags = "-r")
        }
        
        # Add to export history
        new_export <- data.frame(
          timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          filename = filename,
          format = toupper(input$export_format),
          size = file.size(temp_file),
          status = "Ready",
          stringsAsFactors = FALSE
        )
        
        local_values$export_history <- rbind(new_export, local_values$export_history)
        
        waiter::waiter_hide()
        
        # Trigger download
        session$sendCustomMessage(
          type = "download_file",
          message = list(
            filename = filename,
            filepath = temp_file
          )
        )
        
        modern_notify(
          "Export generated successfully! Download will start automatically.",
          type = "success"
        )
        
      }, error = function(e) {
        waiter::waiter_hide()
        modern_notify(
          paste("Export failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Export history table
    output$export_history <- DT::renderDataTable({
      req(nrow(local_values$export_history) > 0)
      
      # Format file sizes
      history_display <- local_values$export_history %>%
        mutate(
          size = ifelse(
            size > 1024^2,
            paste(round(size / 1024^2, 1), "MB"),
            paste(round(size / 1024, 1), "KB")
          )
        )
      
      modern_data_table(
        history_display,
        selection = "none",
        options = list(
          pageLength = 5,
          order = list(list(0, "desc")),
          columnDefs = list(
            list(className = "dt-center", targets = c(2, 3, 4))
          )
        )
      )
    }, server = FALSE)
    
    # Output reactive for conditional panels
    output$export_available <- reactive({
      export_available()
    })
    outputOptions(output, "export_available", suspendWhenHidden = FALSE)
  })
}