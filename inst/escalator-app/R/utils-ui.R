# ============================================================================
# UI Utility Functions for Modern Escalation Analyzer
# Reusable UI components and helper functions
# ============================================================================

#' Create a modern info box with gradient styling
#' @param title Box title
#' @param value Main value to display
#' @param subtitle Optional subtitle
#' @param icon FontAwesome icon name
#' @param color Color theme (primary, secondary, success, info, warning, danger)
#' @param width Box width (1-12)
modern_info_box <- function(title, value, subtitle = NULL, icon = "info", 
                           color = "primary", width = 3) {
  
  color_class <- paste0("bg-", color)
  
  div(
    class = paste("col-md-", width),
    div(
      class = paste("card", color_class, "text-white"),
      div(
        class = "card-body",
        div(
          class = "d-flex justify-content-between",
          div(
            h4(value, class = "mb-0"),
            p(title, class = "mb-0 small"),
            if (!is.null(subtitle)) small(subtitle, class = "text-white-50")
          ),
          div(
            class = "align-self-center",
            icon(icon, class = "fa-2x")
          )
        )
      )
    )
  )
}

#' Create a modern progress indicator
#' @param value Progress value (0-100)
#' @param label Progress label
#' @param color Progress bar color
#' @param striped Whether to show striped pattern
#' @param animated Whether to animate the stripes
modern_progress <- function(value, label = NULL, color = "primary", 
                           striped = FALSE, animated = FALSE) {
  
  classes <- c("progress-bar")
  if (striped) classes <- c(classes, "progress-bar-striped")
  if (animated) classes <- c(classes, "progress-bar-animated")
  
  div(
    class = "mb-3",
    if (!is.null(label)) {
      div(class = "d-flex justify-content-between mb-1",
          span(label), span(paste0(value, "%")))
    },
    div(
      class = "progress",
      div(
        class = paste(classes, collapse = " "),
        style = paste0("width: ", value, "%"),
        role = "progressbar",
        `aria-valuenow` = value,
        `aria-valuemin` = "0",
        `aria-valuemax` = "100"
      )
    )
  )
}

#' Create a modern notification toast
#' @param message Notification message
#' @param type Notification type (success, warning, danger, info)
#' @param duration Duration in milliseconds
modern_notify <- function(message, type = "info", duration = 5000) {
  showNotification(
    ui = div(
      class = paste("alert alert-", type, "notification"),
      style = "border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);",
      message
    ),
    duration = duration,
    type = "message"
  )
}

#' Create a modern file upload area with drag and drop
#' @param inputId Input ID
#' @param label Upload label
#' @param accept File types to accept
#' @param multiple Whether to allow multiple files
modern_file_upload <- function(inputId, label = "Upload File", 
                              accept = NULL, multiple = FALSE) {
  
  div(
    class = "upload-area",
    style = "
      border: 2px dashed #667eea; 
      border-radius: 12px; 
      padding: 40px; 
      text-align: center; 
      background: #f8f9fa;
      transition: all 0.3s ease;
      cursor: pointer;
    ",
    onmouseover = "this.style.borderColor='#764ba2'; this.style.backgroundColor='#ffffff';",
    onmouseout = "this.style.borderColor='#667eea'; this.style.backgroundColor='#f8f9fa';",
    
    fileInput(
      inputId = inputId,
      label = NULL,
      accept = accept,
      multiple = multiple,
      buttonLabel = "Browse",
      placeholder = label,
      style = "display: none;"
    ),
    
    div(
      onclick = paste0("document.getElementById('", inputId, "').click();"),
      icon("cloud-upload-alt", class = "fa-3x mb-3", style = "color: #667eea;"),
      h4(label, style = "color: #2d3748; margin-bottom: 8px;"),
      p("Drag and drop files here or click to browse", 
        style = "color: #718096; margin: 0;"),
      if (!is.null(accept)) {
        small(paste("Accepted formats:", accept), 
              style = "color: #a0aec0; margin-top: 8px; display: block;")
      }
    )
  )
}

#' Create a modern data table with enhanced styling
#' @param data Data frame to display
#' @param selection Selection mode
#' @param options Additional DT options
modern_data_table <- function(data, selection = "single", options = list()) {
  
  default_options <- list(
    pageLength = 10,
    scrollX = TRUE,
    autoWidth = FALSE,
    columnDefs = list(
      list(className = "dt-center", targets = "_all")
    ),
    language = list(
      search = "Search:",
      lengthMenu = "Show _MENU_ entries",
      info = "Showing _START_ to _END_ of _TOTAL_ entries",
      paginate = list(
        first = "First",
        last = "Last", 
        next = "Next",
        previous = "Previous"
      )
    )
  )
  
  final_options <- modifyList(default_options, options)
  
  DT::datatable(
    data,
    selection = selection,
    options = final_options,
    class = "table table-striped table-hover",
    style = "bootstrap4"
  )
}

#' Create a modern statistics summary card
#' @param title Card title
#' @param stats List of statistics (name = value)
#' @param color Card color theme
modern_stats_card <- function(title, stats, color = "primary") {
  
  stats_items <- mapply(function(name, value) {
    div(
      class = "d-flex justify-content-between py-2",
      span(name, class = "text-muted"),
      strong(value)
    )
  }, names(stats), stats, SIMPLIFY = FALSE)
  
  div(
    class = "card",
    div(
      class = paste("card-header", paste0("bg-", color), "text-white"),
      h5(title, class = "card-title mb-0")
    ),
    div(
      class = "card-body",
      do.call(tagList, stats_items)
    )
  )
}

#' Create a modern chart container with loading state
#' @param outputId Chart output ID
#' @param height Chart height
#' @param title Chart title
modern_chart_container <- function(outputId, height = "400px", title = NULL) {
  
  div(
    class = "card",
    if (!is.null(title)) {
      div(class = "card-header", h5(title, class = "card-title mb-0"))
    },
    div(
      class = "card-body p-0",
      withSpinner(
        plotlyOutput(outputId, height = height),
        type = 8,
        color = "#667eea",
        size = 0.8
      )
    )
  )
}

#' Create responsive column layout
#' @param ... UI elements to arrange in columns
#' @param widths Column widths (should sum to 12)
responsive_columns <- function(..., widths = NULL) {
  
  elements <- list(...)
  n_elements <- length(elements)
  
  if (is.null(widths)) {
    widths <- rep(12 %/% n_elements, n_elements)
  }
  
  if (length(widths) != n_elements) {
    stop("Number of widths must match number of elements")
  }
  
  if (sum(widths) > 12) {
    stop("Column widths cannot exceed 12")
  }
  
  columns <- mapply(function(element, width) {
    div(class = paste("col-md-", width), element)
  }, elements, widths, SIMPLIFY = FALSE)
  
  div(class = "row", do.call(tagList, columns))
}