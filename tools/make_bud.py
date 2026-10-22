"""Generates Bud's sprite sheets (one per hoodie) plus a preview sheet and GIF.

Run:  python3 tools/make_bud.py            (needs Pillow: pip install pillow)
Writes assets/sprites/characters/bud/bud_<outfit>.png

Sheet layout: 32x32 frames, 4 columns. Row order must match BUD_ANIMATIONS in scripts/player.gd.
  row 0  idle_down   4 frames  hands in hoodie pocket, breathing
  row 1  walk_down   4
  row 2  walk_up     4
  row 3  walk_side   4         faces right; the game flips it for left
  row 4  punch_down  3         guard, jab, guard
  row 5  punch_up    3
  row 6  punch_side  3
  row 7  dash_down, dash_up, dash_side, hurt   (one frame each)
  row 8  defeated    1
An artist can redraw the PNG by hand as long as the grid stays the same.
"""
import os
from PIL import Image, ImageDraw, ImageFont

FRAME = 32
COLS = 4
ROWS = 9
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "characters", "bud")

BASE = dict(
    hair=(90, 58, 34), hairhi=(122, 82, 51), skin=(241, 195, 155), skinsh=(215, 159, 120),
    eye=(27, 20, 36), pants=(107, 111, 122), pantssh=(78, 81, 91), cuff=(139, 144, 155),
    shoe=(242, 242, 245), sole=(154, 160, 170),
)
OUTLINE = (18, 13, 28)
OUTFITS = {
    "white": dict(c=(233, 232, 239), sh=(185, 183, 198), d=(107, 111, 122), trim=None),
    "gray": dict(c=(61, 63, 74), sh=(44, 45, 54), d=(201, 201, 211), trim=None),
    "black": dict(c=(24, 22, 31), sh=(14, 13, 19), d=(230, 230, 238), trim=(230, 230, 238)),
}


class Canvas:
    def __init__(self):
        self.px = {}

    def rect(self, x0, y0, x1, y1, k):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < FRAME and 0 <= y < FRAME:
                    self.px[(x, y)] = k

    def dot(self, x, y, k):
        if 0 <= x < FRAME and 0 <= y < FRAME:
            self.px[(x, y)] = k

    def clear(self, x, y):
        self.px.pop((x, y), None)


# ---------------------------------------------------------------- front (down)

def head_front(cv, dy=0, dx=0, eyes="open"):
    cv.rect(11 + dx, 8 + dy, 20 + dx, 13 + dy, "skin")
    cv.rect(10 + dx, 4 + dy, 21 + dx, 9 + dy, "hair")
    for x, y in [(10, 3), (13, 3), (16, 2), (17, 3), (20, 3), (9, 6), (22, 7), (9, 8), (22, 5)]:
        cv.dot(x + dx, y + dy, "hair")
    for x, y in [(12, 5), (15, 4), (18, 5), (19, 6)]:
        cv.dot(x + dx, y + dy, "hairhi")
    for x in [11, 12, 15, 18, 19, 20]:
        cv.dot(x + dx, 10 + dy, "hair")
    if eyes == "open":
        cv.dot(13 + dx, 11 + dy, "eye")
        cv.dot(18 + dx, 11 + dy, "eye")
    else:  # squeezed shut
        for x in (12, 13, 18, 19):
            cv.dot(x + dx, 11 + dy, "eye")
    cv.dot(15 + dx, 13 + dy, "skinsh")
    cv.dot(16 + dx, 13 + dy, "skinsh")


def torso_front(cv, dy=0, back=False):
    cv.rect(10, 14 + dy, 21, 21, "c")
    if back:
        cv.rect(12, 14 + dy, 19, 17 + dy, "sh")  # hood hanging on his back
    else:
        cv.rect(10, 14 + dy, 21, 14 + dy, "sh")
        cv.rect(12, 18 + dy, 19, 19 + dy, "sh")  # front pocket
        for x, y in [(14, 15), (14, 16), (17, 15), (17, 16)]:
            cv.dot(x, y + dy, "d")
    cv.rect(10, 21, 21, 21, "sh")


