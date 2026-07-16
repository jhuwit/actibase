test_that("basic helper utilities behave as expected", {
  expect_true(is.AccData(structure(list(), class = "AccData")))
  expect_false(is.AccData(list()))

  expect_equal(
    format(ticks2datetime(1e7, tz = "UTC"), "%H:%M:%S"),
    "00:00:01"
  )

  expect_equal(Round(c(-1.234, 1.234), 2), c(-1.23, 1.23))

  expect_equal(
    strip_hour_shift(
      c("2019-01-01 12:00+03:00", "2019-01-01 12:00-04:00")
    ),
    c("2019-01-01 12:00", "2019-01-01 12:00")
  )
  expect_error(strip_hour_shift("2019-01-01 12:00", max_index = 3))

  expect_equal(tzoffset_to_tz("+04:00"), "Etc/GMT+4")
  expect_equal(tzoffset_to_tz("-04:00"), "Etc/GMT-4")
  expect_error(tzoffset_to_tz("+04:30"))
})


test_that("convert helpers handle valid and invalid values", {
  expect_equal(as_date_safe("2020-01-02"), as.Date("2020-01-02"))
  expect_equal(
    as_datetime_safe("2020-01-02 03:04:05", tz = "UTC"),
    as.POSIXct("2020-01-02 03:04:05", tz = "UTC")
  )
  expect_error(as_date_safe("not-a-date"))
  expect_error(as_datetime_safe("not-a-datetime", tz = "UTC"))
})

test_that("transformations are prefixed and accumulated correctly", {
  x <- data.frame(a = 1)
  expect_equal(prefix_transformations("step"), "step")
  expect_equal(prefix_transformations("step", prefix = "pkg"), "pkg:step")

  x <- set_transformations(x, "first", add = FALSE)
  expect_equal(attr(x, "transformations"), "first")

  x <- set_transformations(x, "second", prefix = "pkg", add = TRUE)
  expect_equal(attr(x, "transformations"), c("pkg:second", "first"))

  acc <- structure(
    list(data = structure(data.frame(a = 1), transformations = c("inner"))),
    class = "AccData",
    transformations = c("outer")
  )
  expect_equal(get_transformations(acc), c("outer", "inner"))
})

test_that("standardizing data renames axes and time", {
  raw <- data.frame(
    HEADER_TIME_STAMP = as.POSIXct(
      c("2020-01-02 00:00:00", "2020-01-01 23:59:00"),
      tz = "UTC"
    ),
    x = c(1, 2),
    y = c(3, 4),
    z = c(5, 6),
    wear = c(TRUE, FALSE)
  )

  standardized <- acti_standardize_data(raw)
  expect_equal(names(standardized), c("time", "X", "Y", "Z"))
  expect_equal(as.numeric(standardized$X), c(1, 2))

  kept <- acti_standardize_data(
    data.frame(time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC"), wear = TRUE),
    subset_xyz = FALSE,
    check_xyz = FALSE
  )
  expect_equal(names(kept), c("time", "wear"))

  expect_error(
    acti_standardize_data(
      data.frame(time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")),
      subset_xyz = FALSE
    )
  )

  expect_error(
    acti_standardize_data(matrix(c("a", "b", "c"), ncol = 3))
  )

  mat <- matrix(1:6, ncol = 3)
  standardized_mat <- acti_standardize_data(mat)
  expect_equal(names(standardized_mat), c("X", "Y", "Z"))
  expect_equal(unname(as.matrix(standardized_mat)), mat)

  expect_equal(
    unname(actibase:::xyz_data(raw)),
    unname(as.matrix(standardized[, c("X", "Y", "Z")]))
  )
})

test_that("sorting and zero filling preserve order and transformations", {
  unsorted <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:02", "2020-01-01 00:00:00", "2020-01-01 00:00:01"),
      tz = "UTC"
    ),
    X = c(2, 1, 0),
    Y = c(2, 1, 0),
    Z = c(2, 1, 0)
  )

  sorted <- actibase:::sort_time_df(unsorted, prefix = "test")
  expect_equal(sorted$time, sort(unsorted$time))
  expect_equal(attr(sorted, "transformations"), "test:sorted_by_time")

  expect_identical(actibase:::sort_time_df(data.frame(X = 1:2)), data.frame(X = 1:2))

  expect_warning({filled <- acti_fill_zeros(unsorted)}, "unsorted")
  expect_equal(filled$X, c(1, 1, 2))
  expect_equal(filled$Y, c(1, 1, 2))
  expect_equal(filled$Z, c(1, 1, 2))
  expect_equal(
    attr(filled, "transformations"),
    c("acti_fill_zeros:filled_zeros", "acti_fill_zeros:sorted_by_time")
  )

  expect_identical(acti_fill_zeroes(unsorted), filled)
})

