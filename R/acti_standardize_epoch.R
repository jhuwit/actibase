#' Standardize an Epoch Length
#'
#' Converts an epoch given as a number, a string such as `"1 min"`, `"30s"`,
#' `"5 seconds"`, or `"1 hour"`, a `lubridate` `Duration` or `Period`, or a
#' `difftime` into a consistent representation: either a number in a given
#' unit (e.g. `60` seconds) or a string that can be passed to
#' [lubridate::floor_date()] (e.g. `"1 min"`).
#'
#' @param epoch A single epoch length: a positive number (in `input_unit`),
#' a string parseable by [lubridate::duration()] (`"1 min"`, `"1min"`,
#' `"30s"`, `"2 hours"`; `"hr"` and the `lubridate` arbitrary units such as
#' `"90 aseconds"` are also accepted), a `Duration`, a `Period`, or a
#' `difftime`.  Calendar units without a fixed length (months, quarters,
#' years, ...) are not epochs and give an error.
#' @param unit Unit to standardize the epoch to: one of `"seconds"`,
#' `"minutes"`, `"hours"`, `"days"`, or `"auto"`.  `"auto"` is only
#' available for `output = "character"` and picks the largest unit that
#' [lubridate::floor_date()] can round with (e.g. `"1 min"` rather than
#' `"60 secs"`), falling back to `"aseconds"` for lengths such as
#' 90 seconds.  Defaults to `"seconds"` for numeric output and `"auto"` for
#' character output.  Singular and abbreviated unit names are matched to the
#' unit they name: `"second"`, `"sec"`, and `"secs"` are treated as
#' `"seconds"`; `"minute"`, `"min"`, and `"mins"` as `"minutes"`; `"hour"`,
#' `"hr"`, and `"hrs"` as `"hours"`; and `"day"` as `"days"`.  Other names,
#' including partial ones such as `"m"`, are an error.
#' @param output Type of output: `"numeric"` returns the length in `unit`,
#' `"character"` returns a string such as `"30 secs"`, `"1 min"`, or
#' `"2 hours"`, which [lubridate::floor_date()], [seq()], [cut()], and
#' `MIMSunit` all understand.
#' @param input_unit Unit of `epoch` when `epoch` is numeric (or a string with
#' no unit, such as `"60"`).  Ignored otherwise.  Abbreviations are matched
#' as for `unit`.
#'
#' @returns A numeric value or a single string.
#'
#' @note The `"aseconds"` fallback for `output = "character"` relies on the
#' absolute-unit rounding that [lubridate::floor_date()] has supported since
#' lubridate 1.9.0.
#' @export
#'
#' @examples
#' acti_standardize_epoch(60)
#' acti_standardize_epoch("1 min")
#' acti_standardize_epoch("1 min", unit = "minutes")
#' acti_standardize_epoch(30, output = "character")
#' acti_standardize_epoch(60, output = "character")
#' acti_standardize_epoch(5, input_unit = "minutes")
#' acti_standardize_epoch("2 hours", unit = "minutes", output = "character")
#' acti_standardize_epoch(lubridate::minutes(5))
#' acti_standardize_epoch(as.difftime(30, units = "secs"), output = "character")
acti_standardize_epoch = function(
    epoch,
    unit = c("seconds", "minutes", "hours", "days", "auto"),
    output = c("numeric", "character"),
    input_unit = c("seconds", "minutes", "hours", "days")
) {
  output = match.arg(output)
  if (missing(unit)) {
    unit = if (output == "character") "auto" else "seconds"
  }
  unit = epoch_unit_name(unit, c("seconds", "minutes", "hours", "days", "auto"),
                         arg = "unit")
  input_unit = epoch_unit_name(input_unit[1],
                               c("seconds", "minutes", "hours", "days"),
                               arg = "input_unit")
  if (unit == "auto" && output == "numeric") {
    stop("`unit = \"auto\"` is only available for `output = \"character\"`.",
         call. = FALSE)
  }

  seconds = epoch_to_seconds(epoch, input_unit = input_unit)

  if (unit == "auto") {
    return(epoch_auto_string(seconds))
  }
  value = seconds / epoch_unit_seconds[[unit]]
  if (output == "numeric") {
    return(value)
  }
  epoch_string(value, unit)
}

