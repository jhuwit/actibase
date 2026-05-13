

library(tidyverse)
library(actibase)
# devtools::load_all(".")
path = "inst/extdata/TAS1H30182785_2019-09-17.gt3x.gz"
data = ab_read_gt3x(path, apply_tz = TRUE)
data = ab_calibrate(data)
data = ab_standardize_data(data)

path = "inst/extdata/ax3_testfile.cwa.gz"
data = ab_read_cwa(path, apply_tz = TRUE)
data = ab_standardize_data(data)

# path = "inst/extdata/TAS1H30182785_2019-09-17.gt3x.gz"
# data = ab_read_gt3x(path, apply_tz = FALSE, fill_zeroes = TRUE, digits = 5)
# data = ab_standardize_data(data)

# unres_counts = ww_calculate_counts(std, 60L)

#!!! need to att sample_rate to the result
resampled = ab_resample(data, sample_rate = 30L)
get_transformations(resampled)
attr(resampled, "sample_rate")

counts = ab_calculate_counts(resampled, 60L)
get_transformations(counts)

wear = ab_calculate_nonwear(counts, method = "choi")
counts
get_transformations(wear)

result = dplyr::full_join(counts, wear, by = "time") %>%
  dplyr::mutate(wear = ifelse(is.na(wear), FALSE, wear))
result = set_transformations(result,
                             c("counts_wear_merge",
                               get_transformations(wear)
                             ),
                             add = FALSE)
get_transformations(result)

processed = ab_process(data)
get_transformations(processed)





#
# result = dplyr::full_join(result, sdata, by = "time")
#
# result = result %>%
#   dplyr::mutate(date = lubridate::date(time))
#
# per_day = result %>%
#   dplyr::mutate(wear = ifelse(is.na(wear), FALSE, wear)) %>%
#   dplyr::group_by(date) %>%
#   dplyr::summarise(
#     wear_time = sum(wear, na.rm = TRUE),
#     counts = sum(counts, na.rm = TRUE),
#     steps = sum(steps, na.rm = TRUE)
#   ) %>%
#   dplyr::ungroup()
# per_day
# min_wear_time_per_day = 200
# final_data = per_day %>%
#   filter(wear_time >= min_wear_time_per_day)
# min_n_day = 3
# if (n_distinct(final_data$date) < min_n_day) {
#   final_data = NULL
# }
# sums = final_data %>%
#   summarise(across(c(counts, steps), mean))
# library(mapnhanespa)
#
# mapnhanespa::nhanes_pa_quantile(
#   value = sums$counts,
#   measure = "AC"
# )
# mapnhanespa::nhanes_pa_quantile(
#   value = sums$steps,
#   measure = "scsslsteps"
# )
#
#
# mapnhanespa::map_nhanes_pa_quantiles(
#   sums %>%
#     select(value = steps) %>%
#     mutate(measure = "scsslsteps",
#            age = 30),
#   sex = NULL
# )
#
# mapnhanespa::map_nhanes_pa_quantiles(
#   sums %>%
#     select(value = steps) %>%
#     mutate(measure = "scsslsteps",
#            age = 30,
#            sex = "Male")
# )


