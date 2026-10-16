# Label quality flags with CDC NHANES letters

Creates a character column containing the CDC letter codes corresponding
to TRUE package flag columns. Multiple codes are concatenated in
alphabetical order. The default map expects axis-specific columns where
the package provides them; run the relevant detector with
`by_axis = TRUE` for spikes and interval jumps. The helper maps existing
results and does not run any flag detector.

## Usage

``` r
acti_flag_cdc_labels(
  data,
  flag_map = c(A = "flag_spike_X", B = "flag_spike_Y", C = "flag_spike_Z", D =
    "flag_device_max_X", E = "flag_device_max_Y", F = "flag_device_max_Z", G =
    "flag_device_min_X", H = "flag_device_min_Y", I = "flag_device_min_Z", J =
    "flag_contiguous_max_X", K = "flag_contiguous_max_Y", L = "flag_contiguous_max_Z", M
    = "flag_contiguous_min_X", N = "flag_contiguous_min_Y", O = "flag_contiguous_min_Z",
    P = "flag_impossible", Q = "flag_all_zero", R = "flag_repeated_samples", S =
    "flag_spike_second_X", T = "flag_spike_second_Y", 
     U = "flag_spike_second_Z", V
    = "flag_adjacent_invalid", W = "flag_interval_jump_X", X = "flag_interval_jump_Y", Y
    = "flag_interval_jump_Z"),
  output = "PAXFLGSM",
  separator = ""
)
```

## Arguments

- data:

  Data containing logical flag columns.

- flag_map:

  Named character vector mapping CDC letters to column names. Defaults
  to the package's axis-specific flag names and uses the mapped columns
  present in `data`, allowing a selected subset of detectors. A custom
  map must refer to existing columns.

- output:

  Name of the output column.

- separator:

  String inserted between multiple letters. Use `""` for CDC-style
  compact values such as `"ABP"`.

## Value

Input data with a character column of CDC-style flag letters.
