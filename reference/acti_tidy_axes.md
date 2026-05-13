# Tidy axes to a long format

Tidy axes to a long format

## Usage

``` r
acti_tidy_axes(data, colname_time = "time")
```

## Arguments

- data:

  An object with columns a time column \`X\`, \`Y\`, and \`Z\` or an
  object of class \`AccData\`

- colname_time:

  column name of header for time

## Value

A long data set with \`time\`, \`axis\`, and \`value\`

## Examples

``` r
long = acti_tidy_axes(acti_raw_data)
```
