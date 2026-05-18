#!/usr/bin/env python3
"""Compose the two-step onboarding diagram from the two source screenshots.

Step 1: cropped CopyPath row from the Extensions list (with the ⓘ icon)
Step 2: cropped File Provider toggle row from the CopyPath Extensions sheet

Writes the composed PNG to ../CopyPathHelper/Resources/onboarding-target.png.
"""

from PIL import Image, ImageDraw, ImageFont
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

EXTENSIONS_LIST_PATH = os.path.expanduser(
    "~/apps/auto-screenshot-renamer/_today/May-18-2026-08-macos-system-settings-extensions-by-app.png"
)
TOGGLE_SHEET_PATH = os.path.expanduser(
    "~/apps/auto-screenshot-renamer/_today/May-18-2026-07-macos-extensions-copypath-file-provider.png"
)
OUT_PATH = os.path.join(REPO, "CopyPathHelper", "Resources", "onboarding-target.png")

# --- Load sources ----------------------------------------------------------
ext_list = Image.open(EXTENSIONS_LIST_PATH).convert("RGB")
toggle_sheet = Image.open(TOGGLE_SHEET_PATH).convert("RGB")

print(f"Extensions list: {ext_list.size}")
print(f"Toggle sheet: {toggle_sheet.size}")

# --- Crop the Extensions section header + CopyPath row -------------------
# Show users WHERE in Settings to look (Extensions section) AND the specific
# row to click. Crop two strips:
#   - top: the "Extensions" header + subtitle + tab buttons (y=0..225)
#   - bottom: the CopyPath row (y=648..738)
# Stitch them vertically with a small "skipped rows" gap indicator.
EXT_W = ext_list.size[0]
ext_header = ext_list.crop((20, 18, EXT_W - 20, 225))
copypath_row = ext_list.crop((20, 648, EXT_W - 20, 738))
print(f"Extensions header crop: {ext_header.size}")
print(f"CopyPath row crop: {copypath_row.size}")

# Build the "Step 1" panel: header + gap-indicator + CopyPath row
GAP_INDICATOR_H = 30
panel_w = ext_header.size[0]
panel_h = ext_header.size[1] + GAP_INDICATOR_H + copypath_row.size[1]
step1_panel = Image.new("RGB", (panel_w, panel_h), (255, 255, 255))
step1_panel.paste(ext_header, (0, 0))

# Draw "skipped" gap — dotted line + ellipsis text
panel_draw = ImageDraw.Draw(step1_panel)
gap_y = ext_header.size[1]
font_skip = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 16)
skip_text = "…  (other apps in your list)  …"
sb = panel_draw.textbbox((0, 0), skip_text, font=font_skip)
sw = sb[2] - sb[0]
panel_draw.text(
    ((panel_w - sw) / 2, gap_y + (GAP_INDICATOR_H - (sb[3] - sb[1])) / 2 - 2),
    skip_text, font=font_skip, fill=(160, 160, 170),
)

step1_panel.paste(copypath_row, (0, ext_header.size[1] + GAP_INDICATOR_H))
copypath_row = step1_panel  # reuse the variable downstream

# --- Crop the File Provider toggle row from the sheet ---------------------
# Toggle sheet is 906x308. The File Provider toggle row starts around y=148.
TS_W = toggle_sheet.size[0]
toggle_row = toggle_sheet.crop((10, 140, TS_W - 10, 270))
print(f"Toggle row crop: {toggle_row.size}")

# --- Normalize widths so the two rows line up vertically ------------------
TARGET_W = 880  # pixel width of each row in the composition (retina)
def resize_to_width(img, target_w):
    ratio = target_w / img.size[0]
    return img.resize((target_w, int(img.size[1] * ratio)), Image.LANCZOS)

copypath_row = resize_to_width(copypath_row, TARGET_W)
toggle_row = resize_to_width(toggle_row, TARGET_W)

print(f"Resized CopyPath row: {copypath_row.size}")
print(f"Resized toggle row: {toggle_row.size}")

# --- Build composition canvas ---------------------------------------------
PADDING = 24
LABEL_H = 36
GAP = 28

W = TARGET_W + PADDING * 2
H = PADDING + LABEL_H + copypath_row.size[1] + GAP + LABEL_H + toggle_row.size[1] + PADDING

canvas = Image.new("RGB", (W, H), (250, 250, 252))
draw = ImageDraw.Draw(canvas)

# --- Step labels ----------------------------------------------------------
# SFCompact supports ⓘ (U+24D8); HelveticaNeue does not.
font_path = "/System/Library/Fonts/SFCompact.ttf"
font = ImageFont.truetype(font_path, 22)

def draw_label(text: str, y: int):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) / 2, y), text, font=font, fill=(60, 60, 80))

y = PADDING
draw_label("Step 1 — Click the info button on the CopyPath row", y)
y += LABEL_H
canvas.paste(copypath_row, (PADDING, y))
y += copypath_row.size[1] + GAP

draw_label("Step 2 — Flip the File Provider toggle on", y)
y += LABEL_H
canvas.paste(toggle_row, (PADDING, y))

# --- Save -----------------------------------------------------------------
canvas.save(OUT_PATH, "PNG", optimize=True)
print(f"Wrote {OUT_PATH}  ({canvas.size[0]}x{canvas.size[1]})")
