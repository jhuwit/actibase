# Separate Times into Date, Hour, and Minute

Separate Times into Date, Hour, and Minute

## Usage

``` r
acti_separate_time(data)

acti_separate_times(data)

acti_create_date(data)

acti_create_hour(data)

acti_create_minute(data)
```

## Arguments

- data:

  a \`data.frame\` with a \`time\` column

## Value

A \`data.frame\` with date, hour, minute, and day columns

## Examples

``` r
library(actibase)
acti_separate_time(acti_raw_data)
#> # A tibble: 240,500 × 8
#>    time                    X      Y     Z date       hour   minute   day
#>    <dttm>              <dbl>  <dbl> <dbl> <date>     <time> <time> <dbl>
#>  1 2019-09-17 18:40:00 0      0.008 0.996 2019-09-17 18:00  18:40      1
#>  2 2019-09-17 18:40:00 0.016  0     1.01  2019-09-17 18:00  18:40      1
#>  3 2019-09-17 18:40:00 0.02  -0.008 1.00  2019-09-17 18:00  18:40      1
#>  4 2019-09-17 18:40:00 0.016 -0.012 1.01  2019-09-17 18:00  18:40      1
#>  5 2019-09-17 18:40:00 0.016 -0.008 1.01  2019-09-17 18:00  18:40      1
#>  6 2019-09-17 18:40:00 0.008 -0.008 1.01  2019-09-17 18:00  18:40      1
#>  7 2019-09-17 18:40:00 0.016 -0.008 1.02  2019-09-17 18:00  18:40      1
#>  8 2019-09-17 18:40:00 0.02  -0.004 1.02  2019-09-17 18:00  18:40      1
#>  9 2019-09-17 18:40:00 0.016  0     1.01  2019-09-17 18:00  18:40      1
#> 10 2019-09-17 18:40:00 0.012  0     1.02  2019-09-17 18:00  18:40      1
#> # ℹ 240,490 more rows
acti_create_date(acti_raw_data)
acti_create_hour(acti_raw_data)
acti_create_minute(acti_raw_data)
```
