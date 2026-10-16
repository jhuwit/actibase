# Legacy overlay helpers.
# These functions are kept out of the exported actibase baseline API on
# purpose. Move them into a downstream overlay package if they are still
# needed.

parse_flag_time = function(time) {
  if (is.character(time) || is.factor(time)) {
    time = suppressWarnings(as.POSIXct(as.character(time), tz = "UTC"))
  }
  time
}

is_sample_adjacent = function(time, sample_rate = NULL, tolerance = 0.002) {
  if (is.null(sample_rate) || length(sample_rate) != 1L ||
      !is.finite(sample_rate) || sample_rate <= 0) {
    stop("A positive `sample_rate` is required to check timestamp continuity.", call. = FALSE)
  }
  time = parse_flag_time(time)
  if (is.null(time) || length(time) < 2L) return(logical(max(0L, length(time) - 1L)))
  delta = as.numeric(diff(time))
  !is.na(delta) & abs(delta - 1 / sample_rate) <= tolerance
}

mark_sample_runs = function(condition, min_length, time = NULL,
                            sample_rate = NULL) {
  if (is.null(time) || length(condition) < 2L) {
    return(mark_condition(condition, min_length = min_length))
  }
  adjacent = is_sample_adjacent(time, sample_rate = sample_rate)
  segment = cumsum(c(TRUE, !adjacent))
  out = condition
  for (i in unique(segment)) {
    idx = which(segment == i)
    out[idx] = mark_condition(condition[idx], min_length = min_length)
  }
  out
}

#' Flag Spikes
#'
#' @param data A data set of actigraphy
#' @param spike_size size of "spike" - which is the absolute difference
#' in contiguous observations on a single axis
#' @param by_axis If `TRUE`, also return one spike indicator per axis.
#'
#' @return A data set back
#' @details These functions provide configurable sample-level and window-level
#'   signal indicators. Thresholds and run or window lengths are arguments;
#'   they do not encode a specific device or study's quality-control scheme.
#'   When continuity is checked, `sample_rate` is extracted with
#'   `get_sample_rate()` unless supplied explicitly.
#' @export
#'
#' @examples
#' res = acti_raw_data
#' res = acti_flag_spike(res)
#' res = acti_flag_interval_jump(res)
#' res = acti_flag_spike_second(res)
#' res = acti_flag_same_value(res)
#' res = acti_flag_device_limit(res)
#' res = acti_flag_all_zero(res)
#' res = acti_flag_impossible(res)
acti_flag_spike = function(data, spike_size = 11, sample_rate = NULL,
                      by_axis = FALSE) {
  X = Y = Z = NULL
  rm(list = c("X", "Y", "Z"))

  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  adjacent = if ("time" %in% names(data) && !is.null(sample_rate)) {
    is_sample_adjacent(data$time, sample_rate = sample_rate)
  } else {
    rep(TRUE, max(0L, nrow(data) - 1L))
  }
  axis_flags = lapply(c("X", "Y", "Z"), function(axis) {
    values = data[[axis]]
    c(FALSE, abs(diff(values)) >= spike_size) & c(FALSE, adjacent)
  })
  names(axis_flags) = c("X", "Y", "Z")
  data$flag_spike = Reduce(`|`, axis_flags)
  if (isTRUE(by_axis)) {
    for (axis in names(axis_flags)) {
      data[[paste0("flag_spike_", axis)]] = axis_flags[[axis]]
    }
  }
  data
}


