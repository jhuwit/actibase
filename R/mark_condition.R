#' Mark a Condition of a Specified Minimum Length
#'
#' @param x A logical vector
#' @param min_length minimum length, contiguous \code{TRUE} values required
#'
#' @return A logical vector
#' @export
#'
#' @examples
#' x = c(FALSE, TRUE, TRUE, FALSE, FALSE, rep(TRUE, 10), FALSE, rep(TRUE, 20))
#' mark_condition(x)
#' mark_condition(x, 2)
#' mark_condition(x, 5)
#' mark_condition(x, 15)
mark_condition = function(x, min_length = 1) {
  stopifnot(is.logical(x))
  if (length(x) == 0L) return(x)
  if (!anyNA(x) && all(x) && length(x) >= min_length) return(x)
  bad = rle(x)
  keep = !is.na(bad$values) & bad$values
  missing = is.na(bad$values)
  bad$values[keep] = bad$lengths[keep] >= min_length
  bad$values[!keep & !missing] = FALSE
  inverse.rle(bad)
}
