# Fill in Zeros

Fill in Zeros

## Usage

``` r
acti_fill_zeros(data, method = c("all", "actilife"), sample_rate = NULL)

acti_fill_zeroes(data, method = c("all", "actilife"), sample_rate = NULL)

acti_remove_leading_zeros(data)

acti_remove_leading_zeroes(data)
```

## Arguments

- data:

  a data frame containing columns time, X, Y, Z

- method:

  `"all"` (default) fills every all-zero row. `"actilife"` fills only
  runs of all-zero rows that are at least one second long (`sample_rate`
  rows) and keeps shorter runs as recorded zeros. In idle sleep the
  device stops sampling for at least a second, and ActiLife repeats the
  last sample over that time, but a single recorded `(0, 0, 0)` sample
  is kept by ActiLife.

- sample_rate:

  sample rate, in Hz, used when `method = "actilife"`. If `NULL`, it is
  resolved with
  [`get_sample_rate()`](https://jhuwit.github.io/actibase/reference/get_sample_rate.md).

## Value

the modified data frame with zeros replaced by NA

## Note

With `method = "actilife"`, the kept zero rows are still all zero, so a
later step that treats all-zero rows as idle sleep (such as
`agcounts::calculate_counts()`) will fill them anyway.

## Examples

``` r
acti_fill_zeros(acti_raw_data)
#> # A tibble: 240,500 × 4
#>    time                    X      Y     Z
#>    <dttm>              <dbl>  <dbl> <dbl>
#>  1 2019-09-17 18:40:00 0      0.008 0.996
#>  2 2019-09-17 18:40:00 0.016  0     1.01 
#>  3 2019-09-17 18:40:00 0.02  -0.008 1.00 
#>  4 2019-09-17 18:40:00 0.016 -0.012 1.01 
#>  5 2019-09-17 18:40:00 0.016 -0.008 1.01 
#>  6 2019-09-17 18:40:00 0.008 -0.008 1.01 
#>  7 2019-09-17 18:40:00 0.016 -0.008 1.02 
#>  8 2019-09-17 18:40:00 0.02  -0.004 1.02 
#>  9 2019-09-17 18:40:00 0.016  0     1.01 
#> 10 2019-09-17 18:40:00 0.012  0     1.02 
#> # ℹ 240,490 more rows
acti_fill_zeroes(acti_raw_data)
#> # A tibble: 240,500 × 4
#>    time                    X      Y     Z
#>    <dttm>              <dbl>  <dbl> <dbl>
#>  1 2019-09-17 18:40:00 0      0.008 0.996
#>  2 2019-09-17 18:40:00 0.016  0     1.01 
#>  3 2019-09-17 18:40:00 0.02  -0.008 1.00 
#>  4 2019-09-17 18:40:00 0.016 -0.012 1.01 
#>  5 2019-09-17 18:40:00 0.016 -0.008 1.01 
#>  6 2019-09-17 18:40:00 0.008 -0.008 1.01 
#>  7 2019-09-17 18:40:00 0.016 -0.008 1.02 
#>  8 2019-09-17 18:40:00 0.02  -0.004 1.02 
#>  9 2019-09-17 18:40:00 0.016  0     1.01 
#> 10 2019-09-17 18:40:00 0.012  0     1.02 
#> # ℹ 240,490 more rows
# \donttest{
   acti_fill_zeros(acti_raw_data, method = "actilife")
#> # A tibble: 240,500 × 4
#>    time                    X      Y     Z
#>    <dttm>              <dbl>  <dbl> <dbl>
#>  1 2019-09-17 18:40:00 0      0.008 0.996
#>  2 2019-09-17 18:40:00 0.016  0     1.01 
#>  3 2019-09-17 18:40:00 0.02  -0.008 1.00 
#>  4 2019-09-17 18:40:00 0.016 -0.012 1.01 
#>  5 2019-09-17 18:40:00 0.016 -0.008 1.01 
#>  6 2019-09-17 18:40:00 0.008 -0.008 1.01 
#>  7 2019-09-17 18:40:00 0.016 -0.008 1.02 
#>  8 2019-09-17 18:40:00 0.02  -0.004 1.02 
#>  9 2019-09-17 18:40:00 0.016  0     1.01 
#> 10 2019-09-17 18:40:00 0.012  0     1.02 
#> # ℹ 240,490 more rows
# }
```
