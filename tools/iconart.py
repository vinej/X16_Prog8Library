#!/usr/bin/env python3
# =====================================================================
# iconart.py -- the drawing kit the desktop's icons are built from.
#
# 32x32 at 4bpp is small enough that an icon is mostly silhouette: at
# this size a recognisable OUTLINE beats any amount of interior detail,
# and one wrong pixel on an edge is visible. So the primitives here are
# deliberately blunt -- filled rectangles, one-pixel outlines, lines and
# ellipses -- plus a stamp() for hand-drawn text art, which is the only
# sane way to author something like a brush or a musical note.
#
# Colours are indices into the stock X16 16, because the desktop draws
# its sprites with palette offset 0. Index 0 is transparent, so an icon
# is a shape on the wallpaper rather than a tile on a coloured square.
#
# Everything works on a plain [[int]*32]*32 grid. tools/icon.py turns
# that into the VERA bytes and the 16x16 companion.
# =====================================================================
import icon

W = H = 32
CLEAR = 0

# The stock palette, by the name that makes an icon readable at a glance.
BLACK, WHITE, RED, CYAN = 0, 1, 2, 3
PURPLE, GREEN, BLUE, YELLOW = 4, 5, 6, 7
ORANGE, BROWN, PINK, DKGREY = 8, 9, 10, 11
GREY, LTGREEN, LTBLUE, LTGREY = 12, 13, 14, 15

# Index 0 means "see through" in a sprite, so a genuinely black pixel
# has to be faked. Dark grey reads as black against the wallpaper and
# still draws an outline that holds an edge.
INK = DKGREY


def grid(fill=CLEAR):
    return [[fill] * W for _ in range(H)]


# ---------------------------------------------------------------------
# primitives
# ---------------------------------------------------------------------
def px(g, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c


def fill_rect(g, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            g[y][x] = c


def rect(g, x0, y0, x1, y1, c):
    for x in range(x0, x1 + 1):
        px(g, x, y0, c)
        px(g, x, y1, c)
    for y in range(y0, y1 + 1):
        px(g, x0, y, c)
        px(g, x1, y, c)


def line(g, x0, y0, x1, y1, c):
    """Bresenham -- the same shape the library's gfx routines draw."""
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        px(g, x0, y0, c)
        if x0 == x1 and y0 == y1:
            return
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def ellipse(g, cx, cy, rx, ry, c, fill=None):
    for y in range(-ry, ry + 1):
        for x in range(-rx, rx + 1):
            d = (x * x) / (rx * rx or 1) + (y * y) / (ry * ry or 1)
            if d <= 1.0:
                inner = ((abs(x) - 1) ** 2) / (rx * rx or 1) + \
                        ((abs(y) - 1) ** 2) / (ry * ry or 1)
                if fill is not None:
                    px(g, cx + x, cy + y, fill)
                if d > 0.62 or inner > 1.0:
                    px(g, cx + x, cy + y, c)


def round_rect(g, x0, y0, x1, y1, c, fill=None):
    """A box with the four corner pixels dropped -- at 32 pixels that
    single missing pixel is the whole difference between a card and a
    brick, and anything more elaborate just looks chewed."""
    if fill is not None:
        fill_rect(g, x0, y0, x1, y1, fill)
    rect(g, x0, y0, x1, y1, c)
    for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        px(g, x, y, CLEAR)


# ---------------------------------------------------------------------
# text art
# ---------------------------------------------------------------------
# A motif is a list of equal-length strings. The key maps a character
# to a colour index; a space, or any character missing from the key,
# leaves the pixel alone -- so motifs stack without carrying their own
# background around with them.
def stamp(g, x, y, art, key):
    for dy, row in enumerate(art):
        for dx, ch in enumerate(row):
            if ch == " ":
                continue
            c = key.get(ch)
            if c is not None:
                px(g, x + dx, y + dy, c)


def outline(g, c=INK, over=CLEAR):
    """Trace a one-pixel border around everything already drawn.

    An icon of mid-grey on a mid-blue wallpaper disappears. Giving the
    silhouette an outline is what makes an icon survive being dropped
    on any background, which is exactly the case here -- the user picks
    the wallpaper.
    """
    src = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if src[y][x] != over:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and src[ny][nx] not in (over, c):
                    g[y][x] = c
                    break


# ---------------------------------------------------------------------
# output
# ---------------------------------------------------------------------
def save(g, path_ico, path_i16=None):
    icon.write(path_ico, g)
    if path_i16:
        icon.write(path_i16, icon.shrink(g))


def preview(g, path_png, zoom=8):
    icon.as_png(g, path_png, zoom)


# Previews are drawn over the desktop's own backdrop, not over nothing.
# Rendering transparency as white made every white-filled icon look
# empty -- a page, a clock face and a calculator all judged as broken
# when they were fine. The wallpaper is a photo, but plain desktop blue
# is the honest worst case for contrast.
BACKDROP = (0x2A, 0x3A, 0x6E)


def sheet(grids, path_png, cols=8, zoom=4, gap=2, small=False):
    """Contact sheet, so a whole batch can be judged at once instead of
    one file at a time. small=True halves each icon first, which is the
    view that actually decides whether an icon works."""
    import zlib, struct
    cell = W
    if small:
        grids = [icon.shrink(g) for g in grids]
        cell = W // 2
    rows = (len(grids) + cols - 1) // cols
    sw, sh = cols * (cell + gap) + gap, rows * (cell + gap) + gap
    canvas = [[CLEAR] * sw for _ in range(sh)]
    for i, g in enumerate(grids):
        ox = gap + (i % cols) * (cell + gap)
        oy = gap + (i // cols) * (cell + gap)
        for y in range(cell):
            for x in range(cell):
                canvas[oy + y][ox + x] = g[y][x]
    raw = b""
    for row in canvas:
        ln = b""
        for v in row:
            r, gg, b = BACKDROP if v == CLEAR else icon.X16_PALETTE[v]
            ln += bytes((r, gg, b, 255)) * zoom
        raw += (b"\x00" + ln) * zoom

    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload +
                struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    open(path_png, "wb").write(
        b"\x89PNG\r\n\x1a\n" +
        chunk(b"IHDR", struct.pack(">IIBBBBB", sw * zoom, sh * zoom, 8, 6, 0, 0, 0)) +
        chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
