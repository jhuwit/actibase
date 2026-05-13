Sys.setenv("RETICULATE_PYTHON" = "managed")
library(reticulate)
py_require("stepcount==3.11.0", python_version = "3.10")
sc = import("stepcount")
sc$stepcount
stepcount::stepcount_check()

library(tidyverse)
library(activerse)
path = "~/Dropbox/Data/wearable_pilot/data/raw/ag_axivity_test/John/114890_0000000000.cwa"

# path = "inst/extdata/TAS1H30182785_2019-09-17.gt3x.gz"
data = acti_read_cwa(path)
function(data, calibrate = FALSE) {
  if (calibrate) {
    data = acti_calibrate(data)
  }

  # already resampled
  processed = acti_process(data)
  trans = get_transformations(processed)

  steps = acti_calculate_stepcount(data)
  step_trans = get_transformations(steps)
  processed = processed %>%
    dplyr::full_join(steps)

  res = create_day_inclusion(processed, min_required = 1368L)
  processed = processed %>%
    mutate(date = as.Date(time)) %>%
    left_join(res)
  processed %>%
    mutate(log10AC = log(counts)) %>%

    summarise
}







