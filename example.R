Sys.setenv("RETICULATE_PYTHON" = "managed")
library(reticulate)
py_require("stepcount==3.11.0", python_version = "3.10")
sc = import("stepcount")
sc$stepcount
stepcount::stepcount_check()

library(tidyverse)
library(activerse)
# devtools::load_all(".")
path = "~/Dropbox/Data/wearable_pilot/data/raw/ag_axivity_test/John/114890_0000000000.cwa"

# path = "inst/extdata/TAS1H30182785_2019-09-17.gt3x.gz"
data = acti_read_cwa(path)
# data = acti_calibrate(data)

# already resampled
processed = acti_process(data)
get_transformations(processed)

res = create_day_inclusion(processed)
data = data %>%
  mutate(date = as.Date(time)) %>%
  left_join(res)

steps = acti_calculate_stepcount(data)






