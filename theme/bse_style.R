# Shared ggplot2 styling for BSE Econometrics TA slides.
#
# Usage, at the top of a slide deck's first R code cell:
#
#   source("../theme/bse_style.R")
#   theme_set(theme_bse())
#
# Keeps every chart's font, color palette, and axis styling consistent
# with the reveal.js slide theme (bse-theme.scss) and the matplotlib
# styling in theme/bse_style.py.

suppressPackageStartupMessages({
  library(ggplot2)
})

# Same six colors as theme/bse-theme.scss and theme/bse_style.py
BSE_TEAL       <- "#0396A6"
BSE_TEAL_LIGHT <- "#79BAC8"
BSE_PURPLE     <- "#3E2259"
BSE_ORANGE     <- "#F28627"
BSE_BLACK      <- "#0D0D0D"
BSE_GRAY       <- "#E9EAEA"

BSE_PALETTE <- c(BSE_TEAL, BSE_PURPLE, BSE_ORANGE, BSE_TEAL_LIGHT, BSE_BLACK)

# Register the slide's serif font (Source Serif 4) so ggplot2 can use it,
# without needing the font installed at the OS level. Falls back to a
# generic serif if the font file or {systemfonts} isn't available.
bse_register_font <- function() {
  candidates <- c(
    "../theme/fonts/SourceSerif4-Variable.ttf",
    "theme/fonts/SourceSerif4-Variable.ttf",
    "/Users/luciasauer/Desktop/Econometrics_TA/bse_econometrics/theme/fonts/SourceSerif4-Variable.ttf"
  )
  font_path <- candidates[file.exists(candidates)][1]

  if (is.na(font_path) || !requireNamespace("systemfonts", quietly = TRUE)) {
    return("serif")
  }

  systemfonts::register_font("Source Serif 4 BSE", plain = font_path)
  "Source Serif 4 BSE"
}

BSE_FONT <- bse_register_font()

# A clean, minimal ggplot2 theme matching the slide deck's aesthetic:
# no top/right border, light gray gridlines, bold serif titles.
theme_bse <- function(base_size = 14) {
  theme_minimal(base_size = base_size, base_family = BSE_FONT) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = BSE_GRAY, linewidth = 0.5),
      axis.line = element_line(color = BSE_BLACK),
      axis.ticks = element_line(color = BSE_BLACK),
      axis.text = element_text(color = BSE_BLACK, size = base_size * 0.75),
      axis.title = element_text(color = BSE_BLACK, size = base_size * 0.85),
      plot.title = element_text(size = base_size * 1.15, face = "bold", color = BSE_PURPLE),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      legend.position = "top",
      legend.title = element_blank()
    )
}

# Discrete color/fill scales using the BSE palette
scale_color_bse <- function(...) scale_color_manual(values = BSE_PALETTE, ...)
scale_fill_bse  <- function(...) scale_fill_manual(values = BSE_PALETTE, ...)
