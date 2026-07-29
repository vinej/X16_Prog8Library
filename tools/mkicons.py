#!/usr/bin/env python3
# =====================================================================
# mkicons.py -- give every program on the card an icon.
#
# Walks the SD card image, works out which file in each directory is
# the program you would actually launch, picks an icon for it, and
# writes the pair:
#
#   <program dir>/NAME.ICO   32x32, beside the program it belongs to
#   <program dir>/NAME.I16   16x16
#   /DESKTOP/NAME.ICO        the same file again, as the library the
#   /DESKTOP/NAME.I16        picker offers when a program has none
#
# Two copies on purpose. The one beside the program is what the desktop
# finds automatically when you add that program; the one in /DESKTOP is
# what you choose from by hand for a program that has no icon of its own.
# They are the same bytes, and a card is big enough that 640 bytes per
# program is not worth being clever about.
#
#   python tools/mkicons.py --plan            what it would do, no writes
#   python tools/mkicons.py --out build/icons write the files to disk
#   python tools/mkicons.py --card x16_rc3.img   ...and onto the card
#   python tools/mkicons.py --sheet out.png   contact sheet of the lot
# =====================================================================
import os, sys, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import icon, iconart, icons_def as D
from img_put import Fat32

CARD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "x16_rc3.img")
RUNNABLE = (".PRG", ".X16")

# ---------------------------------------------------------------------
# which icon a program gets
# ---------------------------------------------------------------------
# Matched against "<DIRECTORY>/<PROGRAM>" upper-cased, first hit wins,
# so the specific rules have to come before the general ones. Anything
# that matches nothing lands on its directory's category, and anything
# with no category at all gets "app" -- there are no blank squares.
RULES = [
    # --- unmistakable programs ---------------------------------------
    ("PAINT", "paint"), ("PETDRAW", "paint"), ("DRAW", "paint"),
    ("CLOCK", "clock"), ("TIME", "clock"),
    ("CALC", "calc"), ("KALK", "calc"), ("SHEET", "calc"),
    ("FONT", "font"), ("CHARSET", "font"), ("PETSCII", "font"),
    ("IMAGEVIE", "image"), ("IMGVIEW", "image"), ("XVIEW", "image"),
    ("VIEWER", "image"), ("SLDESHOW", "image"), ("SLIDESHO", "image"),
    ("KOALA", "image"), ("DOODLE", "image"), ("BMX", "image"),
    ("MIDI", "music"), ("WAV", "music"), ("ZSM", "music"), ("AUDIO", "music"),
    ("MUSIC", "music"), ("SONG", "music"), ("PSG", "music"), ("YM", "music"),
    ("TILE", "tile"), ("SPRITE", "tile"), ("MAP", "tile"),
    ("HXD", "hex"), ("HEX", "hex"), ("MON", "hex"),
    ("EDIT", "edit"), ("X16EDIT", "edit"), ("WRITE", "edit"), ("TEXT", "edit"),
    ("ASSE", "dev"), ("ASM", "dev"), ("FORTH", "dev"), ("PASC", "dev"),
    ("COMPIL", "dev"), ("BASLOAD", "dev"),
    ("ROMFLASH", "chip"), ("FLASH", "chip"), ("ROM", "chip"), ("SMC", "chip"),
    ("INFO", "info"), ("XINFO", "info"), ("HELP", "info"), ("README", "info"),
    ("LAUNCH", "rocket"), ("SHELL", "term"), ("CMD", "term"), ("DOS", "term"),
    ("CAT", "folder"), ("DIR", "folder"), ("FILE", "folder"),
    ("3D", "cube"), ("ENGINE", "cube"), ("SUZANNE", "cube"), ("XWING", "cube"),
    ("PACMAN", "game"), ("SNAKE", "game"), ("TETRIS", "game"), ("BOULD", "game"),
    ("INVAD", "game"), ("CHASE", "game"), ("JIMBO", "game"), ("VELOCITY", "game"),
    ("CRAZY", "game"), ("GAME", "game"), ("PONG", "game"), ("LIFE", "game"),
    ("DEMO", "demo"), ("INTRO", "demo"), ("BADAPPLE", "demo"),
    ("SONIC", "demo"), ("TRIB", "demo"), ("DANC", "demo"), ("METAL", "demo"),
    ("PAL", "palette"), ("COLOR", "palette"), ("COLOUR", "palette"),
    ("VERA", "chip"), ("VGA", "chip"), ("I2C", "chip"),
    ("TERM", "term"), ("MODEM", "term"), ("SERIAL", "term"), ("BBS", "term"),
]

