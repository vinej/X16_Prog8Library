#!/usr/bin/env python3
# =====================================================================
# icons_def.py -- what each icon actually looks like.
#
# Two kinds live here. HERO icons are drawn one at a time and are the
# ones worth recognising instantly: paint, the clock, the calculator.
# CATEGORY icons are the fallback every other program gets, so that a
# card with two hundred programs on it has no blank squares.
#
# Rules that hold at 32x32, learned the hard way and worth keeping:
#   - silhouette first. If it is not readable as a black shape it will
#     not be readable in colour.
#   - one pixel of outline (INK) around everything, because the user
#     chooses the wallpaper and mid-grey on mid-blue is invisible.
#   - leave the outer ring of pixels clear. Icons sit next to each
#     other and a shape that touches the edge reads as a rectangle.
#   - no detail finer than 2 pixels, and put it on EVEN coordinates.
#     The 16x16 companion is made by halving 2x2 blocks, so a 2-pixel
#     bar starting at y=8 survives whole and the same bar starting at
#     y=9 straddles two blocks and turns to mush. This is the rule that
#     decides whether the small icon works, not the colour choices.
# =====================================================================
from iconart import (grid, px, fill_rect, rect, line, ellipse, round_rect,
                     stamp, outline, CLEAR, INK,
                     WHITE, RED, CYAN, PURPLE, GREEN, BLUE, YELLOW, ORANGE,
                     BROWN, PINK, DKGREY, GREY, LTGREEN, LTBLUE, LTGREY)

HERO = {}
CATEGORY = {}


def hero(name):
    def deco(fn):
        HERO[name] = fn
        return fn
    return deco


def category(name):
    def deco(fn):
        CATEGORY[name] = fn
        return fn
    return deco


# ---------------------------------------------------------------------
# hero icons
# ---------------------------------------------------------------------
@hero("paint")
def _paint(g):
    # A palette with a thumb hole and four blobs, brush across it. The
    # blobs are what make it read as "paint" rather than "shield".
    ellipse(g, 15, 18, 12, 10, INK, fill=BROWN)
    ellipse(g, 19, 21, 4, 3, INK, fill=CLEAR)
    for (bx, by, c) in ((9, 13, RED), (15, 11, YELLOW),
                        (21, 13, GREEN), (7, 20, LTBLUE)):
        ellipse(g, bx, by, 2, 2, INK, fill=c)
    line(g, 20, 8, 28, 3, BROWN)
    line(g, 21, 9, 29, 4, BROWN)
    fill_rect(g, 18, 8, 21, 11, LTGREY)
    px(g, 19, 12, RED)
    px(g, 20, 12, RED)


@hero("clock")
def _clock(g):
    ellipse(g, 16, 17, 13, 13, INK, fill=WHITE)
    ellipse(g, 16, 17, 11, 11, LTGREY, fill=None)
    for (x, y) in ((16, 7), (16, 27), (6, 17), (26, 17)):
        px(g, x, y, INK)
    line(g, 16, 17, 16, 10, INK)      # hour hand
    line(g, 16, 17, 22, 20, RED)      # minute hand
    fill_rect(g, 15, 16, 17, 18, INK)
    fill_rect(g, 14, 2, 18, 4, GREY)  # the little top button
    rect(g, 14, 2, 18, 4, INK)


@hero("calc")
def _calc(g):
    round_rect(g, 6, 2, 25, 29, INK, fill=LTGREY)
    fill_rect(g, 9, 5, 22, 10, LTGREEN)
    rect(g, 9, 5, 22, 10, INK)
    fill_rect(g, 18, 7, 21, 8, DKGREY)
    for row in range(4):
        for col in range(3):
            x, y = 9 + col * 5, 13 + row * 4
            fill_rect(g, x, y, x + 3, y + 2, DKGREY)


@hero("disk")
def _disk(g):
    round_rect(g, 3, 3, 28, 28, INK, fill=BLUE)
    fill_rect(g, 9, 4, 22, 13, LTGREY)      # shutter
    rect(g, 9, 4, 22, 13, INK)
    fill_rect(g, 13, 5, 18, 12, GREY)
    fill_rect(g, 7, 17, 24, 27, WHITE)      # label
    rect(g, 7, 17, 24, 27, INK)
    for y in (20, 23):
        line(g, 10, y, 21, y, GREY)


