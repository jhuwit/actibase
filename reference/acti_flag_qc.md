# Flag Quality Control Values

Flag Quality Control Values

## Usage

``` r
acti_flag_qc(
  data,
  dynamic_range = NULL,
  verbose = TRUE,
  flags = c("all", "spike", "interval_jump", "spike_second", "same_value",
    "device_limit", "all_zero", "impossible")
)

acti_flag_qc_all(
  data,
  dynamic_range = NULL,
  verbose = TRUE,
  flags = c("all", "spike", "interval_jump", "spike_second", "same_value",
    "device_limit", "all_zero", "impossible")
)
```

## Arguments

- data:

  A data set of actigraphy

- dynamic_range:

  dynamic range of the device, used to find the device limit.

- verbose:

  print diagnostic messages

- flags:

  the flags to run for QC. If you set this to `"all"`, then all flags
  are run, as the default.

## Value

A data set with a `flags` column (`acti_flag_qc`) or a number of columns
starting with `flag_*` (`acti_flag_qc_all`)

## Examples

``` r
res = acti_raw_data
out = acti_flag_qc(res)
#> Flagging Spikes
#> Flagging Interval Jumps
#> Flagging Spikes at Second-level
#> Flagging Repeated Values
#> Flagging Device Limit Values
#> Flagging Zero Values
#> Flagging 'Impossible' Values
```
