# Mapping NHANES PAM quality flags

``` r

library(actibase)
```

## Scope

CDC NHANES PAM quality flags are reported at the minute level. Most
`actibase` detectors operate on raw samples, so the table identifies the
closest function and its output, along with parameters and known
differences. These helpers are general-purpose; CDC-specific thresholds
below are example settings for reproducing the NHANES rules.

## CDC code mapping

| CDC code | CDC definition (summary) | `actibase` function and output | Match notes |
|:---|:---|:---|:---|
| A–C | Axis-specific spikes: adjacent-sample change ≥11 g | `acti_flag_spike(by_axis = TRUE)`: `flag_spike_X/Y/Z` | Sample-level; set `spike_size = 11`. |
| D–F | Per-minute count of positive near-limit values, ≥690 samples | [`acti_flag_device_limit_windows()`](https://jhuwit.github.io/actibase/reference/acti_flag_device_limit_windows.md): `flag_device_max_X/Y/Z` | Set `min_count = 690`, `window_seconds = 60`, range ±6 g, and `epsilon = 0.05`. |
| G–I | Per-minute count of negative near-limit values, ≥690 samples | [`acti_flag_device_limit_windows()`](https://jhuwit.github.io/actibase/reference/acti_flag_device_limit_windows.md): `flag_device_min_X/Y/Z` | Same thresholds as D–F, for negative values. |
| J–L | Contiguous positive near-limit run, ≥160 samples | [`acti_flag_contiguous_device_limit_runs()`](https://jhuwit.github.io/actibase/reference/acti_flag_contiguous_device_limit_runs.md): `flag_contiguous_max_X/Y/Z` | Set `min_length = 160`; CDC assigns the run to every overlapping minute. |
| M–O | Contiguous negative near-limit run, ≥160 samples | [`acti_flag_contiguous_device_limit_runs()`](https://jhuwit.github.io/actibase/reference/acti_flag_contiguous_device_limit_runs.md): `flag_contiguous_min_X/Y/Z` | Set `min_length = 160`; CDC permits runs to cross minute boundaries. |
| P | Contiguous impossible gravity values | [`acti_flag_impossible()`](https://jhuwit.github.io/actibase/reference/acti_flag_spike.md): `flag_impossible` | CDC settings: seven samples, \<0.01 g change on each axis, vector magnitude \>1.25 g, excluding ±6 g values. |
| Q | Contiguous adjacent zero values | [`acti_flag_all_zero()`](https://jhuwit.github.io/actibase/reference/acti_flag_spike.md): `flag_all_zero` | Package checks all three axes. CDC documents a historical programming error that checked only X; exact reproduction of that error is not intended. |
| R | Contiguous identical, non-zero three-axis samples | [`acti_flag_repeated_samples()`](https://jhuwit.github.io/actibase/reference/acti_flag_repeated_samples.md): `flag_repeated_samples` | Use `min_length = 2`, `exclude_zero = TRUE`, `require_equal_axes = TRUE`. CDC run lengths and minute attribution may differ. |
| S–U | Axis-specific 1-second spike counts | `acti_flag_spike_second(by_axis = TRUE)`: `flag_spike_second_X/Y/Z` | Set `window_seconds = 1`, `min_spikes = 13`, `spike_size = 11`; CDC counts qualifying local-extremum events. |
| V | Minute before and after an invalid minute | [`acti_flag_adjacent_invalid_periods()`](https://jhuwit.github.io/actibase/reference/acti_flag_adjacent_invalid_periods.md): `flag_adjacent_invalid` | Caller supplies invalid periods. Match CDC’s hour-boundary exception with the `group` argument. |
| W–Y | Axis-specific interval jumps within a second | `acti_flag_interval_jump(by_axis = TRUE)`: `flag_interval_jump_X/Y/Z` | Set `window_seconds = 1`, `min_repeats = 10`, `min_distinct = 3`, `min_separation = 0.5`; this is an approximation. |

The CDC summary describes the 690-sample positive and negative limits as
occurring in a minute, and the contiguous flags as runs of at least 160
samples. At 80 Hz, these correspond to about 8.6 seconds and 2 seconds,
respectively. Minute boundaries and CDC’s separate raw-data flagging
workflow can affect direct comparisons.

## Producing letter labels

[`acti_flag_cdc_labels()`](https://jhuwit.github.io/actibase/reference/acti_flag_cdc_labels.md)
maps logical flag columns already in a data frame to CDC letter codes.
It does not run detectors. For axis-specific codes, create axis-specific
outputs first (using `by_axis = TRUE` where available):

``` r

raw <- acti_flag_spike(raw, by_axis = TRUE)
raw <- acti_flag_device_limit_windows(raw, dynamic_range = c(-6, 6),
                                      min_count = 690)
raw <- acti_flag_contiguous_device_limit_runs(raw, dynamic_range = c(-6, 6),
                                              min_length = 160)
raw <- acti_flag_cdc_labels(raw)
```

By default, the result is stored in `PAXFLGSM`, with multiple letters
concatenated alphabetically (for example, `"ABP"`). Rows with no true
mapped flags receive an empty string. You can provide a custom named
`flag_map` when your columns use different names.

## Reference

Definitions and the documented caveats about the historical Q flag and
contiguous-run reporting come from the [CDC NHANES PAM Data Quality Flag
Summary Table](https://wwwn.cdc.gov/nchs/nhanes/Pam/Default.aspx).
