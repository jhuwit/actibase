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

  spike <- flag_spike(spike_df, spike_size = 11)
  expect_identical(spike$flag_spike, c(FALSE, TRUE, FALSE))
  expect_identical(attr(spike, "sample_rate"), 1)
  expect_identical(attr(spike, "dynamic_range"), c(-6, 6))

  second_df <- data.frame(
    time = base_time + rep(0, 12),
    X = c(rep(0, 4), rep(12, 4), rep(0, 4)),
    Y = 0,
    Z = 0
  )
  attr(second_df, "sample_rate") <- 12
  attr(second_df, "dynamic_range") <- c(-6, 6)

  spike_second <- flag_spike_second(second_df, spike_size = 11)
  expect_true(all(spike_second$flag_spike_second))
  expect_identical(attr(spike_second, "sample_rate"), 12)
  expect_identical(attr(spike_second, "dynamic_range"), c(-6, 6))

  device_df <- data.frame(
    time = base_time + 0:2,
    X = c(-6, 5.94, 5.96),
    Y = c(0, 0, 0),
    Z = c(0, 0, 0)
  )
  attr(device_df, "dynamic_range") <- c(-6, 6)

  device <- flag_device_limit(device_df, epsilon = 0.05)
  expect_identical(device$flag_device_limit, c(TRUE, FALSE, TRUE))

  contiguous <- flag_contiguous_device_limit(device_df, epsilon = 0.05)
  expect_identical(contiguous$flag_contiguous_device_limit, c(FALSE, FALSE, FALSE))

  preflagged <- device
  preflagged$flag_device_limit <- c(FALSE, TRUE, TRUE)
  contiguous_preflagged <- flag_contiguous_device_limit(preflagged)
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
  same <- flag_same_value(same_df, min_length = 3)
  expect_identical(same$flag_same_value, c(FALSE, TRUE, TRUE, TRUE, FALSE))

  zero_df <- data.frame(
    time = base_time + 0:4,
    X = c(1, 2, 0, 0, 0),
    Y = c(1, 2, 0, 0, 0),
    Z = c(1, 2, 0, 0, 0)
  )
  zero <- flag_all_zero(zero_df, min_length = 3)
  expect_identical(zero$flag_all_zero, c(FALSE, FALSE, TRUE, TRUE, TRUE))

  impossible_df <- data.frame(
    time = base_time + 0:6,
    X = c(rep(0, 6), 2),
    Y = c(rep(1.3, 6), 0.5),
    Z = c(rep(0.5, 6), 0.5)
  )
  impossible <- flag_impossible(impossible_df, min_length = 6)
  expect_identical(
    impossible$flag_impossible,
    c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE)
  )
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

  flagged <- suppressMessages(flag_interval_jump(data, verbose = TRUE))
  expect_true(all(flagged$flag_interval_jump))
  expect_identical(flagged$time, data$time)
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

  qc_all <- expect_warning(
    flag_qc_all(qc_df, verbose = FALSE, flags = "all"),
    "Data has columns starting with flag"
  )
  expect_true(all(startsWith(names(qc_all), "flag_") | names(qc_all) %in% c("time", "X", "Y", "Z")))
  expect_true(any(grepl("^flagging_data:", attr(qc_all, "transformations"))))

  suppressWarnings(
    suppressMessages(
      flag_qc_all(qc_df, verbose = TRUE, flags = "all")
    )
  )

  qc <- flag_qc(qc_df, verbose = FALSE)
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
})
