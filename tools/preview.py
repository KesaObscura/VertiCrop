# Logo and in-game icon: a drawn diagram of the frame, not a game screenshot (the social preview comes
# from real screenshots, see tools/gallery.py). Usage: python3 tools/preview.py. Needs Pillow.
# Not part of the addon zip.
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "images")
ICON = os.path.join(os.path.dirname(__file__), "..", "icon.tga")
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



def logo():
    """Drawn at 1024 px and scaled down: docs/images/logo.png (400, CurseForge avatar) and
    icon.tga (64, the in-game icon: addon list and addon menu at the minimap)."""
    S = 1024
    bg = background(S, S).convert("RGBA")
    over = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    # the wide game screen behind
    d.rounded_rectangle((70, 300, 954, 724), 40, fill=(30, 38, 58, 255), outline=(84, 100, 132, 255), width=14)
    # the 9:16 frame: a snowy scene inside
    fx0, fy0, fx1, fy1 = 282, 92, 742, 932
    scene = Image.new("RGBA", (fx1 - fx0, fy1 - fy0))
    sd = ImageDraw.Draw(scene)
    for y in range(scene.height):
        t = y / scene.height
        sd.line([(0, y), (scene.width, y)], fill=(int(40 + 60 * t), int(90 + 80 * t), int(150 + 70 * t), 255))
    sd.polygon([(0, 560), (180, 470), (330, 540), (460, 480), (460, 840), (0, 840)], fill=(196, 222, 240, 255))
    mask = Image.new("L", scene.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, scene.width - 1, scene.height - 1), 36, fill=255)
    over.paste(scene, (fx0, fy0), mask)
    d = ImageDraw.Draw(over)
    # red zones: top bar, captions
    d.rectangle((fx0 + 13, fy0 + 13, fx1 - 13, fy0 + 120), fill=(242, 38, 38, 190))
    d.rectangle((fx0 + 13, fy1 - 190, fx1 - 13, fy1 - 13), fill=(242, 38, 38, 190))
    # yellow safe box
    d.rounded_rectangle((fx0 + 60, fy0 + 160, fx1 - 90, fy1 - 240), 12, outline=(255, 214, 60, 255), width=12)
    # the character
    cx = (fx0 + fx1) / 2 - 15
    d.ellipse((cx - 46, 420, cx + 46, 512), fill=(240, 214, 186, 255))
    d.rounded_rectangle((cx - 64, 512, cx + 64, 660), 30, fill=(96, 62, 150, 255))
    # the frame line
    d.rounded_rectangle((fx0, fy0, fx1, fy1), 36, outline=BLUE + (255,), width=28)
    img = Image.alpha_composite(bg, over).convert("RGB")
    img.resize((400, 400), Image.LANCZOS).save(os.path.join(OUT, "logo.png"), optimize=True)
    img.resize((64, 64), Image.LANCZOS).convert("RGBA").save(ICON)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    logo()