# The directory a program sits in, when its own name says nothing.
DIR_CATEGORY = [
    ("GAMES", "game"), ("DEMOS", "demo"), ("MUSIC", "music"),
    ("BASIC", "basic"), ("DEV", "dev"), ("SYSTEM", "system"),
    ("DOCS", "doc"), ("APPS", "app"), ("EXPLORE", "app"), ("INTRO", "demo"),
]


# What the READMEs actually say. A name tells you almost nothing about
# JIMBO or 1160, but the .NFO sitting beside it says "platform game" or
# "raster demo" in as many words. These are matched against the text of
# every readable file in the program's own directory, and only consulted
# when the name rules above have nothing to offer -- a filename is a
# deliberate label, prose is circumstantial.
TEXT_HINTS = {
    "game":    ["game", "player", "score", "level", "enemy", "joystick",
                "lives", "arcade", "shoot", "jump", "maze", "platform"],
    "demo":    ["demo", "scroller", "raster", "effect", "greetings", "scene",
                "sine", "plasma", "bouncing", "intro", "party"],
    "music":   ["music", "tune", "song", "melody", "audio", "sound", "psg",
                "note", "octave", "instrument", "zsm", "midi"],
    "paint":   ["paint", "draw", "brush", "canvas", "pixel art", "palette"],
    "image":   ["image", "picture", "photo", "bitmap", "viewer", "slideshow"],
    "dev":     ["assembler", "compiler", "source", "opcode", "label",
                "assembly", "debugger", "disassemb"],
    "edit":    ["editor", "text file", "cursor", "word wrap", "typing"],
    "basic":   ["basic program", "10 print", "gosub", "goto", "list the"],
    "calc":    ["calculator", "spreadsheet", "arithmetic", "formula"],
    "term":    ["terminal", "modem", "serial", "bbs", "baud", "shell"],
    "system":  ["utility", "system", "configure", "settings", "install"],
    "info":    ["documentation", "manual", "reference", "guide", "about"],
    "tile":    ["tile", "sprite", "tileset", "tilemap"],
    "font":    ["font", "charset", "character set", "typeface", "glyph"],
    "chip":    ["vera", "register", "firmware", "rom", "flash", "smc"],
}

# Bytes to letters, whatever the encoding. Text on this card is PETSCII,
# where the letters live at $41-$5A and again at $C1-$DA depending on the
# case mode the writer was in; decoding it as ASCII and lower-casing gets
# you mojibake and no matches at all. Everything that is not a letter or
# a digit becomes a space, which is all a keyword search needs.
def _letters(data):
    out = bytearray()
    for b in data:
        if 0x41 <= b <= 0x5A or 0xC1 <= b <= 0xDA:
            out.append((b & 0x1F) + 0x60)        # -> a-z
        elif 0x61 <= b <= 0x7A:
            out.append(b)
        elif 0x30 <= b <= 0x39:
            out.append(b)
        else:
            out.append(0x20)
    return out.decode("ascii")


HINT_EXT = (".TXT", ".NFO", ".MD", ".DOC", ".ME", ".DIZ", ".SEQ")
HINT_BUDGET = 8192          # per directory; a manual proves nothing more


def read_hints(fs, path, files):
    """The prose in a program's own directory, as one lower-case string."""
    text, budget = [], HINT_BUDGET
    for name, size in files:
        base, _, ext = name.upper().partition(".")
        if "." + ext not in HINT_EXT and "READ" not in base:
            continue
        if budget <= 0:
            break
        try:
            data = fs.read_file(f"{path}/{name}")
        except SystemExit:
            continue
        if not data:
            continue
        text.append(_letters(data[:budget]))
        budget -= len(data[:budget])
    return " ".join(text)


