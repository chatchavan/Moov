#' @title Read Moov sensor data
#'
#' @param db_path The path of the database file \code{user.db}
#'
#' @details
#' To use this function, you need to find the \code{user.db} fil from the dump of
#' MOOV data (@seealso \code{\link{read_moov_swim_bin}}) at
#' \code{/Applications/moov.core/Library/Application Support/user_data/( user id )/}.
#'
#' @return a tibble containing data of each workout session
#' @importFrom tibble as_tibble
#' @export
#'
#' @examples
#' \dontrun{
#' read_moov("user.db")
#' }
read_moov <- function(db_path) {
  # load user.db
  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
  workouts <- DBI::dbReadTable(con, "workouts")
  DBI::dbDisconnect(con)

  # return
  as_tibble(workouts)
}

#' @title Parse swimming summary data
#'
#' @description Filter the swimming data form Moov workout data.
#'     Then, extracts JSON data related to swimming
#'
#' @param workout A tibble containing workout data
#'
#' @return a tibble containing summarized data of each swimming session
#' @import dplyr
#' @importFrom jsonlite fromJSON
#' @importFrom magrittr %<>%
#' @export
#'
#' @examples
#' \dontrun{
#' workouts <- read_moov("user.db")
#' parse_swimming(workouts)
#' }
parse_swimming <- function(workouts) {

  # extract swimming data
  swimming <-
    workouts %>%
    filter(workout_type == 2) %>%
    rename(distance_m = magnitude)


  # get lap count and length
  swim_info <-
    (function(){
      n <- nrow(swimming)
      lap_counts <- rep(NA, n)
      lap_length_ms <- rep(NA, n)
      stroke_counts <- rep(NA, n)
      stroke_rates <- rep(NA, n)
      distance_per_strokes <- rep(NA, n)

      for (i in seq_len(nrow(swimming))) {

        # program_specific_data
        json <- swimming$program_specific_data[i]
        info <- fromJSON(json)
        lap_counts[i] <- info$lap_count
        lap_length_ms[i] <- info$lap_length_in_lap_unit
        stroke_counts[i] <- info$stroke_count


        # local_cache
        json2 <- swimming$local_cache[i]
        if (!is.na(json2)) {
          info2 <- fromJSON(json2)
          stroke_rates[i] <- ifelse(!is.null(info2$stroke_rate), info2$stroke_rate, info2$main_stroke_rate)
          distance_per_strokes[i] <- ifelse(!is.null(info2$distance_per_stroke), info2$distance_per_stroke, info2$main_distance_per_stroke)
        }
      }

      list(
        lap_counts = lap_counts,
        lap_length_ms = lap_length_ms,
        stroke_counts = stroke_counts,
        distance_per_strokes = distance_per_strokes,
        stroke_rates = stroke_rates
      )
    })()

  # add the info to the main tibble
  swimming %<>%
    mutate(
      lap_count = swim_info$lap_counts,
      lap_length_m = swim_info$lap_length_ms,
      stroke_count = swim_info$stroke_counts,
      distance_per_stroke = swim_info$distance_per_strokes,
      stroke_rate = swim_info$stroke_rates
    )
  rm(swim_info)

  # return
  swimming
}



#' @title Plot swimming stats over session
#'
#' @param swim_data A tibble containing the swimming summary data  (@seealso \code{\link{parse_swimming}}).
#' @param col_name The name of the column to plot. Interesting names are:
#'    \code{"distance_per_stroke", "stroke_rate"}. For all names, use \code{names(swim_data)}.
#' @param ylim A vector of two number to limits the y-axis of the graph
#'
#' @import ggplot2
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' plot_swim_summary(swim_data, "distance_per_stroke") + geom_smooth(method="loess")
#' }
plot_swim_summary <- function(swim_data, col_name, ylim = c(1.5, 2.4)) {
  ylim_ <- ylim
  swim_data %>%
    mutate(session = 1:n()) %>%
    ggplot(aes_string(x = "session", y = col_name)) +
    geom_point() +
    geom_line() +
    coord_cartesian(ylim = ylim_)
}

