get_sample_rate_from_header = function(hdr, sample_rate = NULL) {
  if (is.null(sample_rate) && !is.null(hdr)) {
    sample_rate = hdr$Value[hdr$Field == "Sample Rate"]
    sample_rate = as.numeric(sample_rate)
    if (length(sample_rate) == 0) {
      sample_rate = NULL
    }
    if (is.null(sample_rate))  {
      sample_rate = hdr$SampleRate
      sample_rate = as.numeric(sample_rate)
      if (length(sample_rate) == 0 ||
          all(is.na(sample_rate))) {
        sample_rate = NULL
      }
    }
  }
  sample_rate
}

#' Get Sample Rate
#'
#' @param data A data set of actigraphy/activity data
#' @param sample_rate the sample rate.  If this is not \code{NULL}, then
#' it will be guess from the header or the data or the data separation
#' @param flag_estimated if `TRUE`, then the output will have the attribute
#' `"estimated"`, which is a logical indicated if it was found or estimated
#'
#' @return A length-1 numeric vector
#' @export
get_sample_rate = function(data, sample_rate = NULL, flag_estimated = FALSE) {
  if (!is.null(sample_rate)) {
    assertthat::assert_that(
      is.numeric(sample_rate) && is.finite(sample_rate)
    )
    return(sample_rate)
  }
  if (is.AccData(data)) {
    sample_rate = data$freq
  }
  if (is.null(sample_rate) || is.na(sample_rate)) {
    sample_rate = attr(data, "sample_rate")
  }
  if (is.null(sample_rate) || is.na(sample_rate)) {
    sample_rate = get_sample_rate_from_header(attr(data, "header"))
  }
  estimated = FALSE

  if (
    (is.null(sample_rate) || is.na(sample_rate)) &&
    any(
      c("time", "HEADER_TIME_STAMP", "HEADER_TIMESTAMP") %in% colnames(data)
    )
  ) {
    message("Guessing sample_rate from the data")
    time = data[["time"]]
    if (is.null(time)) {
      time = data[["HEADER_TIME_STAMP"]]
    }
    if (is.null(time)) {
      time = data[["HEADER_TIMESTAMP"]]
    }
    if (is.null(time)) stop("No usable timestamp column found.", call. = FALSE)
    time = time[!is.na(time)]
    if (length(time) < 2L) {
      stop("At least two non-missing timestamps are required to estimate sample rate.",
           call. = FALSE)
    }
    time = sort(unique(time))
    if (length(time) < 2L) {
      stop("At least two distinct timestamps are required to estimate sample rate.",
           call. = FALSE)
    }
    d = diff(time)
    units(d) = "secs"
    rm(list = "time")
    if (all(d > 1)) {
      # For sparse minute-level records, average observed interval rates.
      sample_rate = mean(1 / as.numeric(d))
    } else {
      sample_rate = unique(round(1 / as.numeric(d)))
      if (length(sample_rate) > 1) {
        warning("Multiple sample rates found in data, using the rounded mean!")
        sample_rate = round(mean(1 / as.numeric(d)))
      }
    }
    stopifnot(length(sample_rate) == 1)
    estimated = TRUE
  }
  stopifnot(!is.null(sample_rate))
  assertthat::assert_that(
    is.numeric(sample_rate) && is.finite(sample_rate)
  )
  if (flag_estimated) {
    attr(sample_rate, "estimated") = estimated
  }
  return(sample_rate)
}

