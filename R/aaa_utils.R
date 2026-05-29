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






tzoffset_to_tz = function(x) {
  stopifnot(all(grepl(":00", x)))
  x = sub(":00:00$", "", x)
  x = sub(":00$", "", x)
  stopifnot(nchar(x) <= 3)
  x = as.numeric(x)
  x = ifelse(x > 0, paste0("+", x), as.character(x))
  x = paste0("Etc/GMT", x)
  stopifnot(x %in% OlsonNames())
  x
}

