# Convert an HMS Time to a Minute Index

Convert an HMS Time to a Minute Index

## Usage

``` r
acti_hms_to_minute(x, start = 1L)
```

## Arguments

- x:

  An \`hms\`, \`POSIXt\`, or \`HH:MM\[:SS\]\` character vector.

- start:

  The index assigned to midnight, either \`0\` or \`1\`.

## Value

An integer minute-of-day index.

## Note

This is a strict \`hms\` entry point for callers that have already
separated time of day from date and want the standard activity-day
index.

## Examples

``` r
acti_hms_to_minute(hms::hms(hours = c(0, 23), minutes = c(0, 59)))
#> [1]    1 1440
```
