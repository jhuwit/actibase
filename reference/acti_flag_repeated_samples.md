# Flag repeated samples

Marks samples in runs of repeated three-axis observations. Options can
exclude all-zero observations or require equal values across the three
axes. Timestamp gaps break runs based on the supplied or extracted rate.

## Usage

``` r
acti_flag_repeated_samples(
  data,
  sample_rate = NULL,
  min_length = 2,
  exclude_zero = FALSE,
  require_equal_axes = FALSE
)
```

## Arguments

- data:

  Raw accelerometer data.

- sample_rate:

  Sampling frequency; extracted from data when omitted.

- min_length:

  Minimum repeated run length in samples.

- exclude_zero:

  Exclude samples where all axes are zero.

- require_equal_axes:

  Require all axes to have equal values.

## Value

Input data with `flag_repeated_samples`.
