#!/usr/bin/env python3
# =====================================================================
# icon.py -- the desktop's icon format: raw VERA sprite pixels.
#
# An icon file has NO header. It is exactly the bytes VERA reads as
# sprite pixels, so the desktop gets one on screen with a plain LOAD
# into VRAM and nothing to decode. That is not a format we invented:
# it is what SpritemateX writes as NAME.spr and what SlithyMatt's
# tile editor writes as TILES.BIN, so an icon can be drawn in either
# editor and dropped straight in.
#
#   NAME.ICO   32x32 4bpp, 2 + 512 bytes  -- the hires icon
#   NAME.I16   16x16 4bpp, 2 + 128 bytes  -- the lores icon
#   NAME.MET   6 bytes, optional          -- tile-editor metadata
#
# The 2 is a load-address header, and it is NOT optional. The desktop
# loads an icon with cx.fs_vload, which forces the secondary address to
# 0 so that the destination in X/Y is honoured -- and a CBM LOAD with
# SA=0 still reads the file's first two bytes and throws them away.
# Hand it a bare 512-byte file and the icon loads two bytes short, with
# every row after the first shifted by one pixel. The two bytes we write
# are zero: nothing reads them, they only have to be there to be eaten.
# This is exactly what the tile editor's prg_header flag records, and
# why SpritemateX's raw .spr needs converting rather than copying.
#
# The EXTENSION carries the geometry, which is why most icons need no
# .MET at all. That matters more than it sounds: 512 bytes of 4bpp is
# 1024 pixels, which is 32x32 -- but equally 64x16 or 16x64. Nothing
# in the pixels says which, and SpritemateX writes no metadata, so a
# bare .spr is genuinely ambiguous. Fixing the geometry to the name
# removes the guess without costing a file per icon.
#
# .MET, when written, is the tile editor's own 6-byte record so that
# tool can open our files:
#     0  width in pixels        (8/16/32/64)
#     1  height in pixels
#     2  bits per pixel         (literal 1/2/4/8, not a code)
#     3  tile count, 2 bytes little-endian
#     5  prg_header flag        (1 = the pixel file starts with a
#                                2-byte load address; ours never do)
#
# 4bpp packing: two pixels per byte, LEFT pixel in the HIGH nibble.
# Verified against a real SpritemateX save rather than assumed --
# decoding a 32x32 the other way combs every diagonal.
#
#   python tools/icon.py info FILE...        what a file is
#   python tools/icon.py show FILE           print it as text
#   python tools/icon.py png FILE OUT.PNG    render it
#   python tools/icon.py shrink IN.ICO OUT.I16
# =====================================================================
import os, struct, sys

ICO_W = ICO_H = 32
I16_W = I16_H = 16
BPP = 4
ICO_BYTES = ICO_W * ICO_H // 2          # 512
I16_BYTES = I16_W * I16_H // 2          # 128
TRANSPARENT = 0                         # index 0 is see-through in a sprite

# The stock X16 palette's first 16 entries, for rendering previews on
# the host. The machine already has these; nothing is written to the
# card from this table.
X16_PALETTE = [
    (0x00, 0x00, 0x00), (0xFF, 0xFF, 0xFF), (0x88, 0x00, 0x00), (0xAA, 0xFF, 0xEE),
    (0xCC, 0x44, 0xCC), (0x00, 0xCC, 0x55), (0x00, 0x00, 0xAA), (0xEE, 0xEE, 0x77),
    (0xDD, 0x88, 0x55), (0x66, 0x44, 0x00), (0xFF, 0x77, 0x77), (0x33, 0x33, 0x33),
    (0x77, 0x77, 0x77), (0xAA, 0xFF, 0x66), (0x00, 0x88, 0xFF), (0xBB, 0xBB, 0xBB),
]


# ---------------------------------------------------------------------
# 4bpp pixels <-> VERA bytes
# ---------------------------------------------------------------------
def pack(rows):
    """[[index,...] per row] -> VERA 4bpp bytes."""
    out = bytearray()
    for row in rows:
        if len(row) % 2:
            raise ValueError("a 4bpp row needs an even pixel count")
        for x in range(0, len(row), 2):
            out.append(((row[x] & 0x0F) << 4) | (row[x + 1] & 0x0F))
    return bytes(out)


def unpack(data, w, h):
    """VERA 4bpp bytes -> [[index,...] per row]."""
    stride = w // 2
    if len(data) < stride * h:
        raise ValueError(f"{len(data)} bytes is short of {w}x{h} ({stride*h})")
    rows = []
    for y in range(h):
        row = []
        for b in data[y * stride:(y + 1) * stride]:
            row.append(b >> 4)          # left pixel
            row.append(b & 0x0F)
        rows.append(row)
    return rows


# ---------------------------------------------------------------------
# files
# ---------------------------------------------------------------------
def geometry(path):
    """(w, h) implied by the extension, or guessed from the size."""
    ext = os.path.splitext(path)[1].upper()
    if ext in (".ICO", ".SPR", ".BIN"):
        return ICO_W, ICO_H
    if ext == ".I16":
        return I16_W, I16_H
    n = os.path.getsize(path)
    if n == ICO_BYTES:
        return ICO_W, ICO_H
    if n == I16_BYTES:
        return I16_W, I16_H
    raise SystemExit(f"{path}: cannot tell the geometry from name or size")


