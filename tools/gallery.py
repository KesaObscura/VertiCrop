# CurseForge gallery images (1280x720) and the GitHub social preview (1280x640) from the
# owner's in-game screenshots (1920x1080, English client).
# Usage: python3 tools/gallery.py <work dir>   -> <work dir>/out/*.png
# The work dir holds src/<name>.webp (names below). Source screenshots never go into the repo:
# they show chat and other players. The chat box is blurred here, as streamers do.
# Needs Pillow. Not part of the addon zip.
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

WORK = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = os.path.join(WORK, "out")
W, H = 1280, 720
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
WHITE, SUB = (240, 244, 252), (160, 178, 214)
BLUE, GREEN, RED, YELLOW = (79, 195, 247), (110, 240, 150), (255, 120, 120), (255, 214, 60)
CROP = (656, 0, 1264, 1080)          # the 9:16 frame on a 1920x1080 screen
CHAT = (28, 790, 490, 960)           # chat box of the default UI


def font(size, bold=True):
    return ImageFont.truetype(BOLD if bold else REG, size)


def background(w=W, h=H):
    bg = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(12 + 10 * t), int(18 + 16 * t), int(34 + 28 * t)))
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((w * 0.15, h * 0.3, w * 0.85, h * 1.3), fill=60)
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    return Image.composite(Image.new("RGB", (w, h), (40, 70, 130)), bg, glow)


def shot(name, box=None, h=None, w=None, blur_chat=True):
    im = Image.open(os.path.join(WORK, "src", name + ".webp")).convert("RGB")
    if blur_chat:
        im.paste(im.crop(CHAT).filter(ImageFilter.GaussianBlur(10)), CHAT[:2])
    if box:
        im = im.crop(box)
    if h:
        im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
    elif w:
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    return im


