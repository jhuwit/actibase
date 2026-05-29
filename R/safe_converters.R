#' Convert vectors ensuring no new NA
#'
#' @param x a vector
#' @param ... additional arguments to pass to `func`
#' @param func the function to use to transform the vector `x`
#'
#' @returns A converted `vector` the same length as `x` or errors if there
#' are introduced NAs.
#' @export
#' @rdname as_convert_safe
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

#' @export
#' @rdname as_convert_safe
as_date_safe = function(x, ...) {
  as_convert_safe(x, ..., func = lubridate::as_date)
}

#' @export
#' @rdname as_convert_safe
as_datetime_safe = function(x, ...) {
  as_convert_safe(x, ..., func = lubridate::as_datetime)
}

