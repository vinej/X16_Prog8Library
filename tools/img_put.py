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
#   python tools/img_put.py card.img build/DESKTOP.PRG build/KALK.PRG
#   python tools/img_put.py card.img --as WALL.BMX build/WALL.BMX
#
# Short 8.3 names only, which is all the X16 asks for. A file of the
# same name is replaced -- its clusters are freed first, so re-syncing
# after a rebuild does not leak space -- and every write is read back
# and compared before the tool reports success. The FSInfo free-cluster
# count is recomputed afterwards: the X16's DOS believes whatever it finds
# there, so the "unknown" sentinel most PC tools leave behind is what makes
# the machine report 4095 GB free.
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

    # ---- the root directory -----------------------------------------
    def _slots(self):
        for c in self.chain(self.root):
            for off in range(0, self.csize, 32):
                yield c, off

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

    def list_root(self):
        out = []
        for c, off in self._slots():
            e = self._read(c, off)
            if e[0] == 0x00:
                break
            if e[0] == 0xE5 or e[11] == 0x0F or (e[11] & 0x08):
                continue          # deleted, a long-name part, or the label
            name = e[0:8].decode("latin-1").rstrip()
            ext = e[8:11].decode("latin-1").rstrip()
            out.append((name + ("." + ext if ext else ""),
                        "DIR" if e[11] & 0x10 else "FILE",
                        int.from_bytes(e[28:32], "little"),
                        int.from_bytes(e[20:22], "little") << 16 |
                        int.from_bytes(e[26:28], "little")))
        return out

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

    def delete(self, name):
        """Remove a root file by SHORT or LONG name, its LFN slots included.

        The X16's SAVE writes a long-name entry with a mangled short name
        -- DESKTOP.CFG lands as 0000101D~C~ plus an LFN -- so matching the
        short name alone leaves that file sitting there and adds a second
        one beside it. The KERNAL then goes on reading its own.
        """
        tag = self.short(name)
        want = name.upper()
        pending, found = [], False
        for c, off in self._slots():
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
            if e[0:11] == tag or long.upper() == want:
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

    def add(self, name, data):
        self.delete(name)
        n = max(1, (len(data) + self.csize - 1) // self.csize)
        clusters = self.free_clusters(n)
        for i, cl in enumerate(clusters):
            chunk = data[i * self.csize:(i + 1) * self.csize]
            self.f.seek(self.cluster_off(cl))
            self.f.write(chunk + b"\x00" * (self.csize - len(chunk)))
        for i, cl in enumerate(clusters):
            self.fat_set(cl, 0x0FFFFFFF if i == n - 1 else clusters[i + 1])

        entry = self.short(name) + bytes([0x20]) + b"\x00" * 2
        entry += struct.pack("<HHH", 0, 0x5721, 0x5721)
        entry += struct.pack("<H", clusters[0] >> 16)
        entry += struct.pack("<HH", 0, 0x5721)
        entry += struct.pack("<H", clusters[0] & 0xFFFF)
        entry += struct.pack("<I", len(data))

        for c, off in self._slots():
            e = self._read(c, off)
            if e[0] in (0x00, 0xE5):
                was_end = e[0] == 0x00
                self._write(c, off, entry)
                if was_end and off + 32 < self.csize:
                    self._write(c, off + 32, b"\x00" * 32)   # keep the marker
                return clusters[0]
        raise SystemExit("the root directory is full")

    def read_file(self, name):
        tag = self.short(name)
        want = name.upper()
        pending = []
        for c, off in self._slots():
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
            if e[0:11] == tag or long.upper() == want:
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
        print("usage: img_put.py IMAGE [--list] [--as NAME] FILE...")
        return 1
    img, args = argv[0], argv[1:]
    fs = Fat32(img)
    if args[:1] == ["--list"]:
        for name, kind, size, _cl in fs.list_root():
            print(f"  {name:14} {kind:4} {size:9}")
        fs.close()
        return 0

    i, wrote = 0, 0
    while i < len(args):
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