@hero("folder")
def _folder(g):
    fill_rect(g, 3, 7, 14, 10, ORANGE)      # tab
    rect(g, 3, 7, 14, 10, INK)
    round_rect(g, 3, 9, 28, 26, INK, fill=YELLOW)
    line(g, 6, 13, 25, 13, ORANGE)


@hero("doc")
def _doc(g):
    fill_rect(g, 7, 2, 24, 29, WHITE)
    rect(g, 7, 2, 24, 29, INK)
    fill_rect(g, 19, 2, 24, 7, CLEAR)       # folded corner
    line(g, 19, 2, 24, 7, INK)
    line(g, 19, 2, 19, 7, INK)
    line(g, 19, 7, 24, 7, INK)
    for y in range(11, 26, 3):
        line(g, 10, y, 21, y, GREY)


@hero("music")
def _music(g):
    # Stems on even columns and the beam on even rows, or the halved
    # note loses one stem and reads as a stray flag.
    ellipse(g, 9, 24, 4, 3, INK, fill=PURPLE)
    ellipse(g, 21, 21, 4, 3, INK, fill=PURPLE)
    fill_rect(g, 12, 8, 13, 24, INK)
    fill_rect(g, 24, 6, 25, 21, INK)
    fill_rect(g, 12, 6, 25, 9, INK)         # the beam


@hero("game")
def _game(g):
    round_rect(g, 3, 13, 28, 27, INK, fill=RED)
    fill_rect(g, 7, 17, 9, 23, DKGREY)      # d-pad
    fill_rect(g, 5, 19, 11, 21, DKGREY)
    ellipse(g, 22, 19, 2, 2, INK, fill=YELLOW)
    ellipse(g, 26, 22, 2, 2, INK, fill=YELLOW)
    fill_rect(g, 15, 4, 17, 13, GREY)       # stick
    ellipse(g, 16, 4, 4, 3, INK, fill=LTBLUE)


@hero("image")
def _image(g):
    fill_rect(g, 3, 6, 28, 25, LTBLUE)
    rect(g, 3, 6, 28, 25, INK)
    ellipse(g, 9, 12, 3, 3, INK, fill=YELLOW)
    line(g, 4, 24, 13, 15, GREEN)           # hills
    line(g, 13, 15, 20, 22, GREEN)
    line(g, 18, 24, 24, 17, LTGREEN)
    line(g, 24, 17, 27, 21, LTGREEN)
    fill_rect(g, 4, 22, 27, 24, GREEN)


@hero("term")
def _term(g):
    round_rect(g, 2, 4, 29, 24, INK, fill=GREY)
    fill_rect(g, 6, 8, 25, 20, DKGREY)
    # A chevron drawn as blocks rather than lines: two 2x2 steps down
    # and two back up, all on even coordinates, so the prompt is still
    # a prompt after halving instead of disappearing.
    fill_rect(g, 8, 10, 9, 11, LTGREEN)
    fill_rect(g, 10, 12, 11, 13, LTGREEN)
    fill_rect(g, 8, 14, 9, 15, LTGREEN)
    fill_rect(g, 14, 14, 21, 15, LTGREEN)   # the cursor line
    fill_rect(g, 12, 26, 19, 28, GREY)      # stand
    rect(g, 12, 26, 19, 28, INK)


@hero("font")
def _font(g):
    fill_rect(g, 5, 2, 26, 29, WHITE)
    rect(g, 5, 2, 26, 29, INK)
    line(g, 16, 7, 10, 24, INK)             # a big letter A
    line(g, 16, 7, 22, 24, INK)
    line(g, 17, 7, 23, 24, INK)
    line(g, 12, 19, 20, 19, INK)