test_that("separate time and day inclusion helpers return expected summaries", {
  time_data <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:01:00", "2020-01-01 01:01:00"),
      tz = "UTC"
    ),
    X = c(1, 2, 3),
    Y = c(4, 5, 6),
    Z = c(7, 8, 9)
  )

  separated <- acti_separate_time(time_data)
  expect_equal(names(separated), c("time", "X", "Y", "Z", "date", "hour", "minute", "day"))
  expect_equal(separated$day, c(1, 1, 1))
  expect_equal(as.character(separated$hour[1]), "00:00:00")
  expect_equal(as.character(separated$minute[3]), "01:01:00")

  separated <- acti_separate_times(time_data)
  expect_equal(names(separated), c("time", "X", "Y", "Z", "date", "hour", "minute", "day"))
  expect_equal(separated$day, c(1, 1, 1))
  expect_equal(as.character(separated$hour[1]), "00:00:00")
  expect_equal(as.character(separated$minute[3]), "01:01:00")

  separated <- acti_create_hour(time_data)
  expect_equal(names(separated), c("time", "X", "Y", "Z", "hour"))
  expect_equal(as.character(separated$hour[1]), "00:00:00")

  separated <- acti_create_minute(time_data)
  expect_equal(names(separated), c("time", "X", "Y", "Z", "minute"))
  expect_equal(as.character(separated$minute[3]), "01:01:00")

  separated <- acti_create_date(time_data)
  expect_equal(names(separated), c("time", "X", "Y", "Z", "date"))
  expect_equal(separated$date[1], as.Date("2020-01-01"))


  inclusion_data <- data.frame(
    time = as.POSIXct(
      c(
        "2020-01-01 00:00:00",
        "2020-01-01 00:01:00",
        "2020-01-01 00:02:00",
        "2020-01-02 00:00:00"
      ),
      tz = "UTC"
    ),
    wear = c(TRUE, TRUE, FALSE, TRUE)
  )

  inclusion <- create_day_inclusion(inclusion_data, min_required = 2L)
  expect_equal(nrow(inclusion), 2L)
  expect_equal(inclusion$n_minutes_wear, c(2L, 1L))
  expect_equal(inclusion$is_included, c(TRUE, FALSE))

  added <- add_day_inclusion(inclusion_data, min_required = 2L)
  expect_equal(nrow(added), nrow(inclusion_data))
  expect_equal(
    names(added),
    c(
      "time", "wear", "date", "n_minutes_wear", "n_minutes_observed",
      "prop_minutes_wear", "prop_minutes_wear_from_observed", "is_included"
    )
  )
  expect_equal(added$n_minutes_wear, c(2L, 2L, 2L, 1L))
  expect_equal(added$is_included, c(TRUE, TRUE, TRUE, FALSE))

  expect_error(
    create_day_inclusion(data.frame(time = as.POSIXct("2020-01-01 00:00:00", tz = "UTC"))),
    "Columns wear are not present"
  )

  expect_error(
    create_day_inclusion(
      data.frame(
        time = as.POSIXct(
          c("2020-01-01 00:00:00", "2020-01-01 00:00:00"),
          tz = "UTC"
        ),
        wear = c(TRUE, FALSE)
      )
    ),
    "duplicate rows"
  )
})

test_that("tidy axes reshapes data and carries transformations", {
  x <- acti_raw_data[1:2, ]
  attr(x, "transformations") <- c("seed")

  long <- acti_tidy_axes(x)
  expect_equal(names(long), c("time", "axis", "value"))
  expect_equal(nrow(long), 6L)
  expect_equal(unique(long$axis), c("X", "Y", "Z"))
  expect_equal(attr(long, "transformations"), c("axes_reshaped", "seed"))
})

test_that("resampling works for data frames and tibbles", {
  base <- data.frame(
    time = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 00:00:01", "2020-01-01 00:00:02"),
      tz = "UTC"
    ),
    X = c(0, 1, 2),
    Y = c(2, 3, 4),
    Z = c(4, 5, 6)
  )
  attr(base, "transformations") <- c("seed")

  res_df <- acti_resample(base, sample_rate = 2, method = "linear")
  expect_s3_class(res_df, "data.frame")
  expect_false(inherits(res_df, "tbl_df"))
  expect_equal(attr(res_df, "sample_rate"), 2L)
  expect_equal(nrow(res_df), 5L)
  expect_true(any(grepl("linear_resampled_to_2Hz", attr(res_df, "transformations"))))
  expect_true(any(grepl("seed", attr(res_df, "transformations"))))

  res_tbl <- acti_resample(dplyr::as_tibble(base), sample_rate = 2, method = "natural")
  expect_true(inherits(res_tbl, "tbl_df"))
  expect_equal(attr(res_tbl, "sample_rate"), 2L)
  expect_true(any(grepl("natural_resampled_to_2Hz", attr(res_tbl, "transformations"))))

  times <- as.POSIXct(
    c("2020-01-01 00:00:00", "2020-01-01 00:00:01"),
    tz = "UTC"
  )
  aligned <- acti_resample_to_time(base, times = times, method = "constant")
  expect_equal(nrow(aligned), 2L)
  expect_equal(aligned$time, times)
  expect_true(any(grepl("resampled_to_specific_times", attr(aligned, "transformations"))))

  aligned_tbl <- acti_resample_to_time(dplyr::as_tibble(base), times = times)
  expect_true(inherits(aligned_tbl, "tbl_df"))

  expect_error(
    acti_resample_to_time(
      base,
      times = as.POSIXct(
        c("2020-01-01 00:00:00", "2020-01-01 00:00:01"),
        tz = "America/New_York"
      )
    ),
    "Timezone in data times do not match timezone in time vector"
  )
})

test_that("tidy axes and duplicate checks can fail cleanly", {
  expect_error(
    with_mocked_bindings(
      acti_tidy_axes(acti_raw_data),
      requireNamespace = function(...) FALSE,
      .package = "base"
    ),
    "tidyr required for tidy_axes"
  )

  call_count <- 0L
  expect_error(
    with_mocked_bindings(
      create_day_inclusion(
        data.frame(
          time = as.POSIXct(
            c("2020-01-01 00:00:00", "2020-01-01 00:01:00"),
            tz = "UTC"
          ),
          wear = c(TRUE, FALSE)
        )
      ),
      get_dupes = function(...) {
        call_count <<- call_count + 1L
        if (call_count == 1L) {
          data.frame()
        } else {
          data.frame(date = as.Date("2020-01-01"), hourtime = hms::as_hms("00:00:00"))
        }
      },
      .package = "janitor"
    ),
    "duplicate rows of date and minute"
  )
})