def pick_icon(dirpath, prog, hints=""):
    hay = f"{dirpath}/{prog}".upper()
    for needle, name in RULES:
        if needle in hay:
            return name, "rule:" + needle
    if hints:
        score = {}
        for name, words in TEXT_HINTS.items():
            n = sum(hints.count(w) for w in words)
            if n:
                score[name] = n
        if score:
            best = max(score, key=lambda k: score[k])
            # Two hits, or one that beats everything else outright. A
            # single incidental "sound" in a game's readme should not
            # outvote the directory it sits in.
            if score[best] >= 2:
                return best, f"text:{best}={score[best]}"
    for needle, name in DIR_CATEGORY:
        if needle in dirpath.upper():
            return name, "dir:" + needle
    return "app", "default"


def draw(name):
    """Resolve an icon name to a grid, hero first then category."""
    fn = D.HERO.get(name) or D.CATEGORY.get(name)
    if fn is None:
        fn = D.CATEGORY["app"]
    return D.render(fn)


# ---------------------------------------------------------------------
# reading the card
# ---------------------------------------------------------------------
def entries(fs, cluster):
    out, pending = [], []
    for c, off in fs._slots(cluster):
        e = fs._read(c, off)
        if e[0] == 0x00:
            break
        if e[0] == 0xE5:
            pending = []
            continue
        if e[11] == 0x0F:
            pending.append(e)
            continue
        long = "".join(fs._lfn_chars(x) for x in reversed(pending))
        pending = []
        if e[11] & 0x08:
            continue
        nm = e[0:8].decode("latin-1").rstrip()
        ex = e[8:11].decode("latin-1").rstrip()
        if nm in (".", ".."):
            continue
        short = nm + ("." + ex if ex else "")
        # The LONG name wins wherever there is one. 81 of this card's
        # programs are stored under a mangled 8.3 name -- IMAGEVIE.PRG
        # is IMAGEVIEWER.PRG, and some are bare aliases like
        # 3DENGI~1.PRG -- and CMDR-DOS hands the long one back. Naming
        # an icon after the short entry produced 3DENGI~1.ICO, which is
        # a file the desktop would never once ask for.
        out.append((long or short, bool(e[11] & 0x10),
                    int.from_bytes(e[28:32], "little"), fs._start_of(e)))
    return out


def programs(files):
    """Every file in a directory you would actually launch.

    One icon per DIRECTORY was the first cut, and it was wrong: the
    card's root alone holds desktop, kalk, imgview, fm and shell, and
    picking a single "main" program there left kalk with no icon at
    all. A directory is not a program. Each runnable gets its own.

    AUTOBOOT.X16 is excluded -- it is a stub the ROM runs to load
    something else, so it never names the program it starts. .BIN is
    excluded too: there are 1841 on this card and they are tilesets and
    samples, not programs.
    """
    return sorted(n for n, _s in files
                  if os.path.splitext(n)[1].upper() in RUNNABLE
                  and not n.upper().startswith("AUTOBOOT"))


def scan(img):
    fs = Fat32(img)
    found = []

    def walk(cluster, path, depth=0):
        if depth > 4:
            return
        ents = entries(fs, cluster)
        files = [(n, s) for n, d, s, _c in ents if not d]
        progs = programs(files)
        if progs:
            hints = read_hints(fs, path, files)
            for prog in progs:
                found.append((path or "/", prog, hints))
        for n, isdir, _s, start in ents:
            if isdir and not n.startswith("0000"):
                walk(start, f"{path}/{n}", depth + 1)

    walk(fs.root, "")
    fs.close()
    return found


