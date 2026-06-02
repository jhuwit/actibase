#' Separate Times into Date, Hour, and Minute
#'
#' @param data a `data.frame` with a `time` column
#'
#' @returns A `data.frame` with date, hour, minute, and day columns
#' @export
#'
#' @examples
#' library(actibase)
#' acti_separate_time(acti_raw_data)
#' acti_create_date(acti_raw_data)
#' acti_create_hour(acti_raw_data)
#' acti_create_minute(acti_raw_data)
acti_separate_time = function(data) {
  time = minute = hour = day = date = NULL
  rm(list = c("minute", "day", "hour", "date", "time"))
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)
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

#' @export
#' @rdname acti_separate_time
acti_separate_times = acti_separate_time

#' @export
#' @rdname acti_separate_time
acti_create_date = function(data) {
  time = date = NULL
  rm(list = c("date", "time"))
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)
  data = data %>%
    dplyr::mutate(
      date = lubridate::floor_date(time, "1 day"),
      date = lubridate::as_date(date)
    )
}

#' @export
#' @rdname acti_separate_time
acti_create_hour = function(data) {
  time = minute = hour = day = date = NULL
  rm(list = c("minute", "day", "hour", "date", "time"))
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)
  data = data %>%
    dplyr::mutate(
      hour = lubridate::floor_date(time, "1 hour"),
      hour = hms::as_hms(hour)
    )
}


#' @export
#' @rdname acti_separate_time
acti_create_minute = function(data) {
  time = minute = hour = day = date = NULL
  rm(list = c("minute", "day", "hour", "date", "time"))
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)
  data = data %>%
    dplyr::mutate(
      minute = lubridate::floor_date(time, "1 minute"),
      minute = hms::as_hms(minute)
    )
}