#' @export
#' @rdname acti_flag_spike
#' @param verbose print diagnostic messages
#' @param min_repeats Minimum occurrences of an axis value in a window.
#' @param min_distinct Minimum number of frequent axis values required.
#' @param min_separation Minimum separation between retained values.
#' @param by_axis If `TRUE`, also return a separate indicator for each axis.
#' @param digits Number of decimal places used when grouping axis values.
#' @param chunk_windows Number of windows processed together to bound memory.
acti_flag_interval_jump = function(data, verbose = FALSE, window_seconds = 1,
                              min_repeats = 10, min_distinct = 3,
                              min_separation = 0.5, by_axis = FALSE,
                              digits = 3, chunk_windows = 50000L) {
  value = window = NULL
  rm(list = c("value", "window"))
  data = acti_standardize_data(data, subset_xyz = FALSE)
  if (!"time" %in% names(data)) {
    stop("`time` is required for interval-jump windows.", call. = FALSE)
  }
  time = parse_flag_time(data$time)
  if (!length(time) || anyNA(time)) {
    stop("`time` must contain a valid timestamp for every sample.", call. = FALSE)
  }
  if (is.unsorted(time, strictly = FALSE)) {
    stop("Samples must be ordered by `time`.", call. = FALSE)
  }
  if (window_seconds <= 0 || min_repeats < 1 || min_distinct < 2 ||
      min_separation < 0 || digits < 0 || chunk_windows < 1) {
    stop("Interval-jump parameters are outside their valid ranges.", call. = FALSE)
  }

  n = nrow(data)
  if (!n) {
    data$flag_interval_jump = logical()
    return(data)
  }
  origin = min(time)
  window_id = floor(as.numeric(difftime(time, origin, units = "secs")) /
                      window_seconds)
  starts = c(1L, which(diff(window_id) != 0) + 1L)
  ends = c(starts[-1L] - 1L, n)
  n_windows = length(starts)
  per_axis = matrix(FALSE, nrow = n_windows, ncol = 3L,
                    dimnames = list(NULL, c("X", "Y", "Z")))

  # Count one axis at a time in bounded chunks. This avoids expanding the raw
  # table to three times its size before grouping.
  window_values = unique(window_id)
  chunk_starts = seq.int(1L, n_windows, by = as.integer(chunk_windows))
  for (axis in colnames(per_axis)) {
    axis_index = match(axis, colnames(per_axis))
    axis_values = data[[axis]]
    for (chunk in seq_along(chunk_starts)) {
      first_window = chunk_starts[chunk]
      last_window = min(n_windows, first_window + as.integer(chunk_windows) - 1L)
      row_idx = starts[first_window]:ends[last_window]
      values = round(axis_values[row_idx], digits = digits)
      counts = dplyr::tibble(window = window_id[row_idx], value = values) %>%
        dplyr::filter(!is.na(value)) %>%
        dplyr::count(window, value, name = "n") %>%
        dplyr::filter(n >= min_repeats) %>%
        dplyr::arrange(window, dplyr::desc(n), value) %>%
        dplyr::group_by(window) %>%
        dplyr::slice_head(n = min_distinct) %>%
        dplyr::summarise(
          flag = dplyr::n() == min_distinct &&
            all(diff(sort(value)) >= min_separation),
          .groups = "drop"
        )
      if (nrow(counts)) {
        target = match(counts$window, window_values)
        per_axis[target, axis_index] = counts$flag
      }
      if (verbose) {
        message("Processed ", axis, " windows ", last_window, " of ", n_windows)
      }
    }
  }

  sample_window = match(window_id, unique(window_id))
  axis_flags = lapply(seq_len(ncol(per_axis)), function(j) {
    per_axis[sample_window, j]
  })
  names(axis_flags) = colnames(per_axis)
  data$flag_interval_jump = Reduce(`|`, axis_flags)
  if (isTRUE(by_axis)) {
    for (axis in names(axis_flags)) {
      data[[paste0("flag_interval_jump_", axis)]] = axis_flags[[axis]]
    }
  }
  data
}

