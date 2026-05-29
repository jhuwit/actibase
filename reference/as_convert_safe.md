# Convert vectors ensuring no new NA

Convert vectors ensuring no new NA

## Usage

``` r
as_convert_safe(x, ..., func = lubridate::as_datetime)

as_date_safe(x, ...)

as_datetime_safe(x, ...)
```

## Arguments

- x:

  a vector

- ...:

  additional arguments to pass to \`func\`

- func:

  the function to use to transform the vector \`x\`

## Value

A converted \`vector\` the same length as \`x\` or errors if there are
introduced NAs.
