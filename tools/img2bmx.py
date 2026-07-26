#!/usr/bin/env python3
# =====================================================================
# img2bmx.py -- convert an image into a BMX v1 file for the Commander
# X16, sized for the 640x480 8bpp VERA_2 bitmap (the gfx8h engine).
# Load it on the X16 with cx.bmx_load_hires().
#
# Reads ANY format Pillow supports -- JPG, PNG, WEBP, AVIF, GIF, BMP,
# TIFF, ICO, TGA, PCX, PPM, QOI, and more -- plus HEIC/HEIF when the
# optional `pillow-heif` package is installed (pip install pillow-heif).
#
# The X16 has no image decoder (and decoding these on a 6502 is not
# practical), so the conversion + 256-colour quantization happen here on
# the PC; the X16 side is a single bmx_load_hires() call.
#
#   python tools/img2bmx.py photo.jpg  build/IMAGE.BMX
#   python tools/img2bmx.py photo.heic build/IMAGE.BMX   # needs pillow-heif
#   python tools/img2bmx.py photo.webp build/IMAGE.BMX --stretch
#   python tools/img2bmx.py photo.jpg  build/WALL.BMX --lores
#
# --lores targets the OTHER 8bpp bitmap: 320x240 on VERA layer 0, which
# the KERNAL's screen mode $80 pairs with a 40x30 text layer. Text can
# then sit over the image, so it makes a desktop background rather than
# a picture to look at. Its palette is quantized to 240 colours and
# placed at index 16, leaving 0-15 -- the system colours the text layer
# draws with -- alone. Get that wrong and the wallpaper repaints every
# character on screen.
#
# BMX v1 layout (see src_acme/storage/bmx.asm):
#   16-byte header, then palette (2 bytes/entry, VERA GB then R),
#   then one byte per pixel, row-major.
# =====================================================================
import sys, struct, argparse
from PIL import Image

# Optional: register the HEIC/HEIF opener if pillow-heif is available.
try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    pass

W, H = 640, 480               # the VERA_2 bitmap (gfx8h)
LORES_W, LORES_H = 320, 240   # VERA layer 0 (gfx8l), under 40x30 text
SYSCOLS = 16                  # palette entries the text layer needs kept

def main():
    ap = argparse.ArgumentParser(
        description="Convert an image (any format Pillow reads; HEIC needs "
                    "pillow-heif) to an X16 BMX for the 640x480 8bpp bitmap.")
    ap.add_argument("input")
    ap.add_argument("output", help="output .BMX (use an UPPER-CASE 8.3 name for the X16)")
    ap.add_argument("--stretch", action="store_true",
                    help="stretch to 640x480 (default: fit and letterbox, preserving aspect)")
    ap.add_argument("--bg", default="0,0,0", help="letterbox colour r,g,b (default 0,0,0)")
    ap.add_argument("--lores", action="store_true",
                    help="320x240 for VERA layer 0 under 40x30 text (a desktop "
                         "background); 240 colours from index 16, leaving the "
                         "16 system colours for the text")
    args = ap.parse_args()

    w, h = (LORES_W, LORES_H) if args.lores else (W, H)
    palstart = SYSCOLS if args.lores else 0
    ncols = 256 - palstart

    try:
        im = Image.open(args.input).convert("RGB")
    except Image.UnidentifiedImageError:
        hint = ""
        if args.input.lower().endswith((".heic", ".heif")):
            hint = "  (HEIC/HEIF needs:  pip install pillow-heif)"
        sys.exit(f"error: cannot read '{args.input}' -- unsupported image format{hint}")
    if args.stretch:
        im = im.resize((w, h), Image.LANCZOS)
    else:
        bg = tuple(int(c) for c in args.bg.split(","))
        canvas = Image.new("RGB", (w, h), bg)
        fit = im.copy()
        fit.thumbnail((w, h), Image.LANCZOS)
        canvas.paste(fit, ((w - fit.width) // 2, (h - fit.height) // 2))
        im = canvas

    p = im.convert("P", palette=Image.ADAPTIVE, colors=ncols)
    pal = p.getpalette()[:ncols * 3]               # RGB triples
    pixels = p.tobytes()                           # w*h indices, row-major
    assert len(pixels) == w * h, len(pixels)
    if palstart:
        # The quantizer numbers its colours from 0; shift both the pixels
        # and the palette up so nothing lands on a system colour.
        pixels = bytes(b + palstart for b in pixels)

    # VERA palette: 2 bytes/entry, low = (G4<<4)|B4, high = R4  (12-bit colour)
    palbytes = bytearray()
    for i in range(ncols):
        r, g, b = (pal[i*3] if i*3 < len(pal) else 0,
                   pal[i*3+1] if i*3+1 < len(pal) else 0,
                   pal[i*3+2] if i*3+2 < len(pal) else 0)
        r4, g4, b4 = r >> 4, g >> 4, b >> 4
        palbytes.append((g4 << 4) | b4)
        palbytes.append(r4)

    data_off = 16 + len(palbytes)
    header = bytes([ord("B"), ord("M"), ord("X"), 1,
                    8,        # bpp
                    3,        # VERA depth code (log2 8 = 3)
                    w & 0xFF, w >> 8,
                    h & 0xFF, h >> 8,
                    ncols & 0xFF,   # palette entries (0 = 256)
                    palstart,       # first palette index
                    data_off & 0xFF, data_off >> 8,
                    0,        # compression: none
                    0])       # border colour

    with open(args.output, "wb") as f:
        f.write(header)
        f.write(palbytes)
        f.write(pixels)
    total = len(header) + len(palbytes) + len(pixels)
    print(f"wrote {args.output}: {w}x{h}x8, {ncols} colours from index "
          f"{palstart}, {total} bytes ({len(pixels)} pixel bytes)")

if __name__ == "__main__":
    main()