def arms_front(cv, mode, dy=0, swing=0):
    if mode == "pocket":
        cv.rect(9, 15 + dy, 9, 19 + dy, "c")
        cv.rect(22, 15 + dy, 22, 19 + dy, "c")
        cv.dot(9, 19 + dy, "sh")
        cv.dot(22, 19 + dy, "sh")
    elif mode == "swing":
        cv.rect(8, 15 + dy, 9, 20 + dy + swing, "c")
        cv.rect(22, 15 + dy, 23, 20 + dy - swing, "c")
        cv.rect(8, 21 + dy + swing, 9, 21 + dy + swing, "skin")
        cv.rect(22, 21 + dy - swing, 23, 21 + dy - swing, "skin")
    elif mode == "flail":
        cv.rect(7, 14 + dy, 8, 18 + dy, "c")
        cv.rect(23, 14 + dy, 24, 18 + dy, "c")
        cv.rect(6, 13 + dy, 7, 13 + dy, "skin")
        cv.rect(24, 13 + dy, 25, 13 + dy, "skin")
    else:  # guard / jab: fists up by the chin
        cv.rect(8, 15 + dy, 9, 18 + dy, "c")
        cv.rect(10, 16 + dy, 11, 17 + dy, "c")
        cv.rect(11, 14 + dy, 12, 15 + dy, "skin")
        cv.dot(12, 15 + dy, "skinsh")
        if mode == "guard":
            cv.rect(22, 15 + dy, 23, 18 + dy, "c")
            cv.rect(20, 16 + dy, 21, 17 + dy, "c")
            cv.rect(19, 14 + dy, 20, 15 + dy, "skin")
            cv.dot(19, 15 + dy, "skinsh")
        elif mode == "jab_down":  # right fist punches toward the camera
            cv.rect(22, 15 + dy, 23, 17 + dy, "c")
            cv.rect(18, 17 + dy, 21, 20 + dy, "c")
            cv.rect(16, 20 + dy, 19, 23 + dy, "skin")
            cv.rect(16, 23 + dy, 19, 23 + dy, "skinsh")
        elif mode == "jab_up":  # right fist punches up past the head
            cv.rect(21, 4 + dy, 22, 15 + dy, "c")
            cv.rect(20, 1 + dy, 23, 3 + dy, "skin")


def legs(cv, lift_left=0, lift_right=0):
    cv.rect(10, 22, 21, 24, "pants")
    # left leg
    cv.rect(9, 25, 14, 27 - lift_left, "pants")
    cv.rect(8, 27 - lift_left, 14, 27 - lift_left, "pants")
    cv.rect(8, 28 - lift_left, 14, 28 - lift_left, "cuff")
    cv.rect(8, 29 - lift_left, 14, 29 - lift_left, "shoe")
    cv.rect(7, 30 - lift_left, 14, 30 - lift_left, "sole")
    # right leg
    cv.rect(17, 25, 22, 27 - lift_right, "pants")
    cv.rect(17, 27 - lift_right, 23, 27 - lift_right, "pants")
    cv.rect(17, 28 - lift_right, 23, 28 - lift_right, "cuff")
    cv.rect(17, 29 - lift_right, 23, 29 - lift_right, "shoe")
    cv.rect(17, 30 - lift_right, 24, 30 - lift_right, "sole")
    for y in range(23, 28):
        cv.dot(12, y, "pantssh")
        cv.dot(19, y, "pantssh")
    cv.rect(15, 25, 16, 27, "pants")
    cv.dot(15, 25, "pantssh")
    cv.dot(16, 25, "pantssh")
    for y in (26, 27):
        cv.clear(15, y)
        cv.clear(16, y)


def head_back(cv, dy=0):
    cv.rect(10, 4 + dy, 21, 13 + dy, "hair")
    for x, y in [(10, 3), (13, 3), (16, 2), (17, 3), (20, 3), (9, 6), (22, 7), (9, 8), (22, 5), (11, 14), (15, 14), (19, 14)]:
        cv.dot(x, y + dy, "hair")
    for x, y in [(12, 6), (15, 5), (18, 7), (14, 10), (19, 11)]:
        cv.dot(x, y + dy, "hairhi")


# ---------------------------------------------------------------- side (right)

def head_side(cv, dy=0, dx=0):
    cv.rect(12 + dx, 8 + dy, 20 + dx, 13 + dy, "skin")
    cv.dot(21 + dx, 11 + dy, "skin")  # nose
    cv.rect(11 + dx, 4 + dy, 20 + dx, 9 + dy, "hair")
    cv.rect(11 + dx, 8 + dy, 14 + dx, 12 + dy, "hair")
    for x, y in [(11, 3), (14, 3), (17, 2), (19, 3), (10, 6), (10, 9), (21, 6), (11, 13)]:
        cv.dot(x + dx, y + dy, "hair")
    for x, y in [(13, 5), (16, 4), (18, 6), (12, 10)]:
        cv.dot(x + dx, y + dy, "hairhi")
    for x in (18, 19, 20):
        cv.dot(x + dx, 10 + dy, "hair")
    cv.dot(18 + dx, 11 + dy, "eye")
    cv.dot(19 + dx, 13 + dy, "skinsh")