def read(path):
    w, h = geometry(path)
    data = open(path, "rb").read()
    want = w * h // 2
    if len(data) == want + 2:
        # a PRG-style 2-byte load address in front; the tile editor can
        # write one and BASIC's SAVE always does.
        data = data[2:]
    if len(data) != want:
        raise SystemExit(f"{path}: {len(data)} bytes, expected {want} for {w}x{h}")
    return unpack(data, w, h), w, h


HEADER = b"\x00\x00"        # eaten by LOAD; see the note at the top


def write(path, rows, header=True):
    open(path, "wb").write((HEADER if header else b"") + pack(rows))


def write_meta(path, w, h, count=1, prg_header=1):
    """The tile editor's 6-byte sidecar, so it can open our icons."""
    open(path, "wb").write(bytes([w, h, BPP]) + struct.pack("<H", count) +
                           bytes([prg_header]))


def read_meta(path):
    b = open(path, "rb").read()
    if len(b) < 6:
        raise SystemExit(f"{path}: {len(b)} bytes, expected a 6-byte record")
    return dict(width=b[0], height=b[1], bpp=b[2],
                count=struct.unpack("<H", b[3:5])[0], prg_header=b[5])


# ---------------------------------------------------------------------
# 32x32 -> 16x16
# ---------------------------------------------------------------------
OUTLINE = 11            # dark grey: what iconart draws silhouettes with


def _rank(v):
    """Tie-break order for the halving vote.

    A 2x2 block straddling a 1-pixel outline is an exact tie -- one
    outline pixel, one interior pixel -- and picking arbitrarily is
    what made the first attempt keep the left and right edges of a
    page while losing the top and bottom. The silhouette is the one
    thing that has to survive being halved, so the outline wins ties;
    transparency loses them, or icons grow holes.
    """
    if v == OUTLINE:
        return 2
    if v == TRANSPARENT:
        return 0
    return 1


def shrink(rows):
    """Halve by 2x2 blocks, by vote rather than by dropping pixels.

    Taking every other pixel loses any feature only one pixel wide --
    which at this size is most of the outline. Voting keeps a thin line
    alive as long as it fills half its block, and _rank settles the
    ties that a vote alone cannot.
    """
    out = []
    for y in range(0, len(rows), 2):
        row = []
        for x in range(0, len(rows[y]), 2):
            block = [rows[y][x], rows[y][x + 1], rows[y + 1][x], rows[y + 1][x + 1]]
            solid = [v for v in block if v != TRANSPARENT]
            if not solid:
                row.append(TRANSPARENT)
            else:
                row.append(max(set(solid), key=lambda v: (solid.count(v), _rank(v))))
        out.append(row)
    return out


# ---------------------------------------------------------------------
# host-side preview
# ---------------------------------------------------------------------
GLYPHS = " .:-=+*#%@01234X"


def as_text(rows):
    return "\n".join("".join(GLYPHS[v] for v in r) for r in rows)


def as_png(rows, path, zoom=8):
    import zlib
    h, w = len(rows), len(rows[0])
    raw = b""
    for row in rows:
        line = b""
        for v in row:
            r, g, b = X16_PALETTE[v]
            line += bytes((r, g, b, 0 if v == TRANSPARENT else 255)) * zoom
        raw += (b"\x00" + line) * zoom

    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload +
                struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    open(path, "wb").write(
        b"\x89PNG\r\n\x1a\n" +
        chunk(b"IHDR", struct.pack(">IIBBBBB", w * zoom, h * zoom, 8, 6, 0, 0, 0)) +
        chunk(b"IDAT", zlib.compress(raw, 9)) +
        chunk(b"IEND", b""))


# ---------------------------------------------------------------------
def main(argv):
    if not argv:
        print(__doc__ or "usage: icon.py info|show|png|shrink ...")
        return 1
    cmd, args = argv[0], argv[1:]

    if cmd == "info":
        for p in args:
            rows, w, h = read(p)
            used = sorted({v for r in rows for v in r})
            clear = sum(r.count(TRANSPARENT) for r in rows)
            print(f"{p}: {w}x{h} {BPP}bpp, {os.path.getsize(p)} bytes, "
                  f"colours {used}, {clear}/{w*h} transparent")
        return 0

    if cmd == "show":
        rows, w, h = read(args[0])
        print(f"{args[0]}  {w}x{h}")
        print(as_text(rows))
        return 0

    if cmd == "png":
        rows, _, _ = read(args[0])
        as_png(rows, args[1])
        print(f"wrote {args[1]}")
        return 0

    if cmd == "shrink":
        rows, w, h = read(args[0])
        if (w, h) != (ICO_W, ICO_H):
            raise SystemExit(f"shrink wants a {ICO_W}x{ICO_H} source, got {w}x{h}")
        write(args[1], shrink(rows))
        print(f"wrote {args[1]}  ({I16_BYTES} bytes)")
        return 0

    raise SystemExit(f"unknown command: {cmd}")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
