test_that("minute helpers convert hms, character, and POSIXt values", {
  hms_time = hms::hms(hours = c(0, 23), minutes = c(0, 59))
  expect_identical(acti_hms_to_minute(hms_time), c(1L, 1440L))
  expect_identical(acti_time_to_minute(c("00:00", "23:59:59"), start = 0), c(0L, 1439L))

  time_ct = as.POSIXct(c("2020-01-01 00:00:30", "2020-01-01 23:59:59"), tz = "America/New_York")
  expect_identical(acti_time_to_minute(time_ct), c(1L, 1440L))
  expect_identical(acti_time_to_minute(as.POSIXlt(time_ct)), c(1L, 1440L))
  expect_identical(acti_time_to_minute(hms::hms(NA)), NA_integer_)
})

test_that("minute positions round trip through hms", {
  minutes = c(1L, 721L, 1440L, NA_integer_)
  expect_identical(acti_time_to_minute(acti_minute_to_hms(minutes)), minutes)
  expect_identical(as.character(acti_minute_to_hms(c(0L, 1439L), start = 0)), c("00:00:00", "23:59:00"))
})

test_that("time of day extraction validates timezones", {
  x = as.POSIXct("2020-01-01 05:30:00", tz = "UTC")
  expect_identical(as.character(acti_time_of_day(x)), "05:30:00")
  expect_identical(as.character(acti_time_of_day(x, "America/New_York")), "00:30:00")
  unzoned_x = structure(as.numeric(x), class = c("POSIXct", "POSIXt"))
  expect_identical(as.character(acti_time_of_day(unzoned_x)), "05:30:00")
  expect_error(acti_time_of_day(x, "not/a-timezone"), "timezone")
  expect_error(acti_time_of_day(as.Date("2020-01-01")), "POSIXt")
})

test_that("time of day repeats across recording dates", {
  time = as.POSIXct(c("2020-01-01 12:00:00", "2020-01-03 12:00:00"), tz = "UTC")
  expect_identical(
    acti_repeat_time_of_day("01:30", time),
    as.POSIXct(c("2020-01-01 01:30:00", "2020-01-02 01:30:00", "2020-01-03 01:30:00"), tz = "UTC")
  )
  expect_error(acti_repeat_time_of_day(86400, time), "seconds")
  expect_error(acti_repeat_time_of_day("01:00", as.Date("2020-01-01")), "POSIXt")
})

test_that("intervals split at local midnight", {
  start = as.POSIXct(c("2020-01-01 23:30:00", NA), tz = "UTC")
  end = as.POSIXct(c("2020-01-02 00:30:00", NA), tz = "UTC")
  got = acti_split_intervals_at_midnight(start, end)
  expect_identical(got$interval, c(1L, 1L, 2L))
  expect_identical(format(got$start, "%F %T"), c("2020-01-01 23:30:00", "2020-01-02 00:00:00", NA))
  expect_identical(format(got$end, "%F %T"), c("2020-01-02 00:00:00", "2020-01-02 00:30:00", NA))
  expect_error(acti_split_intervals_at_midnight(end, start), "end")
  expect_error(acti_split_intervals_at_midnight(as.Date("2020-01-01"), end), "equally sized")
})

test_that("activity day helpers support non-midnight boundaries", {
  time = as.POSIXct(c("2020-01-01 03:59:00", "2020-01-01 04:00:00", "2020-01-02 02:00:00"), tz = "UTC")
  expected = as.POSIXct(c("2019-12-31 04:00:00", "2020-01-01 04:00:00", "2020-01-01 04:00:00"), tz = "UTC")

  # The default activity-day boundary is equivalent to a calendar day.
  expect_identical(acti_day_start(time), lubridate::floor_date(time, "day"))

  # A custom boundary retains overnight observations in the preceding day.
  expect_identical(acti_day_start(time, "04:00"), expected)
  expect_identical(acti_day_index(time, "04:00"), c(1L, 2L, 2L))
  expect_identical(acti_day_index(time, "04:00", origin = as.Date("2020-01-01"), start = 0), c(-1L, 0L, 0L))
  expect_identical(acti_day_index(time, "04:00", origin = time[2]), c(0L, 1L, 1L))
  expect_identical(acti_day_index(as.POSIXct(NA, origin = "1970-01-01", tz = "UTC")), NA_integer_)
  expect_error(acti_day_index(time, origin = 1), "origin")
})

test_that("time helpers validate malformed inputs", {
  expect_error(acti_time_to_minute("24:00"), "HH:MM")
  expect_error(acti_time_to_minute(1), "hms")
  expect_error(acti_hms_to_minute("00:00"), "hms")
  expect_error(acti_time_to_minute(hms::hms(0), start = 2), "0 or 1")
  expect_error(acti_minute_to_hms(c(1, 1.5)), "whole-minute")
  expect_error(acti_minute_to_hms("1"), "whole-minute")
  expect_error(acti_day_start(as.Date("2020-01-01")), "POSIXt")
  expect_error(acti_day_start(as.POSIXct("2020-01-01", tz = "UTC"), hms::hms(86400)), "within a day")
})
