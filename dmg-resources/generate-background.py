#!/usr/bin/env python3
"""Generate dmg-resources/background.png at 2x retina (1080x760) for a 540x380 DMG window.

The arrow visually connects the CopyPath.app icon (logical x=150, y=220) to the
Applications drop link (logical x=390, y=220). Endpoints are nudged inward so the
arrow ends just above each icon rather than overlapping it.

Run: python3 dmg-resources/generate-background.py
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# --- Dimensions (2x retina) -------------------------------------------------
SCALE = 2
W_LOG, H_LOG = 540, 380
W, H = W_LOG * SCALE, H_LOG * SCALE  # 1080 x 760

# Icon centers in LOGICAL coords (icons are 100px, positioned by top-left at 150,220 and 390,220)
LEFT_ICON_CENTER = (150 + 50, 220 + 50)   # (200, 270)
RIGHT_ICON_CENTER = (390 + 50, 220 + 50)  # (440, 270)

# Arrow control points (logical) — gentle arc above the icons
START_LOG = (LEFT_ICON_CENTER[0] + 35, LEFT_ICON_CENTER[1] - 75)   # (235, 195) — upper-right of app icon
END_LOG   = (RIGHT_ICON_CENTER[0] - 25, RIGHT_ICON_CENTER[1] - 70) # (415, 200) — upper-left of apps icon
CTRL_LOG  = ((START_LOG[0] + END_LOG[0]) / 2, 120)                  # arc peak

# Scale to retina pixels
START = (START_LOG[0] * SCALE, START_LOG[1] * SCALE)
END   = (END_LOG[0] * SCALE,   END_LOG[1] * SCALE)
CTRL  = (CTRL_LOG[0] * SCALE,  CTRL_LOG[1] * SCALE)

# Colors
BG_TOP = (235, 244, 252)     # very light blue
BG_BOTTOM = (197, 220, 240)  # slightly darker blue
ARROW_COLOR = (110, 145, 200)
TEXT_COLOR = (130, 155, 195)

OUT = os.path.join(os.path.dirname(__file__), "background.png")

# --- Build canvas with vertical gradient ------------------------------------
img = Image.new("RGB", (W, H), BG_TOP)
draw = ImageDraw.Draw(img)
for y in range(H):
    t = y / H
    r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
    g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
    b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
    draw.line([(0, y), (W, y)], fill=(r, g, b))

# --- "DRAG TO INSTALL" text -------------------------------------------------
text = "DRAG TO INSTALL"
font_path = "/System/Library/Fonts/Supplemental/Futura.ttc"
if not os.path.exists(font_path):
    font_path = "/System/Library/Fonts/HelveticaNeue.ttc"
font = ImageFont.truetype(font_path, 36 * SCALE)
text_bbox = draw.textbbox((0, 0), text, font=font, spacing=8 * SCALE)
tw = text_bbox[2] - text_bbox[0]
th = text_bbox[3] - text_bbox[1]
text_x = (W - tw) // 2
text_y = 50 * SCALE
# Slight letter spacing — draw character by character
spacing_px = 8 * SCALE
total_w = sum(draw.textbbox((0, 0), ch, font=font)[2] for ch in text) + spacing_px * (len(text) - 1)
x = (W - total_w) // 2
for ch in text:
    draw.text((x, text_y), ch, font=font, fill=TEXT_COLOR)
    ch_w = draw.textbbox((0, 0), ch, font=font)[2]
    x += ch_w + spacing_px

# --- Quadratic Bezier arrow -------------------------------------------------
def bezier(t, p0, p1, p2):
    x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
    y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
    return (x, y)

# Sample many points along the curve and draw thick rounded segments
STROKE = 7 * SCALE
prev = None
samples = 240
for i in range(samples + 1):
    t = i / samples
    pt = bezier(t, START, CTRL, END)
    if prev is not None:
        draw.line([prev, pt], fill=ARROW_COLOR, width=STROKE)
    # also dab circles to keep the stroke smooth
    r = STROKE // 2
    draw.ellipse((pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r), fill=ARROW_COLOR)
    prev = pt

# --- Arrowhead --------------------------------------------------------------
# Tangent at t=1 of quadratic bezier is 2*(P2 - P1)
tangent_x = 2 * (END[0] - CTRL[0])
tangent_y = 2 * (END[1] - CTRL[1])
angle = math.atan2(tangent_y, tangent_x)
HEAD_LEN = 28 * SCALE
HEAD_WIDTH_ANGLE = math.radians(28)
left_x = END[0] - HEAD_LEN * math.cos(angle - HEAD_WIDTH_ANGLE)
left_y = END[1] - HEAD_LEN * math.sin(angle - HEAD_WIDTH_ANGLE)
right_x = END[0] - HEAD_LEN * math.cos(angle + HEAD_WIDTH_ANGLE)
right_y = END[1] - HEAD_LEN * math.sin(angle + HEAD_WIDTH_ANGLE)
draw.polygon(
    [(END[0], END[1]), (left_x, left_y), (right_x, right_y)],
    fill=ARROW_COLOR,
)

img.save(OUT, "PNG", optimize=True)
print(f"Wrote {OUT}  ({W}x{H} retina, {W_LOG}x{H_LOG} logical)")
