#!/usr/bin/env python3
# =====================================================================
# img2bmx.py -- convert a PNG/JPG (anything Pillow reads) into a BMX v1
# file for the Commander X16, sized for the 640x480 8bpp VERA_2 bitmap
# (the gfx8h engine). Load it on the X16 with cx.bmx_load_hires().
#
# The X16 has no PNG/JPEG decoder (and decoding those on a 6502 is not
# practical), so the conversion + 256-colour quantization happen here on
# the PC; the X16 side is a single bmx_load_hires() call.
#
#   python tools/img2bmx.py photo.jpg build/IMAGE.BMX
#   python tools/img2bmx.py photo.png build/IMAGE.BMX --stretch
#
# BMX v1 layout (see src_acme/storage/bmx.asm):
#   16-byte header, then palette (2 bytes/entry, VERA GB then R),
#   then one byte per pixel, row-major.
# =====================================================================
import sys, struct, argparse
from PIL import Image

W, H = 640, 480

def main():
    ap = argparse.ArgumentParser(description="PNG/JPG -> X16 BMX (640x480 8bpp)")
    ap.add_argument("input")
    ap.add_argument("output", help="output .BMX (use an UPPER-CASE 8.3 name for the X16)")
    ap.add_argument("--stretch", action="store_true",
                    help="stretch to 640x480 (default: fit and letterbox, preserving aspect)")
    ap.add_argument("--bg", default="0,0,0", help="letterbox colour r,g,b (default 0,0,0)")
    args = ap.parse_args()

    im = Image.open(args.input).convert("RGB")
    if args.stretch:
        im = im.resize((W, H), Image.LANCZOS)
    else:
        bg = tuple(int(c) for c in args.bg.split(","))
        canvas = Image.new("RGB", (W, H), bg)
        fit = im.copy()
        fit.thumbnail((W, H), Image.LANCZOS)
        canvas.paste(fit, ((W - fit.width) // 2, (H - fit.height) // 2))
        im = canvas

    # 256-colour adaptive palette
    p = im.convert("P", palette=Image.ADAPTIVE, colors=256)
    pal = p.getpalette()[:256 * 3]                 # RGB triples
    pixels = p.tobytes()                           # W*H indices, row-major
    assert len(pixels) == W * H, len(pixels)

    # VERA palette: 2 bytes/entry, low = (G4<<4)|B4, high = R4  (12-bit colour)
    palbytes = bytearray()
    for i in range(256):
        r, g, b = (pal[i*3] if i*3 < len(pal) else 0,
                   pal[i*3+1] if i*3+1 < len(pal) else 0,
                   pal[i*3+2] if i*3+2 < len(pal) else 0)
        r4, g4, b4 = r >> 4, g >> 4, b >> 4
        palbytes.append((g4 << 4) | b4)
        palbytes.append(r4)

    data_off = 16 + len(palbytes)                  # 16 + 512 = 528
    header = bytes([ord("B"), ord("M"), ord("X"), 1,
                    8,        # bpp
                    3,        # VERA depth code (log2 8 = 3)
                    W & 0xFF, W >> 8,
                    H & 0xFF, H >> 8,
                    0,        # palette entries (0 = 256)
                    0,        # first palette index
                    data_off & 0xFF, data_off >> 8,
                    0,        # compression: none
                    0])       # border colour

    with open(args.output, "wb") as f:
        f.write(header)
        f.write(palbytes)
        f.write(pixels)
    total = len(header) + len(palbytes) + len(pixels)
    print(f"wrote {args.output}: {W}x{H}x8, 256 colours, {total} bytes "
          f"({len(pixels)} pixel bytes)")

if __name__ == "__main__":
    main()
