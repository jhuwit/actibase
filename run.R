Sys.setenv("RETICULATE_PYTHON" = "managed")
library(reticulate)
# py_require("numpy==1.24.*", python_version = "3.10")
py_require("stepcount==3.11.0", python_version = "3.10")
sc = import("stepcount")
sc$stepcount
stepcount::stepcount_check()

library(tidyverse)
library(actigraph.sleepr)
library(agcounts)
library(stepcount)
library(read.gt3x)
library(waterways)
options(digits.secs = 3)



file = "~/Dropbox/Projects/nhanes_80hz/data/csv/pax_g/62357.csv.gz"
source("R/standardize_data.R")

data = readr::read_csv(file,
                      col_types = readr::cols(
                        # HEADER_TIMESTAMP = col_datetime_with_frac_secs(),
                        HEADER_TIMESTAMP = vroom::col_datetime(),
                        X = vroom::col_double(),
                        Y = vroom::col_double(),
                        Z = vroom::col_double()
                      )
)
readr::stop_for_problems(data)

data = SummarizedActigraphy::fix_zeros(data)

std = standardize_data(data)
sample_rate = 80L
attr(std, "sample_rate") = sample_rate

# unres_counts = ww_calculate_counts(std, 60L)

#!!! need to att sample_rate to the result
res = SummarizedActigraphy::resample_accel_data(std, sample_rate = 30L)
attr(res, "sample_rate") = 30L
counts = ww_calculate_counts(res, 60L)


wear = ww_calculate_nonwear(counts, method = "choi")

result = dplyr::full_join(counts, wear, by = "time") %>%
  dplyr::mutate(wear = ifelse(is.na(wear), FALSE, wear))


steps = stepcount::stepcount(std, sample_rate = sample_rate, model_type = "ssl")

sdata = steps$steps %>%
  dplyr::mutate(time = lubridate::floor_date(time, unit = "1 min")) %>%
  dplyr::group_by(time) %>%
  dplyr::summarise(steps = sum(steps, na.rm = TRUE)) %>%
  dplyr::ungroup()
sdata = sdata %>%
  dplyr::mutate(steps = ifelse(!is.finite(steps), NA_integer_, steps))

result = dplyr::full_join(result, sdata, by = "time")

result = result %>%
  dplyr::mutate(date = lubridate::date(time))

per_day = result %>%
  dplyr::mutate(wear = ifelse(is.na(wear), FALSE, wear)) %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(
    wear_time = sum(wear, na.rm = TRUE),
    counts = sum(counts, na.rm = TRUE),
    steps = sum(steps, na.rm = TRUE)
  ) %>%
  dplyr::ungroup()
per_day
min_wear_time_per_day = 200
final_data = per_day %>%
  filter(wear_time >= min_wear_time_per_day)
min_n_day = 3
if (n_distinct(final_data$date) < min_n_day) {
  final_data = NULL
}
sums = final_data %>%
  summarise(across(c(counts, steps), mean))
library(mapnhanespa)

mapnhanespa::nhanes_pa_quantile(
  value = sums$counts,
  measure = "AC"
)
mapnhanespa::nhanes_pa_quantile(
  value = sums$steps,
  measure = "scsslsteps"
)


mapnhanespa::map_nhanes_pa_quantiles(
  sums %>%
    select(value = steps) %>%
    mutate(measure = "scsslsteps",
           age = 30),
  sex = NULL
)

mapnhanespa::map_nhanes_pa_quantiles(
  sums %>%
    select(value = steps) %>%
    mutate(measure = "scsslsteps",
           age = 30,
           sex = "Male")
)
