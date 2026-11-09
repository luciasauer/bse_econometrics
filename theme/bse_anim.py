"""Step-by-step matplotlib figures for reveal.js slides.

Build a figure incrementally, calling ``snap()`` after each stage; ``show()``
emits the frames stacked on top of each other, with every frame after the
first as a reveal.js fragment. Clicking "next" then reveals the figure one
stage at a time (and "back" un-reveals it).

Usage, in a cell with ``#| output: asis``:

    s = bse_anim.Steps("myfig", figsize=(9, 4.5), margins=dict(right=0.75))
    ax = s.ax
    ax.scatter(x, y); s.snap()
    ax.axhline(y.mean()); s.snap()
    s.show(height=420)

``ncols``/``nrows``/``sharey``/``sharex`` are passed to ``plt.subplots``, in
which case ``s.ax`` is the array of axes. ``margins`` goes to
``fig.subplots_adjust``.
"""

import base64
import io

import matplotlib.pyplot as plt


class Steps:
    def __init__(self, name, figsize=(9, 4.5), nrows=1, ncols=1,
                 sharex=False, sharey=False, margins=None, dpi=150):
        self.name = name
        self.dpi = dpi
        self.fig, self.ax = plt.subplots(nrows, ncols, figsize=figsize,
                                         sharex=sharex, sharey=sharey)
        if margins:
            self.fig.subplots_adjust(**margins)
        self.frames = []

    def snap(self):
        """Capture the current state of the figure as the next frame."""
        buf = io.BytesIO()
        # No bbox_inches="tight": every frame must share the exact same canvas
        # so the stacked images line up pixel for pixel.
        self.fig.savefig(buf, format="png", dpi=self.dpi, facecolor="white")
        self.frames.append(base64.b64encode(buf.getvalue()).decode("ascii"))

    def html(self, height=420):
        if not self.frames:
            self.snap()
        imgs = []
        for k, b64 in enumerate(self.frames):
            cls = ' class="fragment bse-anim-frame"' if k else ' class="bse-anim-frame"'
            imgs.append(
                f'<img{cls} src="data:image/png;base64,{b64}" '
                f'alt="{self.name} step {k + 1}" '
                f'style="position:absolute;top:0;left:50%;transform:translateX(-50%);'
                f'height:{height}px;width:auto;max-width:none;margin:0;'
                f'box-shadow:none;border:none;">'
            )
        return (
            f'<div class="bse-anim" id="anim-{self.name}" '
            f'style="position:relative;height:{height}px;width:100%;margin:0.2em auto;">'
            + "".join(imgs) + "</div>"
        )

    def show(self, height=420):
        """Print the frames as raw HTML (cell needs ``#| output: asis``)."""
        out = self.html(height)
        plt.close(self.fig)
        print("\n```{=html}\n" + out + "\n```\n")
