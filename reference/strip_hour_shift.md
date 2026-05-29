# Strip Hour Shift from Character Time Vector

Strip Hour Shift from Character Time Vector

## Usage

``` r
strip_hour_shift(x, max_index = 2L)
```

## Arguments

- x:

  character vector with times that may include hour shifts (e.g.,
  "2019-01-01 12:00+03:00")

- max_index:

  maximum index to grab the shift from after splitting on spaces,
  default is 2 (e.g., "2019-01-01 12:00")

## Value

A character vector with the \`+\`/\`-\` hour shift removed

## Examples

``` r
strip_hour_shift(c("2019-01-01 12:00+03:00", "2019-01-01 12:00-04:00"))
#> [1] "2019-01-01 12:00" "2019-01-01 12:00"
```
