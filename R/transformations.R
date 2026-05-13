#' Get Transformations
#'
#' @param data data set of data, usually time and X/Y/Z.
#' @return \code{\link{set_transformations}} returns the data, with the
#' `transformations` attribute updated and \code{\link{set_transformations}}
#' returns the attribute `transformations`
#' @export
get_transformations = function(data) {
  transforms = attr(data, "transformations")
  is_acc = is.AccData(data)
  if (is_acc) {
    transforms = c(transforms, attr(data$data, "transformations"))
    transforms = unique(transforms)
  }
  transforms
}

#' @export
#' @rdname get_transformations
#' @param prefix if not `NULL`, the prefix plus `:` would be pasted to the
#' transformations.
prefix_transformations = function(transformations, prefix = NULL) {
  if (!is.null(prefix)) {
    assertthat::assert_that(
      assertthat::is.string(prefix)
    )
    transformations = paste0(prefix, ":", transformations)
  }
  transformations
}

#' @export
#' @rdname get_transformations
#' @param add Add the transformations to those already there in `data`
#' @param transformations character string of transformations
set_transformations = function(data, transformations, add = TRUE,
                               prefix = NULL) {
  if (add) {
    transforms = get_transformations(data)
  } else {
    transforms = NULL
  }
  transformations = prefix_transformations(transformations, prefix = prefix)
  # this is right - we are appending new stuff to beginning
  transformations = c(transformations, transforms)
  attr(data, "transformations") = transformations
  data
}
