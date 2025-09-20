# ============================================================================
# File Upload Module for Modern Escalation Analyzer
# Handles data import, validation, and preview
# ============================================================================

#' File Upload Module UI
#' @param id Module namespace ID
mod_upload_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Upload interface
      bs4Card(
        title = "Data Import", 
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        # File upload options
        radioButtons(
          ns("data_source"),
          "Data Source:",
          choices = list(
            "Upload CSV/Excel File" = "upload",
            "FRED API Download" = "fred"
          ),
          selected = "upload",
          inline = TRUE
        ),
        
        hr(),
        
        # Upload file interface
        conditionalPanel(
          condition = "input.data_source == 'upload'",
          ns = ns,
          
          modern_file_upload(
            ns("file_upload"),
            label = "Select Data File",
            accept = ".csv,.xlsx,.xls"
          ),
          
          br(),
          
          # File format options
          selectInput(
            ns("file_format"),
            "File Format:",
            choices = list(
              "Auto-detect" = "auto",
              "CSV" = "csv", 
              "Excel" = "excel"
            ),
            selected = "auto"
          ),
          
          # CSV specific options
          conditionalPanel(
            condition = "input.file_format == 'csv' || input.file_format == 'auto'",
            ns = ns,
            
            div(
              style = "border: 1px solid #dee2e6; padding: 15px; border-radius: 8px; background: #f8f9fa;",
              h6("CSV Options"),
              
              fluidRow(
                column(6,
                  selectInput(
                    ns("csv_sep"),
                    "Separator:",
                    choices = list("Comma" = ",", "Semicolon" = ";", "Tab" = "\t"),
                    selected = ","
                  )
                ),
                column(6,
                  selectInput(
                    ns("csv_quote"),
                    "Quote Character:",
                    choices = list("Double Quote" = '"', "Single Quote" = "'", "None" = ""),
                    selected = '"'
                  )
                )
              ),
              
              checkboxInput(
                ns("csv_header"),
                "Header row present",
                value = TRUE
              )
            )
          )
        ),
        
        # FRED API interface
        conditionalPanel(
          condition = "input.data_source == 'fred'",
          ns = ns,
          
          textInput(
            ns("fred_series_id"),
            "FRED Series ID:",
            placeholder = "e.g., PCU3364133641"
          ),
          
          br(),
          
          fluidRow(
            column(6,
              dateInput(
                ns("fred_start_date"),
                "Start Date:",
                value = Sys.Date() - 365*5,
                max = Sys.Date()
              )
            ),
            column(6, 
              dateInput(
                ns("fred_end_date"),
                "End Date:",
                value = Sys.Date(),
                max = Sys.Date()
              )
            )
          ),
          
          br(),
          
          actionButton(
            ns("download_fred"),
            "Download from FRED",
            icon = icon("download"),
            class = "btn btn-primary btn-block"
          )
        ),
        
        br(),
        
        # Import button
        conditionalPanel(
          condition = "input.data_source == 'upload'",
          ns = ns,
          actionButton(
            ns("import_data"),
            "Import Data",
            icon = icon("upload"),
            class = "btn btn-success btn-block"
          )
        )
      ),
      
      # Data validation and info
      bs4Card(
        title = "Import Status",
        status = "info", 
        solidHeader = TRUE,
        width = 6,
        
        # Import progress
        div(id = ns("import_progress")),
        
        # Data info
        div(id = ns("data_info")),
        
        # Validation results
        div(id = ns("validation_results"))
      )
    ),
    
    # Data preview
    fluidRow(
      bs4Card(
        title = "Data Preview",
        status = "success",
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        conditionalPanel(
          condition = "output['upload_module-data_imported']",
          
          # Column mapping interface
          div(
            style = "margin-bottom: 20px; padding: 15px; background: #f8f9fa; border-radius: 8px;",
            h5("Column Mapping"),
            p("Map your data columns to required fields:", style = "color: #6c757d;"),
            
            fluidRow(
              column(4,
                selectInput(
                  ns("date_column"),
                  "Date Column:",
                  choices = NULL
                )
              ),
              column(4,
                selectInput(
                  ns("value_column"), 
                  "Value Column:",
                  choices = NULL
                )
              ),
              column(4,
                selectInput(
                  ns("series_column"),
                  "Series Column (optional):",
                  choices = NULL
                )
              )
            ),
            
            actionButton(
              ns("apply_mapping"),
              "Apply Mapping",
              icon = icon("check"),
              class = "btn btn-primary"
            )
          ),
          
          # Data table preview
          div(
            style = "margin-top: 20px;",
            DT::dataTableOutput(ns("data_preview"))
          )
        ),
        
        conditionalPanel(
          condition = "!output['upload_module-data_imported']",
          div(
            style = "text-align: center; padding: 40px; color: #6c757d;",
            icon("table", class = "fa-3x"),
            h4("No Data Imported"),
            p("Upload a file or download from FRED to see preview")
          )
        )
      )
    )
  )
}

