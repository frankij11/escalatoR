/* ============================================================================
   Modern Escalation Analyzer - Custom JavaScript
   Enhanced user interactions and modern functionality
   ============================================================================ */

$(document).ready(function() {
  
  // Initialize application
  initializeApp();
  
  // Setup event listeners
  setupEventListeners();
  
  // Setup enhanced interactions
  setupEnhancedInteractions();
  
  // Setup notifications
  setupNotifications();
  
  // Setup file upload enhancements
  setupFileUpload();
  
  // Setup accessibility features
  setupAccessibility();
});

/**
 * Initialize the application
 */
function initializeApp() {
  console.log('🚀 Escalation Analyzer - Modern UI Initialized');
  
  // Add fade-in animation to cards
  $('.card').addClass('fade-in-up');
  
  // Initialize tooltips
  if (typeof $().tooltip === 'function') {
    $('[data-toggle="tooltip"]').tooltip({
      trigger: 'hover',
      delay: { show: 500, hide: 100 }
    });
  }
  
  // Initialize popovers
  if (typeof $().popover === 'function') {
    $('[data-toggle="popover"]').popover({
      trigger: 'click',
      html: true,
      container: 'body'
    });
  }
  
  // Close popovers when clicking outside
  $(document).on('click', function(e) {
    if (!$(e.target).closest('[data-toggle="popover"]').length) {
      $('[data-toggle="popover"]').popover('hide');
    }
  });
}

/**
 * Setup enhanced event listeners
 */
function setupEventListeners() {
  
  // Smooth scrolling for internal links
  $('a[href^="#"]').on('click', function(event) {
    var target = $(this.getAttribute('href'));
    if (target.length) {
      event.preventDefault();
      $('html, body').stop().animate({
        scrollTop: target.offset().top - 100
      }, 1000, 'easeInOutQuart');
    }
  });
  
  // Enhanced button interactions
  $('.btn').on('mouseenter', function() {
    $(this).addClass('shadow-custom');
  }).on('mouseleave', function() {
    $(this).removeClass('shadow-custom');
  });
  
  // Card hover effects
  $('.card').on('mouseenter', function() {
    $(this).addClass('shadow-custom-lg');
  }).on('mouseleave', function() {
    $(this).removeClass('shadow-custom-lg');
  });
  
  // Auto-resize textareas
  $('textarea').on('input', function() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
  });
}

/**
 * Setup enhanced user interactions
 */
function setupEnhancedInteractions() {
  
  // Loading state for buttons
  $(document).on('click', '.btn[data-loading-text]', function() {
    var $btn = $(this);
    var loadingText = $btn.data('loading-text');
    
    if (loadingText) {
      $btn.data('original-text', $btn.html());
      $btn.html('<span class="spinner-border spinner-border-sm me-2"></span>' + loadingText);
      $btn.prop('disabled', true);
      
      // Reset after 10 seconds (fallback)
      setTimeout(function() {
        resetButton($btn);
      }, 10000);
    }
  });
  
  // Form validation enhancements
  $('.form-control, .form-select').on('blur', function() {
    validateField($(this));
  });
  
  // Progressive disclosure for advanced options
  $('.advanced-toggle').on('click', function() {
    var target = $(this).data('target');
    $(target).slideToggle('fast');
    
    var icon = $(this).find('i');
    icon.toggleClass('fa-chevron-down fa-chevron-up');
  });
  
  // Copy to clipboard functionality
  $('.copy-to-clipboard').on('click', function() {
    var text = $(this).data('copy-text');
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(function() {
        showToast('Copied to clipboard!', 'success');
      });
    } else {
      // Fallback for older browsers
      var textArea = document.createElement('textarea');
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      showToast('Copied to clipboard!', 'success');
    }
  });
}

/**
 * Setup notification system
 */
