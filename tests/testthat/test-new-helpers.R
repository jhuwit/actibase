test_that("mark_condition keeps and drops contiguous runs as requested", {
  x <- c(FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE)

  expect_identical(actibase::mark_condition(x, min_length = 2), x)
  expect_identical(
    actibase::mark_condition(x, min_length = 4),
    c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )

  y <- c(FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, FALSE)
  expect_identical(
    actibase::mark_condition(y, min_length = 3),
    c(FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )

  expect_identical(actibase::mark_condition(rep(TRUE, 3), min_length = 5), rep(TRUE, 3))
  expect_identical(actibase::mark_condition(rep(FALSE, 3), min_length = 5), rep(FALSE, 3))
})

test_that("floor_sec handles date and datetime inputs", {
  expect_equal(
    actibase:::floor_sec(as.Date("2020-01-01")),
    as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
  )
  expect_equal(
    actibase:::floor_sec(as.POSIXct("2020-01-01 00:00:01.9", tz = "UTC")),
    as.POSIXct("2020-01-01 00:00:01", tz = "UTC")
  )
})

test_that("get_sample_rate prefers explicit values and falls back safely", {
  data <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:01", "2020-01-01 00:00:02"),
      tz = "UTC"
    ),
    X = 1:3,
    Y = 4:6,
    Z = 7:9
  )

  expect_equal(actibase::get_sample_rate(data, sample_rate = 80), 80)
  expect_error(actibase::get_sample_rate(data, sample_rate = "fast"))

  attr(data, "sample_rate") <- 25
  expect_equal(actibase::get_sample_rate(data), 25)

  attr(data, "sample_rate") <- NULL
  expect_warning(expect_equal(actibase::get_sample_rate(data), 1), "Guessing sample_rate")

  acc <- structure(
    list(
      data = data,
      header = data.frame(Field = character(), Value = character()),
      original_header = NULL
    ),
    class = "AccData"
  )
  acc$freq <- 32
  expect_equal(actibase::get_sample_rate(acc), 32)
})

test_that("get_dynamic_range extracts header and attribute values", {
  data <- data.frame(
    X = c(-1.5, 2.5),
    Y = c(-2.5, 1.5),
    Z = c(0.5, 0.75)
  )

  attr(data, "dynamic_range") <- c(-4, 4)
  expect_identical(actibase::get_dynamic_range(data), c(-4, 4))

  attr(data, "dynamic_range") <- NULL
  expect_warning(
    expect_identical(actibase::get_dynamic_range(data), c(-3, 3)),
    "No dynamic range found in header"
  )

  acc <- structure(
    list(
      data = data,
      header = data.frame(
        Field = c("Acceleration Min", "Acceleration Max"),
        Value = c("-6", "6")
      ),
      original_header = NULL
    ),
    class = "AccData"
  )

  expect_identical(actibase::get_dynamic_range(acc), c(-6, 6))

  acc_attr <- acc
  attr(acc_attr, "dynamic_range") <- c(-9, 9)
  expect_identical(actibase::get_dynamic_range(acc_attr), c(-9, 9))

  acc2 <- structure(
    list(
      data = data,
      header = data.frame(accrange = c("8", "-8")),
      original_header = NULL
    ),
    class = "AccData"
  )

  expect_identical(actibase::get_dynamic_range(acc2), c(-8, 8))
  expect_identical(
    actibase:::get_dynamic_range_actilife_header(NULL),
    NULL
  )
  expect_identical(
    actibase:::get_dynamic_range_actilife_header(
      "--- Serial Number: TAS12345 Start Time ---"
    ),
    c(-8, 8)
  )
  expect_identical(
    actibase:::get_dynamic_range_actilife_header(
      "--- Serial Number: IMU12345 Start Time ---"
    ),
    c(-16, 16)
  )
  expect_warning(
    expect_identical(
      actibase:::get_dynamic_range_actilife_header(
        "--- Serial Number: VERYLONGSERIALNUMBER123456789 Start Time ---"
      ),
      NULL
    ),
    "dynamic range may be wrong"
  )

  acc3 <- structure(
    list(
      data = data,
      header = data.frame(Field = character(), Value = character()),
      original_header = "--- Serial Number: TAS12345 Start Time ---"
    ),
    class = "AccData"
  )
  expect_identical(actibase::get_dynamic_range(acc3), c(-8, 8))
})

test_that("flag_spike flags large adjacent changes", {
  data <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:01", "2020-01-01 00:00:02"),
      tz = "UTC"
    ),
    X = c(0, 12, 12),
    Y = c(0, 0, 0),
    Z = c(0, 0, 0)
  )

  flagged <- actibase::flag_spike(data, spike_size = 11)
  expect_true("flag_spike" %in% names(flagged))
  expect_identical(flagged$flag_spike, c(FALSE, TRUE, FALSE))
  expect_identical(flagged$time, data$time)
})

