# Convert a Minute Index to an HMS Time

Convert a Minute Index to an HMS Time

## Usage

``` r
acti_minute_to_hms(minute, start = 1L)
```

## Arguments

- minute:

  Whole-minute positions in a day.

- start:

  The index assigned to midnight, either \`0\` or \`1\`.

## Value

An \`hms\` vector.

## Note

This is the inverse of \[acti_time_to_minute()\] for readable axis
labels and for joining minute-indexed results back to a time-of-day
value.

## Examples

``` r
acti_minute_to_hms(c(1, 721, 1440))
#> 00:00:00
#> 12:00:00
#> 23:59:00
acti_minute_to_hms(c(0, 1439), start = 0)
#> 00:00:00
#> 23:59:00
```
