#' Tidy axes to a long format
#'
#' @param data An object with columns a time column `X`, `Y`, and `Z` or an
#' object of class `AccData`
#' @inheritParams acti_standardize_data
#' @return A long data set with `time`, `axis`, and `value`
#' @export
#'
#' @examples
#' long = acti_tidy_axes(acti_raw_data)
acti_tidy_axes = function(data,
                          colname_time = "time") {
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    stop("tidyr required for tidy_axes")
  }
  time = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIME_STAMP", "X", "Y", "Z", "time"))
  data = acti_standardize_data(data, subset_xyz = TRUE, colname_time = colname_time)
  transformations = get_transformations(data)

  data = data %>%
    tidyr::gather("axis", "value", -dplyr::any_of(colname_time))
  transforms = "axes_reshaped"
  transformations = c(transforms, transformations)
  data = set_transformations(data, transformations = transformations, add = FALSE)
  data
}

renamer = function(data, colname, candidates) {
  if (!colname %in% colnames(data)) {
    for (i in candidates) {
      check = i %in% colnames(data)
      if (check) {
        colnames(data)[colnames(data) %in% i] = colname
        break
      }
    }
  }
  data
}
rename_time = function(data) {
  HEADER_TIMESTAMP = TIME = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "X", "Y", "Z",
              "TIME"))
  candidates =  c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "TIME")
  candidates = c(candidates, tolower(candidates))
  data = renamer(data, "time", candidates)
  data
}


#' Standardize the Accelerometry Data
#'
#' @param data A `data.frame` with a column for time in `POSIXct` (usually
#' `time`), and `X`, `Y`, `Z`
#' @param subset_xyz should only the `time` (if available)
#' and `XYZ` be subset?
#' @param colname_time column name of header for time
#' @param check_xyz Check if X/Y/Z is in the data
#'
#' @return A `data.frame` with `X/Y/Z` and a time in
#' `time` (if available).
#' @export
#' @examples
#'
#' acti_standardize_data(acti_raw_data)
#' acti_standardise_data(acti_raw_data)
#'
acti_standardize_data = function(data,
                                 subset_xyz = TRUE,
                                 colname_time = "time",
                                 check_xyz = TRUE) {
  HEADER_TIMESTAMP = TIME = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "X", "Y", "Z",
              "TIME"))
  assertthat::assert_that(
    assertthat::is.string(colname_time),
    assertthat::is.flag(subset_xyz)
  )
  if (is.matrix(data)) {
    if (is.numeric(data)) {
      stopifnot(ncol(data) == 3)
      data = as.data.frame(data)
      colnames(data) = c("X", "Y", "Z")
    } else {
      stop("data is a matrix and cannot be coerced to necessary structure")
    }
  }

  data = rename_time(data)
  data = renamer(data, "X", "x")
  data = renamer(data, "Y", "y")
  data = renamer(data, "Z", "z")

  if (subset_xyz) {
    data = data %>%
      dplyr::select(dplyr::any_of("time"), X, Y, Z)
  }
  if ("time" %in% colnames(data)) {
    cn = colnames(data)
    cn[cn == "time"] = colname_time
    colnames(data) = cn
  }

  if (check_xyz) {
    stopifnot(all(c("X", "Y", "Z") %in% colnames(data)))
  }
  data
}

#' @export
#' @rdname acti_standardize_data
acti_standardise_data = acti_standardize_data

xyz_data = function(data) {
  data = acti_standardize_data(data)
  as.matrix(data[, c("X", "Y", "Z"), drop = FALSE])
}
