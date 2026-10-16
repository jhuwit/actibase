# Flag periods adjacent to invalid periods

Marks the previous and next observed periods when their timestamps are
exactly `window_seconds` apart. Groups are evaluated independently.

## Usage

``` r
acti_flag_adjacent_invalid_periods(
  data,
  invalid,
  time = "time",
  window_seconds,
  group = NULL
)
```

## Arguments

- data:

  Minute-level summary data.

- invalid:

  Logical vector identifying invalid periods.

- time:

  Name of the timestamp column.

- window_seconds:

  Expected duration between adjacent periods.

- group:

  Optional grouping column name(s).

## Value

Input data with `flag_adjacent_invalid`.
