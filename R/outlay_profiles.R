#' Outlay Profile Management Functions

#' Load default outlay profiles
#' @return List of default outlay profiles
#' @export
load_default_profiles <- function() {
  profiles <- list(
    aircraft_development = data.frame(
      year_offset = 0:5,
      outlay_pct = c(0.15, 0.25, 0.30, 0.20, 0.08, 0.02),
      profile_type = "Aircraft Development"
    ),
    ship_building = data.frame(
      year_offset = 0:7,
      outlay_pct = c(0.05, 0.10, 0.15, 0.20, 0.20, 0.15, 0.10, 0.05),
      profile_type = "Ship Building"
    ),
    electronics = data.frame(
      year_offset = 0:3,
      outlay_pct = c(0.20, 0.35, 0.30, 0.15),
      profile_type = "Electronics/IT"
    ),
    munitions = data.frame(
      year_offset = 0:2,
      outlay_pct = c(0.40, 0.40, 0.20),
      profile_type = "Munitions"
    ),
    services = data.frame(
      year_offset = 0:4,
      outlay_pct = c(0.20, 0.20, 0.20, 0.20, 0.20),
      profile_type = "Services"
    )
  )
  for (name in names(profiles)) {
    total <- sum(profiles[[name]]$outlay_pct)
    if (abs(total - 1.0) > 0.001) {
      warning(sprintf("Profile %s sums to %.1f%%, normalizing...", name, total * 100))
      profiles[[name]]$outlay_pct <- profiles[[name]]$outlay_pct / total
    }
  }
  return(profiles)
}

#' Create custom outlay profile
#' @param outlays Vector of outlay percentages
#' @param profile_name Name for the profile
#' @return Data frame with outlay profile
#' @export
create_custom_profile <- function(outlays, profile_name = "Custom") {
  total <- sum(outlays)
  if (abs(total - 1.0) > 0.001) {
    message(sprintf("Outlays sum to %.1f%%, normalizing to 100%%", total * 100))
    outlays <- outlays / total
  }
  profile <- data.frame(
    year_offset = 0:(length(outlays) - 1),
    outlay_pct = outlays,
    profile_type = profile_name
  )
  return(profile)
}