@hero("gear")
def _gear(g):
    ellipse(g, 16, 16, 11, 11, INK, fill=GREY)
    for (dx, dy) in ((0, -13), (0, 13), (-13, 0), (13, 0),
                     (-9, -9), (9, -9), (-9, 9), (9, 9)):
        fill_rect(g, 16 + dx - 2, 16 + dy - 2, 16 + dx + 2, 16 + dy + 2, GREY)
        rect(g, 16 + dx - 2, 16 + dy - 2, 16 + dx + 2, 16 + dy + 2, INK)
    ellipse(g, 16, 16, 11, 11, INK, fill=None)
    ellipse(g, 16, 16, 4, 4, INK, fill=CLEAR)


@hero("info")
def _info(g):
    ellipse(g, 16, 16, 13, 13, INK, fill=LTBLUE)
    fill_rect(g, 14, 8, 17, 11, WHITE)          # the dot of the i
    fill_rect(g, 14, 14, 17, 24, WHITE)         # ...and its stem


@hero("palette")
def _palette(g):
    round_rect(g, 2, 4, 29, 27, INK, fill=LTGREY)
    swatches = ((RED, ORANGE, YELLOW), (GREEN, CYAN, LTBLUE),
                (BLUE, PURPLE, PINK))
    for r, rowc in enumerate(swatches):
        for c, col in enumerate(rowc):
            x, y = 5 + c * 8, 7 + r * 7
            fill_rect(g, x, y, x + 5, y + 4, col)
            rect(g, x, y, x + 5, y + 4, INK)


@hero("chip")
def _chip(g):
    for y in range(8, 25, 4):                   # legs down both sides
        fill_rect(g, 2, y, 5, y + 1, GREY)
        fill_rect(g, 26, y, 29, y + 1, GREY)
    round_rect(g, 6, 6, 25, 26, INK, fill=DKGREY)
    ellipse(g, 11, 11, 2, 2, GREY, fill=CLEAR)  # the pin-1 dimple
    fill_rect(g, 14, 14, 21, 15, GREY)
    fill_rect(g, 14, 18, 21, 19, GREY)


@hero("rocket")
def _rocket(g):
    fill_rect(g, 13, 4, 18, 21, LTGREY)
    ellipse(g, 16, 6, 3, 5, INK, fill=LTGREY)   # nose
    rect(g, 13, 4, 18, 21, INK)
    ellipse(g, 16, 12, 3, 3, INK, fill=LTBLUE)  # window
    line(g, 12, 14, 8, 22, INK)                 # fins
    line(g, 8, 22, 12, 21, INK)
    fill_rect(g, 9, 20, 12, 21, RED)
    line(g, 19, 14, 23, 22, INK)
    line(g, 23, 22, 19, 21, INK)
    fill_rect(g, 19, 20, 22, 21, RED)
    fill_rect(g, 14, 22, 17, 25, ORANGE)        # flame
    fill_rect(g, 15, 26, 16, 28, YELLOW)


@hero("cube")
def _cube(g):
    # An isometric box: top face, then the two visible sides.
    top = ((16, 4), (28, 11), (16, 18), (4, 11))
    for i in range(4):
        line(g, top[i][0], top[i][1], top[(i + 1) % 4][0], top[(i + 1) % 4][1], INK)
    fill_rect(g, 5, 12, 15, 24, CYAN)
    fill_rect(g, 17, 12, 27, 24, BLUE)
    for i in range(4):
        line(g, top[i][0], top[i][1], top[(i + 1) % 4][0], top[(i + 1) % 4][1], LTBLUE)
    line(g, 4, 11, 4, 21, INK)
    line(g, 28, 11, 28, 21, INK)
    line(g, 16, 18, 16, 28, INK)
    line(g, 4, 21, 16, 28, INK)
    line(g, 28, 21, 16, 28, INK)


@hero("edit")
def _edit(g):
    fill_rect(g, 4, 4, 21, 29, WHITE)
    rect(g, 4, 4, 21, 29, INK)
    for y in range(9, 26, 4):
        fill_rect(g, 7, y, 18, y + 1, GREY)
    line(g, 20, 18, 27, 5, BROWN)               # pencil
    line(g, 21, 19, 28, 6, YELLOW)
    line(g, 22, 20, 29, 7, BROWN)
    fill_rect(g, 19, 19, 21, 21, LTGREY)        # its tip
    px(g, 19, 21, INK)