#' @export
#' @rdname acti_flag_spike
#' @param window_seconds Width of each window used by `acti_flag_spike_second`.
#' @param min_spikes Minimum number of qualifying extrema in a window.
#' @param max_change_seconds Maximum time between an extremum and a qualifying
#'   large change; the CDC rule uses less than 0.1 seconds.
#' @param sample_rate Sampling frequency; extracted from data when omitted.
#' @param by_axis If `TRUE`, also return one indicator per axis.
#' @note `acti_flag_spike` compares adjacent observations by axis. The
#'   `acti_flag_spike_second` checks for repeated local extrema followed by a large
#'   change within the requested time, then counts them within each window.
acti_flag_spike_second = function(data, spike_size = 11, window_seconds = 1,
                             min_spikes = 13, max_change_seconds = 0.1,
                             sample_rate = NULL, by_axis = FALSE) {
  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  dynamic_range = attr(data, "dynamic_range")
  if (!"time" %in% names(data)) {
    stop("`time` is required for time-window spike checks.", call. = FALSE)
  }
  time = parse_flag_time(data$time)
  if (length(time) != nrow(data) || anyNA(time)) {
    stop("`time` must contain a valid timestamp for every sample.", call. = FALSE)
  }
  if (is.unsorted(time, strictly = FALSE)) {
    stop("Samples must be ordered by `time`.", call. = FALSE)
  }
  if (window_seconds <= 0 || min_spikes < 1 || max_change_seconds <= 0) {
    stop("Window and spike parameters must be positive.", call. = FALSE)
  }

  n = nrow(data)
  if (!n) {
    data$flag_spike_second = logical()
    return(data)
  }
  origin = min(time)
  window_id = floor(as.numeric(difftime(time, origin, units = "secs")) /
                      window_seconds)
  adjacent = is_sample_adjacent(time, sample_rate)
  segment = cumsum(c(TRUE, !adjacent))
  max_offset = min(n - 1L, max(0L, ceiling(sample_rate * max_change_seconds) - 1L))
  axis_flags = stats::setNames(vector("list", 3L), c("X", "Y", "Z"))

  for (axis in names(axis_flags)) {
    x = data[[axis]]
    event = rep(FALSE, n)
    if (n >= 3L && max_offset >= 1L) {
      # Use the usual centered definition for local extrema.
      local_max = rep(FALSE, n)
      local_min = rep(FALSE, n)
      ii = 2:(n - 1L)
      local_max[ii] = adjacent[ii - 1L] & adjacent[ii] &
        !is.na(x[ii - 1L]) & !is.na(x[ii]) & !is.na(x[ii + 1L]) &
        x[ii] >= x[ii - 1L] & x[ii] > x[ii + 1L]
      local_min[ii] = adjacent[ii - 1L] & adjacent[ii] &
        !is.na(x[ii - 1L]) & !is.na(x[ii]) & !is.na(x[ii + 1L]) &
        x[ii] <= x[ii - 1L] & x[ii] < x[ii + 1L]
      extrema = which(local_max | local_min)
      if (length(extrema)) {
        for (offset in seq_len(max_offset)) {
          idx = extrema[extrema + offset <= n]
          if (!length(idx)) next
          next_idx = idx + offset
          fast = as.numeric(difftime(time[next_idx], time[idx], units = "secs")) <
            max_change_seconds
          continuous = segment[idx] == segment[next_idx]
          rise_from_min = local_min[idx] & (x[next_idx] - x[idx] >= spike_size)
          fall_from_max = local_max[idx] & (x[idx] - x[next_idx] >= spike_size)
          hit = fast & continuous & (rise_from_min | fall_from_max)
          event[idx[hit]] = TRUE
        }
      }
    }
    event_window = unique(window_id)
    event_count = tabulate(match(window_id[event], event_window),
                           nbins = length(event_window))
    axis_flags[[axis]] = event_count[match(window_id, event_window)] >= min_spikes
  }
  data$flag_spike_second = axis_flags$X | axis_flags$Y | axis_flags$Z
  if (isTRUE(by_axis)) {
    for (axis in names(axis_flags)) {
      data[[paste0("flag_spike_second_", axis)]] = axis_flags[[axis]]
    }
  }
  attr(data, "sample_rate") = sample_rate
  attr(data, "dynamic_range") = dynamic_range
  data
}

#' @export
#' @rdname acti_flag_spike
#' @param dynamic_range dynamic range of the device, used to find the
#' device limit.
#' @param epsilon A small adjustment so that if values are within the
#' device limit, but minus epsilon, still flagged as hitting the limit.
#' For example, if `dynamic_range = c(-6, 6)` and `epsilon = 0.05`, then any
#' value <= `-5.95` or `>= 5.95` gravity units will be flagged
acti_flag_device_limit = function(data, dynamic_range = NULL, epsilon = 0.05) {
  # #2 and #3
  # Maximum gravity values on the x-, y-, or z-axis: Any value greater than
  # 5.95 g is deemed as near or above the maximum g value measured by the
  # device (i.e., +6g);

  dynamic_range = get_dynamic_range(data, dynamic_range)
  limit = max(abs(dynamic_range)) - epsilon

  X = Y = Z = NULL
  rm(list = c("X", "Y", "Z"))

  data = acti_standardize_data(data, subset_xyz = FALSE)
  data = data %>%
    dplyr::mutate(
      flag_device_limit =
        abs(X) >= limit |
        abs(Y) >= limit |
        abs(Z) >= limit
    )
  data
}

