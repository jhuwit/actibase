# Split Intervals at Midnight

Split Intervals at Midnight

## Usage

``` r
acti_split_intervals_at_midnight(start, end, timezone = NULL)
```

## Arguments

- start, end:

  Equally sized \`POSIXt\` vectors.

- timezone:

  Optional Olson timezone used to define midnight.

## Value

A data frame with input \`interval\` number and split \`start\`/\`end\`.

## Note

Sleep, wear, and activity episodes can span dates; splitting them makes
their durations and faceted daily displays unambiguous.

## Examples

``` r
start = as.POSIXct("2020-01-01 23:30:00", tz = "UTC")
end = as.POSIXct("2020-01-02 00:30:00", tz = "UTC")
acti_split_intervals_at_midnight(start, end)
#>   interval               start                 end
#> 1        1 2020-01-01 23:30:00 2020-01-02 00:00:00
#> 2        1 2020-01-02 00:00:00 2020-01-02 00:30:00
```
