#!/usr/bin/env python3
# =====================================================================
# mkwalls.py -- turn the photos in pictures/ into desktop wallpapers.
#
# Each picture becomes TWO files in /DESKTOP on the card, because the
# desktop runs at one of two sizes and they are not interchangeable:
#
#   <STEM>.BMX   640x480 8bpp, for the VERA_2 board's own SDRAM
#   <STEM>.BMO   320x240 8bpp, for VERA layer 0 on a plain machine
#
# The lores one is quantized to 240 colours placed at index 16, leaving
# 0-15 alone -- those are the system colours the text layer draws with,
# and a wallpaper that takes them repaints every character on screen.
# img2bmx.py handles that; this just drives it for a folder.
#
# Stems are PICnn, deliberately short: the desktop remembers the chosen
# wallpaper in the 11 spare bytes of DESKTOP.CFG's header, which holds
# an 8-character stem and no more.
#
#   python tools/mkwalls.py                 convert into build/walls
#   python tools/mkwalls.py --card x16_rc3.img   ...and onto the card
# =====================================================================
import os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
PICS = os.path.join(ROOT, "pictures")
OUT = os.path.join(ROOT, "build", "walls")
IMG2BMX = os.path.join(HERE, "img2bmx.py")
EXTS = (".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tif", ".tiff")


def thumb(src, dst):
    """A 64x64 4bpp sprite of the picture, for the chooser to show.

    The chooser cannot show the wallpapers themselves -- one is 300 KB
    and there is nowhere to hold ten at once -- so each gets a thumbnail
    in exactly the format the icons use, and the same grid displays it.
    Quantized to the stock 16 colours, skipping index 0: that is
    transparent in a sprite, and a photograph with holes in it looks
    like a fault rather than a picture.
    """
    from PIL import Image
    import icon
    im = Image.open(src).convert("RGB").resize((64, 64), Image.LANCZOS)
    pal = list(enumerate(icon.X16_PALETTE))[1:]
    rows = []
    for y in range(64):
        row = []
        for x in range(64):
            r, g, b = im.getpixel((x, y))
            best, bd = 1, 1 << 30
            for i, (pr, pg, pb) in pal:
                d = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
                if d < bd:
                    bd, best = d, i
            row.append(best)
        rows.append(row)
    icon.write(dst, rows)


def convert(src, dst, lores):
    cmd = [sys.executable, IMG2BMX, src, dst, "--stretch"]
    if lores:
        cmd.append("--lores")
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"  FAILED {os.path.basename(src)}: "
              f"{(r.stderr or r.stdout).strip().splitlines()[-1:]}")
        return False
    return True


def main(argv):
    card = None
    if "--card" in argv:
        card = argv[argv.index("--card") + 1]
    if not os.path.isdir(PICS):
        raise SystemExit(f"no {PICS}")
    os.makedirs(OUT, exist_ok=True)

    pics = [(f"PIC{i:02d}", os.path.join(PICS, f))
            for i, f in enumerate(
                sorted(g for g in os.listdir(PICS)
                       if os.path.splitext(g)[1].lower() in EXTS), 1)]
    # The desktop's original wallpaper, so choosing another is not a
    # one-way door. It is the picture WALL.BMX was made from, and it
    # keeps that name -- the desktop already falls back to it.
    orig = os.path.join(ROOT, "1694790733.jpg")
    if os.path.isfile(orig):
        pics.insert(0, ("WALL", orig))

    made = []
    for stem, src in pics:
        big = os.path.join(OUT, stem + ".BMX")
        small = os.path.join(OUT, stem + ".BMO")
        print(f"  {os.path.basename(src)}  ->  {stem}")
        if convert(src, big, False) and convert(src, small, True):
            thumb(src, os.path.join(OUT, stem + ".THM"))
            made.append(stem)
    print(f"\n{len(made)} wallpaper(s) in {OUT}")

    if card and made:
        sys.path.insert(0, HERE)
        from img_put import Fat32
        fs = Fat32(card)
        fs.resolve(["DESKTOP"], create=True)
        for stem in made:
            for ext in (".BMX", ".BMO", ".THM"):
                data = open(os.path.join(OUT, stem + ext), "rb").read()
                fs.add(f"/DESKTOP/{stem}{ext}", data)
        free = fs.update_fsinfo()
        fs.close()
        print(f"{len(made) * 2} files written to {card}; {free} clusters free")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
