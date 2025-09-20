#' Weighted Index Calculation Functions

#' Calculate weighted escalation index
#' @param escalation_data Data frame with escalation rates
#' @param outlay_profile Data frame with outlay profile
#' @param start_year Starting fiscal year for calculation
#' @return Data frame with weighted indices
#' @export
calculate_weighted_index <- function(escalation_data, outlay_profile, start_year) {
  expanded_outlays <- expand.grid(
    base_year = start_year,
    year_offset = outlay_profile$year_offset
  ) %>%
    dplyr::mutate(
      fiscal_year = base_year + year_offset
    ) %>%
    dplyr::left_join(outlay_profile, by = "year_offset")
  weighted_data <- expanded_outlays %>%
    dplyr::left_join(
      escalation_data %>% 
        dplyr::select(fiscal_year, normalized_index, escalation_rate),
      by = "fiscal_year"
    ) %>%
    dplyr::mutate(
      weighted_index = normalized_index * outlay_pct,
      weighted_rate = escalation_rate * outlay_pct
    )
  composite <- weighted_data %>%
    dplyr::group_by(base_year) %>%
    dplyr::summarise(
      composite_index = sum(weighted_index, na.rm = TRUE),
      composite_rate = sum(weighted_rate, na.rm = TRUE),
      years_included = dplyr::n(),
      total_weight = sum(outlay_pct, na.rm = TRUE),
      .groups = 'drop'
    )
  result <- list(
    detailed = weighted_data,
    composite = composite
  )
  return(result)
}
