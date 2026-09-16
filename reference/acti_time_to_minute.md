# Convert a Time of Day to a Minute Index

Convert a Time of Day to a Minute Index

## Usage

``` r
acti_time_to_minute(x, start = 1L, timezone = NULL)
```

## Arguments

- x:

  An \`hms\`, \`POSIXt\`, or \`HH:MM\[:SS\]\` character vector.

- start:

  The index assigned to midnight, either \`0\` or \`1\`.

- timezone:

  Optional Olson timezone for \`POSIXt\` values.

## Value

An integer minute-of-day index.

## Note

This converts each minute of a day to either \`0\` through \`1439\` or
\`1\` through \`1440\`, the two common minute-of-day conventions.

## Examples

``` r
acti_time_to_minute(c("00:00", "12:00", "23:59"))
#> [1]    1  721 1440
acti_time_to_minute("00:00", start = 0)
#> [1] 0
```
