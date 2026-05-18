#!/usr/bin/env python3
"""Generate the DMG window background as a retina pair.

Produces TWO files create-dmg picks up automatically:
  dmg-resources/background.png      540x380 (logical 1x)
  dmg-resources/background@2x.png   1080x760 (retina 2x)

The DMG window is 540x380. Icons are positioned by their CENTER:
  CopyPath.app    center (150, 220)  -> bounding box x=100..200, y=170..270
  Applications    center (390, 220)  -> bounding box x=340..440, y=170..270

The arrow starts just above-right of the app icon and ends just above
the apps folder, with the arrowhead pointing down-right into it.

Run: python3 dmg-resources/generate-background.py
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# --- Logical dimensions -----------------------------------------------------
W_LOG, H_LOG = 540, 380

# Icon centers (logical coords matching create-dmg.sh)
LEFT_ICON_CENTER  = (150, 220)
RIGHT_ICON_CENTER = (390, 220)

# Arrow endpoints (logical) — start above-right of app icon, end above-left of apps icon
START_LOG = (LEFT_ICON_CENTER[0] + 55,  LEFT_ICON_CENTER[1] - 75)   # (205, 145)
END_LOG   = (RIGHT_ICON_CENTER[0] - 55, RIGHT_ICON_CENTER[1] - 65)  # (335, 155)
CTRL_LOG  = ((START_LOG[0] + END_LOG[0]) / 2, 90)                    # arc peak above the text baseline

# Colors
BG_TOP    = (235, 244, 252)
BG_BOTTOM = (197, 220, 240)
ARROW     = (110, 145, 200)
TEXT      = (130, 155, 195)

OUT_1X = os.path.join(os.path.dirname(__file__), "background.png")
OUT_2X = os.path.join(os.path.dirname(__file__), "background@2x.png")


def render(scale: int, out_path: str) -> None:
    W, H = W_LOG * scale, H_LOG * scale
    img = Image.new("RGB", (W, H), BG_TOP)
    draw = ImageDraw.Draw(img)

    # Vertical gradient
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Heading + two-step instructions
    font_path = "/System/Library/Fonts/Supplemental/Futura.ttc"
    if not os.path.exists(font_path):
        font_path = "/System/Library/Fonts/HelveticaNeue.ttc"
    system_font_path = "/System/Library/Fonts/HelveticaNeue.ttc"

    def draw_tracked_text(text: str, y_log: int, size_log: int, font_p: str, color, tracking_log: int = 4):
        font = ImageFont.truetype(font_p, size_log * scale)
        spacing = tracking_log * scale
        widths = [draw.textbbox((0, 0), ch, font=font)[2] for ch in text]
        total = sum(widths) + spacing * max(0, len(text) - 1)
        x = (W - total) // 2
        y = y_log * scale
        for ch, w in zip(text, widths):
            draw.text((x, y), ch, font=font, fill=color)
            x += w + spacing

    # Top heading — same Futura "DRAG TO INSTALL" as before
    draw_tracked_text("DRAG TO INSTALL", y_log=38, size_log=22, font_p=font_path, color=TEXT, tracking_log=4)

    # Footer — step 2 instruction in plain system font for readability
    draw_tracked_text(
        "Then open the Applications folder and double-click Copy Path.",
        y_log=325, size_log=12, font_p=system_font_path, color=TEXT, tracking_log=0,
    )

    # Scale arrow control points
    start = (START_LOG[0] * scale, START_LOG[1] * scale)
    end   = (END_LOG[0]   * scale, END_LOG[1]   * scale)
    ctrl  = (CTRL_LOG[0]  * scale, CTRL_LOG[1]  * scale)

    # Quadratic bezier curve, drawn with overlapping dabs for smoothness
    stroke = 4 * scale
    samples = 240
    prev = None

    def bezier(t):
        bx = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * ctrl[0] + t ** 2 * end[0]
        by = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * ctrl[1] + t ** 2 * end[1]
        return (bx, by)

    for i in range(samples + 1):
        pt = bezier(i / samples)
        if prev is not None:
            draw.line([prev, pt], fill=ARROW, width=stroke)
        r = stroke // 2
        draw.ellipse((pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r), fill=ARROW)
        prev = pt

    # Arrowhead — tangent at t=1 of quadratic bezier is 2*(end - ctrl)
    angle = math.atan2(2 * (end[1] - ctrl[1]), 2 * (end[0] - ctrl[0]))
    head_len = 16 * scale
    head_angle = math.radians(28)
    left = (
        end[0] - head_len * math.cos(angle - head_angle),
        end[1] - head_len * math.sin(angle - head_angle),
    )
    right = (
        end[0] - head_len * math.cos(angle + head_angle),
        end[1] - head_len * math.sin(angle + head_angle),
    )
    draw.polygon([end, left, right], fill=ARROW)

    img.save(out_path, "PNG", optimize=True)
    print(f"Wrote {out_path}  ({W}x{H})")


render(1, OUT_1X)
render(2, OUT_2X)
