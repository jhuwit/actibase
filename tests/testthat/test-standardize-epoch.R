test_that("acti_standardize_epoch parses many epoch forms to seconds", {
  expect_equal(acti_standardize_epoch(60), 60)
  expect_equal(acti_standardize_epoch(60L), 60)
  expect_equal(acti_standardize_epoch("1 min"), 60)
  expect_equal(acti_standardize_epoch("1min"), 60)
  expect_equal(acti_standardize_epoch("1 min"), 60)
  expect_equal(acti_standardize_epoch("30s"), 30)
  expect_equal(acti_standardize_epoch("30 sec"), 30)
  expect_equal(acti_standardize_epoch("5 seconds"), 5)
  expect_equal(acti_standardize_epoch("1 hour"), 3600)
  expect_equal(acti_standardize_epoch("1 hr"), 3600)
  expect_equal(acti_standardize_epoch("2hrs"), 7200)
  expect_equal(acti_standardize_epoch("90 aseconds"), 90)
  expect_equal(acti_standardize_epoch("60"), 60)
  expect_equal(acti_standardize_epoch(0.5), 0.5)
  expect_equal(acti_standardize_epoch(lubridate::minutes(5)), 300)
  expect_equal(acti_standardize_epoch(lubridate::dminutes(5)), 300)
  expect_equal(acti_standardize_epoch(as.difftime(2, units = "mins")), 120)
})

test_that("acti_standardize_epoch converts units", {
  expect_equal(acti_standardize_epoch("1 min", unit = "minutes"), 1)
  expect_equal(acti_standardize_epoch(30, unit = "minutes"), 0.5)
  expect_equal(acti_standardize_epoch("2 hours", unit = "minutes"), 120)
  expect_equal(acti_standardize_epoch(90, unit = "hours"), 0.025)
  expect_equal(acti_standardize_epoch("1 day"), 86400)
  expect_equal(acti_standardize_epoch("12 hours", unit = "days"), 0.5)
  expect_equal(acti_standardize_epoch(2, input_unit = "days"), 172800)
  expect_equal(acti_standardize_epoch(5, input_unit = "minutes"), 300)
  expect_equal(acti_standardize_epoch(1, unit = "secs", input_unit = "hr"),
               3600)
  expect_equal(acti_standardize_epoch("5", input_unit = "minutes"), 300)
  # abbreviated unit names are matched silently
  for (u in c("secs", "sec", "second")) {
    expect_equal(acti_standardize_epoch("1 min", unit = u), 60)
  }
  for (u in c("mins", "min", "minute")) {
    expect_equal(acti_standardize_epoch(90, unit = u), 1.5)
  }
  expect_equal(acti_standardize_epoch(2, input_unit = "mins"), 120)
  expect_equal(acti_standardize_epoch(1, input_unit = "day"), 86400)
  expect_equal(acti_standardize_epoch(120, unit = "mins", output = "character"),
               "2 mins")
  # input_unit only applies to unitless input
  expect_equal(acti_standardize_epoch("30s", input_unit = "minutes"), 30)
})

test_that("acti_standardize_epoch makes floor_date-ready strings", {
  expect_equal(acti_standardize_epoch(30, output = "character"), "30 secs")
  expect_equal(acti_standardize_epoch(1, output = "character"), "1 sec")
  expect_equal(acti_standardize_epoch(60, output = "character"), "1 min")
  expect_equal(acti_standardize_epoch("1 min", output = "character"),
               "1 min")
  expect_equal(acti_standardize_epoch(300, output = "character"), "5 mins")
  expect_equal(acti_standardize_epoch(3600, output = "character"), "1 hour")
  expect_equal(acti_standardize_epoch("120 minutes", output = "character"),
               "2 hours")
  expect_equal(acti_standardize_epoch("1 day", output = "character"), "1 day")
  expect_equal(acti_standardize_epoch("24 hours", output = "character"),
               "1 day")
  expect_equal(acti_standardize_epoch("1 week", output = "character"),
               "7 days")
  expect_equal(acti_standardize_epoch(0.5, output = "character"),
               "0.5 secs")
  expect_equal(acti_standardize_epoch(90, output = "character"),
               "90 aseconds")
  expect_equal(
    acti_standardize_epoch(60, unit = "seconds", output = "character"),
    "60 secs")
  expect_equal(
    acti_standardize_epoch("2 hours", unit = "minutes", output = "character"),
    "120 mins")

  # the strings also work with base R and MIMSunit-style parsers
  expect_length(seq(as.POSIXct("2020-01-01", tz = "UTC"), by =
                      acti_standardize_epoch(30, output = "character"),
                    length.out = 3), 3)

  x = as.POSIXct("2020-01-01 01:37:43", tz = "UTC")
  for (epoch in list(30, 60, 90, 300, 3600, "1 min", "120 minutes",
                    "1 day", "2 days")) {
    unit = acti_standardize_epoch(epoch, output = "character")
    floored = lubridate::floor_date(x, unit)
    expect_true(floored <= x)
    expect_equal(acti_standardize_epoch(unit),
                 acti_standardize_epoch(epoch))
  }
})

test_that("acti_standardize_epoch rejects bad input", {
  expect_error(acti_standardize_epoch(0), "positive")
  expect_error(acti_standardize_epoch(-5), "positive")
  expect_error(acti_standardize_epoch(NA), "positive")
  expect_error(acti_standardize_epoch("soon"), "positive")
  expect_error(acti_standardize_epoch(c(30, 60)), "single")
  expect_error(acti_standardize_epoch("1 month"), "fixed length")
  expect_error(acti_standardize_epoch("1 year"), "fixed length")
  expect_error(acti_standardize_epoch(60, unit = "auto"), "character")
  expect_error(acti_standardize_epoch(60, unit = "fortnights"))
  # no partial matching: "m" could mean months
  expect_error(acti_standardize_epoch(60, unit = "m"), "must be one of")
  expect_error(acti_standardize_epoch(60, unit = "minu"), "must be one of")
  expect_error(acti_standardize_epoch(60, input_unit = "m"), "input_unit")
  expect_error(acti_standardize_epoch(60, unit = "months"), "must be one of")
  expect_identical(acti_standardise_epoch, acti_standardize_epoch)
})
