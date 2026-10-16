# Flag device-limit counts within time windows

Groups samples into fixed-duration windows from the first timestamp,
counts values at the positive and negative device limits on each axis,
and compares each count with `min_count`.

## Usage

``` r
acti_flag_device_limit_windows(
  data,
  dynamic_range = NULL,
  epsilon = 0.05,
  min_count = 1,
  window_seconds = 60
)
```

## Arguments

- data:

  Raw accelerometer samples with a timestamp column.

- dynamic_range:

  Device range; inferred when omitted.

- epsilon:

  Margin inside the device limit, in g.

- min_count:

  Minimum number of samples required within a window.

- window_seconds:

  Window duration in seconds.

## Value

One row per window with axis-specific flags.