function setupNotifications() {
  
  // Auto-hide alerts after delay
  $('.alert').each(function() {
    var $alert = $(this);
    var delay = $alert.data('delay') || 5000;
    
    setTimeout(function() {
      $alert.fadeOut('slow', function() {
        $(this).remove();
      });
    }, delay);
  });
  
  // Enhanced notification positioning
  if (typeof Shiny !== 'undefined') {
    Shiny.addCustomMessageHandler('show_notification', function(message) {
      showToast(message.text, message.type, message.duration);
    });
  }
}

/**
 * Setup file upload enhancements
 */
function setupFileUpload() {
  
  // Drag and drop functionality
  $('.upload-area').on('dragover dragenter', function(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).addClass('dragover');
  });
  
  $('.upload-area').on('dragleave', function(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).removeClass('dragover');
  });
  
  $('.upload-area').on('drop', function(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).removeClass('dragover');
    
    var files = e.originalEvent.dataTransfer.files;
    if (files.length > 0) {
      var fileInput = $(this).find('input[type="file"]')[0];
      if (fileInput) {
        fileInput.files = files;
        $(fileInput).trigger('change');
        showToast('File dropped successfully!', 'success');
      }
    }
  });
  
  // File input change handler with preview
  $('input[type="file"]').on('change', function() {
    var file = this.files[0];
    if (file) {
      var fileName = file.name;
      var fileSize = formatFileSize(file.size);
      var fileType = file.type || 'Unknown';
      
      showToast(`File selected: ${fileName} (${fileSize})`, 'info');
      
      // Update upload area text if it exists
      var uploadArea = $(this).closest('.upload-area');
      if (uploadArea.length) {
        uploadArea.find('h4').text(`Selected: ${fileName}`);
        uploadArea.find('p').text(`Size: ${fileSize} | Type: ${fileType}`);
      }
    }
  });
}

/**
 * Setup accessibility features
 */
function setupAccessibility() {
  
  // Keyboard navigation for custom elements
  $('.btn, .card, .nav-link').attr('tabindex', '0');
  
  // Enhanced focus management
  $(document).on('keydown', function(e) {
    // Escape key to close modals/dropdowns
    if (e.key === 'Escape') {
      $('.modal').modal('hide');
      $('.dropdown-menu').removeClass('show');
      $('[data-toggle="popover"]').popover('hide');
    }
    
    // Enter key activation for custom buttons
    if (e.key === 'Enter' && $(e.target).hasClass('btn-custom')) {
      $(e.target).click();
    }
  });
  
  // ARIA label updates for dynamic content
  $('.progress-bar').each(function() {
    var $this = $(this);
    var value = $this.attr('aria-valuenow');
    $this.attr('aria-label', `Progress: ${value}%`);
  });
  
  // Skip links for keyboard navigation
  if ($('.skip-link').length === 0) {
    $('body').prepend(
      '<a href="#main-content" class="skip-link sr-only-focusable">Skip to main content</a>'
    );
  }
}

/**
 * Utility Functions
 */

/**
 * Reset button to original state
 */
function resetButton($btn) {
  var originalText = $btn.data('original-text');
  if (originalText) {
    $btn.html(originalText);
    $btn.prop('disabled', false);
  }
}

/**
 * Validate form field
 */
function validateField($field) {
  var value = $field.val();
  var isRequired = $field.prop('required');
  var pattern = $field.attr('pattern');
  var type = $field.attr('type');
  
  var isValid = true;
  var message = '';
  
  // Required field validation
  if (isRequired && !value) {
    isValid = false;
    message = 'This field is required';
  }
  
  // Pattern validation
  if (isValid && pattern && value) {
    var regex = new RegExp(pattern);
    if (!regex.test(value)) {
      isValid = false;
      message = 'Invalid format';
    }
  }
  
  // Type-specific validation
  if (isValid && value) {
    switch (type) {
      case 'email':
        var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(value)) {
          isValid = false;
          message = 'Invalid email address';
        }
        break;
      case 'number':
        if (isNaN(value)) {
          isValid = false;
          message = 'Must be a number';
        }
        break;
    }
  }
  
  // Update field appearance
  $field.removeClass('is-valid is-invalid');
  $field.next('.feedback').remove();
  
  if (!isValid) {
    $field.addClass('is-invalid');
    $field.after(`<div class="feedback invalid-feedback">${message}</div>`);
  } else if (value) {
    $field.addClass('is-valid');
  }
  
  return isValid;
}

