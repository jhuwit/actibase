# Convert a POSIX Time to a Minute of the Day

Converts the time-of-day component of a timestamp to its minute position
within a 24-hour day, in the timestamp's timezone. By default, positions
are one-based, so midnight is minute 1 and 23:59 is minute 1440.

## Usage

``` r
posix_to_minute(x, start = 1L)

datetime_to_minute(x, start = 1L)
```

## Arguments

- x:

  A vector inheriting from \`POSIXt\`, such as \`POSIXct\` or
  \`POSIXlt\`.

- start:

  The index assigned to midnight; either \`0\` or \`1\`.

## Value

An integer vector with values from \`start\` through \`start + 1439\`.

## Examples

``` r
x = as.POSIXct("2020-01-01 23:59:00", tz = "UTC")
posix_to_minute(x)
#> [1] 1440
```