#' @rdname acti_flag_spike
#' @export
acti_flag_adjacent_device_limit_samples = function(data, dynamic_range = NULL,
                                                   epsilon = 0.05,
                                                   sample_rate = NULL) {
  # #1
  flag_device_limit = X = Y = Z = NULL
  rm(list = c("X", "Y", "Z", "flag_device_limit"))

  if (!"flag_device_limit" %in% colnames(data)) {
    data = acti_flag_device_limit(data, dynamic_range = dynamic_range, epsilon = epsilon)
  } else {
    data = acti_standardize_data(data, subset_xyz = FALSE)
  }
  sample_rate = get_sample_rate(data, sample_rate)
  adjacent = if ("time" %in% names(data)) {
    is_sample_adjacent(data$time, sample_rate)
  } else {
    rep(TRUE, max(0L, nrow(data) - 1L))
  }
  data = data %>%
    dplyr::mutate(
      flag_adjacent_device_limit_samples = flag_device_limit &
        ((c(FALSE, adjacent) & dplyr::lag(flag_device_limit, default = FALSE)) |
         (c(adjacent, FALSE) & dplyr::lead(flag_device_limit, default = FALSE)))
    )
  data
}

#' @rdname acti_flag_spike
#' @export
acti_flag_contiguous_device_limit = function(data, dynamic_range = NULL,
                                             epsilon = 0.05,
                                             sample_rate = NULL) {
  data = acti_flag_adjacent_device_limit_samples(
    data, dynamic_range = dynamic_range, epsilon = epsilon,
    sample_rate = sample_rate
  )
  data$flag_contiguous_device_limit = data$flag_adjacent_device_limit_samples
  data$flag_adjacent_device_limit_samples = NULL
  data
}



#' @export
#' @rdname acti_flag_spike
#' @param min_length minimum length of the condition for contiguous
#' samples. If `min_length = 7`, then at least 7 `TRUE`s in a row is required,
#' any stretches of single `TRUE` values or 2 `TRUE` followed by `FALSE`,
#' will be set to `FALSE`.
acti_flag_same_value = function(data, min_length = 1, sample_rate = NULL) {
  # #6
  # Contiguous adjacent identical non-zero values on the x-, y-, or z-axis:
  # all three axes are equal and contiguous but not zeros
  # (contiguous adjacent measures can continue between minutes, hours, or days);

  # NOTE! we do not check that these values are non-zero

  same_value = X = Y = Z = NULL
  rm(list = c("X", "Y", "Z", "same_value"))

  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  dynamic_range = attr(data, "dynamic_range")
  data = data %>%
    dplyr::mutate(
      flag_same_value =
        c(1, diff(X)) == 0 &
        c(1, diff(Y)) == 0 &
        c(1, diff(Z)) == 0
    )
  data$flag_same_value = mark_sample_runs(data$flag_same_value,
    min_length = min_length, time = if ("time" %in% names(data)) data$time else NULL,
    sample_rate = sample_rate)
  attr(data, "sample_rate") = sample_rate
  attr(data, "dynamic_range")   = dynamic_range
  data
}

#' @export
#' @rdname acti_flag_spike
acti_flag_all_zero = function(data, min_length = 3, sample_rate = NULL) {
  # #5
  # Contiguous adjacent zero values on the x-, y-, and z-axis: 3 or more
  # contiguous measures are zero on all three axes (contiguous measure
  # can continue between minutes, hours, or days);

  all_zero = X = Y = Z = NULL
  rm(list = c("X", "Y", "Z", "all_zero"))

  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  dynamic_range = attr(data, "dynamic_range")
  data = data %>%
    dplyr::mutate(
      flag_all_zero = X == 0 & Y == 0 & Z == 0
    )
  data$flag_all_zero = mark_sample_runs(data$flag_all_zero,
    min_length = min_length, time = if ("time" %in% names(data)) data$time else NULL,
    sample_rate = sample_rate)
  attr(data, "sample_rate") = sample_rate
  attr(data, "dynamic_range")   = dynamic_range
  data
}


