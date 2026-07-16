# Get Dynamic Range

Get Dynamic Range

## Usage

``` r
get_dynamic_range(data, dynamic_range = NULL, flag_estimated = FALSE)
```

## Arguments

- data:

  An `AccData` object from an actigraphy reader

- dynamic_range:

  the dynamic range. If this is not `NULL`, then it will be guess from
  the header or the data

- flag_estimated:

  if \`TRUE\`, then the output will have the attribute \`"estimated"\`,
  which is a logical indicated if it was found or estimated

## Value

A length-2 numeric vector, or the original dynamic range (no checking
done)