#' @rdname acti_standardize_epoch
#' @export
acti_standardise_epoch = acti_standardize_epoch

epoch_unit_seconds = c(seconds = 1, minutes = 60, hours = 3600, days = 86400)

# Silently map singular/abbreviated names ("secs", "min", "hr", ...) onto the
# documented choices.  Matching is exact (not match.arg()) so that partial
# names such as "m" are not silently taken as minutes when months were meant.
epoch_unit_name = function(x, choices, arg = "unit") {
  assertthat::assert_that(assertthat::is.string(x))
  x = tolower(trimws(x))
  aliases = c(
    second = "seconds", sec = "seconds", secs = "seconds",
    minute = "minutes", min = "minutes", mins = "minutes",
    hour = "hours", hr = "hours", hrs = "hours",
    day = "days"
  )
  if (x %in% names(aliases)) {
    x = aliases[[x]]
  }
  if (!x %in% choices) {
    stop("`", arg, "` must be one of ",
         paste0('"', choices, '"', collapse = ", "), ", not \"", x, "\".",
         call. = FALSE)
  }
  x
}

epoch_to_seconds = function(epoch, input_unit = "seconds") {
  if (length(epoch) != 1L) {
    stop("`epoch` must be a single epoch length, not length ", length(epoch),
         ".", call. = FALSE)
  }
  original = epoch
  if (lubridate::is.duration(epoch)) {
    seconds = as.numeric(epoch)
  } else if (lubridate::is.period(epoch)) {
    seconds = lubridate::period_to_seconds(epoch)
  } else if (inherits(epoch, "difftime")) {
    seconds = as.numeric(epoch, units = "secs")
  } else if (is.numeric(epoch)) {
    seconds = as.numeric(epoch) * epoch_unit_seconds[[input_unit]]
  } else if (is.character(epoch)) {
    x = tolower(trimws(epoch))
    if (grepl("^[0-9]*[.]?[0-9]+$", x)) {
      seconds = as.numeric(x) * epoch_unit_seconds[[input_unit]]
    } else {
      # lubridate::floor_date() arbitrary units, e.g. "90 aseconds"
      x = sub("([0-9 ]|^)a(sec|min|hour)", "\\1\\2", x)
      x = sub("([0-9 ]|^)hrs?$", "\\1hours", x)
      if (grepl("(mon|quarter|season|halfyear|year)", x)) {
        stop("Epoch '", epoch, "' does not have a fixed length; use ",
             "seconds, minutes, hours, or days.", call. = FALSE)
      }
      seconds = tryCatch(
        as.numeric(lubridate::duration(x)),
        error = function(e) NA_real_
      )
    }
  } else {
    seconds = NA_real_
  }
  if (length(seconds) != 1L || is.na(seconds) || !is.finite(seconds) ||
      seconds <= 0) {
    stop("Could not interpret epoch '", format(original), "' as a positive ",
         "length of time (e.g. 60, \"1 min\", \"30s\", \"1 hour\").",
         call. = FALSE)
  }
  seconds
}

# Abbreviations understood by lubridate::floor_date(), seq(), cut(), and
# MIMSunit, e.g. "30 secs", "1 min", "2 hours", "1 day"
epoch_string = function(value, unit) {
  unit = c(seconds = "secs", minutes = "mins", hours = "hours",
           days = "days")[[unit]]
  if (isTRUE(all.equal(value, 1))) {
    unit = sub("s$", "", unit)
  }
  paste(epoch_number(value), unit)
}

epoch_number = function(x) {
  trimws(formatC(x, format = "fg", digits = 15))
}

# Largest unit lubridate::floor_date() can round with
epoch_auto_string = function(seconds) {
  is_whole = function(x) isTRUE(all.equal(x, round(x)))
  days = seconds / 86400
  if (is_whole(days) && days <= 31) {
    return(epoch_string(round(days), "days"))
  }
  hours = seconds / 3600
  minutes = seconds / 60
  if (is_whole(hours) && hours <= 24) {
    return(epoch_string(round(hours), "hours"))
  }
  if (is_whole(minutes) && minutes <= 60) {
    return(epoch_string(round(minutes), "minutes"))
  }
  if (seconds <= 60) {
    return(epoch_string(seconds, "seconds"))
  }
  paste(epoch_number(seconds), "aseconds")
}
