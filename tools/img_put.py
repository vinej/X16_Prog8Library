#!/usr/bin/env python3
# =====================================================================
# img_put.py -- put files into the root of an X16 SD card image.
#
# The emulator will mount a .img with -sdcard, but nothing on the host
# side writes into one, so a freshly built PRG cannot be tried on the
# card without a detour through a real card reader. This does it
# directly: FAT32 is simple enough that adding a file to a root
# directory is a couple of hundred lines, and having it here keeps
# "build, copy, run" a single step.
#
#   python tools/img_put.py card.img --list
#   python tools/img_put.py card.img --list /DESKTOP
#   python tools/img_put.py card.img build/DESKTOP.PRG build/KALK.PRG
#   python tools/img_put.py card.img --as WALL.BMX build/WALL.BMX
#   python tools/img_put.py card.img --mkdir /DESKTOP
#   python tools/img_put.py card.img --as /DESKTOP/PAINT.ICO build/paint.ico
#
# Short 8.3 names only, which is all the X16 asks for. A file of the
# same name is replaced -- its clusters are freed first, so re-syncing
# after a rebuild does not leak space -- and every write is read back
# and compared before the tool reports success. The FSInfo free-cluster
# count is recomputed afterwards: the X16's DOS believes whatever it finds
# there, so the "unknown" sentinel most PC tools leave behind is what makes
# the machine report 4095 GB free.
#
# Any name may carry a /PATH. Directories are walked, created on demand
# with --mkdir, and grown by a cluster when one fills up -- the root
# included, which used to be a hard "the root directory is full".
# =====================================================================
import os, struct, sys


