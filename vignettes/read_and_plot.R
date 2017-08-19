## ----load packages, message=FALSE, warning=FALSE-------------------------
library(Moov)

library(tidyverse)
library(cowplot)

## ----plot summary, fig.height=5, fig.width=7, warning=FALSE--------------
db_path <- "../private/Applications/moov.core/Library/Application Support/user_data/6234565289443328/user.db"

swimming <- parse_swimming(read_moov(db_path))

plot_grid(
  plot_swim_summary(swimming, "distance_per_stroke") + geom_smooth(method = "loess"),
  plot_swim_summary(swimming, "stroke_rate", ylim = NULL) + geom_smooth(method = "loess"),
  plot_swim_summary(swimming, "distance_m", ylim = NULL),
  ncol = 1
)


## ----plot swim binary, fig.height=2, fig.width=7, warning=FALSE----------
swimming_root <- "../private/Applications/moov.core/Library/Application Support/user_data/6234565289443328/swimming/"

data <- read_moov_swim_bin("swimming-k5y5pqbib17vbjqrh9gr16e", swimming_root)
plot_sensor_swim(data)

