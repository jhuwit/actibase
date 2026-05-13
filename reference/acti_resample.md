# Resample 3-axial input signal to a specific sampling rate

Resample 3-axial input signal to a specific sampling rate

## Usage

``` r
acti_resample(data, sample_rate, method = "linear", ...)

acti_resample_to_time(data, times, method = "linear", ...)
```

## Arguments

- data:

  A \`data.frame\` with a column for time in \`POSIXct\` (usually
  \`time\`), and \`X\`, \`Y\`, \`Z\`

- sample_rate:

  sampling frequency, coercible to an integer. This is the sampling rate
  you're sampling the data \*into\*.

- method:

  method for interpolation. Options are \`"linear"/"constant"\`, which
  uses \`stats::approx\`, or one of \`"fmm", "periodic", "natural",
  "monoH.FC", "hyman"\`, which uses \`stats::spline\`

- ...:

  additional arguments to pass to \[stats::approx()\] or
  \[stats::spline\]

- times:

  a vector of \`POSIXct\` date/time values to interpolate the data to

## Value

A \`data.frame\`/\`tibble\` of \`time\` and \`X\`, \`Y\`, \`Z\`.

## Examples

``` r
options(digits.secs = 3)
x = acti_raw_data
res = acti_resample(data = x, sample_rate = 80)
res = acti_resample(data = x, sample_rate = 100)
res = acti_resample(data = x, sample_rate = 1)
res = acti_resample_to_time(
  data = x,
  times = lubridate::floor_date(x$time, unit = "1 sec"),
)
res_nat = acti_resample_to_time(
  data = x,
  times = lubridate::floor_date(x$time, unit = "1 sec"),
  method = "natural"
)
```
