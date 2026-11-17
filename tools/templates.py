# Safe zone templates for video editors (CapCut, DaVinci Resolve, Premiere): transparent
# 1080x1920 PNGs with the same dead zones and safe box as the addon, one per platform.
# Usage: python3 tools/templates.py (runs tools/templates.lua with lua5.1). Needs Pillow.
# Not part of the addon zip; the PNGs go to docs/templates/ and to the GitHub release.
import os
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "docs", "templates")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
W, H = 1080, 1920
NAMES = {"all": "All", "shorts": "YouTube Shorts", "tiktok": "TikTok", "reels": "Instagram Reels"}
LABELS = {"zoneT": "Top bar", "zoneB": "Captions and buttons", "zoneR": "Buttons"}

lines = subprocess.run(["lua5.1", "tools/templates.lua"], cwd=ROOT, capture_output=True,
                       text=True, check=True).stdout.splitlines()
rects = {}
for line in lines:
    pid, name, kind, x, y, w, h = line.split("\t")
    rects.setdefault(pid, []).append((name, kind, float(x), float(y), float(w), float(h)))

os.makedirs(OUT, exist_ok=True)
font = ImageFont.truetype(FONT, 34)
small = ImageFont.truetype(FONT, 26)
for pid, rs in rects.items():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def box(x, y, w, h):  # bottom-left origin to PIL's top-left
        return (round(x), round(H - y - h), round(x + w) - 1, round(H - y) - 1)
    for name, kind, x, y, w, h in rs:
        if kind == "zone":
            d.rectangle(box(x, y, w, h), fill=(242, 38, 38, 90))
    for name, kind, x, y, w, h in rs:
        if kind == "edge":
            d.rectangle(box(x, y, w, h), fill=(242, 51, 51, 220))
        elif kind == "box":
            d.rectangle(box(x, y, w, h), fill=(255, 209, 26, 235))
    for name, kind, x, y, w, h in rs:
        if name in LABELS:
            cx, cy = x + w / 2, H - y - h / 2
            f = small if name == "zoneR" else font
            text = LABELS[name] if name != "zoneR" else "Buttons"
            d.text((cx, cy), text, font=f, fill=(255, 255, 255, 230), anchor="mm",
                   stroke_width=3, stroke_fill=(0, 0, 0, 200))
    top = [r for r in rs if r[0] == "boxT"][0]
    d.text((top[2] + top[4] / 2, H - top[3] - top[5] - 26), "Safe box", font=small, fill=(255, 209, 26, 255), anchor="mm",
           stroke_width=3, stroke_fill=(0, 0, 0, 200))
    d.text((W - 20, H - 20), "VertiCrop · " + NAMES[pid], font=small, fill=(255, 255, 255, 160),
           anchor="rd", stroke_width=2, stroke_fill=(0, 0, 0, 160))
    path = os.path.join(OUT, "verticrop-safe-zones-%s.png" % pid)
    im.save(path, optimize=True)
    print(path)
