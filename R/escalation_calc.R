#' Escalation Rate Calculation Functions

#' Calculate year-over-year escalation rates
#' @param data Data frame with fiscal year index values
#' @param method Calculation method ("simple", "compound", "geometric")
#' @return Data frame with escalation rates
#' @export
calculate_escalation_rates <- function(data, method = "simple") {
  data <- data %>%
    dplyr::arrange(fiscal_year) %>%
    dplyr::mutate(
      lag_value = dplyr::lag(index_value, 1),
      escalation_rate = dplyr::case_when(
        method == "simple" ~ (index_value / lag_value - 1) * 100,
        method == "compound" ~ ((index_value / lag_value)^(1/1) - 1) * 100,
        method == "geometric" ~ (exp(log(index_value / lag_value)) - 1) * 100,
        TRUE ~ (index_value / lag_value - 1) * 100
      )
    )
  stats <- data %>%
    dplyr::summarise(
      mean_rate = mean(escalation_rate, na.rm = TRUE),
      median_rate = median(escalation_rate, na.rm = TRUE),
      sd_rate = sd(escalation_rate, na.rm = TRUE),
      min_rate = min(escalation_rate, na.rm = TRUE),
      max_rate = max(escalation_rate, na.rm = TRUE)
    )
  attr(data, "escalation_stats") <- stats
  return(data)
}

#' Normalize index to specified base year
#' @param data Data frame with index values
#' @param base_year Base year for normalization
#' @return Data frame with normalized index
#' @export
normalize_base_year <- function(data, base_year) {
  base_value <- data %>%
    dplyr::filter(fiscal_year == base_year) %>%
    dplyr::pull(index_value)
  if (length(base_value) == 0) {
    stop(sprintf("Base year %d not found in data", base_year))
  }
  data <- data %>%
    dplyr::mutate(
      base_year_value = base_value[1],
      normalized_index = (index_value / base_value[1]) * 100,
      raw_index = index_value
    )
  message(sprintf("✓ Index normalized to base year %d (value = %.2f)", 
                 base_year, base_value[1]))
  return(data)
}
