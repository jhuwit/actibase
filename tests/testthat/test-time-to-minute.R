test_that("hms_to_minute returns a minute-of-day index", {
  times = hms::as_hms(c(
    "00:00:00", "00:00:59", "00:01:00", "12:00:00", "23:59:59", NA
  ))

  expect_identical(hms_to_minute(times), c(1L, 1L, 2L, 721L, 1440L, NA_integer_))
  expect_identical(hms_to_minute(times, start = 0), c(0L, 0L, 1L, 720L, 1439L, NA_integer_))
  expect_identical(hms_to_minute(hms::as_hms("24:00:00")), 1L)
})

test_that("POSIX minute helpers use the local time of their timestamps", {
  times_ct = as.POSIXct(
    c("2020-01-01 00:00:00", "2020-01-01 23:59:30"),
    tz = "America/New_York"
  )
  times_lt = as.POSIXlt(times_ct)

  expect_identical(posix_to_minute(times_ct), c(1L, 1440L))
  expect_identical(posix_to_minute(times_lt), c(1L, 1440L))
  expect_identical(datetime_to_minute(times_lt, start = 0), c(0L, 1439L))
  expect_identical(posix_to_minute(as.POSIXct(NA)), NA_integer_)
})

test_that("minute conversion validates its inputs", {
  expect_error(hms_to_minute("00:00:00"), "hms")
  expect_error(posix_to_minute(as.Date("2020-01-01")), "POSIXt")

  time = hms::as_hms("00:00:00")
  expect_error(hms_to_minute(time, start = "1"), "0 or 1")
  expect_error(hms_to_minute(time, start = c(0, 1)), "0 or 1")
  expect_error(hms_to_minute(time, start = NA_real_), "0 or 1")
  expect_error(hms_to_minute(time, start = 0.5), "0 or 1")
})
