

#' Create Day-Level Inclusion information
#'
#' @param data A `data.frame` with the columns `time`
#' @param min_required Number of minutes required in a day to be called `included`
#'
#' @return A `data.frame` for each day with information of number of minutes observed
#' and included
#' @export
#'
#' @examples
#' data = acti_raw_data %>%
#'   dplyr::mutate(r = sqrt(X^2 + Y^2 + Z^2),
#'                 time = lubridate::floor_date(time, "1 minute")) %>%
#'   dplyr::group_by(time) %>%
#'   dplyr::summarise(r = sum(r), .groups = "drop") %>%
#'   dplyr::mutate(wear = r > 4000)
#'
#' res = create_day_inclusion(data)
create_day_inclusion = function(
    data,
    min_required = 1368L
) {
  time = n_minutes_observed = minute = n_minutes_wear = wear = hourtime = NULL
  rm(list = c("n_minutes_wear", "wear", "hourtime", "minute",
              "n_minutes_observed", "time"))
  HEADER_TIME_STAMP = observed = NULL
  rm(list = c("observed", "HEADER_TIME_STAMP"))
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)

  sd = setdiff(c("time", "wear"), colnames(data))
  if (length(sd) > 0) {
    cn = paste(sd, collapse = ", ")
    stop(paste0("Columns ", cn, " are not present in the data"))
  }
  data = data %>%
    dplyr::mutate(
      date = as_date_safe(time),
      minute = lubridate::floor_date(time, unit = "minutes"),
      hourtime = hms::as_hms(time))

  # make distinct for summarization
  data = data %>%
    dplyr::distinct(date, minute, hourtime, wear)

  # Check for duplicates - should not be there
  suppressMessages({
    dupes = janitor::get_dupes(data, date, minute)
  })
  if (nrow(dupes) > 0) {
    stop("There are duplicate rows of date and minute!")
  }

  suppressMessages({
    dupes = janitor::get_dupes(data, date, hourtime)
  })
  if (nrow(dupes) > 0) {
    stop("There are duplicate rows of date and minute!")
  }
  all_minutes = expand.grid(
    date = unique(data$date),
    hourtime = hms::hms(minutes = 1:1440),
    observed = TRUE
  )
  data = data %>%
    dplyr::full_join(all_minutes, by = dplyr::join_by(date, hourtime)) %>%
    tidyr::replace_na(list(wear = FALSE,
                           observed = FALSE))

  # summarise
  res = data %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(
      n_minutes_wear = sum(wear),
      n_minutes_observed = sum(observed),
    ) %>%
    dplyr::mutate(
      prop_minutes_wear = n_minutes_wear / 1440L,
      prop_minutes_wear_from_observed = n_minutes_wear / n_minutes_observed
    ) %>%
    dplyr::mutate(
      is_included = n_minutes_wear >= min_required
    )

  return(res)
}

#' @export
#' @rdname create_day_inclusion
#' @param ... arguments to pass to [create_day_inclusion] when using
#' [add_day_inclusion]
add_day_inclusion = function(
    data,
    ...
) {
  day_data =   create_day_inclusion(data, ...)
  data = acti_standardize_data(data, subset_xyz = FALSE, check_xyz = FALSE)
  data = data %>%
    dplyr::mutate(
      date = as_date_safe(time)
    )

  data = data %>%
    dplyr::left_join(day_data, day_data, by = dplyr::join_by(date))

  data
}
