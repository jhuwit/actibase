# Get Dynamic Range

Get Dynamic Range

## Usage

``` r
get_dynamic_range(data, dynamic_range = NULL)
```

## Arguments

- data:

  An `AccData` object from an actigraphy reader

- dynamic_range:

  the dynamic range. If this is not `NULL`, then it will be guess from
  the header or the data

## Value

A length-2 numeric vector, or the original dynamic range (no checking
done)
