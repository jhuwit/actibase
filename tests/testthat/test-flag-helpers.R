test_that("flag API functions use acti names and data as the first argument", {
  flag_functions <- c(
    "acti_flag_spike", "acti_flag_interval_jump", "acti_flag_spike_second",
    "acti_flag_device_limit", "acti_flag_contiguous_device_limit",
    "acti_flag_adjacent_device_limit_samples",
    "acti_flag_same_value", "acti_flag_all_zero", "acti_flag_impossible",
    "acti_flag_contiguous_device_limits", "acti_flag_contiguous_device_limit_runs",
    "acti_flag_device_limit_windows",
    "acti_flag_adjacent_invalid_periods", "acti_flag_repeated_samples",
    "acti_flag_qc", "acti_flag_qc_all"
  )
  expect_true(all(vapply(flag_functions, function(name) {
    identical(names(formals(get(name)))[1L], "data")
  }, logical(1))))
})

test_that("CDC flag labels support partial, missing, and custom flags", {
  data <- data.frame(
    flag_impossible = c(TRUE, FALSE, NA),
    flag_spike_X = c(TRUE, FALSE, FALSE),
    flag_all_zero = c(FALSE, TRUE, FALSE)
  )
  labelled <- acti_flag_cdc_labels(data)
  expect_identical(labelled$PAXFLGSM, c("AP", "Q", ""))

  custom <- acti_flag_cdc_labels(
    data,
    flag_map = c(B = "flag_impossible", A = "flag_spike_X"),
    output = "letters",
    separator = "+"
  )
  expect_identical(custom$letters, c("A+B", "", ""))
  expect_error(
    acti_flag_cdc_labels(data, flag_map = c(A = "not_a_flag")),
    "Missing flag columns"
  )
  expect_error(
    acti_flag_cdc_labels(transform(data, flag_spike_X = as.integer(flag_spike_X))),
    "must be logical"
  )
})