def torso_side(cv, dy=0, dx=0):
    cv.rect(12 + dx, 14 + dy, 19 + dx, 21, "c")
    cv.rect(11 + dx, 14 + dy, 12 + dx, 16 + dy, "sh")  # hood bunched at the back
    cv.rect(16 + dx, 18 + dy, 19 + dx, 19 + dy, "sh")
    cv.rect(12 + dx, 21, 19 + dx, 21, "sh")


def arm_side(cv, mode, dy=0, swing=0, dx=0):
    if mode == "pocket":
        cv.rect(15 + dx, 15 + dy, 16 + dx, 18 + dy, "c")
        cv.rect(14 + dx, 15 + dy, 14 + dx, 18 + dy, "sh")
    elif mode == "swing":
        cv.rect(14 + dx + swing, 15 + dy, 16 + dx + swing, 19 + dy, "c")
        cv.rect(14 + dx + swing, 15 + dy, 14 + dx + swing, 19 + dy, "sh")
        cv.rect(15 + dx + swing * 2, 20 + dy, 16 + dx + swing * 2, 20 + dy, "skin")
    elif mode == "guard":
        cv.rect(15 + dx, 15 + dy, 18 + dx, 16 + dy, "c")
        cv.rect(14 + dx, 15 + dy, 14 + dx, 17 + dy, "sh")
        cv.rect(19 + dx, 13 + dy, 21 + dx, 15 + dy, "skin")
        cv.dot(19 + dx, 15 + dy, "skinsh")
    elif mode == "jab":
        cv.rect(15 + dx, 15 + dy, 24 + dx, 16 + dy, "c")
        cv.rect(14 + dx, 15 + dy, 14 + dx, 17 + dy, "sh")
        cv.rect(25 + dx, 14 + dy, 28 + dx, 16 + dy, "skin")
        cv.dot(25 + dx, 16 + dy, "skinsh")
    elif mode == "back":  # arm thrown back while dashing
        cv.rect(10 + dx, 16 + dy, 13 + dx, 17 + dy, "c")
        cv.rect(9 + dx, 17 + dy, 9 + dx, 18 + dy, "skin")


def legs_side(cv, stride):
    cv.rect(11, 22, 20, 24, "pants")
    if stride == 0:
        cv.rect(11, 25, 20, 27, "pants")
        cv.dot(15, 26, "pantssh")
        cv.dot(15, 27, "pantssh")
        cv.rect(11, 28, 20, 28, "cuff")
        cv.rect(12, 29, 21, 29, "shoe")
        cv.rect(12, 30, 22, 30, "sole")
    else:
        cv.rect(9, 25, 14, 27, "pantssh")  # back leg sits in shadow
        cv.rect(9, 28, 14, 28, "cuff")
        cv.rect(9, 29, 15, 29, "shoe")
        cv.rect(9, 30, 16, 30, "sole")
        cv.rect(16, 25, 22, 27, "pants")
        cv.rect(16, 28, 22, 28, "cuff")
        cv.rect(17, 29, 23, 29, "shoe")
        cv.rect(17, 30, 24, 30, "sole")


# ---------------------------------------------------------------- frames

def f_front(arm_mode, dy=0, swing=0, lift=(0, 0), eyes="open"):
    cv = Canvas()
    legs(cv, *lift)
    torso_front(cv, dy)
    arms_front(cv, arm_mode, dy, swing)
    head_front(cv, dy, eyes=eyes)
    if arm_mode in ("guard", "jab_down"):  # fists drawn over the torso, re-draw so they sit on top
        arms_front(cv, arm_mode, dy, swing)
    return cv


def f_back(arm_mode, dy=0, swing=0, lift=(0, 0)):
    cv = Canvas()
    legs(cv, *lift)
    torso_front(cv, dy, back=True)
    head_back(cv, dy)
    if arm_mode == "jab_up":
        arms_front(cv, "guard", dy)
        cv.rect(19, 14 + dy, 20, 15 + dy, "c")
        arms_front(cv, "jab_up", dy)
    else:
        arms_front(cv, arm_mode, dy, swing)
    return cv


def f_side(arm_mode, stride=0, dy=0, swing=0, lean=0):
    cv = Canvas()
    legs_side(cv, stride)
    torso_side(cv, dy, lean)
    head_side(cv, dy, lean)
    arm_side(cv, arm_mode, dy, swing, lean)
    return cv