#' @export
#' @rdname acti_flag_spike
#' @param change_threshold Maximum absolute change between adjacent samples
#'   on each axis for a stable run to qualify. The default is 0.01 g.
#' @param magnitude_threshold Minimum vector magnitude required at both ends
#'   of each stable adjacent pair. The default is 1.25 g.
#' @param dynamic_range Device dynamic range. When omitted, it is read from the
#'   data with `get_dynamic_range()`; data-based estimates are rejected.
acti_flag_impossible = function(data, min_length = 7, change_threshold = 0.01,
                           magnitude_threshold = 1.25, sample_rate = NULL,
                           dynamic_range = NULL) {
  # #4
  # CDC's P rule requires at least seven contiguous samples. A run of seven
  # samples has six qualifying adjacent pairs.


  X = Y = Z = NULL
  rm(list = c("X", "Y", "Z"))
  dynamic_range = suppressWarnings(get_dynamic_range(
    data, dynamic_range = dynamic_range, flag_estimated = TRUE
  ))
  if (isTRUE(attr(dynamic_range, "estimated"))) {
    stop("Supply `dynamic_range` or attach it to `data` before flagging impossible gravity.",
         call. = FALSE)
  }
  if (!is.numeric(dynamic_range) || length(dynamic_range) != 2L || anyNA(dynamic_range) ||
      any(!is.finite(dynamic_range))) {
    stop("`dynamic_range` must contain two finite values.", call. = FALSE)
  }
  max_abs_value = max(abs(dynamic_range))
  if (max_abs_value <= 0) {
    stop("`dynamic_range` must include a non-zero boundary.", call. = FALSE)
  }
  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  if (min_length < 2) stop("`min_length` must be at least 2 samples.", call. = FALSE)
  n = nrow(data)
  flag = rep(FALSE, n)
  if (n > 1L) {
    magnitude = sqrt(data$X^2 + data$Y^2 + data$Z^2)
    below_saturation = abs(data$X) < max_abs_value &
      abs(data$Y) < max_abs_value & abs(data$Z) < max_abs_value
    stable_pair = abs(diff(data$X)) < change_threshold &
      abs(diff(data$Y)) < change_threshold & abs(diff(data$Z)) < change_threshold &
      magnitude[-1L] > magnitude_threshold & magnitude[-n] > magnitude_threshold &
      below_saturation[-1L] & below_saturation[-n]
    if ("time" %in% names(data)) {
      stable_pair = stable_pair & is_sample_adjacent(data$time, sample_rate)
    }
    stable_pair[is.na(stable_pair)] = FALSE
    stable_pair = mark_condition(stable_pair, min_length = min_length - 1L)
    # A run of k stable adjacent pairs represents k + 1 raw samples.
    flag = c(stable_pair, FALSE) | c(FALSE, stable_pair)
  }
  data$flag_impossible = flag
  data
}

