#' Convert a Time of Day to a Minute Index
#'
#' @note This converts each minute of a day to either `0` through `1439` or
#'   `1` through `1440`, the two common minute-of-day conventions.
#'
#' @param x An `hms`, `POSIXt`, or `HH:MM[:SS]` character vector.
#' @param start The index assigned to midnight, either `0` or `1`.
#' @param timezone Optional Olson timezone for `POSIXt` values.
#'
#' @returns An integer minute-of-day index.
#' @export
#' @examples
#' acti_time_to_minute(c("00:00", "12:00", "23:59"))
#' acti_time_to_minute("00:00", start = 0)
acti_time_to_minute = function(x, start = 1L, timezone = NULL) {
  acti_hms_to_minute(acti_as_hms(x, timezone), start = start)
}

#' Convert an HMS Time to a Minute Index
#'
#' @note This is a strict `hms` entry point for callers that have already
#'   separated time of day from date and want the standard activity-day index.
#'
#' @inheritParams acti_time_to_minute
#'
#' @returns An integer minute-of-day index.
#' @export
#' @examples
#' acti_hms_to_minute(hms::hms(hours = c(0, 23), minutes = c(0, 59)))
acti_hms_to_minute = function(x, start = 1L) {
  if (!inherits(x, "hms")) {
    stop("`x` must be an `hms` vector.", call. = FALSE)
  }
  start = acti_validate_start(start)
  as.integer(floor(as.numeric(x) / 60) %% 1440 + start)
}

#' Convert a Minute Index to an HMS Time
#'
#' @note This is the inverse of [acti_time_to_minute()] for readable axis labels
#'   and for joining minute-indexed results back to a time-of-day value.
#'
#' @param minute Whole-minute positions in a day.
#' @param start The index assigned to midnight, either `0` or `1`.
#'
#' @returns An `hms` vector.
#' @export
#' @examples
#' acti_minute_to_hms(c(1, 721, 1440))
#' acti_minute_to_hms(c(0, 1439), start = 0)
acti_minute_to_hms = function(minute, start = 1L) {
  start = acti_validate_start(start)
  if (!is.numeric(minute)) {
    stop("`minute` must contain whole-minute positions in the daily range.",
      call. = FALSE)
  }
  valid = is.na(minute) | (is.finite(minute) & minute == floor(minute) &
    minute >= start & minute <= start + 1439L)
  if (any(!valid)) {
    stop("`minute` must contain whole-minute positions in the daily range.",
      call. = FALSE)
  }
  hms::hms(seconds = (minute - start) * 60)
}

#' Extract the Time of Day
#'
#' @note This explicitly applies the recording or requested timezone before
#'   dropping the date, which prevents a timestamp from being assigned to the
#'   wrong activity-day minute.
#'
#' @param time A `POSIXt` vector.
#' @param timezone Optional Olson timezone in which to extract time of day.
#'
#' @returns An `hms` vector.
#' @export
#' @examples
#' time = as.POSIXct("2020-01-01 05:30:00", tz = "UTC")
#' acti_time_of_day(time, timezone = "America/New_York")
acti_time_of_day = function(time, timezone = NULL) {
  if (!inherits(time, "POSIXt")) {
    stop("`time` must be a `POSIXt` vector.", call. = FALSE)
  }
  timezone = acti_time_zone(time, timezone)
  hms::parse_hms(format(time, format = "%H:%M:%S", tz = timezone,
    usetz = FALSE))
}