test_that("flag helpers set expected indicators and preserve metadata", {
  base_time <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC")

  spike_df <- data.frame(
    time = base_time + 0:2,
    X = c(0, 12, 12),
    Y = c(0, 0, 0),
    Z = c(0, 0, 0)
  )
  attr(spike_df, "sample_rate") <- 1
  attr(spike_df, "dynamic_range") <- c(-6, 6)

  spike <- acti_flag_spike(spike_df, spike_size = 11, by_axis = TRUE)
  expect_identical(spike$flag_spike, c(FALSE, TRUE, FALSE))
  expect_identical(spike$flag_spike_X, c(FALSE, TRUE, FALSE))
  expect_false(any(spike$flag_spike_Y) || any(spike$flag_spike_Z))
  expect_identical(attr(spike, "sample_rate"), 1)
  expect_identical(attr(spike, "dynamic_range"), c(-6, 6))

  second_df <- data.frame(
    time = base_time + (0:79) / 80,
    X = rep(c(-6, 6), 40),
    Y = 0,
    Z = 0
  )
  attr(second_df, "sample_rate") <- 80
  attr(second_df, "dynamic_range") <- c(-6, 6)

  spike_second <- acti_flag_spike_second(second_df, spike_size = 11, by_axis = TRUE)
  expect_true(all(spike_second$flag_spike_second_X))
  expect_false(any(spike_second$flag_spike_second_Y) ||
                 any(spike_second$flag_spike_second_Z))
  expect_identical(attr(spike_second, "sample_rate"), 80)
  expect_identical(attr(spike_second, "dynamic_range"), c(-6, 6))

  fewer_spikes <- data.frame(
    time = base_time + (0:17) / 80,
    X = rep(c(0, 12, 0), 6), Y = 0, Z = 0
  )
  attr(fewer_spikes, "sample_rate") <- 80
  expect_false(any(acti_flag_spike_second(fewer_spikes)$flag_spike_second))

  lower_rate <- data.frame(
    time = base_time + (0:39) / 40,
    X = rep(c(-6, 6), 20), Y = 0, Z = 0
  )
  attr(lower_rate, "sample_rate") <- 40
  expect_true(all(acti_flag_spike_second(lower_rate)$flag_spike_second))

  device_df <- data.frame(
    time = base_time + 0:2,
    X = c(-6, 5.94, 5.96),
    Y = c(0, 0, 0),
    Z = c(0, 0, 0)
  )
  attr(device_df, "dynamic_range") <- c(-6, 6)

  device <- acti_flag_device_limit(device_df, epsilon = 0.05)
  expect_identical(device$flag_device_limit, c(TRUE, FALSE, TRUE))

  contiguous <- acti_flag_contiguous_device_limit(device_df, epsilon = 0.05)
  expect_identical(contiguous$flag_contiguous_device_limit, c(FALSE, FALSE, FALSE))
  adjacent <- acti_flag_adjacent_device_limit_samples(device_df, epsilon = 0.05)
  expect_identical(
    adjacent$flag_adjacent_device_limit_samples,
    contiguous$flag_contiguous_device_limit
  )

  preflagged <- device
  preflagged$flag_device_limit <- c(FALSE, TRUE, TRUE)
  contiguous_preflagged <- acti_flag_contiguous_device_limit(preflagged)
  expect_identical(
    contiguous_preflagged$flag_contiguous_device_limit,
    c(FALSE, TRUE, TRUE)
  )

  same_df <- data.frame(
    time = base_time + 0:4,
    X = c(1, 1, 1, 1, 2),
    Y = c(3, 3, 3, 3, 4),
    Z = c(5, 5, 5, 5, 6)
  )
  same <- acti_flag_same_value(same_df, min_length = 3)
  expect_identical(same$flag_same_value, c(FALSE, TRUE, TRUE, TRUE, FALSE))

  zero_df <- data.frame(
    time = base_time + 0:4,
    X = c(1, 2, 0, 0, 0),
    Y = c(1, 2, 0, 0, 0),
    Z = c(1, 2, 0, 0, 0)
  )
  zero <- acti_flag_all_zero(zero_df, min_length = 3)
  expect_identical(zero$flag_all_zero, c(FALSE, FALSE, TRUE, TRUE, TRUE))

  impossible_df <- data.frame(
    time = base_time + (0:7) / 80,
    X = c(rep(2, 7), 0),
    Y = c(rep(1.3, 7), 0.5),
    Z = c(rep(0.5, 7), 0.5)
  )
  impossible <- acti_flag_impossible(impossible_df, min_length = 7, sample_rate = 80,
                                dynamic_range = c(-6, 6))
  expect_identical(
    impossible$flag_impossible,
    c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE)
  )
  expect_identical(
    acti_flag_impossible(impossible_df, sample_rate = 80,
                    dynamic_range = c(-6, 6))$flag_impossible,
    impossible$flag_impossible
  )
  short_impossible <- impossible_df[1:6, ]
  expect_false(any(acti_flag_impossible(short_impossible, sample_rate = 80,
                                  dynamic_range = c(-6, 6))$flag_impossible))
  expect_error(acti_flag_impossible(impossible_df, sample_rate = 80), "dynamic_range")
  attr(impossible_df, "dynamic_range") <- c(-6, 6)
  expect_identical(
    acti_flag_impossible(impossible_df, sample_rate = 80)$flag_impossible,
    impossible$flag_impossible
  )

  saturated <- data.frame(
    time = base_time + (0:7) / 80,
    X = 6, Y = 0, Z = 0
  )
  expect_false(any(acti_flag_impossible(
    saturated, sample_rate = 80, dynamic_range = c(-6, 6)
  )$flag_impossible))
})

