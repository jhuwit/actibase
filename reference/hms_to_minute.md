# Convert an \`hms\` Time to a Minute of the Day

Converts a time of day to its minute position within a 24-hour day. By
default, positions are one-based, so midnight is minute 1 and 23:59 is
minute 1440.

## Usage

``` r
hms_to_minute(x, start = 1L)
```

## Arguments

- x:

  A vector of class \`hms\`.

- start:

  The index assigned to midnight; either \`0\` or \`1\`.

## Value

An integer vector with values from \`start\` through \`start + 1439\`.

## Examples

``` r
hms_to_minute(hms::as_hms(c("00:00:00", "23:59:00")))
#> [1]    1 1440
hms_to_minute(hms::as_hms("00:00:00"), start = 0)
#> [1] 0
```
