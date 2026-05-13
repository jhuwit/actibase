is.AccData = function(x) {
  inherits(x, "AccData")
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

read_csv_safe = function(..., guess_max = Inf) {
  x = readr::read_csv(..., guess_max = guess_max)
  p = readr::problems(x)
  cn = list(...)$col_names
  if (is.null(cn)) {
    cn = TRUE
  }
  if (nrow(p) > 0) {
    print(p)
    rows = unique(p$row)
    if (cn) {
      rows = rows - 1
    }
    bad_data = x[rows, unique(p$col)]
    print("Bad Data:")
    print(bad_data)
  }
  readr::stop_for_problems(x)
  x
}



as_convert_safe = function(x, ..., func = lubridate::as_datetime) {
  nax = is.na(x)
  xx = func(x, ...)
  naxx = is.na(xx)
  any_na = !nax & naxx
  if (any(any_na)) {
    message("Conversion not done for:")
    print(x[any_na])
    stop("conversion failed")
  }
  xx
}

as_date_safe = function(x, ...) {
  as_convert_safe(x, ..., func = lubridate::as_date)
}

as_datetime_safe = function(x, ...) {
  as_convert_safe(x, ..., func = lubridate::as_datetime)
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