test_that("general flag helpers accept caller-supplied sampling and window norms", {
  time <- as.POSIXct("2020-01-01", tz = "UTC") + (0:319) / 80
  raw <- data.frame(time = time, X = 0, Y = 0, Z = 0)
  raw$Z[1:160] <- -5.96
  limit <- acti_flag_contiguous_device_limits(raw, dynamic_range = c(-6, 6),
                                         min_length = 160, sample_rate = 80)
  limit_runs <- acti_flag_contiguous_device_limit_runs(
    raw, dynamic_range = c(-6, 6), min_length = 160, sample_rate = 80
  )
  expect_identical(limit_runs, limit)
  expect_true(all(limit$flag_contiguous_min_Z[1:160]))
  expect_false(any(limit$flag_contiguous_min_Z[161:320]))

  minute_raw <- data.frame(
    time = as.POSIXct("2020-01-01", tz = "UTC") + rep(0:59, each = 80),
    X = 0, Y = 0, Z = 0
  )
  minute_raw$Y[1:690] <- 5.96
  limits <- acti_flag_device_limit_windows(minute_raw, dynamic_range = c(-6, 6),
                                      min_count = 690, window_seconds = 60)
  expect_true(limits$flag_device_max_Y)
  expect_false(limits$flag_device_max_X)

  minute <- data.frame(time = as.POSIXct("2020-01-01", tz="UTC") + 60*(0:3),
                       invalid = c(TRUE, FALSE, FALSE, TRUE))
  adjacent <- acti_flag_adjacent_invalid_periods(minute, minute$invalid,
                                             window_seconds = 60)
  expect_identical(adjacent$flag_adjacent_invalid, c(FALSE, TRUE, TRUE, FALSE))

  repeated <- data.frame(time = time[1:5], X = c(1, 1, 2, 2, 0),
                         Y = c(1, 1, 2, 2, 0), Z = c(1, 1, 3, 3, 0))
  repeated <- acti_flag_repeated_samples(repeated, sample_rate = 80,
                                    exclude_zero = TRUE, require_equal_axes = TRUE)
  expect_identical(repeated$flag_repeated_samples, c(TRUE, TRUE, FALSE, FALSE, FALSE))
})


test_that("contiguous checks break at missing sample times", {
  t <- as.POSIXct("2020-01-01", tz = "UTC") +
    c(0:3, 5:8) / 80
  stationary <- data.frame(time = t, X = 2, Y = 1.3, Z = 0.5)
  expect_false(any(acti_flag_impossible(stationary, min_length = 7,
                                  sample_rate = 80,
                                  dynamic_range = c(-6, 6))$flag_impossible))

  t <- as.POSIXct("2020-01-01", tz = "UTC") + c(0:79, 81:200) / 80
  extreme <- data.frame(time = t, X = 0, Y = 0, Z = 0)
  extreme$Z[c(1:80, 121:200)] <- -5.96
  flagged <- acti_flag_contiguous_device_limits(extreme, dynamic_range = c(-6, 6),
                                           min_length = 160, sample_rate = 80)
  expect_false(any(flagged$flag_contiguous_min_Z))

  repeated <- data.frame(
    time = as.POSIXct("2020-01-01", tz = "UTC") + c(0, 2) / 80,
    X = 1, Y = 1, Z = 1
  )
  expect_false(any(acti_flag_repeated_samples(repeated, sample_rate = 80,
    exclude_zero = TRUE, require_equal_axes = TRUE)$flag_repeated_samples))

  no_rate <- data.frame(X = 1, Y = 1, Z = 1)
  expect_error(acti_flag_repeated_samples(no_rate), "sample_rate")
})

test_that("flag_interval_jump detects repeated values within a second", {
  data <- data.frame(
    time = as.POSIXct(
      rep("2020-01-01 00:00:00", 30),
      tz = "UTC"
    ),
    X = rep(c(0, 1, 2), each = 10),
    Y = rep(0, 30),
    Z = rep(0, 30)
  )

  flagged <- suppressMessages(acti_flag_interval_jump(data, verbose = TRUE,
                                                   by_axis = TRUE))
  expect_true(all(flagged$flag_interval_jump))
  expect_true(all(flagged$flag_interval_jump_X))
  expect_false(any(flagged$flag_interval_jump_Y) ||
                 any(flagged$flag_interval_jump_Z))
  expect_identical(flagged$time, data$time)
  small_chunks <- suppressMessages(acti_flag_interval_jump(
    data, by_axis = TRUE, chunk_windows = 1L
  ))
  expect_identical(small_chunks$flag_interval_jump,
                   flagged$flag_interval_jump)
  expect_identical(small_chunks$flag_interval_jump_X,
                   flagged$flag_interval_jump_X)
})

test_that("contiguous flag helpers preserve missing observations", {
  time <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + 0:3
  data <- data.frame(
    time = time,
    X = c(0, NA, 0, 0),
    Y = c(0, 0, 0, 0),
    Z = c(0, 0, 0, 0)
  )

  zero <- acti_flag_all_zero(data, min_length = 2)
  expect_identical(zero$flag_all_zero, c(FALSE, NA, TRUE, TRUE))

  same <- data.frame(
    time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + 0:4,
    X = c(1, NA, 1, 1, 1), Y = 2, Z = 3
  )
  same <- acti_flag_same_value(same, min_length = 2)
  expect_identical(same$flag_same_value, c(FALSE, NA, NA, TRUE, TRUE))
})