class Fat32:
    def __init__(self, path, part_lba=None):
        self.f = open(path, "r+b")
        if part_lba is None:
            self.f.seek(0)
            mbr = self.f.read(512)
            part_lba = 0
            for i in range(4):
                e = mbr[446 + i * 16: 446 + (i + 1) * 16]
                if any(e) and e[4] in (0x0B, 0x0C, 0x06, 0x04, 0x0E):
                    part_lba = int.from_bytes(e[8:12], "little")
                    break
        self.base = part_lba * 512
        self.f.seek(self.base)
        b = self.f.read(512)
        if b[510:512] != b"\x55\xaa":
            raise SystemExit("not a filesystem: no boot signature")
        self.bps = int.from_bytes(b[11:13], "little")
        self.spc = b[13]
        self.res = int.from_bytes(b[14:16], "little")
        self.nfat = b[16]
        self.spf = int.from_bytes(b[36:40], "little")
        self.root = int.from_bytes(b[44:48], "little")
        self.total = int.from_bytes(b[32:36], "little")
        if not (self.bps and self.spc and self.spf):
            raise SystemExit("not FAT32")
        self.fat0 = self.base + self.res * self.bps
        self.data = self.fat0 + self.nfat * self.spf * self.bps
        self.csize = self.spc * self.bps
        self.nclusters = (self.total - self.res - self.nfat * self.spf) // self.spc + 2

    # ---- the allocation table ---------------------------------------
    def fat_get(self, cl):
        self.f.seek(self.fat0 + cl * 4)
        return int.from_bytes(self.f.read(4), "little") & 0x0FFFFFFF

    def fat_set(self, cl, val):
        # every copy, or the next thing to mount this disagrees with us
        for i in range(self.nfat):
            off = self.fat0 + i * self.spf * self.bps + cl * 4
            self.f.seek(off)
            old = int.from_bytes(self.f.read(4), "little")
            self.f.seek(off)
            self.f.write(((old & 0xF0000000) | (val & 0x0FFFFFFF)).to_bytes(4, "little"))

    def chain(self, cl):
        out = []
        while 2 <= cl < 0x0FFFFFF8:
            out.append(cl)
            cl = self.fat_get(cl)
            if len(out) > 1_000_000:
                raise SystemExit("cluster loop in the FAT")
        return out

    def free_clusters(self, n):
        found, cl = [], 2
        while cl < self.nclusters and len(found) < n:
            if self.fat_get(cl) == 0:
                found.append(cl)
            cl += 1
        if len(found) < n:
            raise SystemExit("no room left on the image")
        return found

    def cluster_off(self, cl):
        return self.data + (cl - 2) * self.csize

    # ---- directories -------------------------------------------------
    def _slots(self, cluster=None):
        """Every 32-byte entry slot of one directory, in order."""
        for c in self.chain(self.root if cluster is None else cluster):
            for off in range(0, self.csize, 32):
                yield c, off

    def _grow_dir(self, cluster):
        """Append one zeroed cluster to a directory that has filled up.

        Without this a directory is capped at csize/32 entries (128 on a
        4 KB cluster) and the tool simply refused to write. A directory
        of icons hits that, and so does the root of a working card.
        """
        chain = self.chain(cluster)
        new = self.free_clusters(1)[0]
        self.f.seek(self.cluster_off(new))
        self.f.write(b"\x00" * self.csize)
        self.fat_set(new, 0x0FFFFFFF)
        self.fat_set(chain[-1], new)
        return new

    def _read(self, c, off):
        self.f.seek(self.cluster_off(c) + off)
        return self.f.read(32)

    def _write(self, c, off, data):
        self.f.seek(self.cluster_off(c) + off)
        self.f.write(data)

    @staticmethod
    def short(name):
        name = name.upper()
        base, _, ext = name.partition(".")
        if len(base) > 8 or len(ext) > 3:
            raise SystemExit(f"{name}: not an 8.3 name")
        return base.ljust(8).encode("latin-1") + ext.ljust(3).encode("latin-1")

    def list_root(self, cluster=None):
        out = []
        for c, off in self._slots(cluster):
            e = self._read(c, off)
            if e[0] == 0x00:
                break
            if e[0] == 0xE5 or e[11] == 0x0F or (e[11] & 0x08):
                continue          # deleted, a long-name part, or the label
            name = e[0:8].decode("latin-1").rstrip()
            ext = e[8:11].decode("latin-1").rstrip()
            if name in (".", ".."):
                continue
            out.append((name + ("." + ext if ext else ""),
                        "DIR" if e[11] & 0x10 else "FILE",
                        int.from_bytes(e[28:32], "little"),
                        int.from_bytes(e[20:22], "little") << 16 |
                        int.from_bytes(e[26:28], "little")))
        return out

    # ---- walking and making paths ------------------------------------
    @staticmethod
    def split(path):
        """'/DESKTOP/PAINT.ICO' -> (['DESKTOP'], 'PAINT.ICO')."""
        parts = [p for p in path.replace("\\", "/").split("/") if p]
        return parts[:-1], (parts[-1] if parts else "")

    def find_entry(self, cluster, name):
        """(c, off, entry) of a child by SHORT or LONG name, or None.

        Long names matter here as much as for files: /APPS/IMAGEVIEWER
        is stored as IMAGEVIE with the real name in an LFN, so walking a
        path built from long names has to match them or the directory
        simply is not found.
        """
        tag = self.short(name) if self._is_short(name) else None
        want = name.upper()
        pending = []
        for c, off in self._slots(cluster):
            e = self._read(c, off)
            if e[0] == 0x00:
                return None
            if e[0] == 0xE5:
                pending = []
                continue
            if e[11] == 0x0F:
                pending.append(e)
                continue
            long = "".join(self._lfn_chars(x) for x in reversed(pending))
            pending = []
            if (tag and e[0:11] == tag) or long.upper() == want:
                return c, off, e
        return None

    @staticmethod
    def _start_of(e):
        return int.from_bytes(e[20:22], "little") << 16 | \
               int.from_bytes(e[26:28], "little")

    def _put_entry(self, cluster, entries):
        """Write one or more records into CONSECUTIVE free slots.

        Consecutive matters: a long name is only valid while its slots
        sit unbroken immediately before the 8.3 entry they describe, so
        they cannot be scattered into whatever holes happen to be free.
        """
        if isinstance(entries, (bytes, bytearray)):
            entries = [entries]
        need = len(entries)
        while True:
            run = []
            for c, off in self._slots(cluster):
                e = self._read(c, off)
                if e[0] in (0x00, 0xE5):
                    run.append((c, off, e[0] == 0x00))
                    if len(run) == need:
                        for (rc, roff, _), rec in zip(run, entries):
                            self._write(rc, roff, rec)
                        # if we ate the end marker, put one back after us
                        lc, loff, was_end = run[-1]
                        if was_end and loff + 32 < self.csize:
                            self._write(lc, loff + 32, b"\x00" * 32)
                        return
                else:
                    run = []
            self._grow_dir(cluster if cluster is not None else self.root)

    # ---- long names --------------------------------------------------
    # 8.3 is not enough. 81 of the 212 programs on this card are stored
    # under a mangled short name with the real one in a long-name entry
    # -- IMAGEVIE.PRG is IMAGEVIEWER.PRG, LABYRINT.PRG is LABYRINTH.PRG
    # -- and CMDR-DOS hands the LONG name back. An icon named after the
    # short one is an icon nothing ever finds.
    #
    # A long name is stored as a run of 32-byte slots with attr $0F,
    # sitting immediately BEFORE the 8.3 entry and in REVERSE sequence
    # order, 13 UTF-16 characters each, every one carrying a checksum of
    # the 8.3 name so the pair cannot drift apart.
    LFN_OFFSETS = tuple(range(1, 11, 2)) + tuple(range(14, 26, 2)) + (28, 30)

    @staticmethod
    def lfn_checksum(tag):
        s = 0
        for b in tag:
            s = (((s & 1) << 7) + (s >> 1) + b) & 0xFF
        return s

    # The punctuation FAT allows in an 8.3 name. "~" has to be here: it
    # is the character every generated alias is built from, and leaving
    # it out made _is_short("COLORC~1.ICO") false -- so find_entry fell
    # back to matching long names, an alias has none, nothing ever
    # matched, and alias() handed out "~1" to every caller. Four files
    # in one directory ended up sharing a short name.
    SHORT_OK = "_-~$%'@!(){}^#&"

    @staticmethod
    def _is_short(name):
        base, _, ext = name.upper().partition(".")
        return (len(base) <= 8 and len(ext) <= 3 and name == name.upper()
                and base
                and all(c.isalnum() or c in Fat32.SHORT_OK for c in base + ext))

    def alias(self, cluster, name):
        """An unused NAME~N.EXT to stand in for a long name."""
        base, _, ext = name.upper().partition(".")
        keep = "".join(c for c in base if c.isalnum() or c in "_-")[:6] or "ICON"
        ext = "".join(c for c in ext if c.isalnum())[:3]
        for n in range(1, 1000):
            cand = f"{keep[:8 - 1 - len(str(n))]}~{n}" + (f".{ext}" if ext else "")
            if not self.find_entry(cluster, cand):
                return cand
        raise SystemExit(f"{name}: no free short alias")

    def _lfn_entries(self, name, tag):
        """The attr-$0F slots for one long name, in on-disk order."""
        chk = self.lfn_checksum(tag)
        chars = [ord(c) for c in name] + [0x0000]
        while len(chars) % 13:
            chars.append(0xFFFF)
        total = len(chars) // 13
        out = []
        for i in range(total):
            part = chars[i * 13:(i + 1) * 13]
            e = bytearray(b"\x00" * 32)
            e[0] = (i + 1) | (0x40 if i == total - 1 else 0)
            e[11] = 0x0F
            e[13] = chk
            for k, off in enumerate(self.LFN_OFFSETS):
                e[off:off + 2] = part[k].to_bytes(2, "little")
            out.append(bytes(e))
        return list(reversed(out))          # highest sequence number first

    def _dir_entry(self, name, cluster, attr=0x20, size=0):
        # "." and ".." are the two names FAT stores literally: one or two
        # dots then spaces, filling the 11-byte field. They must NOT go
        # through short(), which splits on the dot and would write a
        # blank name -- a directory whose own self and parent links are
        # nameless, which the X16's DOS cannot walk back out of.
        if name in (".", ".."):
            tag = name.ljust(11).encode("latin-1")
        else:
            tag = self.short(name)
        e = tag + bytes([attr]) + b"\x00" * 2
        e += struct.pack("<HHH", 0, 0x5721, 0x5721)
        e += struct.pack("<H", cluster >> 16)
        e += struct.pack("<HH", 0, 0x5721)
        e += struct.pack("<H", cluster & 0xFFFF)
        e += struct.pack("<I", size)
        return e

    def mkdir(self, parent, name):
        """Create one subdirectory and return its cluster (idempotent)."""
        hit = self.find_entry(parent, name)
        if hit:
            if not (hit[2][11] & 0x10):
                raise SystemExit(f"{name}: exists and is a file, not a directory")
            return self._start_of(hit[2])
        cl = self.free_clusters(1)[0]
        self.f.seek(self.cluster_off(cl))
        self.f.write(b"\x00" * self.csize)
        self.fat_set(cl, 0x0FFFFFFF)
        # "." points at itself, ".." at the parent -- and ".." is 0 when
        # the parent is the root, which is what FAT32 expects rather than
        # the root's actual cluster number.
        self._write(cl, 0, self._dir_entry(".", cl, attr=0x10))
        up = 0 if parent in (None, self.root) else parent
        self._write(cl, 32, self._dir_entry("..", up, attr=0x10))
        self._put_entry(parent, self._dir_entry(name, cl, attr=0x10))
        return cl

    def resolve(self, parts, create=False):
        """Walk a list of directory names; return the final cluster."""
        cur = self.root
        for p in parts:
            hit = self.find_entry(cur, p)
            if hit and (hit[2][11] & 0x10):
                cur = self._start_of(hit[2])
            elif create:
                cur = self.mkdir(cur, p)
            else:
                raise SystemExit(f"no such directory: {p}")
        return cur

    @staticmethod
    def _lfn_chars(e):
        """The characters one long-name slot carries, in order."""
        raw = e[1:11] + e[14:26] + e[28:32]
        out = ""
        for i in range(0, len(raw), 2):
            ch = int.from_bytes(raw[i:i + 2], "little")
            if ch in (0x0000, 0xFFFF):
                break
            out += chr(ch)
        return out

    def delete(self, name, cluster=None):
        """Remove a file by SHORT or LONG name, its LFN slots included.

        The X16's SAVE writes a long-name entry with a mangled short name
        -- DESKTOP.CFG lands as 0000101D~C~ plus an LFN -- so matching the
        short name alone leaves that file sitting there and adds a second
        one beside it. The KERNAL then goes on reading its own.
        """
        tag = self.short(name) if self._is_short(name) else None
        want = name.upper()
        pending, found = [], False
        for c, off in self._slots(cluster):
            e = self._read(c, off)
            if e[0] == 0x00:
                break
            if e[0] == 0xE5:
                pending = []
                continue
            if e[11] == 0x0F:
                pending.append((c, off, e))
                continue
            long = "".join(self._lfn_chars(x[2]) for x in reversed(pending))
            if (tag and e[0:11] == tag) or long.upper() == want:
                start = int.from_bytes(e[20:22], "little") << 16 | \
                        int.from_bytes(e[26:28], "little")
                if start >= 2:
                    for cl in self.chain(start):
                        self.fat_set(cl, 0)
                self._write(c, off, b"\xE5" + e[1:])
                for lc, loff, le in pending:
                    self._write(lc, loff, b"\xE5" + le[1:])
                found = True
            pending = []
        return found

    def add(self, path, data, create=True):
        """Write a file, at a bare name or down a /PATH."""
        parts, name = self.split(path)
        cluster = self.resolve(parts, create=create)
        self.delete(name, cluster)
        n = max(1, (len(data) + self.csize - 1) // self.csize)
        clusters = self.free_clusters(n)
        for i, cl in enumerate(clusters):
            chunk = data[i * self.csize:(i + 1) * self.csize]
            self.f.seek(self.cluster_off(cl))
            self.f.write(chunk + b"\x00" * (self.csize - len(chunk)))
        for i, cl in enumerate(clusters):
            self.fat_set(cl, 0x0FFFFFFF if i == n - 1 else clusters[i + 1])
        if self._is_short(name):
            run = [self._dir_entry(name, clusters[0], size=len(data))]
        else:
            short = self.alias(cluster, name)
            tag = self.short(short)
            run = self._lfn_entries(name, tag) + \
                [self._dir_entry(short, clusters[0], size=len(data))]
        self._put_entry(cluster, run)
        return clusters[0]

    def read_file(self, path, cluster=None):
        parts, name = self.split(path)
        if parts:
            cluster = self.resolve(parts)
        tag = self.short(name) if self._is_short(name) else None
        want = name.upper()
        pending = []
        for c, off in self._slots(cluster):
            e = self._read(c, off)
            if e[0] == 0x00:
                break
            if e[0] == 0xE5:
                pending = []
                continue
            if e[11] == 0x0F:
                pending.append(e)
                continue
            long = "".join(self._lfn_chars(x) for x in reversed(pending))
            pending = []
            if (tag and e[0:11] == tag) or long.upper() == want:
                size = int.from_bytes(e[28:32], "little")
                start = int.from_bytes(e[20:22], "little") << 16 | \
                        int.from_bytes(e[26:28], "little")
                out = b""
                for cl in self.chain(start):
                    self.f.seek(self.cluster_off(cl))
                    out += self.f.read(self.csize)
                return out[:size]
        return None

    def update_fsinfo(self):
        """Recount the free clusters and store the true figure.

        The spec allows an "unknown" sentinel here, and most PC tools
        write it after touching an image -- but the X16's DOS trusts
        FSInfo blindly, so the sentinel turns `@$` into "4095 GB FREE".
        Counting properly costs one pass over the FAT, which is nothing
        beside handing the machine a number it will believe.
        (tools/fix_fsinfo.py repairs an image some other tool got wrong.)
        """
        self.f.seek(self.base + 512)
        fsi = self.f.read(512)
        if fsi[0:4] != b"RRaA" or fsi[484:488] != b"rrAa":
            return None
        self.f.seek(self.fat0)
        fat = self.f.read(self.spf * self.bps)
        free, first = 0, 0xFFFFFFFF
        for c in range(2, self.nclusters):
            if int.from_bytes(fat[c * 4:c * 4 + 4], "little") & 0x0FFFFFFF == 0:
                free += 1
                if first == 0xFFFFFFFF:
                    first = c
        self.f.seek(self.base + 512 + 488)
        self.f.write(free.to_bytes(4, "little") + first.to_bytes(4, "little"))
        return free

    def close(self):
        self.f.flush()
        os.fsync(self.f.fileno())
        self.f.close()


def main(argv):
    if not argv:
        print("usage: img_put.py IMAGE [--list [PATH]] [--mkdir PATH] "
              "[--as NAME|/PATH/NAME] FILE...")
        return 1
    img, args = argv[0], argv[1:]
    fs = Fat32(img)
    if args[:1] == ["--list"]:
        where = args[1] if len(args) > 1 else ""
        cluster = fs.resolve([p for p in where.replace("\\", "/").split("/") if p])
        for name, kind, size, _cl in fs.list_root(cluster):
            print(f"  {name:14} {kind:4} {size:9}")
        fs.close()
        return 0

    i, wrote = 0, 0
    while i < len(args):
        if args[i] == "--mkdir":
            parts = [p for p in args[i + 1].replace("\\", "/").split("/") if p]
            fs.resolve(parts, create=True)
            i += 2
            continue
        if args[i] == "--as":
            name, path = args[i + 1], args[i + 2]
            i += 3
        else:
            path = args[i]
            name = os.path.basename(path).upper()
            i += 1
        data = open(path, "rb").read()
        fs.add(name, data)
        if fs.read_file(name) != data:      # never report a write we cannot read
            fs.close()
            raise SystemExit(f"verify failed for {name}")
        # print(f"  {name:14} {len(data):9} bytes")   # per-file log, quiet
        wrote += 1
    free = fs.update_fsinfo()
    fs.close()
    # Success is silent: this runs on every launch, and a wall of sizes
    # buries anything that actually needs reading. Errors still raise.
    # print(f"{wrote} file(s) written to {img}")
    # if free is not None:
    #     print(f"  {free * 4096 / 1048576:.1f} MB free, recorded in FSInfo")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))