def render(cv, outfit):
    img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    for (x, y), k in cv.px.items():
        color = outfit[k] if k in ("c", "sh", "d") else BASE[k]
        img.putpixel((x, y), color + (255,))
    for y in range(FRAME):
        for x in range(FRAME):
            if (x, y) in cv.px:
                continue
            near = [cv.px.get((x + a, y + b)) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if any(near):
                hoodie = any(n in ("c", "sh") for n in near)
                color = outfit["trim"] if (hoodie and outfit["trim"]) else OUTLINE
                img.putpixel((x, y), color + (255,))
    return img


def build_frames():
    """Returns {row: [Canvas or 'defeated', ...]}"""
    return {
        0: [f_front("pocket"), f_front("pocket"), f_front("pocket", dy=1), f_front("pocket", dy=1)],
        1: [f_front("swing", 0, 0), f_front("swing", -1, 1, (1, 0)), f_front("swing", 0, 0), f_front("swing", -1, -1, (0, 1))],
        2: [f_back("swing", 0, 0), f_back("swing", -1, 1, (1, 0)), f_back("swing", 0, 0), f_back("swing", -1, -1, (0, 1))],
        3: [f_side("swing", 0, 0, 0), f_side("swing", 1, -1, 1), f_side("swing", 0, 0, 0), f_side("swing", 1, -1, -1)],
        4: [f_front("guard"), f_front("jab_down"), f_front("guard")],
        5: [f_back("guard"), f_back("jab_up"), f_back("guard")],
        6: [f_side("guard"), f_side("jab", 1), f_side("guard")],
        7: [f_front("guard", dy=2), f_back("swing", -1, 1, (1, 0)), f_side("back", 1, 1, 0, 2), f_front("flail", dy=1, eyes="shut")],
        8: ["defeated"],
    }


def make_sheet(outfit):
    sheet = Image.new("RGBA", (FRAME * COLS, FRAME * ROWS), (0, 0, 0, 0))
    frames = build_frames()
    for row, items in frames.items():
        for col, cv in enumerate(items):
            if cv == "defeated":
                down = render(f_front("flail", eyes="shut"), outfit).rotate(90, expand=False)
                img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
                img.paste(down, (0, 8), down)  # lying on the floor
            else:
                img = render(cv, outfit)
            sheet.paste(img, (col * FRAME, row * FRAME), img)
    return sheet


LABELS = ["idle (pocket)", "walk down", "walk up", "walk side", "punch down", "punch up", "punch side", "dash x3 + hurt", "knocked out"]


def make_preview(sheets):
    s = 4
    pad = 16
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    font = ImageFont.truetype(font_path, 13) if os.path.exists(font_path) else ImageFont.load_default()
    label_w = 120
    w = label_w + len(sheets) * (FRAME * COLS * s + pad) + pad
    h = pad * 2 + 22 + ROWS * FRAME * s
    img = Image.new("RGB", (w, h), (10, 8, 18))
    d = ImageDraw.Draw(img)
    for i, (name, sheet) in enumerate(sheets.items()):
        x = label_w + pad + i * (FRAME * COLS * s + pad)
        d.text((x, pad - 2), name.upper(), font=font, fill=(235, 235, 245))
        bg = Image.new("RGB", (FRAME * COLS * s, FRAME * ROWS * s), (22, 17, 36))
        img.paste(bg, (x, pad + 22))
        big = sheet.resize((FRAME * COLS * s, FRAME * ROWS * s), Image.NEAREST)
        img.paste(big, (x, pad + 22), big)
    for r, label in enumerate(LABELS):
        d.text((pad, pad + 22 + r * FRAME * s + 56), label, font=font, fill=(160, 155, 185))
    return img


def make_gif(sheet, path):
    s = 5
    anims = [("idle", 0, 4, 0.3), ("walk down", 1, 4, 0.15), ("walk up", 2, 4, 0.15), ("walk side", 3, 4, 0.15), ("punch", 6, 3, 0.12)]
    w = len(anims) * FRAME * s
    frames = []
    for t in range(12):
        canvas = Image.new("RGB", (w, FRAME * s), (22, 17, 36))
        for i, (_, row, count, _) in enumerate(anims):
            col = t % count
            cell = sheet.crop((col * FRAME, row * FRAME, (col + 1) * FRAME, (row + 1) * FRAME)).resize((FRAME * s, FRAME * s), Image.NEAREST)
            canvas.paste(cell, (i * FRAME * s, 0), cell)
        frames.append(canvas)
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=160, loop=0)


if __name__ == "__main__":
    import sys
    os.makedirs(OUT_DIR, exist_ok=True)
    preview_dir = sys.argv[1] if len(sys.argv) > 1 else OUT_DIR
    sheets = {}
    for name, outfit in OUTFITS.items():
        sheet = make_sheet(outfit)
        sheet.save(os.path.join(OUT_DIR, f"bud_{name}.png"))
        sheets[name] = sheet
    make_preview(sheets).save(os.path.join(preview_dir, "bud_preview.png"))
    make_gif(sheets["white"], os.path.join(preview_dir, "bud_walk.gif"))
    print("wrote", OUT_DIR)