#' Flag contiguous device-limit runs
#'
#' Marks axis-specific positive and negative device-limit samples in runs
#' meeting `min_length`. Runs are broken at timestamp gaps based on the
#' extracted or supplied sampling rate.
#' @param data Raw accelerometer data.
#' @param dynamic_range Device range; inferred when omitted.
#' @param epsilon Margin inside the device limit, in g.
#' @param min_length Minimum run length.
#' @param sample_rate Sampling frequency; extracted from data when omitted.
#' @return Input data with six axis- and sign-specific contiguous run columns.
#' @export
acti_flag_contiguous_device_limit_runs = function(data, dynamic_range = NULL,
                                                  epsilon = 0.05,
                                                  min_length = 1,
                                                  sample_rate = NULL) {
  data = acti_standardize_data(data, subset_xyz = FALSE)
  if (!"time" %in% names(data)) stop("Raw data must contain timestamps.", call. = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  data$time = parse_flag_time(data$time)
  dynamic_range = get_dynamic_range(data, dynamic_range)
  limit = max(abs(dynamic_range)) - epsilon
  conditions = list(
    max_X = data$X > limit, max_Y = data$Y > limit, max_Z = data$Z > limit,
    min_X = data$X < -limit, min_Y = data$Y < -limit, min_Z = data$Z < -limit
  )
  for (condition in names(conditions)) {
    data[[paste0("flag_contiguous_", condition)]] <- mark_sample_runs(
      conditions[[condition]], min_length, time = data$time, sample_rate = sample_rate
    )
  }
  data
}

#' @rdname acti_flag_contiguous_device_limit_runs
#' @export
acti_flag_contiguous_device_limits = function(data, dynamic_range = NULL,
                                              epsilon = 0.05, min_length = 1,
                                              sample_rate = NULL) {
  acti_flag_contiguous_device_limit_runs(
    data, dynamic_range = dynamic_range, epsilon = epsilon,
    min_length = min_length, sample_rate = sample_rate
  )
}

#' Flag device-limit counts within time windows
#'
#' Groups samples into fixed-duration windows from the first timestamp,
#' counts values at the positive and negative device limits on each axis, and
#' compares each count with `min_count`.
#' @param data Raw accelerometer samples with a timestamp column.
#' @param dynamic_range Device range; inferred when omitted.
#' @param epsilon Margin inside the device limit, in g.
#' @param min_count Minimum number of samples required within a window.
#' @param window_seconds Window duration in seconds.
#' @return One row per window with axis-specific flags.
#' @export
acti_flag_device_limit_windows = function(data, dynamic_range = NULL,
                                    epsilon = 0.05, min_count = 1,
                                    window_seconds = 60) {
  time = NULL
  rm(list = c("time"))
  data = acti_standardize_data(data, subset_xyz = FALSE)
  if (!"time" %in% names(data)) stop("Raw data must contain timestamps.", call. = FALSE)
  data$time = parse_flag_time(data$time)
  dynamic_range = get_dynamic_range(data, dynamic_range)
  limit = max(abs(dynamic_range)) - epsilon
  origin = min(data$time, na.rm = TRUE)
  window = origin + floor(as.numeric(difftime(data$time, origin,
                                               units = "secs")) / window_seconds) * window_seconds
  out = data.frame(time = window)
  out$flag_device_max_X <- data$X > limit
  out$flag_device_max_Y <- data$Y > limit
  out$flag_device_max_Z <- data$Z > limit
  out$flag_device_min_X <- data$X < -limit
  out$flag_device_min_Y <- data$Y < -limit
  out$flag_device_min_Z <- data$Z < -limit
  out = dplyr::as_tibble(out) %>%
    dplyr::group_by(time) %>%
    dplyr::summarise(dplyr::across(dplyr::starts_with("flag_"),
      ~ sum(.x, na.rm = TRUE) >= min_count), .groups = "drop")
  out
}

#' Flag periods adjacent to invalid periods
#'
#' Marks the previous and next observed periods when their timestamps are
#' exactly `window_seconds` apart. Groups are evaluated independently.
#' @param data Minute-level summary data.
#' @param invalid Logical vector identifying invalid periods.
#' @param time Name of the timestamp column.
#' @param window_seconds Expected duration between adjacent periods.
#' @param group Optional grouping column name(s).
#' @return Input data with `flag_adjacent_invalid`.
#' @export
acti_flag_adjacent_invalid_periods = function(data, invalid, time = "time",
                                        window_seconds, group = NULL) {
  if (length(invalid) != nrow(data)) stop("`invalid` must match the number of rows.", call. = FALSE)
  invalid[is.na(invalid)] = FALSE
  if (!time %in% names(data)) stop("`time` column not found.", call. = FALSE)
  if (missing(window_seconds) || length(window_seconds) != 1L ||
      !is.finite(window_seconds) || window_seconds <= 0) stop("Supply positive `window_seconds`.", call. = FALSE)
  timestamp = parse_flag_time(data[[time]])
  order_cols = c(group, time)
  order_cols = order_cols[order_cols %in% names(data)]
  ord = do.call(order, c(data[order_cols], list(na.last = TRUE)))
  flag = logical(nrow(data))
  groups = if (is.null(group)) rep("1", nrow(data)) else interaction(data[group], drop = TRUE)
  for (i in seq_along(ord)) {
    row = ord[[i]]
    if (!invalid[[row]]) next
    if (i > 1L) {
      prev = ord[[i - 1L]]
      consecutive = !is.na(timestamp[row]) && !is.na(timestamp[prev]) &&
        as.numeric(difftime(timestamp[row], timestamp[prev], units = "secs")) == window_seconds
      if (groups[row] == groups[prev] && consecutive) flag[[prev]] = TRUE
    }
    if (i < length(ord)) {
      nxt = ord[[i + 1L]]
      consecutive = !is.na(timestamp[row]) && !is.na(timestamp[nxt]) &&
        as.numeric(difftime(timestamp[nxt], timestamp[row], units = "secs")) == window_seconds
      if (groups[row] == groups[nxt] && consecutive) flag[[nxt]] = TRUE
    }
  }
  data$flag_adjacent_invalid = flag
  data
}

#' Flag repeated samples
#'
#' Marks samples in runs of repeated three-axis observations. Options can
#' exclude all-zero observations or require equal values across the three
#' axes. Timestamp gaps break runs based on the supplied or extracted rate.
#' @param data Raw accelerometer data.
#' @param sample_rate Sampling frequency; extracted from data when omitted.
#' @param min_length Minimum repeated run length in samples.
#' @param exclude_zero Exclude samples where all axes are zero.
#' @param require_equal_axes Require all axes to have equal values.
#' @return Input data with `flag_repeated_samples`.
#' @export
acti_flag_repeated_samples = function(data, sample_rate = NULL, min_length = 2,
                                 exclude_zero = FALSE,
                                 require_equal_axes = FALSE) {
  data = acti_standardize_data(data, subset_xyz = FALSE)
  sample_rate = get_sample_rate(data, sample_rate)
  same = rep(FALSE, nrow(data))
  if (nrow(data) > 1L) {
    idx = 2:nrow(data)
    pair = data$X[idx] == data$X[idx - 1L] &
      data$Y[idx] == data$Y[idx - 1L] & data$Z[idx] == data$Z[idx - 1L] &
      (!require_equal_axes | (data$X[idx] == data$Y[idx] & data$Y[idx] == data$Z[idx])) &
      (!exclude_zero | (data$X[idx] != 0 | data$Y[idx] != 0 | data$Z[idx] != 0))
    if ("time" %in% names(data)) pair = pair & is_sample_adjacent(data$time, sample_rate)
    pair[is.na(pair)] = FALSE
    same = c(pair, FALSE) | c(FALSE, pair)
  }
  data$flag_repeated_samples = mark_sample_runs(same, min_length = min_length,
    time = data$time, sample_rate = sample_rate)
  data
}

#' Label quality flags with CDC NHANES letters
#'
#' Creates a character column containing the CDC letter codes corresponding
#' to TRUE package flag columns. Multiple codes are concatenated in
#' alphabetical order. The default map expects axis-specific columns where
#' the package provides them; run the relevant detector with `by_axis = TRUE`
#' for spikes and interval jumps. The helper maps existing results and does
#' not run any flag detector.
#'
#' @param data Data containing logical flag columns.
#' @param flag_map Named character vector mapping CDC letters to column names.
#'   Defaults to the package's axis-specific flag names and uses the mapped
#'   columns present in `data`, allowing a selected subset of detectors. A
#'   custom map must refer to existing columns.
#' @param output Name of the output column.
#' @param separator String inserted between multiple letters. Use `""` for
#'   CDC-style compact values such as `"ABP"`.
#' @return Input data with a character column of CDC-style flag letters.
#' @export
acti_flag_cdc_labels = function(data, flag_map = c(
    A = "flag_spike_X", B = "flag_spike_Y", C = "flag_spike_Z",
    D = "flag_device_max_X", E = "flag_device_max_Y", F = "flag_device_max_Z",
    G = "flag_device_min_X", H = "flag_device_min_Y", I = "flag_device_min_Z",
    J = "flag_contiguous_max_X", K = "flag_contiguous_max_Y",
    L = "flag_contiguous_max_Z", M = "flag_contiguous_min_X",
    N = "flag_contiguous_min_Y", O = "flag_contiguous_min_Z",
    P = "flag_impossible", Q = "flag_all_zero", R = "flag_repeated_samples",
    S = "flag_spike_second_X", T = "flag_spike_second_Y",
    U = "flag_spike_second_Z", V = "flag_adjacent_invalid",
    W = "flag_interval_jump_X", X = "flag_interval_jump_Y",
    Y = "flag_interval_jump_Z"), output = "PAXFLGSM", separator = "") {
  default_map = missing(flag_map)
  if (!is.character(flag_map) || is.null(names(flag_map)) ||
      anyNA(flag_map) || any(!nzchar(names(flag_map))) || anyDuplicated(names(flag_map))) {
    stop("`flag_map` must be a named character vector with unique letter names.",
         call. = FALSE)
  }
  if (default_map) {
    flag_map = flag_map[unname(flag_map) %in% names(data)]
  }
  missing_columns = setdiff(unname(flag_map), names(data))
  if (length(missing_columns)) {
    stop("Missing flag columns: ", paste(missing_columns, collapse = ", "),
         ". Run the corresponding flag functions first, using `by_axis = TRUE` where supported.",
         call. = FALSE)
  }
  if (!all(vapply(data[unname(flag_map)], is.logical, logical(1)))) {
    stop("Mapped flag columns must be logical.", call. = FALSE)
  }
  flag_map = flag_map[order(names(flag_map))]
  labels = vapply(seq_len(nrow(data)), function(i) {
    hit = vapply(unname(flag_map), function(column) {
      value = data[[column]][i]
      !is.na(value) && value
    }, logical(1))
    paste(names(flag_map)[hit], collapse = separator)
  }, character(1))
  data[[output]] = labels
  data
}

#' Flag Quality Control Values
#'
#' @param data A data set of actigraphy
#' @param verbose print diagnostic messages
#' @param dynamic_range dynamic range of the device, used to find the
#' device limit.
#' @param flags the flags to run for QC.  If you set this to \code{"all"},
#' then all flags are run, as the default.
#'
#' @return A data set with a `flags` column (`acti_flag_qc`) or a number of
#' columns starting with `flag_*` (`acti_flag_qc_all`)
#' @export
#'
#' @examples
#' res = acti_raw_data
#' out = acti_flag_qc(res)
acti_flag_qc = function(data, dynamic_range = NULL, verbose = TRUE,
                   flags = c("all", "spike", "interval_jump",
                             "spike_second",
                             "same_value", "device_limit",
                             "all_zero", "impossible")
){
  data = acti_flag_qc_all(data, dynamic_range, verbose, flags = flags)
  transformations = get_transformations(data)
  transforms = NULL
  is_acc = is.AccData(data)
  # nocov start
  if (is_acc) {
    hdr = data$header
    freq = data$freq
    filename = data$filename
    missingness = data$missingness
  }
  # nocov end
  data = acti_standardize_data(data, subset_xyz = FALSE)
  data$flags = rowSums(
    data %>%
      dplyr::select(dplyr::starts_with("flag_")) > 0
  )
  data = data %>%
    dplyr::select(-dplyr::starts_with("flag_"))

  transforms = "flags_aggregated"
  transformations = c(transforms, transformations)
  data = set_transformations(data, transformations = transformations, add = FALSE)

  # nocov start
  if (is_acc) {
    data = list(
      data = data,
      header = hdr,
      freq = freq,
      filename = filename,
      missingness = missingness
    )
    class(data) = "AccData"
  }
  # nocov end
  data
}

#' @rdname acti_flag_qc
#' @export
acti_flag_qc_all = function(data, dynamic_range = NULL, verbose = TRUE,
                       flags = c("all", "spike", "interval_jump",
                                 "spike_second",
                                 "same_value", "device_limit",
                                 "all_zero", "impossible")) {
  transformations = get_transformations(data)
  transforms = NULL
  is_acc = is.AccData(data)
  # nocov start
  if (is_acc) {
    hdr = data$header
    freq = data$freq
    filename = data$filename
    missingness = data$missingness
  }
  # nocov end
  data = acti_standardize_data(data, subset_xyz = FALSE)
  if (any(startsWith(colnames(data), "flag"))) {
    warning(paste0(
      "Data has columns starting with flag - may affect results",
      " and column will be removed"))
  }
  flags = match.arg(flags, several.ok = TRUE)
  flag_names = c("spike", "interval_jump",
                 "spike_second", "same_value", "device_limit",
                 "all_zero", "impossible")
  all_flags = flag_names %in% flags
  names(all_flags) = flag_names
  if ("all" %in% flags) {
    all_flags[!all_flags] = TRUE
  }
  # nocov start
  if (!any(all_flags)) {
    stop("No flags were identified, why are you running acti_flag_qc_all?")
  }
  # nocov end
  if (all_flags["spike"]) {
    if (verbose) {
      message("Flagging Spikes")
    }
    data = acti_flag_spike(data)
    transforms = c("acti_flag_spike", transforms)
  }
  if (all_flags["interval_jump"]) {
    if (verbose) {
      message("Flagging Interval Jumps")
    }
    data = acti_flag_interval_jump(data, verbose = verbose > 1)
    transforms = c("acti_flag_interval_jump", transforms)
  }
  if (all_flags["spike_second"]) {
    if (verbose) {
      message("Flagging Spikes at Second-level")
    }
    data = acti_flag_spike_second(data)
    transforms = c("acti_flag_spike_second", transforms)
  }
  if (all_flags["same_value"]) {
    if (verbose) {
      message("Flagging Repeated Values")
    }
    data = acti_flag_same_value(data)
    transforms = c("acti_flag_same_value", transforms)
  }
  if (all_flags["device_limit"]) {
    if (verbose) {
      message("Flagging Device Limit Values")
    }
    data = acti_flag_device_limit(data, dynamic_range = dynamic_range)
    transforms = c("acti_flag_device_limit", transforms)
  }
  if (all_flags["all_zero"]) {
    if (verbose) {
      message("Flagging Zero Values")
    }
    data = acti_flag_all_zero(data)
    transforms = c("acti_flag_all_zero", transforms)
  }
  if (all_flags["impossible"]) {
    if (verbose) {
      message("Flagging 'Impossible' Values")
    }
    data = acti_flag_impossible(data, dynamic_range = dynamic_range)
    transforms = c("acti_flag_impossible", transforms)
  }
  transforms = paste(transforms, collapse = ", ")
  transforms = paste0("flagging_data:", transforms)
  transformations = c(transforms, transformations)
  data = set_transformations(data, transformations = transformations, add = FALSE)

  # nocov start
  if (is_acc) {
    data = list(
      data = data,
      header = hdr,
      freq = freq,
      filename = filename,
      missingness = missingness
    )
    class(data) = "AccData"
  }
  # nocov end
  data
}
