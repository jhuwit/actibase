# Repeat a Time of Day Across a Recording

Repeat a Time of Day Across a Recording

## Usage

``` r
acti_repeat_time_of_day(seconds, time, timezone = NULL)
```

## Arguments

- seconds:

  Seconds after midnight, or an \`hms\`/\`HH:MM\[:SS\]\` time.

- time:

  A \`POSIXt\` recording time vector used to determine dates and
  timezone.

- timezone:

  Optional Olson timezone; by default the timezone of \`time\`.

## Value

A \`POSIXct\` vector with one occurrence per recording date.

## Note

This supplies daily plotting boundaries such as a fixed bedtime or wake
time for every calendar date present in a recording.

## Examples

``` r
time = as.POSIXct(c("2020-01-01 12:00:00", "2020-01-03 12:00:00"), tz = "UTC")
acti_repeat_time_of_day("01:30", time)
#> [1] "2020-01-01 01:30:00 UTC" "2020-01-02 01:30:00 UTC"
#> [3] "2020-01-03 01:30:00 UTC"
```
