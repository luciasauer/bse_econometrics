"""Shared matplotlib/seaborn styling for BSE Econometrics TA slides.

Usage, at the top of a slide deck's first code cell:

    import sys
    sys.path.insert(0, "../theme")
    import bse_style
    bse_style.apply()

Keeps every chart's font, color palette, and axis styling consistent
with the reveal.js slide theme (bse-theme.scss).
"""

import os

import matplotlib as mpl
import matplotlib.font_manager as fm

_THEME_DIR = os.path.dirname(os.path.abspath(__file__))
_FONT_PATH = os.path.join(_THEME_DIR, "fonts", "SourceSerif4-Variable.ttf")

# Same six colors as theme/bse-theme.scss
TEAL = "#0396A6"
TEAL_LIGHT = "#79BAC8"
PURPLE = "#3E2259"
ORANGE = "#F28627"
BLACK = "#0D0D0D"
GRAY = "#E9EAEA"

PALETTE = [TEAL, PURPLE, ORANGE, TEAL_LIGHT, BLACK]


def apply():
    """Register the slide font and set matplotlib rcParams for all charts."""
    if os.path.exists(_FONT_PATH):
        fm.fontManager.addfont(_FONT_PATH)
        font_name = fm.FontProperties(fname=_FONT_PATH).get_name()
    else:
        font_name = "serif"

    try:
        import seaborn as sns
        sns.set_theme(style="whitegrid")
        sns.set_palette(PALETTE)
    except ImportError:
        pass

    # Applied last so it always wins over seaborn's theme/context defaults.
    mpl.rcParams.update({
        "font.family": font_name,
        "font.size": 13,
        "text.color": BLACK,
        "axes.titlesize": 15,
        "axes.titleweight": "bold",
        "axes.labelsize": 13,
        "axes.labelcolor": BLACK,
        "axes.edgecolor": BLACK,
        "axes.linewidth": 1.0,
        "axes.facecolor": "white",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "axes.axisbelow": True,
        "axes.prop_cycle": mpl.cycler(color=PALETTE),
        "grid.color": GRAY,
        "grid.linewidth": 0.8,
        "grid.alpha": 0.7,
        "xtick.color": BLACK,
        "ytick.color": BLACK,
        "xtick.labelsize": 11,
        "ytick.labelsize": 11,
        "legend.fontsize": 12,
        "legend.frameon": False,
        "figure.facecolor": "white",
        "figure.dpi": 150,
        "savefig.dpi": 150,
        "savefig.facecolor": "white",
    })

    return font_name
