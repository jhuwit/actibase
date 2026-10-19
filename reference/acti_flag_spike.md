# Flag Spikes

Flag Spikes

## Usage

``` r
acti_flag_spike(data, spike_size = 11, sample_rate = NULL, by_axis = FALSE)

acti_flag_interval_jump(
  data,
  verbose = TRUE,
  window_seconds = 1,
  min_repeats = 10,
  min_distinct = 3,
  min_separation = 0.5,
  by_axis = FALSE,
  digits = 3,
  chunk_windows = 50000L
)

acti_flag_spike_second(
  data,
  spike_size = 11,
  window_seconds = 1,
  min_spikes = 13,
  max_change_seconds = 0.1,
  sample_rate = NULL,
  by_axis = FALSE
)

acti_flag_device_limit(data, dynamic_range = NULL, epsilon = 0.05)

acti_flag_adjacent_device_limit_samples(
  data,
  dynamic_range = NULL,
  epsilon = 0.05,
  sample_rate = NULL
)

acti_flag_contiguous_device_limit(
  data,
  dynamic_range = NULL,
  epsilon = 0.05,
  sample_rate = NULL
)

acti_flag_same_value(data, min_length = 1, sample_rate = NULL)

acti_flag_all_zero(data, min_length = 3, sample_rate = NULL)

acti_flag_impossible(
  data,
  min_length = 7,
  change_threshold = 0.01,
  magnitude_threshold = 1.25,
  sample_rate = NULL,
  dynamic_range = NULL
)
```

## Arguments

- data:

  A data set of actigraphy

- spike_size:

  size of "spike" - which is the absolute difference in contiguous
  observations on a single axis

- sample_rate:

  Sampling frequency; extracted from data when omitted.

- by_axis:

  If `TRUE`, also return one indicator per axis.

- verbose:

  print diagnostic messages

- window_seconds:

  Width of each window used by `acti_flag_spike_second`.

- min_repeats:

  Minimum occurrences of an axis value in a window.

- min_distinct:

  Minimum number of frequent axis values required.

- min_separation:

  Minimum separation between retained values.

- digits:

  Number of decimal places used when grouping axis values.

- chunk_windows:

  Number of windows processed together to bound memory.

- min_spikes:

  Minimum number of qualifying extrema in a window.

- max_change_seconds:

  Maximum time between an extremum and a qualifying large change; the
  CDC rule uses less than 0.1 seconds.

- dynamic_range:

  Device dynamic range. When omitted, it is read from the data with
  [`get_dynamic_range()`](https://jhuwit.github.io/actibase/reference/get_dynamic_range.md);
  data-based estimates are rejected.

- epsilon:

  A small adjustment so that if values are within the device limit, but
  minus epsilon, still flagged as hitting the limit. For example, if
  `dynamic_range = c(-6, 6)` and `epsilon = 0.05`, then any value \<=
  `-5.95` or `>= 5.95` gravity units will be flagged

- min_length:

  minimum length of the condition for contiguous samples. If
  `min_length = 7`, then at least 7 `TRUE`s in a row is required, any
  stretches of single `TRUE` values or 2 `TRUE` followed by `FALSE`,
  will be set to `FALSE`.

- change_threshold:

  Maximum absolute change between adjacent samples on each axis for a
  stable run to qualify. The default is 0.01 g.

- magnitude_threshold:

  Minimum vector magnitude required at both ends of each stable adjacent
  pair. The default is 1.25 g.

## Value

A data set back

## Details

These functions provide configurable sample-level and window-level
signal indicators. Thresholds and run or window lengths are arguments;
they do not encode a specific device or study's quality-control scheme.
When continuity is checked, `sample_rate` is extracted with
[`get_sample_rate()`](https://jhuwit.github.io/actibase/reference/get_sample_rate.md)
unless supplied explicitly.

## Note

`acti_flag_spike` compares adjacent observations by axis. The
`acti_flag_spike_second` checks for repeated local extrema followed by a
large change within the requested time, then counts them within each
window.

## Examples

``` r
res = acti_raw_data
res = acti_flag_spike(res)
res = acti_flag_interval_jump(res)
#> Processed X windows 2405 of 2405
#> Processed Y windows 2405 of 2405
#> Processed Z windows 2405 of 2405
res = acti_flag_spike_second(res)
res = acti_flag_same_value(res)
res = acti_flag_device_limit(res)
res = acti_flag_all_zero(res)
res = acti_flag_impossible(res)
```
