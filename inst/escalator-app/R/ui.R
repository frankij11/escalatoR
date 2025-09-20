# ============================================================================
# Modern UI Definition for Escalation Analyzer
# Uses bs4Dash for modern dashboard layout
# ============================================================================

ui <- bs4DashPage(
  # Enable modern theme
  fresh_theme = escalator_theme,
  
  # Page options
  options = list(
    sidebarExpandOnHover = TRUE,
    boxOptions = list(
      collapsible = TRUE,
      closable = FALSE
    )
  ),
  
  # Custom CSS and JS
  header = tagList(
    modern_css,
    custom_js,
    loading_screen,
    useShinyjs(),
    useShinypop(),
    useShinyFeedback()
  ),
  
  # Dashboard header
  navbar = bs4DashNavbar(
    title = dashboardBrand(
      title = "Escalation Analyzer",
      color = "primary",
      href = "#",
      image = NULL
    ),
    status = "primary",
    fixed = FALSE,
    rightUi = tagList(
      # FRED API connection status indicator
      bs4DropdownMenu(
        type = "notifications",
        badgeStatus = "primary",
        headerText = "Connection Status",
        bs4DropdownMenuItem(
          text = "FRED API Status",
          icon = icon("wifi"),
          status = "info",
          time = textOutput("connection_status_header", inline = TRUE)
        )
      ),
      # User menu placeholder
      bs4DropdownMenu(
        type = "messages", 
        badgeStatus = "success",
        headerText = "Quick Actions",
        bs4DropdownMenuItem(
          text = "Export Results",
          icon = icon("download"),
          status = "success"
        )
      )
    )
  ),
  
  # Sidebar navigation
  sidebar = bs4DashSidebar(
    title = "Navigation",
    skin = "light",
    status = "primary",
    brandColor = "primary",
    url = "#",
    src = NULL,
    elevation = 2,
    opacity = 0.8,
    
    # Sidebar menu
    bs4SidebarMenu(
      id = "sidebar_menu",
      
      bs4SidebarMenuItem(
        text = "Dashboard",
        tabName = "dashboard",
        icon = icon("tachometer-alt")
      ),
      
      bs4SidebarHeader("Data Management"),
      
      bs4SidebarMenuItem(
        text = "File Upload", 
        tabName = "upload",
        icon = icon("cloud-upload-alt")
      ),
      
      bs4SidebarMenuItem(
        text = "Index Builder",
        tabName = "builder", 
        icon = icon("tools")
      ),
      
      bs4SidebarHeader("Analysis"),
      
      bs4SidebarMenuItem(
        text = "Run Analysis",
        tabName = "analysis",
        icon = icon("chart-line")
      ),
      
      bs4SidebarMenuItem(
        text = "Results & Charts",
        tabName = "results",
        icon = icon("chart-bar")
      ),
      
      bs4SidebarHeader("Export & Settings"),
      
      bs4SidebarMenuItem(
        text = "Export Tools",
        tabName = "export",
        icon = icon("download")
      ),
      
      bs4SidebarMenuItem(
        text = "Settings",
        tabName = "settings", 
        icon = icon("cog")
      ),
      
      # FRED API Key input in sidebar
      div(
        style = "padding: 20px 15px; border-top: 1px solid #dee2e6; margin-top: 20px;",
        h6("FRED API Configuration", style = "color: #6c757d; margin-bottom: 15px;"),
        
        passwordInput(
          "fred_api_key",
          label = NULL,
          placeholder = "Enter FRED API Key",
          width = "100%"
        ),
        
        br(),
        
        actionButton(
          "connect_fred",
          "Connect to FRED",
          icon = icon("plug"),
          class = "btn btn-primary btn-sm btn-block",
          style = "margin-bottom: 10px;"
        ),
        
        div(
          id = "connection_status_sidebar",
          style = "font-size: 12px; color: #6c757d; text-align: center;",
          textOutput("connection_status_text")
        )
      )
    )
  ),
  
  # Main content body
  body = bs4DashBody(
    
    # Tab items for different pages
    bs4TabItems(
      
      # Dashboard tab - Overview and summary
      bs4TabItem(
        tabName = "dashboard",
        
        fluidRow(
          # Welcome header
          bs4UserCard(
            title = userDescription(
              title = "Welcome to Escalation Analyzer",
              subtitle = "Modern DoD Cost Escalation Analysis",
              type = 2,
              image = NULL
            ),
            status = "primary",
            width = 12,
            
            # Quick stats
            fluidRow(
              modern_info_box(
                title = "Current Analysis",
                value = textOutput("dashboard_current_analysis", inline = TRUE),
                icon = "chart-line",
                color = "primary",
                width = 3
              ),
              modern_info_box(
                title = "Data Points",
                value = textOutput("dashboard_data_points", inline = TRUE),
                icon = "database", 
                color = "info",
                width = 3
              ),
              modern_info_box(
                title = "Forecast Years",
                value = textOutput("dashboard_forecast_years", inline = TRUE),
                icon = "calendar",
                color = "success",
                width = 3
              ),
              modern_info_box(
                title = "Last Updated",
                value = textOutput("dashboard_last_updated", inline = TRUE),
                icon = "clock",
                color = "warning",
                width = 3
              )
            )
          )
        ),
        
        fluidRow(
          # Current analysis preview
          bs4Card(
            title = "Current Analysis Preview",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            modern_chart_container("dashboard_preview_chart", height = "350px")
          ),
          
          # Analysis summary
          bs4Card(
            title = "Analysis Summary",
            status = "info", 
            solidHeader = TRUE,
            width = 4,
            div(id = "dashboard_summary_content")
          )
        )
      ),
      
      # File Upload tab
      bs4TabItem(
        tabName = "upload",
        mod_upload_ui("upload_module")
      ),
      
      # Index Builder tab  
      bs4TabItem(
        tabName = "builder",
        mod_builder_ui("builder_module")
      ),
      
      # Analysis tab
      bs4TabItem(
        tabName = "analysis", 
        mod_analysis_ui("analysis_module")
      ),
      
      # Results tab
      bs4TabItem(
        tabName = "results",
        mod_results_ui("results_module")  
      ),
      
      # Export tab
      bs4TabItem(
        tabName = "export",
        mod_export_ui("export_module")
      ),
      
      # Settings tab
      bs4TabItem(
        tabName = "settings",
        
        fluidRow(
          bs4Card(
            title = "Application Settings",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            h5("Display Preferences"),
            switchInput(
              "dark_mode",
              label = "Dark Mode",
              value = FALSE
            ),
            
            br(),
            
            numericInput(
              "chart_height",
              "Default Chart Height (px)",
              value = 400,
              min = 200,
              max = 800,
              step = 50
            ),
            
            br(),
            
            selectInput(
              "date_format", 
              "Date Format",
              choices = list(
                "MM/DD/YYYY" = "mdy",
                "DD/MM/YYYY" = "dmy", 
                "YYYY-MM-DD" = "ymd"
              ),
              selected = "mdy"
            )
          ),
          
          bs4Card(
            title = "Data Preferences", 
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            h5("Analysis Defaults"),
            
            numericInput(
              "default_base_year",
              "Default Base Year",
              value = 2024,
              min = 1990,
              max = 2030,
              step = 1
            ),
            
            br(),
            
            selectInput(
              "default_forecast_method",
              "Default Forecast Method",
              choices = list(
                "ARIMA" = "arima",
                "User Defined" = "user",
                "Machine Learning" = "ml"
              ),
              selected = "arima"
            ),
            
            br(),
            
            numericInput(
              "default_forecast_years",
              "Default Forecast Years",
              value = 10,
              min = 1,
              max = 20,
              step = 1
            )
          )
        )
      )
    )
  ),
  
  # Footer
  footer = bs4DashFooter(
    copyrights = "© 2024 escalatoR - DoD Cost Escalation Analysis",
    right_text = "Built with ❤️ and R Shiny"
  )
)