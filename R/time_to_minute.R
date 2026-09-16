#' Convert an `hms` Time to a Minute of the Day
#'
#' Converts a time of day to its minute position within a 24-hour day. By
#' default, positions are one-based, so midnight is minute 1 and 23:59 is
#' minute 1440.
#'
#' @param x A vector of class `hms`.
#' @param start The index assigned to midnight; either `0` or `1`.
#'
#' @returns An integer vector with values from `start` through `start + 1439`.
#' @export
#'
#' @examples
#' hms_to_minute(hms::as_hms(c("00:00:00", "23:59:00")))
#' hms_to_minute(hms::as_hms("00:00:00"), start = 0)
hms_to_minute = function(x, start = 1L) {
  if (!inherits(x, "hms")) {
    stop("`x` must be an `hms` vector.", call. = FALSE)
  }
  start = validate_minute_start(start)
  as.integer((floor(as.numeric(x) / 60) %% 1440) + start)
}

#' Convert a POSIX Time to a Minute of the Day
#'
#' Converts the time-of-day component of a timestamp to its minute position
#' within a 24-hour day, in the timestamp's timezone. By default, positions
#' are one-based, so midnight is minute 1 and 23:59 is minute 1440.
#'
#' @param x A vector inheriting from `POSIXt`, such as `POSIXct` or `POSIXlt`.
#' @inheritParams hms_to_minute
#'
#' @returns An integer vector with values from `start` through `start + 1439`.
#' @export
#'
#' @examples
#' x = as.POSIXct("2020-01-01 23:59:00", tz = "UTC")
#' posix_to_minute(x)
posix_to_minute = function(x, start = 1L) {
  if (!inherits(x, "POSIXt")) {
    stop("`x` must be a `POSIXt` vector.", call. = FALSE)
  }
  hms_to_minute(hms::as_hms(x), start = start)
}

#' @rdname posix_to_minute
#' @export
datetime_to_minute = function(x, start = 1L) {
  posix_to_minute(x, start = start)
}


validate_minute_start = function(start) {
  if (!is.numeric(start) || length(start) != 1L || is.na(start) ||
      !(start %in% c(0, 1))) {
    stop("`start` must be either 0 or 1.", call. = FALSE)
  }
  as.integer(start)
}
