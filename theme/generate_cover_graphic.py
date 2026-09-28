"""Generates theme/assets/cover-graphic.svg: a hexagon containing a scatter
of dots + a regression line, in the BSE Econometrics palette. Used as the
decorative illustration on every deck's title slide.

Run: python theme/generate_cover_graphic.py
"""

import math
import random

random.seed(7)

W = H = 480
CX, CY = W / 2, H / 2
R = 210  # hexagon circumradius

TEAL = "#0396A6"
TEAL_LIGHT = "#79BAC8"
PURPLE = "#3E2259"
ORANGE = "#F28627"
WHITE = "#FFFFFF"

# Flat-top hexagon vertices
hex_points = []
for i in range(6):
    angle = math.radians(60 * i)
    hex_points.append((CX + R * math.sin(angle), CY - R * math.cos(angle)))
hex_path = " ".join(f"{x:.2f},{y:.2f}" for x, y in hex_points)

# Scatter: diagonal cloud of points (lower-left to upper-right), like a
# regression scatterplot. Color sweeps teal -> orange along the diagonal.
n = 42
points = []
for i in range(n):
    t = random.random()
    x = -R * 0.9 + t * R * 1.8 + random.gauss(0, 26)
    y = R * 0.9 - t * R * 1.8 + random.gauss(0, 26)
    # keep roughly inside the hexagon
    x = max(-R * 0.95, min(R * 0.95, x))
    y = max(-R * 0.95, min(R * 0.95, y))
    radius = random.uniform(5, 22)
    if t < 0.4:
        color = TEAL
    elif t < 0.7:
        color = TEAL_LIGHT if random.random() < 0.5 else PURPLE
    else:
        color = ORANGE if random.random() < 0.7 else PURPLE
    points.append((CX + x, CY - y, radius, color))

# Sort largest-first so small dots render on top (matches reference image)
points.sort(key=lambda p: -p[2])

circles_svg = "\n".join(
    f'    <circle cx="{x:.2f}" cy="{y:.2f}" r="{r:.2f}" fill="{c}" opacity="0.92"/>'
    for x, y, r, c in points
)

# Regression line through the cloud, following the same top-left ->
# bottom-right trend as the scatter (teal at top-left, orange at bottom-right)
x1, y1 = CX - R * 0.85, CY - R * 0.55
x2, y2 = CX + R * 0.85, CY + R * 0.55

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">
  <defs>
    <clipPath id="hexClip">
      <polygon points="{hex_path}"/>
    </clipPath>
  </defs>
  <polygon points="{hex_path}" fill="{WHITE}"/>
  <g clip-path="url(#hexClip)">
{circles_svg}
    <line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{PURPLE}" stroke-width="4" stroke-linecap="round" opacity="0.55"/>
  </g>
  <polygon points="{hex_path}" fill="none" stroke="{TEAL}" stroke-width="3" opacity="0.25"/>
</svg>
'''

with open("theme/assets/cover-graphic.svg", "w") as f:
    f.write(svg)

print("wrote theme/assets/cover-graphic.svg,", len(svg), "bytes")
