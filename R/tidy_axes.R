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

standardize_axis_names = function(data) {
  axis_names = c("X", "Y", "Z")
  aliases = lapply(axis_names, function(axis) {
    c(axis, tolower(axis), paste0("acc_", axis), paste0("acc_", tolower(axis)),
      paste0("acceleration_", tolower(axis)), paste0("acceleration_", axis))
  })
  names(aliases) = axis_names

  for (axis in axis_names) {
    if (axis %in% names(data) && tolower(axis) %in% names(data)) {
      stop("Data cannot contain both `", axis, "` and `", tolower(axis),
           "` columns.", call. = FALSE)
    }
  }

  canonical = vapply(axis_names, function(axis) {
    any(c(axis, tolower(axis)) %in% names(data))
  }, logical(1))
  has_prefixed_triplet = function(prefix) {
    all(vapply(axis_names, function(axis) {
      any(c(paste0(prefix, axis), paste0(prefix, tolower(axis))) %in% names(data))
    }, logical(1)))
  }
  has_competing_triplet = has_prefixed_triplet("acc_") ||
    has_prefixed_triplet("acceleration_")
  if (all(canonical) && has_competing_triplet) {
    warning(paste0(
      "Canonical X/Y/Z columns were chosen, but a complete prefixed axis ",
      "set (acc_* or acceleration_*) also exists. The prefixed columns were not used."
    ), call. = FALSE)
  }

  for (axis in axis_names) {
    candidates = aliases[[axis]]
    present = candidates[candidates %in% names(data)]
    if (!length(present)) next
    chosen = present[[1L]]
    if (chosen != axis) {
      names(data)[names(data) == chosen] = axis
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
#' @param data A `data.frame` with an optional time column and three
#'   accelerometer axes. Axes can be named `X/Y/Z`, `x/y/z`, `acc_X/acc_Y/acc_Z`,
#'   `acc_x/acc_y/acc_z`, or `acceleration_X/acceleration_Y/acceleration_Z`
#'   (with lowercase axis letters also accepted).
#' @param subset_xyz should only the `time` (if available)
#' and `XYZ` be subset?
#' @param lower_case flag to make sure all columns are lower case.
#' @param colname_time column name of header for time
#' @param check_xyz Check if X/Y/Z is in the data
#'
#' @details When a complete canonical triplet and a complete prefixed triplet
#'   (`acc_*` or `acceleration_*`) are both present, the canonical columns are
#'   used and a single warning is issued. A data frame containing both `X` and
#'   `x` (or the analogous pair for Y or Z) is rejected as ambiguous.
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
                                 lower_case = FALSE,
                                 check_xyz = TRUE) {
  HEADER_TIMESTAMP = TIME = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "X", "Y", "Z",
              "TIME"))
  assertthat::assert_that(
    assertthat::is.string(colname_time),
    assertthat::is.flag(subset_xyz),
    assertthat::is.flag(lower_case)
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
  data = standardize_axis_names(data)

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
  if (lower_case) {
    colnames(data) = tolower(colnames(data))
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
