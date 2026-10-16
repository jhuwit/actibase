# actibase 0.7.2

* Add `acti_flag_cdc_labels()` to map existing logical QC columns to CDC-style NHANES PAM letter codes.
* Document the CDC NHANES PAM flag mapping in the README and a package vignette, including known differences from CDC output.
* Standardize accelerometer axis columns named `X/Y/Z`, `x/y/z`, `acc_X/acc_x` variants, or `acceleration_X/acceleration_x` variants.
* Fail when upper- and lowercase versions of the same axis are both present. Warn once and prefer `X/Y/Z` when a complete canonical triplet and a complete `acc_*` or `acceleration_*` triplet are present.

# actibase 0.7.1

* Preserve missing values while applying minimum run lengths to logical QC flags.
* Return an empty data frame when all rows are removed by leading-zero trimming.
* Reject HMS times outside a single day instead of wrapping them to another minute.
* Return a typed empty data frame when splitting an empty set of intervals.
* Make the flag helpers configurable for different devices and sample rates. Sample rate defaults to `NULL` and is resolved through `get_sample_rate()` when continuity checks need it.
* Add general helpers for device-limit counts in caller-defined windows, contiguous device-limit runs, adjacent invalid periods, and repeated samples. CDC threshold values are used only in regression tests.
* Respect the minimum run length when an entire logical vector is `TRUE`.
* Break contiguous sample runs at timestamp gaps using the resolved sample rate.
* Add optional per-axis spike indicators and implement time-window spike counts using local extrema, a large-change threshold, and a caller-specified count.
* Return axis-specific interval-jump indicators and process raw samples in bounded window chunks to limit temporary memory use.
* Set the default minimum run for impossible-gravity flags to seven samples, use the device dynamic range to exclude clipped readings, and require the range from an argument or data metadata.
* Prefix flagging functions with `acti_` and standardize their input argument to `data`; use `min_count` and `window_seconds` for window-count and duration arguments.

# actibase 0.7.0

* Fix for `create_day_inclusion` -- number of observed minutes was wrong.
* Added transformations for `add_day_inclusion` and `min_required` as attribute for `create_day_inclusion`.
* `Roxygen: list(markdown = TRUE)` added to the DESCRIPTION.

# actibase 0.6.0

* New helpers for time: `acti_day_index` `acti_day_start` `acti_split_intervals_at_midnight` `acti_repeat_time_of_day` `acti_time_of_day` `acti_minute_to_hms` `acti_hms_to_minute` `acti_time_to_minute`.

# actibase 0.5.0

* Added remove leading zeroes function for `acti_calibrate`.

# actibase 0.3.0

* Bug fix for get_dynamic_range.

# actibase 0.2.0

* CRAN re-submission with minor updates to the DESCRIPTION file and %>%.

# actibase 0.1.0

* Initial CRAN submission.
* Baseline package added.
