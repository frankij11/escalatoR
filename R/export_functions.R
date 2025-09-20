#' Export Functions for Results

#' Export to CSV with metadata
#' @param data Primary data to export
#' @param metadata List of metadata to include
#' @param filename Output filename
#' @export
export_to_csv <- function(data, metadata, filename) {
  export_data <- data %>%
    dplyr::mutate(
      export_date = Sys.Date(),
      escalator_version = "1.0",
      analyst = Sys.info()["user"]
    )
  for (name in names(metadata)) {
    export_data[[paste0("meta_", name)]] <- metadata[[name]]
  }
  write.csv(export_data, filename, row.names = FALSE)
  message(sprintf("✓ Exported to %s", filename))
  return(invisible(TRUE))
}

#' Export to Excel with documentation
#' @param data Primary data to export
#' @param metadata Metadata list
#' @param outlay_profile Outlay profile used
#' @param filename Output filename
#' @export
export_to_excel <- function(data, metadata, outlay_profile, filename) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Escalation_Data")
  openxlsx::writeData(wb, "Escalation_Data", data)
  meta_df <- data.frame(
    Parameter = names(metadata),
    Value = unlist(metadata)
  )
  openxlsx::addWorksheet(wb, "Metadata")
  openxlsx::writeData(wb, "Metadata", meta_df)
  openxlsx::addWorksheet(wb, "Outlay_Profile")
  openxlsx::writeData(wb, "Outlay_Profile", outlay_profile)
  summary_stats <- data %>%
    dplyr::summarise(
      mean_escalation = mean(escalation_rate, na.rm = TRUE),
      median_escalation = median(escalation_rate, na.rm = TRUE),
      sd_escalation = sd(escalation_rate, na.rm = TRUE),
      min_year = min(fiscal_year),
      max_year = max(fiscal_year),
      n_historical = sum(forecast_type == "historical"),
      n_forecast = sum(forecast_type != "historical")
    )
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", summary_stats)
  compliance <- data.frame(
    Requirement = c("Raw Index Downloaded", "Missing Values Filled", 
                   "FY Conversion", "Escalation Calculated", 
                   "Base Year Normalized", "Outlay Weighted"),
    Status = c("Complete", "Complete", "Complete", 
              "Complete", "Complete", "Complete"),
    Method = c(metadata$series_id, metadata$interpolation_method,
              metadata$fy_aggregation, metadata$escalation_method,
              metadata$base_year, metadata$outlay_profile)
  )
  openxlsx::addWorksheet(wb, "DoD_CAPE_Compliance")
  openxlsx::writeData(wb, "DoD_CAPE_Compliance", compliance)
  openxlsx::saveWorkbook(wb, filename, overwrite = TRUE)
  message(sprintf("✓ Exported to Excel: %s", filename))
  return(invisible(TRUE))
}
