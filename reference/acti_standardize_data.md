# Standardize the Accelerometry Data

Standardize the Accelerometry Data

## Usage

``` r
acti_standardize_data(
  data,
  subset_xyz = TRUE,
  colname_time = "time",
  check_xyz = TRUE
)

acti_standardise_data(
  data,
  subset_xyz = TRUE,
  colname_time = "time",
  check_xyz = TRUE
)
```

## Arguments

- data:

  A \`data.frame\` with a column for time in \`POSIXct\` (usually
  \`time\`), and \`X\`, \`Y\`, \`Z\`

- subset_xyz:

  should only the \`time\` (if available) and \`XYZ\` be subset?

- colname_time:

  column name of header for time

- check_xyz:

  Check if X/Y/Z is in the data

## Value

A \`data.frame\` with \`X/Y/Z\` and a time in \`time\` (if available).

## Examples

``` r

acti_standardize_data(acti_raw_data)
#> # A tibble: 240,500 × 4
#>    time                        X      Y     Z
#>    <dttm>                  <dbl>  <dbl> <dbl>
#>  1 2019-09-17 18:40:00.000 0      0.008 0.996
#>  2 2019-09-17 18:40:00.009 0.016  0     1.01 
#>  3 2019-09-17 18:40:00.019 0.02  -0.008 1.00 
#>  4 2019-09-17 18:40:00.029 0.016 -0.012 1.01 
#>  5 2019-09-17 18:40:00.039 0.016 -0.008 1.01 
#>  6 2019-09-17 18:40:00.049 0.008 -0.008 1.01 
#>  7 2019-09-17 18:40:00.059 0.016 -0.008 1.02 
#>  8 2019-09-17 18:40:00.069 0.02  -0.004 1.02 
#>  9 2019-09-17 18:40:00.079 0.016  0     1.01 
#> 10 2019-09-17 18:40:00.089 0.012  0     1.02 
#> # ℹ 240,490 more rows
acti_standardise_data(acti_raw_data)
#> # A tibble: 240,500 × 4
#>    time                        X      Y     Z
#>    <dttm>                  <dbl>  <dbl> <dbl>
#>  1 2019-09-17 18:40:00.000 0      0.008 0.996
#>  2 2019-09-17 18:40:00.009 0.016  0     1.01 
#>  3 2019-09-17 18:40:00.019 0.02  -0.008 1.00 
#>  4 2019-09-17 18:40:00.029 0.016 -0.012 1.01 
#>  5 2019-09-17 18:40:00.039 0.016 -0.008 1.01 
#>  6 2019-09-17 18:40:00.049 0.008 -0.008 1.01 
#>  7 2019-09-17 18:40:00.059 0.016 -0.008 1.02 
#>  8 2019-09-17 18:40:00.069 0.02  -0.004 1.02 
#>  9 2019-09-17 18:40:00.079 0.016  0     1.01 
#> 10 2019-09-17 18:40:00.089 0.012  0     1.02 
#> # ℹ 240,490 more rows
```
