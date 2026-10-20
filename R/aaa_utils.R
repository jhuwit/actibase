#' Is the object of class `AccData`
#'
#' @param x object to test
#'
#' @returns Logical(1)
#' @export
#'
#' @examples
#' is.AccData(mtcars)
is.AccData = function(x) {
  inherits(x, "AccData")
}

floor_sec = function(x) {
  if (lubridate::is.POSIXct(x)) {
    tz = lubridate::tz(x)
    x = as.numeric(x)
    x = floor(x)
    as.POSIXct(x, tz = tz, origin = lubridate::origin)
  } else {
    lubridate::floor_date(x, "1 sec")
  }
}

ticks2datetime = function (ticks, tz = "GMT")
{
  ticks <- as.numeric(ticks)
  seconds <- ticks/1e+07
  datetime <- as.POSIXct(seconds, origin = "0001-01-01", tz = tz)
  datetime
}

Round = function (x, n = 0) {
  return(sign(x) * trunc(abs(x) * 10^n + 0.5)/10^n)
}

#' Strip Hour Shift from Character Time Vector
#'
#' @param x character vector with times that may include hour shifts
#' (e.g., "2019-01-01 12:00+03:00")
#' @param max_index maximum index to grab the shift from after splitting on
#' spaces, default is 2 (e.g., "2019-01-01 12:00")
#'
#' @returns A character vector with the `+`/`-` hour shift removed
#' @export
#'
#' @examples
#' strip_hour_shift(c("2019-01-01 12:00+03:00", "2019-01-01 12:00-04:00"))
strip_hour_shift = function(x, max_index = 2L) {
  x = sub("[+]", " +", x)
  x = sub("-(\\d\\d:00)$", " -\\1", x)
  xx = strsplit(x, split = " ")
  l = sapply(xx, length)
  stopifnot(all(l >= max_index))
  xx = sapply(xx, function(r) {
    paste(r[1:max_index], collapse = " ")
  })
  xx
}


#' Transform timezone offset to timezone
#'
#' Converts UTC offsets such as `"-05:00"` (5 hours behind UTC) into the
#' matching fixed-offset Olson time zone.  Note that `Etc/GMT` zones use an
#' inverted sign convention, so `"-05:00"` is `"Etc/GMT+5"`.
#'
#' @param x A character vector of offsets in the form `"+HH:MM"` or
#' `"+HH:MM:SS"`
#'
#' @returns A character vector
#' @noRd
# Not exported yet: CRAN actiread (<= 0.5.0) exports its own copy, and
# packages that import() both actibase and actiread would warn about the
# replaced import.  Export here (and re-export from actiread) in a later
# release.
tzoffset_to_tz = function(x) {
  seconds = tzoffset_to_seconds(x)
  if (any(seconds %% 3600 != 0)) {
    stop("Offsets that are not whole hours have no Etc/GMT time zone: ",
         paste(unique(x[seconds %% 3600 != 0]), collapse = ", "),
         call. = FALSE)
  }
  hours = -seconds / 3600
  x = ifelse(hours > 0, paste0("+", hours), as.character(hours))
  x = paste0("Etc/GMT", x)
  if (!all(x %in% OlsonNames())) {
    stop("No Olson time zone for offset: ",
         paste(unique(x[!x %in% OlsonNames()]), collapse = ", "),
         call. = FALSE)
  }
  x
}

# Convert "+HH:MM" or "+HH:MM:SS" offsets to signed seconds from UTC
tzoffset_to_seconds = function(x) {
  x = trimws(x)
  pattern = "^([+-]?)([0-9]{1,2}):([0-9]{2})(:([0-9]{2}))?$"
  if (!all(grepl(pattern, x))) {
    stop("Timezone offsets must look like +HH:MM or +HH:MM:SS, got: ",
         paste(unique(x[!grepl(pattern, x)]), collapse = ", "),
         call. = FALSE)
  }
  sign = ifelse(sub(pattern, "\\1", x) == "-", -1, 1)
  hours = as.numeric(sub(pattern, "\\2", x))
  minutes = as.numeric(sub(pattern, "\\3", x))
  secs = sub(pattern, "\\5", x)
  secs = ifelse(nzchar(secs), as.numeric(secs), 0)
  sign * (hours * 3600 + minutes * 60 + secs)
}