test_that("flag QC helpers run every flag and retain labels", {
  qc_df <- data.frame(
    time = as.POSIXct(
      c(
        rep("2020-01-01 00:00:00", 12),
        rep("2020-01-01 00:00:01", 12)
      ),
      tz = "UTC"
    ),
    X = c(
      rep(c(0, 1, 2), each = 4),
      rep(c(0, 12, 12), each = 4)
    ),
    Y = c(
      rep(0, 12),
      rep(c(0, 0, 0), each = 4)
    ),
    Z = c(
      rep(0, 12),
      rep(c(0, 0, 0), each = 4)
    ),
    flag_manual = FALSE
  )
  attr(qc_df, "sample_rate") <- 12
  attr(qc_df, "dynamic_range") <- c(-6, 6)
  attr(qc_df, "transformations") <- "seed"

  expect_warning({
    qc_all <- acti_flag_qc_all(qc_df, verbose = FALSE, flags = "all")
    },
    "Data has columns starting with flag"
  )
  expect_true(all(startsWith(names(qc_all), "flag_") | names(qc_all) %in% c("time", "X", "Y", "Z")))
  expect_true(any(grepl("^flagging_data:", attr(qc_all, "transformations"))))

  suppressWarnings(
    suppressMessages(
      acti_flag_qc_all(qc_df, verbose = TRUE, flags = "all")
    )
  )

  qc <- acti_flag_qc(qc_df, verbose = FALSE)
  expect_true("flags" %in% names(qc))
  expect_false(any(startsWith(names(qc), "flag_")))
  expect_true(any(grepl("flags_aggregated", attr(qc, "transformations"))))

})

test_that("get_sample_rate handles header timestamp fallbacks", {
  header_time_df <- data.frame(
    HEADER_TIME_STAMP = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:10", "2020-01-01 00:00:20"),
      tz = "UTC"
    ),
    X = 1:3,
    Y = 4:6,
    Z = 7:9
  )
  expect_warning(
    expect_equal(actibase::get_sample_rate(header_time_df), 0.1),
    "Guessing sample_rate"
  )

  header_ts_df <- data.frame(
    HEADER_TIMESTAMP = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:02", "2020-01-01 00:00:04"),
      tz = "UTC"
    ),
    X = 1:3,
    Y = 4:6,
    Z = 7:9
  )
  expect_warning(
    expect_equal(actibase::get_sample_rate(header_ts_df), 0.5),
    "Guessing sample_rate"
  )

  fast_df <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:01", "2020-01-01 00:00:02"),
      tz = "UTC"
    ),
    X = 1:3,
    Y = 4:6,
    Z = 7:9
  )
  expect_warning(
    expect_equal(actibase::get_sample_rate(fast_df), 1),
    "Guessing sample_rate"
  )

  uneven_fast_df <- data.frame(
    time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + c(0, 0.01, 0.03),
    X = 1:3,
    Y = 4:6,
    Z = 7:9
  )
  warnings <- character()
  uneven_sample_rate <- withCallingHandlers(
    actibase::get_sample_rate(uneven_fast_df),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_equal(uneven_sample_rate, 75)
  expect_true(any(grepl("Guessing sample_rate", warnings)))
  expect_true(any(grepl("Multiple sample rates", warnings)))

  one_time <- fast_df[1, ]
  expect_error(actibase::get_sample_rate(one_time), "At least two")
  repeated_time <- fast_df[c(1, 1), ]
  expect_error(actibase::get_sample_rate(repeated_time), "distinct timestamps")
  missing_time <- fast_df
  missing_time$time[2] <- as.POSIXct(NA, tz = "UTC")
  expect_warning(expect_equal(actibase::get_sample_rate(missing_time), 0.5),
                 "Guessing sample_rate")

  irregular_minute <- data.frame(
    time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + c(0, 60, 180),
    X = 1:3, Y = 1:3, Z = 1:3
  )
  expect_warning(
    expect_equal(actibase::get_sample_rate(irregular_minute), mean(c(1 / 60, 1 / 120))),
    "Guessing sample_rate"
  )
})