# ---------------------------------------------------------------------
def main(argv):
    img = CARD
    out = sheet_path = None
    card = None
    plan = "--plan" in argv
    for i, a in enumerate(argv):
        if a == "--out":
            out = argv[i + 1]
        elif a == "--card":
            card = argv[i + 1]
        elif a == "--sheet":
            sheet_path = argv[i + 1]
        elif a == "--img":
            img = argv[i + 1]

    progs = scan(img)
    chosen = []
    for path, prog, hints in progs:
        name, why = pick_icon(path, prog, hints)
        chosen.append((path, prog, name, why))

    tally = collections.Counter(c[2] for c in chosen)
    print(f"{len(chosen)} programs, {len(tally)} distinct icons")
    for name, n in tally.most_common():
        kind = "hero" if name in D.HERO else "cat "
        print(f"  {kind} {name:9} {n:4}")

    if plan:
        print()
        for path, prog, name, why in chosen:
            print(f"  {path or '/':44} {prog:14} -> {name:9} ({why})")
        return 0

    if sheet_path:
        seen, grids = [], []
        for name in sorted(tally):
            seen.append(name)
            grids.append(draw(name))
        iconart.sheet(grids, sheet_path, cols=8, zoom=5)
        print(f"\nwrote {sheet_path}: {' '.join(seen)}")

    if out:
        os.makedirs(out, exist_ok=True)
        cache = {}
        for path, prog, name, _why in chosen:
            if name not in cache:
                cache[name] = draw(name)
            stem = os.path.splitext(prog)[0].upper()   # full long name; img_put writes an LFN
            icon.write(os.path.join(out, f"{stem}.ICO"), cache[name])
            icon.write(os.path.join(out, f"{stem}.I16"), icon.shrink(cache[name]))
        print(f"\nwrote {len(os.listdir(out))} files to {out}")

    if card:
        fs = Fat32(card)
        dcl = fs.resolve(["DESKTOP"], create=True)
        # /DESKTOP is a LIBRARY of the distinct icons, named after the
        # drawing rather than after a program. Writing one file per
        # program put 111 of them here, and since 211 programs are drawn
        # from 22 pictures most were byte-identical -- so the grid
        # offered the same icons over and over across five pages.
        # Clear whatever is there before writing, or yesterday's
        # program-named copies linger and the duplicates come back.
        # Walk the slots rather than deleting by name. Deleting by name
        # removes the FIRST match, and an earlier run left several
        # entries sharing one short alias -- COLORC~1.ICO three times --
        # so a name-based pass removed one of each and left the rest.
        # Walking every slot cannot miss a duplicate, because it never
        # asks what anything is called.
        gone = 0
        pending = []
        for c, off in fs._slots(dcl):
            e = fs._read(c, off)
            if e[0] == 0x00:
                break
            if e[0] == 0xE5:
                pending = []
                continue
            if e[11] == 0x0F:
                pending.append((c, off, e))
                continue
            ext = e[8:11].decode("latin-1").rstrip().upper()
            if ext in ("ICO", "I16"):
                start = fs._start_of(e)
                if start >= 2:
                    for cl in fs.chain(start):
                        fs.fat_set(cl, 0)
                fs._write(c, off, b"\xE5" + e[1:])
                for lc, loff, le in pending:
                    fs._write(lc, loff, b"\xE5" + le[1:])
                gone += 1
            pending = []
        cache, wrote = {}, 0
        for path, prog, name, _why in chosen:
            if name not in cache:
                g = draw(name)
                # icon.HEADER, or the card copies go out two bytes short
                # of the files on disk and every row shifts by a pixel.
                cache[name] = (icon.HEADER + icon.pack(g),
                               icon.HEADER + icon.pack(icon.shrink(g)))
            big, small = cache[name]
            stem = os.path.splitext(prog)[0].upper()   # full long name; img_put writes an LFN
            fs.add(f"{path}/{stem}.ICO", big)
            fs.add(f"{path}/{stem}.I16", small)
            wrote += 2
        # One .MET beside the library so the tile editor can open the
        # icons without being told their geometry. Per-icon copies would
        # be 111 more files saying the same six bytes.
        # ...and now the library itself: one file per distinct drawing,
        # named after it, so /DESKTOP holds 22 recognisable choices
        # instead of 111 copies of them.
        lib = 0
        for name in sorted(set(c[2] for c in chosen)):
            big, small = cache[name]
            fs.add(f"/DESKTOP/{name.upper()}.ICO", big)
            fs.add(f"/DESKTOP/{name.upper()}.I16", small)
            lib += 2
        fs.add("/DESKTOP/ICON32.MET", bytes([32, 32, 4, 1, 0, 1]))
        fs.add("/DESKTOP/ICON16.MET", bytes([16, 16, 4, 1, 0, 1]))
        print(f"  /DESKTOP: {gone} old files removed, {lib} written "
              f"({lib // 2} distinct icons)")
        wrote += lib + 2
        free = fs.update_fsinfo()
        fs.close()
        print(f"\n{wrote} files written to {card}; {free} clusters free")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))