#' File Upload Module Server
#' @param id Module namespace ID  
#' @param values Global reactive values
mod_upload_server <- function(id, values) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    local_values <- reactiveValues(
      raw_data = NULL,
      data_imported = FALSE,
      column_choices = NULL
    )
    
    # File upload handler
    observeEvent(input$file_upload, {
      req(input$file_upload)
      
      # Show progress
      showModal(modalDialog(
        title = "Importing Data...",
        div(
          style = "text-align: center;",
          div(class = "spinner-border", role = "status"),
          p("Processing your file...")
        ),
        footer = NULL,
        easyClose = FALSE
      ))
      
      tryCatch({
        file_path <- input$file_upload$datapath
        file_ext <- tools::file_ext(input$file_upload$name)
        
        # Read file based on format
        if (file_ext %in% c("csv", "txt") || input$file_format == "csv") {
          local_values$raw_data <- read.csv(
            file_path,
            sep = input$csv_sep,
            quote = input$csv_quote,
            header = input$csv_header,
            stringsAsFactors = FALSE
          )
        } else if (file_ext %in% c("xlsx", "xls") || input$file_format == "excel") {
          local_values$raw_data <- openxlsx::read.xlsx(file_path)
        } else {
          stop("Unsupported file format")
        }
        
        # Update column choices
        local_values$column_choices <- names(local_values$raw_data)
        
        updateSelectInput(session, "date_column", choices = c("Select..." = "", local_values$column_choices))
        updateSelectInput(session, "value_column", choices = c("Select..." = "", local_values$column_choices))
        updateSelectInput(session, "series_column", choices = c("None" = "", local_values$column_choices))
        
        local_values$data_imported <- TRUE
        
        removeModal()
        
        modern_notify(
          paste("Successfully imported", nrow(local_values$raw_data), "rows"),
          type = "success"
        )
        
      }, error = function(e) {
        removeModal()
        modern_notify(
          paste("Import failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # FRED download handler
    observeEvent(input$download_fred, {
      req(values$fred_connected, input$fred_series_id)
      
      waiter::waiter_show(
        html = tagList(
          h3("Downloading from FRED..."),
          div(class = "spinner-border", role = "status")
        )
      )
      
      tryCatch({
        # Call package function to download data
        local_values$raw_data <- download_ppi_index(
          input$fred_series_id,
          input$fred_start_date,
          input$fred_end_date
        )
        
        # Auto-map columns for FRED data
        local_values$column_choices <- names(local_values$raw_data)
        
        # FRED data typically has 'date' and 'value' columns
        date_col <- names(local_values$raw_data)[grepl("date", names(local_values$raw_data), ignore.case = TRUE)][1]
        value_col <- names(local_values$raw_data)[grepl("value|index", names(local_values$raw_data), ignore.case = TRUE)][1]
        
        updateSelectInput(session, "date_column", choices = local_values$column_choices, selected = date_col)
        updateSelectInput(session, "value_column", choices = local_values$column_choices, selected = value_col)
        updateSelectInput(session, "series_column", choices = c("None" = "", local_values$column_choices))
        
        local_values$data_imported <- TRUE
        
        waiter::waiter_hide()
        
        modern_notify(
          paste("Downloaded", nrow(local_values$raw_data), "data points from FRED"),
          type = "success"
        )
        
      }, error = function(e) {
        waiter::waiter_hide()
        modern_notify(
          paste("Download failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Apply column mapping
    observeEvent(input$apply_mapping, {
      req(local_values$raw_data, input$date_column, input$value_column)
      
      tryCatch({
        # Process and validate data
        processed_data <- local_values$raw_data
        
        # Basic validation - ensure required columns exist
        if (!input$date_column %in% names(processed_data)) {
          stop("Selected date column not found in data")
        }
        if (!input$value_column %in% names(processed_data)) {
          stop("Selected value column not found in data")
        }
        
        # Rename columns to standard format
        processed_data <- processed_data %>%
          rename(
            date = !!input$date_column,
            value = !!input$value_column
          )
        
        # Store in global values
        values$uploaded_data <- processed_data
        values$last_updated <- Sys.time()
        
        modern_notify(
          "Data mapping applied successfully!",
          type = "success"
        )
        
      }, error = function(e) {
        modern_notify(
          paste("Mapping failed:", e$message),
          type = "danger"
        )
      })
    })
    
    # Data preview table
    output$data_preview <- DT::renderDataTable({
      req(local_values$raw_data)
      
      modern_data_table(
        head(local_values$raw_data, 100),
        selection = "none",
        options = list(
          pageLength = 5,
          scrollX = TRUE,
          info = TRUE,
          searching = TRUE
        )
      )
    })
    
    # Output reactive for conditional panels
    output$data_imported <- reactive({
      local_values$data_imported
    })
    outputOptions(output, "data_imported", suspendWhenHidden = FALSE)
  })
}