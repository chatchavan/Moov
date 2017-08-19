#' @title Load the MOOV sensor data from a swimming session
#'
#' @description
#' Find the "swimming_result.pb" for the given session \code{id}. Load and
#' extract the part that contains sensor data.
#'
#' @param id session ID, e.g., \code{"swimming-k5y5pqbib17vbjqrh9gr16e"}
#' @param swimming_root path to the "swimming" folder (see the Details section)
#'
#' @details
#' To use this function, you need to extract the "swimming" folder from your
#' iOS backup. One solution is to use iExplorer (\url{https://macroplant.com/iexplorer}).
#' (The free version allows you to extract unlimited number of files.)
#' The \code{swimming_root} folder is in:
#' \code{/Applications/moov.core/Library/Application Support/user_data/( user id )/swimming}
#'
#' I haven't figured out the acutal meaning of the data. Heck, I don't know whether
#' I extracted it correctly! However, preliminary plots shows that the data are periodic.
#' The data seems like what we would get from accelerometer in lap swimming.
#' The periodicity of strokes and laps are present in this data.
#'
#' Known limitation: this code cannot parse recent swim logs that use different header.
#' I already figured out the binary that marks the beginning of the log (see the source code).
#' However, I haven't got around to add that part in code yet.
#'
#'
#' @return a two-column tibble. `x`: sequence number, `y`: value from the binary
#'
#' @import tibble
#' @import stringr
#' @importFrom utils tail
#' @export
#'
#' @examples
#' \dontrun{
#' read_moov_swim_bin("swimming-a2tj48knt09_f0pkqin8vnt", "data/swimming")
#' }
read_moov_swim_bin <- function(id, swimming_root) {
  # headers
  header_old <- c(9L, 0L, 0L, 0L, 4352L, -1L, -19280L, -952L, 16643L, 410L)
  # TODO: Create a binary parser for the newer files (BINARY: 0108 0C10 6018 0320 0A2A)

  # determine data path
  dir_list <- list.dirs(swimming_root, full.names = TRUE, recursive = TRUE)
  f_path <- file.path(str_subset(dir_list, id), "swimming_result.pb")

  # read binary data
  finfo <- file.info(f_path)
  file_con <- file(f_path, "rb")
  alldata <- readBin(file_con, integer(), size = 2, n = finfo$size, endian = "little")
  close(file_con)

  # extract only data
  data_begin <- max(match(header_old, alldata)) + 1
  data_end <- length(alldata) - max(which(rev(tail(alldata, n = 500)) == -1))
  data <- alldata[data_begin:data_end]

  # return
  tibble(x = 1:length(data), y = data)
}


#' @title Plot swimming sensor data in a given index range
#'
#' @param data A tibble containing sensor data @seealso \code{\link{read_moov_swim_bin}}
#' @param from,to An integer of the range of the indices to plot. If missing,
#'    plot from the beginning to the end of the data.
#'
#' @import tibble
#' @import dplyr
#' @import ggplot2
#' @export
#'
plot_sensor_swim <- function(data, from = NA, to = NA) {
  if (missing(from)) from <- 1
  if (missing(to)) to <- nrow(data)
  data[from:to,] %>%
    ggplot(aes(x = x, y = y)) +
    geom_line()
}
