run_resample = function(
    timestamp, x, y, z,
    time_interp,
    orig_tz,
    method = c("linear", "constant",
               "fmm", "periodic", "natural", "monoH.FC", "hyman"),
    ...) {
  method = match.arg(method)
  func = switch(
    method,
    linear = stats::approx,
    constant = stats::approx,
    fmm = stats::spline,
    periodic = stats::spline,
    natural = stats::spline,
    monoH.FC = stats::spline,
    hyman = stats::spline)
  interpolate = function(values) {
    keep = is.finite(timestamp)
    if (!any(keep)) return(rep(NA_real_, length(time_interp)))
    if (sum(keep) == 1L) {
      return(ifelse(time_interp == timestamp[keep][1L], values[keep][1L], NA_real_))
    }
    result = func(x = timestamp[keep], xout = time_interp, method = method,
                  y = values[keep], ...)$y
    result[time_interp < min(timestamp[keep]) |
             time_interp > max(timestamp[keep])] = NA_real_
    result
  }
  x_out = interpolate(x)
  rm(x)
  y_out = interpolate(y)
  rm(y)
  z_out = interpolate(z)
  rm(z)
  rm(timestamp)


  time_interp = round(time_interp, 3)
  time_interp = as.POSIXct(
    time_interp,
    tz = orig_tz,
    origin = lubridate::origin)

  out = data.frame(
    time = time_interp,
    X = x_out,
    Y = y_out,
    Z = z_out
  )
  # this should allow us to match whatever standardize_data does
  out = acti_standardize_data(data = out, subset_xyz = FALSE)
  out
}


#' Resample 3-axial input signal to a specific sampling rate
#'
#' @param data A `data.frame` with a column for time in `POSIXct` (usually
#' `time`), and `X`, `Y`, `Z`
#' @param sample_rate sampling frequency, coercible to an integer.
#' This is the sampling rate you're sampling the data *into*.
#' @param ... additional arguments to pass to [stats::approx()] or
#' [stats::spline]
#' @param method method for interpolation. Options are
#' `"linear"/"constant"`, which uses `stats::approx`, or one of
#' `"fmm", "periodic", "natural", "monoH.FC", "hyman"`, which uses
#' `stats::spline`
#' @return A `data.frame`/`tibble` of `time` and `X`, `Y`, `Z`.
#' @export
#'
#' @examples
#' old = options(digits.secs = 3)
#' x = acti_raw_data
#' res = acti_resample(data = x, sample_rate = 80)
#' res = acti_resample(data = x, sample_rate = 100)
#' res = acti_resample(data = x, sample_rate = 1)
#' res = acti_resample_to_time(
#'   data = x,
#'   times = lubridate::floor_date(x$time, unit = "1 sec"),
#' )
#' res_nat = acti_resample_to_time(
#'   data = x,
#'   times = lubridate::floor_date(x$time, unit = "1 sec"),
#'   method = "natural"
#' )
#' options(old)
acti_resample = function(
    data,
    sample_rate,
    method = "linear",
    ...
) {
  if (!is.numeric(sample_rate) || length(sample_rate) != 1L ||
      !is.finite(sample_rate) || sample_rate <= 0 || sample_rate != floor(sample_rate)) {
    stop("`sample_rate` must be one positive whole number.", call. = FALSE)
  }
  sample_rate = as.integer(sample_rate)

  data = acti_standardize_data(data)
  if (anyNA(data$time)) {
    stop("`time` contains missing timestamps; drop those rows before resampling.",
         call. = FALSE)
  }
  is_data_tibble = inherits(data, "tbl_df")
  trans = get_transformations(data)
  data = prepare_resample_data(data)
  orig_tz = lubridate::tz(data$time)
  timestamp = as.numeric(data$time)
  x = data[["X"]]
  y = data[["Y"]]
  z = data[["Z"]]
  rm(data)

  # Make it 0 to max so that no overflow issues with numerics
  time_interp = timestamp - timestamp[1]
  time_interp = seq(time_interp[1],
                    time_interp[length(time_interp)],
                    (1/sample_rate)
  )
  time_interp = time_interp + timestamp[1]

  out = run_resample(
    timestamp = timestamp,
    x = x,
    y = y,
    z = z,
    method = method,
    time_interp = time_interp,
    orig_tz = orig_tz,
    ...)
  if (is_data_tibble) {
    out = dplyr::as_tibble(out)
  }
  attr(out, "sample_rate") = sample_rate
  out = set_transformations(out, trans)
  out = set_transformations(out,
                            c(
                              paste0("sample_rate_attribute_changed_to_", sample_rate),
                              paste0(method, "_resampled_to_", sample_rate, "Hz")
                              ),
                            prefix = "acti_resample",
                            add = TRUE)
  return(out)
}

#' @export
#' @param times a vector of `POSIXct` date/time values to interpolate
#' the data to
#' @rdname acti_resample
acti_resample_to_time = function(
    data,
    times,
    method = "linear",
    ...
) {

  data = acti_standardize_data(data)
  is_data_tibble = inherits(data, "tbl_df")
  trans = get_transformations(data)
  data = prepare_resample_data(data)
  if (!inherits(times, "POSIXt")) {
    stop("`times` must be a POSIXt vector.", call. = FALSE)
  }
  if (anyNA(times)) stop("`times` cannot contain missing values.", call. = FALSE)
  orig_tz = lubridate::tz(data$time)
  time_tz = lubridate::tz(times)
  if (orig_tz != time_tz) {
    stop("Timezone in data times do not match timezone in time vector!")
  }
  timestamp = as.numeric(data$time)
  x = data[["X"]]
  y = data[["Y"]]
  z = data[["Z"]]
  rm(data)

  time_interp = as.numeric(times)
  rm(times)

  out = run_resample(
    timestamp = timestamp,
    x = x,
    y = y,
    z = z,
    method = method,
    time_interp = time_interp,
    orig_tz = orig_tz,
    ...)
  if (is_data_tibble) {
    out = dplyr::as_tibble(out)
  }
  out = set_transformations(out, trans)
  out = set_transformations(out,
                            paste0("resampled_to_specific_times"),
                            prefix = "acti_resample_to_time",
                            add = TRUE)
  return(out)
}

prepare_resample_data = function(data) {
  time = X = Y = Z = NULL
  rm(list = c("time", "X", "Y", "Z"))
  if (!inherits(data$time, "POSIXt")) stop("`time` must be a POSIXt vector.", call. = FALSE)
  if (nrow(data) == 0L) stop("`data` must contain at least one timestamp.", call. = FALSE)
  if (anyNA(data$time)) {
    stop("`time` contains missing timestamps; drop those rows before resampling.",
         call. = FALSE)
  }
  data = data[order(data$time), , drop = FALSE]
  if (anyDuplicated(data$time)) {
    data = dplyr::summarise(
      dplyr::group_by(data, time),
      X = if (all(is.na(X))) NA_real_ else mean(X, na.rm = TRUE),
      Y = if (all(is.na(Y))) NA_real_ else mean(Y, na.rm = TRUE),
      Z = if (all(is.na(Z))) NA_real_ else mean(Z, na.rm = TRUE),
      .groups = "drop"
    )
  }
  data
}
