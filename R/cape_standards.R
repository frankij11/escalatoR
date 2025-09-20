#' CAPE Methodology Implementation Functions

#' Validate data according to CAPE standards
#' @param data Data frame to validate
#' @return Validation report
#' @export
validate_cape_standards <- function(data) {
  validation <- list()
  validation$completeness <- list(
    total_records = nrow(data),
    missing_values = sum(is.na(data$index_value)),
    completeness_pct = (1 - sum(is.na(data$index_value)) / nrow(data)) * 100
  )
  validation$range <- list(
    start_year = min(data$fiscal_year),
    end_year = max(data$fiscal_year),
    years_covered = length(unique(data$fiscal_year)),
    sufficient_history = length(unique(data$fiscal_year)) >= 10
  )
  if ("escalation_rate" %in% names(data)) {
    validation$escalation <- list(
      mean_rate = mean(data$escalation_rate, na.rm = TRUE),
      max_rate = max(data$escalation_rate, na.rm = TRUE),
      min_rate = min(data$escalation_rate, na.rm = TRUE),
      reasonable = abs(mean(data$escalation_rate, na.rm = TRUE)) < 20
    )
  }
  validation$status <- all(
    validation$completeness$completeness_pct > 90,
    validation$range$sufficient_history,
    validation$escalation$reasonable
  )
  class(validation) <- c("cape_validation", "list")
  return(validation)
}

#' Apply CAPE risk adjustments
#' @param data Escalation data
#' @param risk_factor Risk adjustment factor (1.0 = no adjustment)
#' @return Risk-adjusted data
#' @export
apply_cape_risk_adjustment <- function(data, risk_factor = 1.0) {
  if (risk_factor == 1.0) {
    message("No risk adjustment applied (factor = 1.0)")
    return(data)
  }
  data <- data %>%
    dplyr::mutate(
      unadjusted_index = normalized_index,
      risk_factor = risk_factor,
      normalized_index = normalized_index * risk_factor,
      risk_adjusted = TRUE
    )
  message(sprintf("✓ Applied risk adjustment factor of %.2f", risk_factor))
  return(data)
}
