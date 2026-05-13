# Legacy overlay helpers.
# These functions are kept out of the exported actibase baseline API on
# purpose. Move them into a downstream overlay package if they are still
# needed.

#' Separate Times into Date, Hour, and Minute
#'
#' @param data a `data.frame` with a `time` column
#'
#' @returns A `data.frame` with date, hour, minute, and day columns
#' @export
#'
#' @examples
#' acti_separate_time(acti_raw_data)
acti_separate_time = function(data) {
  time = minute = hour = day = date = NULL
  rm(list = c("minute", "day", "hour", "date", "time"))
  data = data %>%
    dplyr::mutate(
      date = lubridate::floor_date(time, "1 day"),
      date = lubridate::as_date(date),
      hour = lubridate::floor_date(time, "1 hour"),
      hour = hms::as_hms(hour),
      minute = lubridate::floor_date(time, "1 minute"),
      minute = hms::as_hms(minute)
    )
  data = data %>%
    dplyr::mutate(
      day = as.numeric(difftime(date, min(date), units = "days") + 1)
    )
  data
}
