
get_range_from_header = function(hdr, dynamic_range = NULL) {
  if (is.null(dynamic_range) && !is.null(hdr)) {
    dynamic_range = c(hdr$Value[hdr$Field == "Acceleration Min"],
                      hdr$Value[hdr$Field == "Acceleration Max"])
    dynamic_range = as.numeric(dynamic_range)
    if (length(dynamic_range) == 0) {
      dynamic_range = c(hdr$"Acceleration Min",
                        hdr$"Acceleration Max")
      dynamic_range = as.numeric(dynamic_range)
      if (length(dynamic_range) == 0) {
        dynamic_range = c(hdr$acceleration_min,
                          hdr$acceleration_max)
        dynamic_range = as.numeric(dynamic_range)
        if (length(dynamic_range) == 0) {
          dynamic_range = NULL
        }
      }
    }
  }
  dynamic_range
}

#' Get Dynamic Range
#'
#' @param data An \code{AccData} object from an actigraphy reader
#' @param dynamic_range the dynamic range.  If this is not \code{NULL}, then
#' it will be guess from the header or the data
#'
#' @return A length-2 numeric vector, or the original dynamic range (no
#' checking done)
#' @export
get_dynamic_range = function(data, dynamic_range = NULL) {
  if (is.AccData(data)) {
    hdr = data$header
    drange = attr(data, "dynamic_range")
    if (!is.null(drange)) {
      dynamic_range = drange
    } else {
      dynamic_range = get_range_from_header(hdr, dynamic_range = dynamic_range)
    }
    if (is.null(dynamic_range)) {
      if (length(hdr$accrange) > 0) {
        arange = try({
          unique(abs(as.numeric(hdr$accrange)))
        }, silent = TRUE)
        if (!inherits(arange, "try-error")) {
          dynamic_range = c(-arange, arange)
        }
      }
    }

    # allows for actilife headers to extract it correctly
    if (is.null(dynamic_range) &&
        is.null(attr(data$data, "dynamic_range"))) {
      hdr = data$original_header
      dynamic_range = get_dynamic_range_actilife_header(hdr)
    }
    data = data$data
  }
  drange = attr(data, "dynamic_range")
  if (!is.null(drange)) {
    dynamic_range = drange
  }
  if (is.null(dynamic_range)) {
    hdr = attr(data, "header")
    dynamic_range = get_range_from_header(hdr, dynamic_range = dynamic_range)
  }
  estimated = FALSE
  if (is.null(dynamic_range)) {
    warning("No dynamic range found in header, using data estimate")
    r = range(data[c("X", "Y", "Z")], na.rm = TRUE)
    r = max(abs(r))
    r = ceiling(r)
    dynamic_range = c(-r, r)
    estimated = TRUE
  }
  attr(dynamic_range, "estimated") = estimated
  return(dynamic_range)
}


get_dynamic_range_actilife_header = function(header) {
  if (is.null(header)) {
    return(NULL)
  }
  if (length(header) > 0) {
    header = paste(header, collapse = " ")
  }
  hdr = strsplit(header, "---")[[1]]
  hdr = trimws(hdr)
  hdr = gsub("-", "", hdr)
  hdr = hdr[ !hdr %in% ""]
  hdr = trimws(hdr)
  hdr = hdr[ grepl("Serial", hdr)]
  ACTIGRAPH_SERIALNUM_PATTERN <- paste0(
    ".*Serial\\s*Number:",
    "\\s*([A-Za-z0-9]+)\\s*Start\\s*Time.*")
  sn = sub(ACTIGRAPH_SERIALNUM_PATTERN, "\\1", hdr)
  sn = trimws(sn)
  if (nchar(sn) > 20) {
    warning("Serial number does not seem to be parsed correctly, ",
            "dynamic range may be wrong")
  }
  at <- substr(sn, 1, 3)
  gr <- switch(at, MAT = "3", CLE = "6", MOS = "8", TAS = "8", NULL)
  if (grepl("IMU", hdr[[1]])) {
    gr <- "16"
  }
  gr = as.numeric(gr)
  gr = c(-gr, gr)
  if (length(gr) == 0) {
    gr = NULL
  }
  gr
}
