## R CMD check results

Not run for version 0.7.2 yet.

## Changes in this release

* Add `acti_flag_cdc_labels()` and document how package flags relate to CDC NHANES PAM letter codes.
* Accept common case and prefix variants of X/Y/Z accelerometer column names in `acti_standardize_data()`.
* Reject ambiguous upper/lowercase duplicates for an axis.
* Prefer canonical `X/Y/Z` columns and issue one warning when a complete canonical axis triplet is present alongside a complete `acc_*` or `acceleration_*` triplet.