@hero("hex")
def _hex(g):
    round_rect(g, 2, 4, 29, 27, INK, fill=DKGREY)
    for r in range(4):
        y = 8 + r * 5
        fill_rect(g, 5, y, 8, y + 1, LTGREEN)   # the address column
        for c in range(4):
            fill_rect(g, 11 + c * 5, y, 13 + c * 5, y + 1, LTGREY)


@hero("tile")
def _tile(g):
    round_rect(g, 2, 2, 29, 29, INK, fill=DKGREY)
    cols = ((RED, GREEN, LTBLUE), (YELLOW, PURPLE, CYAN), (ORANGE, WHITE, LTGREEN))
    for r in range(3):
        for c in range(3):
            x, y = 5 + c * 8, 5 + r * 8
            fill_rect(g, x, y, x + 5, y + 5, cols[r][c])
            rect(g, x, y, x + 5, y + 5, INK)


# ---------------------------------------------------------------------
# category fallbacks -- every program gets one of these if nothing better
# ---------------------------------------------------------------------
@category("app")
def _c_app(g):
    round_rect(g, 4, 4, 27, 27, INK, fill=CYAN)
    fill_rect(g, 4, 4, 27, 9, BLUE)
    rect(g, 4, 4, 27, 9, INK)
    for y in range(13, 25, 4):
        line(g, 8, y, 23, y, WHITE)


@category("demo")
def _c_demo(g):
    # Raster bars. Five of them on a 4-pixel pitch starting at an even
    # row, so each one lands on exactly one row of the halved icon --
    # at a 3-pixel pitch they interfered with the block grid and the
    # small version came out a plain grey box.
    round_rect(g, 2, 4, 29, 27, INK, fill=DKGREY)
    for i, c in enumerate((RED, ORANGE, YELLOW, LTGREEN, LTBLUE)):
        fill_rect(g, 6, 8 + i * 4, 25, 9 + i * 4, c)


@category("basic")
def _c_basic(g):
    # A listing: green title bar, then line numbers and code as 2-pixel
    # bars on a 4-pixel pitch so both columns survive being halved.
    fill_rect(g, 4, 2, 27, 29, WHITE)
    rect(g, 4, 2, 27, 29, INK)
    fill_rect(g, 4, 2, 27, 7, GREEN)
    rect(g, 4, 2, 27, 7, INK)
    for i, y in enumerate((10, 14, 18, 22, 26)):
        fill_rect(g, 7, y, 12, y + 1, BLUE)             # line numbers
        fill_rect(g, 14, y, 24 - (i % 2) * 6, y + 1, GREY)


@category("dev")
def _c_dev(g):
    # Angle brackets as 2x2 blocks on even coordinates. Drawn as thin
    # lines they vanished entirely at 16x16 and the icon became a box.
    round_rect(g, 2, 6, 29, 26, INK, fill=GREY)
    fill_rect(g, 5, 9, 26, 23, DKGREY)
    fill_rect(g, 8, 14, 9, 15, LTGREEN)     # <
    fill_rect(g, 10, 12, 11, 13, LTGREEN)
    fill_rect(g, 10, 16, 11, 17, LTGREEN)
    fill_rect(g, 22, 14, 23, 15, LTGREEN)   # >
    fill_rect(g, 20, 12, 21, 13, LTGREEN)
    fill_rect(g, 20, 16, 21, 17, LTGREEN)
    fill_rect(g, 14, 12, 15, 19, YELLOW)    # the slash between them
    fill_rect(g, 16, 12, 17, 15, YELLOW)


@category("music")
def _c_music(g):
    _music(g)


@category("game")
def _c_game(g):
    _game(g)


@category("system")
def _c_system(g):
    _gear(g)


@category("doc")
def _c_doc(g):
    _doc(g)


def render(fn):
    g = grid()
    fn(g)
    outline(g)
    return g

