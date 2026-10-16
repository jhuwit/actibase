# Flag contiguous device-limit samples

Marks samples in runs meeting a device-limit condition. Runs are broken
at timestamp gaps based on the extracted or supplied sampling rate.

## Usage

``` r
acti_flag_contiguous_device_limits(
  data,
  dynamic_range = NULL,
  epsilon = 0.05,
  min_length = 1,
  sample_rate = NULL
)
```

## Arguments

- data:

  Raw accelerometer data.

- dynamic_range:

  Device range; inferred when omitted.

- epsilon:

  Margin inside the device limit, in g.

- min_length:

  Minimum run length.

- sample_rate:

  Sampling frequency; extracted from data when omitted.

## Value

Input data with axis-specific contiguous device-limit columns.
