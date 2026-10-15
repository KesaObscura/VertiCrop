# Social preview (1280x640) and logo (400x400): a drawn diagram of the frame, not a game
# screenshot. Usage: python3 tools/preview.py   (writes docs/images/). Needs Pillow.
# Not part of the addon zip.
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "images")
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BLUE, RED, WHITE, SUB = (79, 195, 247), (242, 38, 38), (240, 244, 252), (160, 178, 214)


def background(w, h):
    bg = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(12 + 10 * t), int(18 + 14 * t), int(34 + 24 * t)))
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((w * 0.05, h * 0.1, w * 0.6, h * 1.1), fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    return Image.composite(Image.new("RGB", (w, h), (40, 80, 130)), bg, glow)


def scene(w, h):
    """A stylized 16:9 game screen: sky, hills, a character, UI corners."""
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(70 + 80 * t), int(110 + 60 * t), int(170 - 40 * t)))
    d.polygon([(0, h * 0.62), (w * 0.25, h * 0.48), (w * 0.5, h * 0.6), (w * 0.78, h * 0.45),
               (w, h * 0.58), (w, h), (0, h)], fill=(52, 92, 60))
    d.polygon([(0, h * 0.78), (w * 0.4, h * 0.7), (w, h * 0.8), (w, h), (0, h)], fill=(40, 72, 48))
    cx, cy = w / 2, h * 0.66
    d.ellipse((cx - w * 0.018, cy - h * 0.16, cx + w * 0.018, cy - h * 0.1), fill=(230, 200, 170))
    d.rounded_rectangle((cx - w * 0.026, cy - h * 0.1, cx + w * 0.026, cy + h * 0.02), 6, fill=(90, 60, 140))
    ui = (20, 22, 30)
    d.rounded_rectangle((w * 0.02, h * 0.03, w * 0.2, h * 0.11), 6, fill=ui)          # unit frame
    d.ellipse((w * 0.87, h * 0.03, w * 0.98, h * 0.22), fill=ui)                       # minimap
    d.rounded_rectangle((w * 0.02, h * 0.7, w * 0.26, h * 0.95), 6, fill=ui)           # chat
    d.rounded_rectangle((w * 0.33, h * 0.9, w * 0.67, h * 0.97), 4, fill=ui)           # action bar
    d.rounded_rectangle((w * 0.42, h * 0.8, w * 0.58, h * 0.83), 3, fill=(230, 180, 60))  # cast bar
    return im


def overlay(im, alpha=0.6):
    w, h = im.size
    cw = h * 9 / 16
    x0 = (w - cw) / 2
    ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    dark = (0, 0, 0, int(255 * alpha))
    d.rectangle((0, 0, x0, h), fill=dark)
    d.rectangle((x0 + cw, 0, w, h), fill=dark)
    z = (242, 38, 38, 72)
    top, bot, right, left = 0.135 * h, 0.25 * h, 0.185 * cw, 0.055 * cw
    d.rectangle((x0, 0, x0 + cw, top), fill=z)
    d.rectangle((x0, h - bot, x0 + cw, h), fill=z)
    d.rectangle((x0 + cw - right, top, x0 + cw, h - bot), fill=z)
    d.rectangle((x0, top, x0 + left, h - bot), fill=z)
    g = (255, 255, 255, 90)
    for i in (1, 2):
        d.line([(x0 + cw * i / 3, 0), (x0 + cw * i / 3, h)], fill=g, width=1)
        d.line([(x0, h * i / 3), (x0 + cw, h * i / 3)], fill=g, width=1)
    d.rectangle((x0 - 3, 0, x0 - 1, h), fill=BLUE + (255,))
    d.rectangle((x0 + cw + 1, 0, x0 + cw + 3, h), fill=BLUE + (255,))
    out = Image.alpha_composite(im.convert("RGBA"), ov)
    return out, x0, cw


def framed(im, r=16):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def social():
    W, H = 1280, 640
    bg = background(W, H).convert("RGBA")
    shot, x0, cw = overlay(scene(704, 396))
    d = ImageDraw.Draw(shot)
    f = ImageFont.truetype(BOLD, 13)
    d.text((x0 + cw / 2, 396 * 0.067), "TOP BAR", font=f, fill=WHITE, anchor="mm")
    d.text((x0 + cw / 2, 396 * 0.94), "CAPTIONS + BUTTONS", font=f, fill=WHITE, anchor="mm")
    d.text((x0 - 12, 14), "9:16", font=ImageFont.truetype(BOLD, 16), fill=WHITE, anchor="ra")
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((52, 138, 52 + 704, 138 + 396), 16, fill=(0, 0, 0, 160))
    bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(14)))
    bg.alpha_composite(framed(shot), (48, 122))
    d = ImageDraw.Draw(bg)
    tx = 800
    d.text((tx, 170), "VertiCrop", font=ImageFont.truetype(BOLD, 64), fill=WHITE)
    lines = ["9:16 crop frame and safe zones", "for YouTube Shorts, TikTok", "and Instagram Reels,", "in World of Warcraft."]
    for i, s in enumerate(lines):
        d.text((tx, 262 + 36 * i), s, font=ImageFont.truetype(REG, 27), fill=SUB)
    d.text((tx, 430), "Retail · Classic · WoW Forever", font=ImageFont.truetype(BOLD, 22), fill=BLUE)
    d.text((tx, 466), "9 languages · OBS crop values", font=ImageFont.truetype(REG, 20), fill=SUB)
    bg.convert("RGB").save(os.path.join(OUT, "social-preview.png"), optimize=True)


def logo():
    S = 400
    bg = background(S, S).convert("RGBA")
    d = ImageDraw.Draw(bg)
    # a wide screen with the vertical frame cut out of it
    sx0, sy0, sx1, sy1 = 40, 112, 360, 292
    d.rounded_rectangle((sx0, sy0, sx1, sy1), 18, fill=(28, 34, 50), outline=(70, 84, 110), width=4)
    fw = (sy1 - sy0 + 70) * 9 / 16
    fx0 = S / 2 - fw / 2
    fy0, fy1 = sy0 - 35, sy1 + 35
    d.rounded_rectangle((fx0, fy0, fx0 + fw, fy1), 14, fill=(52, 92, 140), outline=BLUE + (255,), width=8)
    d.rectangle((fx0 + 8, fy0 + 8, fx0 + fw - 8, fy0 + 40), fill=(242, 38, 38, 140))
    d.rectangle((fx0 + 8, fy1 - 64, fx0 + fw - 8, fy1 - 8), fill=(242, 38, 38, 140))
    d.ellipse((S / 2 - 16, 178, S / 2 + 16, 210), fill=(230, 200, 170))
    d.rounded_rectangle((S / 2 - 22, 210, S / 2 + 22, 262), 8, fill=(90, 60, 140))
    bg.convert("RGB").save(os.path.join(OUT, "logo.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    social()
    logo()