#' Repeat a Time of Day Across a Recording
#'
#' @note This supplies daily plotting boundaries such as a fixed bedtime or
#'   wake time for every calendar date present in a recording.
#'
#' @param seconds Seconds after midnight, or an `hms`/`HH:MM[:SS]` time.
#' @param time A `POSIXt` recording time vector used to determine dates and
#'   timezone.
#' @param timezone Optional Olson timezone; by default the timezone of `time`.
#'
#' @returns A `POSIXct` vector with one occurrence per recording date.
#' @export
#' @examples
#' time = as.POSIXct(c("2020-01-01 12:00:00", "2020-01-03 12:00:00"), tz = "UTC")
#' acti_repeat_time_of_day("01:30", time)
acti_repeat_time_of_day = function(seconds, time, timezone = NULL) {
  if (!inherits(time, "POSIXt")) {
    stop("`time` must be a `POSIXt` vector.", call. = FALSE)
  }
  timezone = acti_time_zone(time, timezone)
  if (inherits(seconds, "hms") || is.character(seconds)) {
    seconds = as.numeric(acti_as_hms(seconds))
  }
  if (!is.numeric(seconds) || length(seconds) != 1L || is.na(seconds) ||
      seconds < 0 || seconds >= 86400) {
    stop("`seconds` must be one value from 0 through 86399.", call. = FALSE)
  }
  dates = seq(min(as.Date(time, tz = timezone), na.rm = TRUE),
    max(as.Date(time, tz = timezone), na.rm = TRUE), by = "day")
  as.POSIXct(dates, tz = timezone) + seconds
}

#' Split Intervals at Midnight
#'
#' @note Sleep, wear, and activity episodes can span dates; splitting them
#'   makes their durations and faceted daily displays unambiguous.
#'
#' @param start,end Equally sized `POSIXt` vectors.
#' @param timezone Optional Olson timezone used to define midnight.
#'
#' @returns A data frame with input `interval` number and split `start`/`end`.
#' @export
#' @examples
#' start = as.POSIXct("2020-01-01 23:30:00", tz = "UTC")
#' end = as.POSIXct("2020-01-02 00:30:00", tz = "UTC")
#' acti_split_intervals_at_midnight(start, end)
acti_split_intervals_at_midnight = function(start, end, timezone = NULL) {
  if (!inherits(start, "POSIXt") || !inherits(end, "POSIXt") ||
      length(start) != length(end)) {
    stop("`start` and `end` must be equally sized `POSIXt` vectors.", call. = FALSE)
  }
  timezone = acti_time_zone(start, timezone)
  start = as.POSIXct(start, tz = timezone)
  end = as.POSIXct(end, tz = timezone)
  if (any(!is.na(start) & !is.na(end) & end < start)) {
    stop("Each `end` must be on or after its `start`.", call. = FALSE)
  }
  pieces = lapply(seq_along(start), function(i) {
    if (is.na(start[i]) || is.na(end[i])) {
      return(data.frame(interval = i, start = start[i], end = end[i]))
    }
    first = as.Date(start[i], tz = timezone) + 1L
    last = as.Date(end[i], tz = timezone)
    mids = if (first > last) as.POSIXct(character(), tz = timezone) else {
      as.POSIXct(seq(first, last, by = "day"), tz = timezone)
    }
    mids = mids[mids < end[i]]
    cut = as.POSIXct(c(as.numeric(start[i]), as.numeric(mids), as.numeric(end[i])),
      origin = "1970-01-01", tz = timezone)
    data.frame(interval = rep.int(i, length(cut) - 1L),
      start = cut[-length(cut)], end = cut[-1L])
  })
  do.call(rbind, pieces)
}

