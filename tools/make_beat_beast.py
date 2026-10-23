"""Generates Beat Beast's sprite sheet (the street wolf from the BEAT KEEPER cabinet).

Run:  python3 tools/make_beat_beast.py [preview_dir]     (needs Pillow)
Writes assets/sprites/beasts/beat_beast.png

Sheet layout: 48x48 frames, 4 columns. Row order must match ANIMATIONS in scripts/beat_beast.gd.
  row 0  idle       2 frames  nodding to the beat
  row 1  walk       4         strut
  row 2  blast      3         box to chest, speakers fire, fire
  row 3  windmill   4         breakdance spin
  row 4  moonwalk   4         gliding backward
  row 5  freeze, hurt, defeated  (one frame each)
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

F = 48
COLS = 4
ROWS = 6
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "beasts", "beat_beast.png")

P = dict(
    fur=(150, 150, 162), fursh=(108, 108, 122), furhi=(196, 196, 206), muzzle=(218, 214, 218), nose=(25, 20, 30),
    eye=(255, 210, 60), pupil=(20, 16, 24), pink=(255, 64, 191), pinksh=(186, 38, 138), white=(240, 240, 245),
    pants=(34, 30, 46), pantssh=(22, 20, 30), sole=(150, 155, 165), silver=(188, 193, 204), silsh=(130, 135, 148),
    spk=(40, 40, 52), glow=(255, 150, 225), mouth=(70, 40, 50),
)
OUTLINE = (16, 11, 24)


class Canvas:
    def __init__(self):
        self.px = {}

    def r(self, x0, y0, x1, y1, k):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < F and 0 <= y < F:
                    self.px[(x, y)] = k

    def d(self, x, y, k):
        if 0 <= x < F and 0 <= y < F:
            self.px[(x, y)] = k


def ear(c, x0, flip):
    for i, y in enumerate(range(3, 11)):
        w = min(i, 5)
        xs = range(x0, x0 + w + 1) if not flip else range(x0 - w, x0 + 1)
        for x in xs:
            c.d(x, y, "fur")
        if i >= 3:
            c.d(x0 + 2 if not flip else x0 - 2, y, "pinksh")


def legs(c, step=0):
    """step 0 = standing, 1 = left foot up, 2 = standing, 3 = right foot up."""
    lift_l = 2 if step == 1 else 0
    lift_r = 2 if step == 3 else 0
    c.r(15, 33, 32, 37, "pants")
    c.r(15, 38, 22, 41 - lift_l, "pants")
    c.r(25, 38, 32, 41 - lift_r, "pants")
    for y in range(33, 42):
        c.d(15, y, "white")
        c.d(32, y, "white")
    c.r(21, 38, 22, 41 - lift_l, "pantssh")
    c.r(25, 38, 26, 41 - lift_r, "pantssh")
    c.r(13, 42 - lift_l, 22, 43 - lift_l, "white")
    c.r(12, 44 - lift_l, 22, 44 - lift_l, "sole")
    c.r(25, 42 - lift_r, 34, 43 - lift_r, "white")
    c.r(25, 44 - lift_r, 35, 44 - lift_r, "sole")
    for x in (16, 18):
        c.d(x, 42 - lift_l, "pants")
    for x in (29, 31):
        c.d(x, 42 - lift_r, "pants")


def head(c, eyes="open"):
    ear(c, 15, False)
    ear(c, 32, True)
    c.r(14, 9, 33, 20, "fur")
    c.r(14, 9, 15, 20, "fursh")
    c.r(32, 9, 33, 20, "fursh")
    for x, y in [(13, 15), (12, 17), (13, 18), (34, 15), (35, 17), (34, 18), (15, 21), (32, 21)]:
        c.d(x, y, "fur")
    for x, y in [(18, 9), (21, 8), (25, 8), (28, 9)]:
        c.d(x, y, "furhi")
    c.r(19, 15, 28, 20, "muzzle")
    c.r(21, 14, 26, 14, "muzzle")
    c.r(22, 15, 25, 16, "nose")
    c.d(23, 17, "nose")
    c.d(24, 17, "nose")
    for x in range(20, 28):
        c.d(x, 19, "mouth")
    c.d(27, 18, "mouth")
    c.d(26, 20, "white")
    c.r(17, 11, 19, 11, "fursh")
    c.r(28, 11, 30, 11, "fursh")
    if eyes == "open":
        c.r(17, 12, 19, 13, "eye")
        c.r(28, 12, 30, 13, "eye")
        for x, y in [(19, 13), (18, 13), (28, 13), (29, 13)]:
            c.d(x, y, "pupil")
    else:
        c.r(17, 13, 19, 13, "pupil")
        c.r(28, 13, 30, 13, "pupil")


def jacket(c):
    c.r(14, 21, 33, 32, "pink")
    c.r(14, 21, 15, 32, "pinksh")
    c.r(32, 21, 33, 32, "pinksh")
    c.r(14, 32, 33, 32, "pinksh")
    for y in range(23, 32):
        c.d(23, y, "white")
        c.d(24, y, "white")
    c.r(19, 21, 28, 22, "pinksh")
    c.r(20, 21, 27, 21, "fur")
    c.d(22, 22, "furhi")
    c.d(25, 22, "furhi")


def tail(c):
    c.r(35, 29, 38, 35, "fur")
    c.r(37, 27, 39, 31, "furhi")
    c.d(39, 26, "furhi")
    c.r(35, 34, 37, 36, "fursh")


def left_arm_down(c, swing=0):
    c.r(10, 22, 13, 31 + swing, "pink")
    c.r(10, 22, 10, 31 + swing, "pinksh")
    for y in range(22, 32 + swing):
        c.d(12, y, "white")
    c.r(10, 32 + swing, 13, 34 + swing, "fur")


def boombox_on_shoulder(c):
    c.r(34, 13, 37, 22, "pink")
    c.r(37, 13, 37, 22, "pinksh")
    for y in range(13, 23):
        c.d(35, y, "white")
    c.r(34, 11, 37, 12, "fur")
    c.r(30, 4, 45, 13, "silver")
    c.r(30, 13, 45, 13, "silsh")
    c.r(34, 2, 41, 3, "silsh")
    c.d(34, 3, "silver")
    c.d(41, 3, "silver")
    for cx in (34, 41):
        c.r(cx - 2, 7, cx + 2, 11, "spk")
        c.d(cx, 9, "silsh")
    c.r(36, 6, 39, 8, "pink")
    c.r(36, 10, 39, 11, "spk")


def boombox_forward(c, firing):
    """Both arms forward, the box held in front of his chest, speakers aimed at you."""
    c.r(10, 22, 13, 27, "pink")
    c.r(34, 22, 37, 27, "pink")
    c.r(12, 27, 16, 29, "fur")
    c.r(31, 27, 35, 29, "fur")
    c.r(14, 22, 33, 31, "silver")
    c.r(14, 31, 33, 31, "silsh")
    c.r(19, 20, 28, 21, "silsh")
    for cx in (18, 29):
        color = "glow" if firing else "spk"
        c.r(cx - 3, 24, cx + 3, 29, color)
        c.r(cx - 1, 26, cx + 1, 27, "white" if firing else "silsh")
    c.r(22, 24, 25, 26, "pink")


def pose(kind="idle", step=0, firing=False, eyes="open"):
    c = Canvas()
    tail(c)
    legs(c, step)
    jacket(c)
    if kind == "blast":
        head(c, eyes)
        boombox_forward(c, firing)
    else:
        swing = {1: 1, 3: -1}.get(step, 0)
        left_arm_down(c, swing)
        head(c, eyes)
        boombox_on_shoulder(c)
    return c


def render(c):
    img = Image.new("RGBA", (F, F), (0, 0, 0, 0))
    for (x, y), k in c.px.items():
        img.putpixel((x, y), P[k] + (255,))
    for y in range(F):
        for x in range(F):
            if (x, y) in c.px:
                continue
            if any((x + a, y + b) in c.px for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                img.putpixel((x, y), OUTLINE + (255,))
    return img


def shift_upper(img, dx, dy, split=33):
    """Moves everything above `split` (head, jacket, box) by dx/dy, leaving the legs planted."""
    out = img.copy()
    upper = img.crop((0, 0, F, split))
    clear = Image.new("RGBA", (F, split), (0, 0, 0, 0))
    out.paste(clear, (0, 0))
    out.paste(upper, (dx, dy), upper)
    return out


def rotated(img, angle, bottom=None):
    """Rotates the figure around its own middle so nothing is cut off.
    With `bottom`, the result is moved so its lowest pixel sits on that row (lying on the floor)."""
    box = img.getbbox()
    fig = img.crop(box)
    centered = Image.new("RGBA", (F, F), (0, 0, 0, 0))
    centered.paste(fig, ((F - fig.width) // 2, (F - fig.height) // 2), fig)
    rot = centered.rotate(angle, resample=Image.NEAREST, center=(F / 2, F / 2))
    if bottom is None:
        return rot
    rbox = rot.getbbox()
    out = Image.new("RGBA", (F, F), (0, 0, 0, 0))
    out.paste(rot, (0, bottom - rbox[3]), rot)
    return out


def build_sheet():
    sheet = Image.new("RGBA", (F * COLS, F * ROWS), (0, 0, 0, 0))
    idle = render(pose())
    rows = {
        0: [idle, shift_upper(idle, 0, 1)],
        1: [render(pose(step=s)) for s in (0, 1, 2, 3)],
        2: [render(pose("blast")), render(pose("blast", firing=True)), shift_upper(render(pose("blast", firing=True)), -1, 0)],
        3: [rotated(idle, a) for a in (0, 90, 180, 270)],
        4: [shift_upper(render(pose(step=s)), -2, 1) for s in (0, 1, 2, 3)],
        5: [rotated(idle, 180, 46), shift_upper(render(pose(eyes="shut")), -2, 1), rotated(render(pose(eyes="shut")), 90, 46)],
    }
    for row, frames in rows.items():
        for col, img in enumerate(frames):
            sheet.paste(img, (col * F, row * F), img)
    return sheet


LABELS = ["idle", "walk", "blast", "windmill", "moonwalk", "freeze / hurt / out"]


def preview(sheet, path):
    s = 4
    pad = 16
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    font = ImageFont.truetype(font_path, 14) if os.path.exists(font_path) else ImageFont.load_default()
    w = 150 + F * COLS * s + pad
    h = pad * 2 + F * ROWS * s
    img = Image.new("RGB", (w, h), (10, 8, 18))
    bg = Image.new("RGB", (F * COLS * s, F * ROWS * s), (22, 17, 36))
    img.paste(bg, (150, pad))
    big = sheet.resize((F * COLS * s, F * ROWS * s), Image.NEAREST)
    img.paste(big, (150, pad), big)
    d = ImageDraw.Draw(img)
    for r, label in enumerate(LABELS):
        d.text((pad, pad + r * F * s + F * s // 2 - 8), label, font=font, fill=(170, 165, 190))
    img.save(path)


if __name__ == "__main__":
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    sheet = build_sheet()
    sheet.save(OUT)
    if len(sys.argv) > 1:
        preview(sheet, os.path.join(sys.argv[1], "beat_beast_sheet.png"))
    print("wrote", OUT)