def place(bg, im, x, y, r=14):
    sh = Image.new("L", bg.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle((x + 6, y + 10, x + im.width + 6, y + im.height + 10), r, fill=170)
    bg.paste((0, 0, 0), (0, 0), sh.filter(ImageFilter.GaussianBlur(12)))
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    bg.paste(im, (x, y), mask)


def title(bg, text, y=48, size=32):
    ImageDraw.Draw(bg).text((bg.width / 2, y), text, font=font(size), fill=WHITE, anchor="mm")


def caption(bg, x, y, text, color, size=20):
    ImageDraw.Draw(bg).text((x, y), text, font=font(size), fill=color, anchor="mm")


def arrow(bg, x, y):
    ImageDraw.Draw(bg).polygon([(x - 14, y - 22), (x + 18, y), (x - 14, y + 22)], fill=BLUE)


def save(bg, name):
    bg.save(os.path.join(OUT, name + ".png"), optimize=True)


def g01_hero():
    bg = background()
    a = shot("20-final-layout-smite", w=780)
    b = shot("22-final-rec100-smite-cast", CROP, h=560)
    place(bg, a, 36, 160)
    place(bg, b, W - 36 - b.width, 100)
    title(bg, "Lay out your UI for 9:16 — see what the phone will show", size=30)
    caption(bg, 36 + a.width / 2, 160 + a.height + 28, "In game: crop frame, safe zones, safe box", BLUE)
    caption(bg, W - 36 - b.width / 2, 100 + b.height + 26, "Your vertical video", GREEN)
    arrow(bg, 862, 380)
    save(bg, "01_hero")
    return a, b


def g02_before_after():
    bg = background()
    a = shot("02-layout-darken-0", w=596)
    b = shot("19-final-layout-xp", w=596)
    y = 150
    place(bg, a, 30, y)
    place(bg, b, W - 30 - b.width, y)
    title(bg, "Before and after: your UI inside the frame")
    caption(bg, 30 + a.width / 2, y + a.height + 30, "Before: frames outside the crop", RED)
    caption(bg, W - 30 - b.width / 2, y + b.height + 30, "After: everything in the safe box", GREEN)
    d = ImageDraw.Draw(bg)
    d.text((W / 2, 610), "Red: covered by the app's top bar, captions and buttons.   Yellow: stays visible everywhere.",
           font=font(17, False), fill=SUB, anchor="mm")
    save(bg, "02_before_after")


def g03_modes():
    bg = background()
    a = shot("20-final-layout-smite", CROP, h=540)
    b = shot("22-final-rec100-smite-cast", CROP, h=540)
    gap = 120
    x1 = (W - a.width - b.width - gap) // 2
    x2 = x1 + a.width + gap
    place(bg, a, x1, 110)
    place(bg, b, x2, 110)
    title(bg, "Set up with the zones, record with a clean frame")
    caption(bg, x1 + a.width / 2, 110 + a.height + 28, "Layout mode", YELLOW)
    caption(bg, x2 + b.width / 2, 110 + b.height + 28, "Recording mode: /vcrop rec", GREEN)
    arrow(bg, W // 2 + 2, 380)
    save(bg, "03_layout_and_recording")


def g04_darkening():
    bg = background()
    title(bg, "Darken outside the frame: 0 %, 50 %, 100 %")
    box = (360, 0, 1560, 1080)
    xs = [30, 30 + 410, 30 + 820]
    for x, (name, label) in zip(xs, [("02-layout-darken-0", "0 %"), ("03-layout-darken-50", "50 %"),
                                     ("04-layout-darken-100", "100 %")]):
        im = shot(name, box, w=400)
        place(bg, im, x, 120)
        caption(bg, x + im.width / 2, 120 + im.height + 26, label, BLUE, 22)
    ImageDraw.Draw(bg).text((W / 2, 600), "The dark part is cut away in the video, so any value is fine for recording.",
                            font=font(18, False), fill=SUB, anchor="mm")
    save(bg, "04_darkening")


def g05_edit_mode():
    bg = background()
    im = shot("13-edit-mode-layout-verticrop-xpbar", w=1100)
    place(bg, im, (W - im.width) // 2, 92)
    title(bg, "Works with Edit Mode: save a layout just for recording", y=46, size=28)
    save(bg, "05_edit_mode")


def g06_settings():
    bg = background()
    win = shot("19-final-layout-xp", (1540, 270, 1839, 841), h=560)
    place(bg, win, 70, 110)
    title(bg, "Everything in one small window: /vcrop opt")
    d = ImageDraw.Draw(bg)
    lines = [
        ("9:16, 4:5 or 1:1", "full screen height, centered"),
        ("Safe zones", "YouTube Shorts, TikTok, Instagram Reels or All"),
        ("Safe box", "long captions, subtitles, tall phones"),
        ("Grid", "rule of thirds and center cross"),
        ("Recording mode", "nothing inside the frame"),
        ("Crop for OBS", "exact pixels: 608 × 1080, left 656, right 656"),
        ("Off at every login", "/vcrop or a key binding switches it on"),
    ]
    x, y = 520, 150
    for head, text in lines:
        d.text((x, y), head, font=font(24), fill=WHITE)
        d.text((x, y + 32), text, font=font(19, False), fill=SUB)
        y += 74
    save(bg, "06_settings")


def social(hero_parts):
    a, b = hero_parts
    bg = background(1280, 640)
    a2 = a.resize((660, round(a.height * 660 / a.width)), Image.LANCZOS)
    b2 = b.resize((round(b.width * 500 / b.height), 500), Image.LANCZOS)
    place(bg, a2, 40, 210)
    place(bg, b2, 1280 - 40 - b2.width, 90)
    d = ImageDraw.Draw(bg)
    d.text((40, 60), "VertiCrop", font=font(64), fill=WHITE)
    d.text((40, 142), "9:16 crop frame and Shorts, TikTok, Reels safe zones in WoW",
           font=font(24, False), fill=SUB)
    arrow(bg, 742, 380)
    bg.save(os.path.join(WORK, "out", "social-preview.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    parts = g01_hero()
    g02_before_after()
    g03_modes()
    g04_darkening()
    g05_edit_mode()
    g06_settings()
    social(parts)
