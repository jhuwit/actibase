# Create Day-Level Inclusion information

Create Day-Level Inclusion information

## Usage

``` r
create_day_inclusion(data, min_required = 1368L)

add_day_inclusion(data, ...)
```

## Arguments

- data:

  A \`data.frame\` with the columns \`time\`

- min_required:

  Number of minutes required in a day to be called \`included\`

- ...:

  arguments to pass to \[create_day_inclusion\] when using
  \[add_day_inclusion\]

## Value

A \`data.frame\` for each day with information of number of minutes
observed and included

## Examples

``` r
data = acti_raw_data %>%
  dplyr::mutate(r = sqrt(X^2 + Y^2 + Z^2),
                time = lubridate::floor_date(time, "1 minute")) %>%
  dplyr::group_by(time) %>%
  dplyr::summarise(r = sum(r), .groups = "drop") %>%
  dplyr::mutate(wear = r > 4000)

res = create_day_inclusion(data)
```
