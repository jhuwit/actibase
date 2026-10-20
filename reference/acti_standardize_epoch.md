# Standardize an Epoch Length

Converts an epoch given as a number, a string such as `"1 min"`,
`"30s"`, `"5 seconds"`, or `"1 hour"`, a `lubridate` `Duration` or
`Period`, or a `difftime` into a consistent representation: either a
number in a given unit (e.g. `60` seconds) or a string that can be
passed to
[`lubridate::floor_date()`](https://lubridate.tidyverse.org/reference/round_date.html)
(e.g. `"1 min"`).

## Usage

``` r
acti_standardize_epoch(
  epoch,
  unit = c("seconds", "minutes", "hours", "days", "auto"),
  output = c("numeric", "character"),
  input_unit = c("seconds", "minutes", "hours", "days")
)

acti_standardise_epoch(
  epoch,
  unit = c("seconds", "minutes", "hours", "days", "auto"),
  output = c("numeric", "character"),
  input_unit = c("seconds", "minutes", "hours", "days")
)
```

## Arguments

- epoch:

  A single epoch length: a positive number (in `input_unit`), a string
  parseable by
  [`lubridate::duration()`](https://lubridate.tidyverse.org/reference/duration.html)
  (`"1 min"`, `"1min"`, `"30s"`, `"2 hours"`; `"hr"` and the `lubridate`
  arbitrary units such as `"90 aseconds"` are also accepted), a
  `Duration`, a `Period`, or a `difftime`. Calendar units without a
  fixed length (months, quarters, years, ...) are not epochs and give an
  error.

- unit:

  Unit to standardize the epoch to: one of `"seconds"`, `"minutes"`,
  `"hours"`, `"days"`, or `"auto"`. `"auto"` is only available for
  `output = "character"` and picks the largest unit that
  [`lubridate::floor_date()`](https://lubridate.tidyverse.org/reference/round_date.html)
  can round with (e.g. `"1 min"` rather than `"60 secs"`), falling back
  to `"aseconds"` for lengths such as 90 seconds. Defaults to
  `"seconds"` for numeric output and `"auto"` for character output.
  Singular and abbreviated unit names are matched to the unit they name:
  `"second"`, `"sec"`, and `"secs"` are treated as `"seconds"`;
  `"minute"`, `"min"`, and `"mins"` as `"minutes"`; `"hour"`, `"hr"`,
  and `"hrs"` as `"hours"`; and `"day"` as `"days"`. Other names,
  including partial ones such as `"m"`, are an error.

- output:

  Type of output: `"numeric"` returns the length in `unit`,
  `"character"` returns a string such as `"30 secs"`, `"1 min"`, or
  `"2 hours"`, which
  [`lubridate::floor_date()`](https://lubridate.tidyverse.org/reference/round_date.html),
  [`seq()`](https://rdrr.io/r/base/seq.html),
  [`cut()`](https://rdrr.io/r/base/cut.html), and `MIMSunit` all
  understand.

- input_unit:

  Unit of `epoch` when `epoch` is numeric (or a string with no unit,
  such as `"60"`). Ignored otherwise. Abbreviations are matched as for
  `unit`.

## Value

A numeric value or a single string.

## Note

The `"aseconds"` fallback for `output = "character"` relies on the
absolute-unit rounding that
[`lubridate::floor_date()`](https://lubridate.tidyverse.org/reference/round_date.html)
has supported since lubridate 1.9.0.

## Examples

``` r
acti_standardize_epoch(60)
#> [1] 60
acti_standardize_epoch("1 min")
#> [1] 60
acti_standardize_epoch("1 min", unit = "minutes")
#> [1] 1
acti_standardize_epoch(30, output = "character")
#> [1] "30 secs"
acti_standardize_epoch(60, output = "character")
#> [1] "1 min"
acti_standardize_epoch(5, input_unit = "minutes")
#> [1] 300
acti_standardize_epoch("2 hours", unit = "minutes", output = "character")
#> [1] "120 mins"
acti_standardize_epoch(lubridate::minutes(5))
#> [1] 300
acti_standardize_epoch(as.difftime(30, units = "secs"), output = "character")
#> [1] "30 secs"
```
