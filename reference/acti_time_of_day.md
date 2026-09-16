# Extract the Time of Day

Extract the Time of Day

## Usage

``` r
acti_time_of_day(time, timezone = NULL)
```

## Arguments

- time:

  A \`POSIXt\` vector.

- timezone:

  Optional Olson timezone in which to extract time of day.

## Value

An \`hms\` vector.

## Note

This explicitly applies the recording or requested timezone before
dropping the date, which prevents a timestamp from being assigned to the
wrong activity-day minute.

## Examples

``` r
time = as.POSIXct("2020-01-01 05:30:00", tz = "UTC")
acti_time_of_day(time, timezone = "America/New_York")
#> 00:30:00
```