#' Find the Start of an Activity Day
#'
#' This is a custom-day-boundary alternative to
#' [lubridate::floor_date()] with `unit = "day"`. Use `floor_date()` when days
#' begin at midnight; use `acti_day_start()` when a recording day begins at a
#' different time, such as 04:00.
#'
#' @note Activity studies often use a non-midnight boundary (for example,
#'   04:00) so nocturnal behavior is assigned to the preceding activity day.
#'
#' @param time A `POSIXt` vector.
#' @param day_start An `hms` or `HH:MM[:SS]` day boundary.
#' @param timezone Optional Olson timezone used to define the day boundary.
#'
#' @returns A `POSIXct` vector.
#' @export
#' @examples
#' time = as.POSIXct(c("2020-01-01 03:00:00", "2020-01-01 05:00:00"), tz = "UTC")
#'
#' # With a midnight boundary, this agrees with floor_date().
#' acti_day_start(time)
#' lubridate::floor_date(time, unit = "day")
#'
#' # With a 04:00 boundary, 03:00 belongs to the preceding activity day.
#' acti_day_start(time, day_start = "04:00")
acti_day_start = function(time, day_start = hms::hms(0), timezone = NULL) {
  if (!inherits(time, "POSIXt")) stop("`time` must be a `POSIXt` vector.", call. = FALSE)
  timezone = acti_time_zone(time, timezone)
  day_start = acti_as_hms(day_start)
  if (length(day_start) != 1L || is.na(day_start) || as.numeric(day_start) >= 86400) {
    stop("`day_start` must be one time within a day.", call. = FALSE)
  }
  dates = as.Date(time, tz = timezone)
  boundary = as.POSIXct(dates, tz = timezone) + as.numeric(day_start)
  boundary[time < boundary] = as.POSIXct(dates[time < boundary] - 1L,
    tz = timezone) + as.numeric(day_start)
  boundary
}

#' Calculate a Baseline-Relative Activity-Day Index
#'
#' @note A stable recording-relative day number supports faceting and alignment
#'   across participants even when their calendar start dates differ.
#'
#' @inheritParams acti_day_start
#' @param origin Optional `Date` or `POSIXt` baseline; by default the first day.
#' @param start The index assigned to the baseline day, either `0` or `1`.
#'
#' @returns An integer vector.
#' @export
#' @examples
#' time = as.POSIXct(c("2020-01-01 03:00:00", "2020-01-01 05:00:00"), tz = "UTC")
#' acti_day_index(time, day_start = "04:00")
acti_day_index = function(time, day_start = hms::hms(0), origin = NULL,
                           start = 1L, timezone = NULL) {
  start = acti_validate_start(start)
  timezone = acti_time_zone(time, timezone)
  starts = acti_day_start(time, day_start, timezone)
  dates = as.Date(starts, tz = timezone)
  if (is.null(origin)) {
    if (all(is.na(dates))) return(rep.int(NA_integer_, length(time)))
    origin = min(dates, na.rm = TRUE)
  } else if (inherits(origin, "POSIXt")) {
    origin = as.Date(acti_day_start(origin, day_start, timezone), tz = timezone)
  } else if (!inherits(origin, "Date") || length(origin) != 1L) {
    stop("`origin` must be `NULL`, one `Date`, or one `POSIXt` value.", call. = FALSE)
  }
  as.integer(dates - origin + start)
}

acti_as_hms = function(x, timezone = NULL) {
  if (inherits(x, "hms")) return(x)
  if (inherits(x, "POSIXt")) return(acti_time_of_day(x, timezone))
  if (!is.character(x)) stop("`x` must be an `hms`, `POSIXt`, or character time vector.", call. = FALSE)
  x = trimws(x)
  valid = is.na(x) | grepl("^([01]?[0-9]|2[0-3]):[0-5]\\d(:[0-5]\\d)?$", x)
  if (any(!valid)) stop("Character times must use `HH:MM[:SS]` format.", call. = FALSE)
  x = ifelse(is.na(x), NA_character_, ifelse(nchar(x) <= 5L, paste0(x, ":00"), x))
  hms::parse_hms(x)
}

acti_time_zone = function(time, timezone = NULL) {
  if (!is.null(timezone)) return(acti_validate_timezone(timezone))
  timezone = attr(time, "tzone")
  if (is.null(timezone) || !nzchar(timezone[1L])) "UTC" else acti_validate_timezone(timezone[1L])
}

acti_validate_start = function(start) {
  if (!is.numeric(start) || length(start) != 1L || is.na(start) || !(start %in% c(0, 1))) {
    stop("`start` must be either 0 or 1.", call. = FALSE)
  }
  as.integer(start)
}

acti_validate_timezone = function(timezone) {
  if (!is.character(timezone) || length(timezone) != 1L || is.na(timezone) ||
      !(timezone %in% OlsonNames())) {
    stop("`timezone` must be one valid Olson timezone.", call. = FALSE)
  }
  timezone
}
