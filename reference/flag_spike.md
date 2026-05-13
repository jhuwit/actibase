# Flag Spikes

Flag Spikes

## Usage

``` r
flag_spike(df, spike_size = 11)

flag_interval_jump(df, verbose = FALSE)

flag_spike_second(df, spike_size = 11)

flag_device_limit(df, dynamic_range = NULL, epsilon = 0.05)

flag_contiguous_device_limit(df, dynamic_range = NULL, epsilon = 0.05)

flag_same_value(df, min_length = 1)

flag_all_zero(df, min_length = 3)

flag_impossible(df, min_length = 6)
```

## Source

<https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXMIN_G.htm>

## Arguments

- df:

  A data set of actigraphy

- spike_size:

  size of "spike" - which is the absolute difference in contiguous
  observations on a single axis

- verbose:

  print diagnostic messages

- dynamic_range:

  dynamic range of the device, used to find the device limit.

- epsilon:

  A small adjustment so that if values are within the device limit, but
  minus epsilon, still flagged as hitting the limit. For example, if
  \`dynamic_range = c(-6, 6)\` and \`epsilon = 0.05\`, then any value
  \<= \`-5.95\` or \`\>= 5.95\` gravity units will be flagged

- min_length:

  minimum length of the condition for contiguous samples. If
  \`min_length = 3\`, then at least 3 \`TRUE\`s in a row is required,
  any stretches of single \`TRUE\` values or 2 \`TRUE\` followed by
  \`FALSE\`, will be set to \`FALSE\`.

## Value

A data set back

## Note

\`flag_spike\` looks if 2 contiguous values, within each axis, are
larger than a absolute size (\`11\` gravity units). The
\`flag_spike_second\` function groups the data by second, finds the
range of values, within each axis, and determines if this range is
greater than a specified size (\`11\` g).

## Examples

``` r
res = acti_raw_data
res = flag_spike(res)
res = flag_interval_jump(res)
res = flag_spike_second(res)
res = flag_same_value(res)
res = flag_device_limit(res)
#> Warning: No dynamic range found in header, using data estimate
res = flag_all_zero(res)
res = flag_impossible(res)
```