/**
 * Show toast notification
 */
function showToast(message, type = 'info', duration = 4000) {
  var toastId = 'toast-' + Date.now();
  var iconClass = {
    'success': 'fa-check-circle',
    'error': 'fa-exclamation-circle',
    'warning': 'fa-exclamation-triangle',
    'info': 'fa-info-circle'
  }[type] || 'fa-info-circle';
  
  var toast = `
    <div id="${toastId}" class="toast-notification alert alert-${type} fade-in" 
         style="position: fixed; top: 20px; right: 20px; z-index: 9999; max-width: 350px;">
      <i class="fas ${iconClass} me-2"></i>
      ${message}
      <button type="button" class="btn-close btn-close-white ms-auto" 
              onclick="$('#${toastId}').fadeOut(300, function() { $(this).remove(); })">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  `;
  
  $('body').append(toast);
  
  // Auto-remove after duration
  setTimeout(function() {
    $('#' + toastId).fadeOut(300, function() {
      $(this).remove();
    });
  }, duration);
}

/**
 * Format file size for display
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  
  var k = 1024;
  var sizes = ['Bytes', 'KB', 'MB', 'GB'];
  var i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Debounce function for performance
 */
function debounce(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}

/**
 * Throttle function for performance
 */
function throttle(func, limit) {
  var inThrottle;
  return function() {
    var args = arguments;
    var context = this;
    if (!inThrottle) {
      func.apply(context, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

/**
 * Custom message handlers for Shiny communication
 */
if (typeof Shiny !== 'undefined') {
  
  // Handle download requests
  Shiny.addCustomMessageHandler('download_file', function(message) {
    var link = document.createElement('a');
    link.href = message.filepath;
    link.download = message.filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  });
  
  // Handle UI state changes
  Shiny.addCustomMessageHandler('update_ui_state', function(message) {
    if (message.loading) {
      showLoadingOverlay(message.message);
    } else {
      hideLoadingOverlay();
    }
  });
  
  // Handle progress updates
  Shiny.addCustomMessageHandler('update_progress', function(message) {
    var progressBar = $('#' + message.id);
    if (progressBar.length) {
      progressBar.css('width', message.value + '%');
      progressBar.attr('aria-valuenow', message.value);
      progressBar.text(message.text || (message.value + '%'));
    }
  });
}

/**
 * Loading overlay functions
 */
function showLoadingOverlay(message = 'Loading...') {
  var overlay = `
    <div id="loading-overlay" class="loading-overlay" 
         style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
                background: rgba(102, 126, 234, 0.9); z-index: 10000; 
                display: flex; align-items: center; justify-content: center; color: white;">
      <div class="text-center">
        <div class="spinner-border spinner-border-lg mb-3"></div>
        <h4>${message}</h4>
      </div>
    </div>
  `;
  
  if ($('#loading-overlay').length === 0) {
    $('body').append(overlay);
  }
}

function hideLoadingOverlay() {
  $('#loading-overlay').fadeOut(300, function() {
    $(this).remove();
  });
}

/**
 * Performance monitoring
 */
function logPerformance(label, startTime) {
  if (console && console.log) {
    var endTime = performance.now();
    console.log(`⚡ ${label}: ${(endTime - startTime).toFixed(2)}ms`);
  }
}

/**
 * Error handling
 */
window.addEventListener('error', function(e) {
  console.error('JavaScript Error:', e.error);
  showToast('An error occurred. Please refresh the page if problems persist.', 'error');
});

/**
 * Responsive behavior
 */
function handleResize() {
  var width = $(window).width();
  
  if (width < 768) {
    $('body').addClass('mobile-view');
  } else {
    $('body').removeClass('mobile-view');
  }
}

$(window).on('resize', throttle(handleResize, 250));
$(document).ready(handleResize);

console.log('✅ Escalation Analyzer JavaScript - Loaded Successfully');