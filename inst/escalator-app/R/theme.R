# ============================================================================
# Modern Theme Configuration for Escalation Analyzer
# Based on bs4Dash with custom CSS design system
# ============================================================================

# Create custom theme using fresh package
escalator_theme <- create_theme(
  bs4dash_vars(
    navbar_light_color = "#fff",
    navbar_light_active_color = "#667eea",
    navbar_light_hover_color = "#764ba2"
  ),
  bs4dash_yiq(
    contrasted_threshold = 10,
    text_dark = "#2d3748", 
    text_light = "#f8f9fa"
  ),
  bs4dash_layout(
    main_bg = "#f8f9fa"
  ),
  bs4dash_sidebar_light(
    bg = "#ffffff",
    color = "#2d3748",
    hover_color = "#667eea",
    submenu_bg = "#f8f9fa", 
    submenu_color = "#2d3748",
    submenu_hover_color = "#667eea"
  ),
  bs4dash_status(
    primary = "#667eea",
    secondary = "#764ba2", 
    success = "#06d6a0",
    info = "#118ab2",
    warning = "#ffd166",
    danger = "#ef476f"
  ),
  bs4dash_color(
    gray_900 = "#2d3748",
    white = "#ffffff"
  )
)

# Modern CSS variables and custom styling
modern_css <- tags$head(
  tags$style(HTML("
    :root {
      --primary: #667eea;
      --secondary: #764ba2;
      --success: #06d6a0;
      --warning: #ffd166;
      --danger: #ef476f;
      --info: #118ab2;
      --light: #f8f9fa;
      --dark: #2d3748;
      
      --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
      
      --border-radius: 12px;
      --spacing-xs: 4px;
      --spacing-sm: 8px;
      --spacing-md: 16px;
      --spacing-lg: 24px;
      --spacing-xl: 32px;
      
      --shadow-sm: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
      --shadow-md: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23);
      --shadow-lg: 0 10px 20px rgba(0,0,0,0.19), 0 6px 6px rgba(0,0,0,0.23);
    }
    
    body {
      font-family: var(--font-primary);
      font-size: 14px;
      line-height: 1.5;
    }
    
    .card {
      border-radius: var(--border-radius);
      border: none;
      box-shadow: var(--shadow-sm);
      transition: all 0.3s ease;
    }
    
    .card:hover {
      box-shadow: var(--shadow-md);
      transform: translateY(-2px);
    }
    
    .btn {
      border-radius: var(--border-radius);
      font-weight: 500;
      padding: var(--spacing-sm) var(--spacing-md);
      transition: all 0.3s ease;
    }
    
    .btn-primary {
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      border: none;
    }
    
    .btn-primary:hover {
      transform: translateY(-1px);
      box-shadow: var(--shadow-md);
    }
    
    .form-control, .form-select {
      border-radius: var(--border-radius);
      border: 1px solid #e2e8f0;
      padding: var(--spacing-sm) var(--spacing-md);
      transition: all 0.3s ease;
    }
    
    .form-control:focus, .form-select:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
    }
    
    .progress {
      height: 8px;
      border-radius: var(--border-radius);
      background-color: #e2e8f0;
    }
    
    .progress-bar {
      background: linear-gradient(90deg, var(--primary), var(--secondary));
      border-radius: var(--border-radius);
    }
    
    .table {
      border-radius: var(--border-radius);
      overflow: hidden;
    }
    
    .table th {
      background-color: var(--light);
      border-top: none;
      font-weight: 600;
      color: var(--dark);
    }
    
    .notification {
      border-radius: var(--border-radius);
      box-shadow: var(--shadow-lg);
    }
    
    .loading-screen {
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      color: white;
    }
    
    .sidebar-menu > li.active > a {
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      color: white;
    }
    
    .content-header h1 {
      color: var(--dark);
      font-weight: 600;
    }
    
    /* Custom animations */
    @keyframes fadeInUp {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    .fade-in-up {
      animation: fadeInUp 0.6s ease;
    }
    
    /* Print styles */
    @media print {
      .sidebar, .main-header, .btn, .no-print { display: none !important; }
      .content-wrapper { margin: 0 !important; }
    }
  "))
)

# Loading screen configuration
loading_screen <- tagList(
  waiter::use_waiter(),
  waiter::waiter_show_on_load(
    html = tagList(
      div(
        style = "color: white; text-align: center;",
        h2("Escalation Analyzer"),
        p("Loading modern interface..."),
        div(class = "spinner-border", role = "status")
      )
    ),
    color = "linear-gradient(135deg, #667eea, #764ba2)"
  )
)

# JavaScript enhancements
custom_js <- tags$script(HTML("
  $(document).ready(function() {
    // Add fade-in animation to cards
    $('.card').addClass('fade-in-up');
    
    // Enhanced tooltips
    $('[data-toggle=\"tooltip\"]').tooltip();
    
    // Smooth scrolling for internal links
    $('a[href^=\"#\"]').on('click', function(event) {
      var target = $(this.getAttribute('href'));
      if( target.length ) {
        event.preventDefault();
        $('html, body').stop().animate({
          scrollTop: target.offset().top
        }, 1000);
      }
    });
    
    // Auto-hide notifications after 5 seconds
    setTimeout(function() {
      $('.alert').fadeOut('slow');
    }, 5000);
  });
"))