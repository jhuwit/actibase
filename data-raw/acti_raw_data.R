## code to prepare `acti_raw_data` dataset goes here
library(tidyverse)
library(read.gt3x)
acti_fill_zeros = function(data) {
  data$all_zero = data$X == 0 & data$Y == 0 & data$Z == 0
  data$X = ifelse(data$all_zero, NA_real_, data$X)
  data$Y = ifelse(data$all_zero, NA_real_, data$Y)
  data$Z = ifelse(data$all_zero, NA_real_, data$Z)
  data$all_zero = NULL

  data$X = vctrs::vec_fill_missing(data$X, direction = "down")
  data$Y = vctrs::vec_fill_missing(data$Y, direction = "down")
  data$Z = vctrs::vec_fill_missing(data$Z, direction = "down")

  data$X[is.na(data$X)] = 0
  data$Y[is.na(data$Y)] = 0
  data$Z[is.na(data$Z)] = 0

  data = set_transformations(data, "filled_zeros", prefix = "acti_fill_zeros", add = TRUE)
  data
}


options(digits.secs = 3)
df = read.gt3x::read.gt3x("data-raw/TAS1H30182785_2019-09-17.gt3x.gz",
                          asDataFrame = TRUE, imputeZeroes = TRUE)
df = as.data.frame(df) %>%
  as_tibble()
acti_raw_data = acti_fill_zeros(df)

usethis::use_data(acti_raw_data, overwrite = TRUE, compress = "xz")
