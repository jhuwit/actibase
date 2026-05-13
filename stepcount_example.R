Sys.setenv("RETICULATE_PYTHON" = "managed")
library(reticulate)
py_require("stepcount==3.11.0", python_version = "3.10")
sc = import("stepcount")
sc$stepcount
stepcount::stepcount_check()

# path = "inst/extdata/ax3_testfile.cwa.gz"
path = "~/Dropbox/Data/wearable_pilot/data/raw/ag_axivity_test/John/114890_0000000000.cwa"
data = ab_read_cwa(path, apply_tz = TRUE)
data = ab_standardize_data(data)

steps = stepcount::stepcount(data,
                             sample_rate = attr(data, "sample_rate"),
                             model_type = "ssl")
sdata = steps$steps
sdata = set_transformations(sdata,
                            c("ssl_stepcounts_created",
                              get_transformations(data)
                            ),
                            add = FALSE)

trans = get_transformations(sdata)
sdata = sdata %>%
  dplyr::mutate(time = lubridate::floor_date(time, unit = "1 min")) %>%
  dplyr::group_by(time) %>%
  dplyr::summarise(steps = sum(steps, na.rm = TRUE)) %>%
  dplyr::ungroup()
sdata = set_transformations(sdata, trans)
sdata = set_transformations(sdata,
                            "steps_summarized_per_60s_epoch",
                            add = TRUE)
get_transformations(sdata)

sdata = sdata %>%
  dplyr::mutate(steps = ifelse(!is.finite(steps), NA_integer_, steps))
