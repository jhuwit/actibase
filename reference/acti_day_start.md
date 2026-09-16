# Find the Start of an Activity Day

This is a custom-day-boundary alternative to \[lubridate::floor_date()\]
with \`unit = "day"\`. Use \`floor_date()\` when days begin at midnight;
use \`acti_day_start()\` when a recording day begins at a different
time, such as 04:00.

## Usage

``` r
acti_day_start(time, day_start = hms::hms(0), timezone = NULL)
```

## Arguments

- time:

  A \`POSIXt\` vector.

- day_start:

  An \`hms\` or \`HH:MM\[:SS\]\` day boundary.

- timezone:

  Optional Olson timezone used to define the day boundary.

## Value

A \`POSIXct\` vector.

## Note

Activity studies often use a non-midnight boundary (for example, 04:00)
so nocturnal behavior is assigned to the preceding activity day.

## Examples

``` r
time = as.POSIXct(c("2020-01-01 03:00:00", "2020-01-01 05:00:00"), tz = "UTC")

# With a midnight boundary, this agrees with floor_date().
acti_day_start(time)
#> [1] "2020-01-01 UTC" "2020-01-01 UTC"
lubridate::floor_date(time, unit = "day")
#> [1] "2020-01-01 UTC" "2020-01-01 UTC"

# With a 04:00 boundary, 03:00 belongs to the preceding activity day.
acti_day_start(time, day_start = "04:00")
#> [1] "2019-12-31 04:00:00 UTC" "2020-01-01 04:00:00 UTC"
```
