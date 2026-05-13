sort_time_df = function(df, prefix = NULL) {
  if ("time" %in% names(df)) {
    if (is.unsorted(df$time)) {
      ord = order(df$time)
      if (!all(ord == 1:nrow(df))) {
        df = set_transformations(df, "sorted_by_time", prefix = prefix, add = TRUE)
        warning("Time is unsorted, will resort the data set")
        df = df[ ord, ]
      }
    }
  }
  df
}


#' Fill in Zeros
#'
#' @param data a data frame containing columns time, X, Y, Z
#'
#' @returns the modified data frame with zeros replaced by NA
#' @export
#'
#' @examples
#' acti_fill_zeros(acti_raw_data)
#' acti_fill_zeroes(acti_raw_data)
acti_fill_zeros = function(data) {
  data = acti_standardize_data(data, subset_xyz = FALSE)
  data = sort_time_df(data, prefix = "acti_fill_zeros")
  data$all_zero = data$X == 0 & data$Y == 0 & data$Z == 0
  data$X = ifelse(data$all_zero, NA_real_, data$X)
  data$Y = ifelse(data$all_zero, NA_real_, data$Y)
  data$Z = ifelse(data$all_zero, NA_real_, data$Z)
  data$all_zero = NULL

  data$X = vctrs::vec_fill_missing(data$X, direction = "down")
  data$Y = vctrs::vec_fill_missing(data$Y, direction = "down")
  data$Z = vctrs::vec_fill_missing(data$Z, direction = "down")

  data$X[is.na(data$X)] = 0
  data$Y[is.na(data$Y)] = 0
  data$Z[is.na(data$Z)] = 0

  data = set_transformations(data, "filled_zeros", prefix = "acti_fill_zeros", add = TRUE)
  data
}

#' @export
#' @rdname acti_fill_zeros
acti_fill_zeroes = acti_fill_zeros
