# ============================================================================
# Modern Server Logic for Escalation Analyzer
# Coordinates modules and handles global reactive values
# ============================================================================

server <- function(input, output, session) {
  
  # Initialize waiter for loading screens
  waiter::waiter_hide()
  
  # Global reactive values for data sharing between modules
  values <- reactiveValues(
    # Connection status
    fred_connected = FALSE,
    api_key = NULL,
    
    # Data states
    uploaded_data = NULL,
    processed_data = NULL,
    forecast_data = NULL,
    
    # Analysis configuration
    selected_index = NULL,
    base_year = 2024,
    forecast_method = "arima",
    forecast_years = 10,
    
    # Outlay and weighting
    outlay_profile = NULL,
    weighted_index = NULL,
    
    # Results
    analysis_results = NULL,
    export_ready = FALSE,
    
    # UI state
    current_tab = "dashboard",
    last_updated = Sys.time()
  )
  
  # FRED API Connection Handler
  observeEvent(input$connect_fred, {
    req(input$fred_api_key)
    
    # Show connecting notification
    waiter::waiter_show(
      html = tagList(
        h3("Connecting to FRED API..."),
        div(class = "spinner-border", role = "status")
      ),
      color = "rgba(102, 126, 234, 0.8)"
    )
    
    tryCatch({
      # Test connection with package function
      init_fred_api(input$fred_api_key)
      
      # Update reactive values
      values$fred_connected <- TRUE
      values$api_key <- input$fred_api_key
      values$last_updated <- Sys.time()
      
      # Hide loading screen
      waiter::waiter_hide()
      
      # Show success notification
      modern_notify(
        "Successfully connected to FRED API! 🎉",
        type = "success",
        duration = 4000
      )
      
    }, error = function(e) {
      waiter::waiter_hide()
      
      # Show error notification
      modern_notify(
        paste("Connection failed:", e$message),
        type = "danger", 
        duration = 6000
      )
      
      values$fred_connected <- FALSE
    })
  })
  
  # Connection status outputs
  output$connection_status_header <- renderText({
    if (values$fred_connected) {
      "Connected ✓"
    } else {
      "Not Connected"
    }
  })
  
  output$connection_status_text <- renderText({
    if (values$fred_connected) {
      "✓ Connected to FRED"
    } else {
      "⚠ Not connected"
    }
  })
  
  # Dashboard outputs
  output$dashboard_current_analysis <- renderText({
    if (!is.null(values$selected_index)) {
      values$selected_index
    } else {
      "None selected"
    }
  })
  
  output$dashboard_data_points <- renderText({
    if (!is.null(values$processed_data)) {
      format(nrow(values$processed_data), big.mark = ",")
    } else {
      "0"
    }
  })
  
  output$dashboard_forecast_years <- renderText({
    as.character(values$forecast_years)
  })
  
  output$dashboard_last_updated <- renderText({
    format(values$last_updated, "%H:%M")
  })
  
  # Dashboard preview chart
  output$dashboard_preview_chart <- renderPlotly({
    if (!is.null(values$forecast_data)) {
      
      p <- values$forecast_data %>%
        plot_ly(
          x = ~fiscal_year, 
          y = ~normalized_index,
          color = ~forecast_type,
          type = 'scatter',
          mode = 'lines+markers',
          colors = c("#667eea", "#764ba2", "#06d6a0"),
          hovertemplate = "<b>FY %{x}</b><br>" +
                         "Index: %{y:.2f}<br>" +
                         "Type: %{color}<br>" +
                         "<extra></extra>"
        ) %>%
        layout(
          title = list(
            text = "Escalation Index Overview",
            font = list(size = 16, color = "#2d3748")
          ),
          xaxis = list(
            title = "Fiscal Year",
            gridcolor = "#e2e8f0",
            showgrid = TRUE
          ),
          yaxis = list(
            title = "Normalized Index", 
            gridcolor = "#e2e8f0",
            showgrid = TRUE
          ),
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)",
          legend = list(
            orientation = "h",
            x = 0.5,
            xanchor = "center",
            y = -0.1
          ),
          margin = list(t = 50, b = 50, l = 50, r = 50)
        ) %>%
        config(
          displayModeBar = FALSE,
          responsive = TRUE
        )
      
      return(p)
      
    } else {
      # Empty state
      plotly_empty() %>%
        layout(
          title = "No data available",
          annotations = list(
            text = "Upload data and run analysis to see preview",
            showarrow = FALSE,
            font = list(size = 14, color = "#a0aec0")
          )
        )
    }
  })
  
  # Initialize all modules with shared reactive values
  mod_upload_server("upload_module", values)
  mod_builder_server("builder_module", values) 
  mod_analysis_server("analysis_module", values)
  mod_results_server("results_module", values)
  mod_export_server("export_module", values)
  
  # Settings handlers
  observeEvent(input$dark_mode, {
    if (input$dark_mode) {
      # Switch to dark theme (placeholder for future implementation)
      modern_notify("Dark mode feature coming soon!", type = "info")
    }
  })
  
  observeEvent(input$default_base_year, {
    values$base_year <- input$default_base_year
  })
  
  observeEvent(input$default_forecast_method, {
    values$forecast_method <- input$default_forecast_method
  })
  
  observeEvent(input$default_forecast_years, {
    values$forecast_years <- input$default_forecast_years
  })
  
  # Track current tab for analytics
  observeEvent(input$sidebar_menu, {
    values$current_tab <- input$sidebar_menu
  })
  
  # Session info for debugging (remove in production)
  if (getOption("shiny.dev", FALSE)) {
    observe({
      cat("Current tab:", values$current_tab, "\n")
      cat("FRED connected:", values$fred_connected, "\n")
      cat("Data rows:", ifelse(is.null(values$processed_data), 0, nrow(values$processed_data)), "\n")
    })
  }
}