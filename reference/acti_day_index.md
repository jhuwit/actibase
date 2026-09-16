# Calculate a Baseline-Relative Activity-Day Index

Calculate a Baseline-Relative Activity-Day Index

## Usage

``` r
acti_day_index(
  time,
  day_start = hms::hms(0),
  origin = NULL,
  start = 1L,
  timezone = NULL
)
```

## Arguments

- time:

  A \`POSIXt\` vector.

- day_start:

  An \`hms\` or \`HH:MM\[:SS\]\` day boundary.

- origin:

  Optional \`Date\` or \`POSIXt\` baseline; by default the first day.

- start:

  The index assigned to the baseline day, either \`0\` or \`1\`.

- timezone:

  Optional Olson timezone used to define the day boundary.

## Value

An integer vector.

## Note

A stable recording-relative day number supports faceting and alignment
across participants even when their calendar start dates differ.

## Examples

``` r
time = as.POSIXct(c("2020-01-01 03:00:00", "2020-01-01 05:00:00"), tz = "UTC")
acti_day_index(time, day_start = "04:00")
#> [1] 1 2
```
