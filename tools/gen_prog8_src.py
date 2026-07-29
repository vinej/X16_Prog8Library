#!/usr/bin/env python3
# =====================================================================
# gen_prog8_src.py -- "pay-per-use" Prog8 wrapper for the X16_Library.
#
# Unlike the fixed prebuilt blob, this embeds the X16_Library's 64tass
# SOURCE port (which Prog8 assembles with the same 64tass it already
# shells out to) and gates it module-by-module. A program links only the
# modules it actually calls, so every one of the library's routines is
# available yet the PRG carries only what is used.
#
# It produces, into x16lib/:
#   x16lib_src.asm    the whole 64tass port flattened into one file
#                     (all `.include`s inlined), still gated by X16_USE_*.
#   x16lib.p8         core block `x16src` that %asminclude's the gates +
#                     the source, plus typed wrappers in block `cx` that
#                     jsr into x16src.<routine>.
#   x16lib_const.p8   the UPPER_SNAKE constants (block x16c).
#   routine_gates.json  routine -> X16_USE_* gate, for build.ps1 to turn
#                     the program's cx.<name>() calls into the gate set.
#
# Usage:  python tools/gen_prog8_src.py [X16_LIBRARY_DIR]
# =====================================================================
import os, re, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
PKG  = os.path.normpath(os.path.join(HERE, "..", "x16lib"))
XLIB = sys.argv[1] if len(sys.argv) > 1 else r"c:/quartus/projects/x16_library"

SRC64  = os.path.join(XLIB, "src_64tass")
INC    = os.path.join(XLIB, "dist", "64tass", "x16lib.inc")
SUGAR  = os.path.join(XLIB, "src_acme", "core", "sugar.asm")

# ---------------------------------------------------------------------
# 1. flatten the 64tass source tree (inline every .include)
# ---------------------------------------------------------------------
def flatten(path, out, base):
    for line in open(os.path.join(base, path), encoding="utf-8", errors="replace"):
        m = re.match(r'\s*\.include\s+"([^"]+)"', line)
        if m:
            out.append(f"; --- inline {m.group(1)} ---\n")
            flatten(m.group(1), out, base)
        else:
            out.append(line)

LIBSYMS = set()      # every label/symbol defined in the embedded source

def write_flat():
    out = []
    flatten("x16.asm", out, SRC64)
    flatten("x16_code.asm", out, SRC64)
    with open(os.path.join(PKG, "x16lib_src.asm"), "w",
              encoding="utf-8", newline="\n") as f:
        f.writelines(out)
    # collect top-level labels and `name = ...` / `name .byte` definitions
    for line in out:
        m = re.match(r"^([a-z][a-z0-9_]*)\b", line)
        if m:
            LIBSYMS.add(m.group(1))
    return len(out)

# ---------------------------------------------------------------------
# 2. routine -> gate map
#    x16_code.asm:  .if xuse_<cond>  ->  .include "dir/file.asm"
#    each file's top-level labels are its routines.
#    gate to *set* = X16_USE_<BASE>, BASE = cond without _any/_core suffix.
# ---------------------------------------------------------------------
def build_gate_map():
    code = open(os.path.join(SRC64, "x16_code.asm"), encoding="utf-8").read().splitlines()
    file_cond = {}                       # "gfx/shapes.asm" -> "shapes"
    pending = None
    for line in code:
        m = re.match(r"\s*\.if\s+xuse_(\w+)", line)
        if m:
            pending = m.group(1)
            continue
        m = re.match(r'\s*\.include\s+"([^"]+)"', line)
        if m and pending:
            file_cond[m.group(1)] = pending
            pending = None

    # cond -> settable gate name
    def cond_gate(cond):
        base = re.sub(r"_(any|core)$", "", cond)
        return "X16_USE_" + base.upper()

    routine_gate = {}
    for relpath, cond in file_cond.items():
        fp = os.path.join(SRC64, relpath)
        if not os.path.isfile(fp):
            continue
        file_gate = cond_gate(cond)
        stack = []                       # nested .if xuse_* gates within the file
        for line in open(fp, encoding="utf-8", errors="replace"):
            mif = re.match(r"\s*\.if\s+(.*)", line)
            if mif:
                sub = re.search(r"xuse_(\w+)", mif.group(1))
                stack.append(cond_gate(sub.group(1)) if sub else None)
                continue
            if re.match(r"\s*\.endif\b", line):
                if stack: stack.pop()
                continue
            m = re.match(r"^([a-z][a-z0-9_]*)\b", line)
            if m:
                inner = next((g for g in reversed(stack) if g), None)
                routine_gate.setdefault(m.group(1), inner or file_gate)
    return routine_gate

# ---------------------------------------------------------------------
# 3. constants
# ---------------------------------------------------------------------
# Two sources, because neither one is complete on its own:
#
#   dist/64tass/x16lib.inc -- the symbol list of the dist blob build.
#   The blob turns on 37 of the library's 89 gates, so every constant
#   belonging to the other 52 modules is simply absent: FPK_*, the
#   GRAPH_STYLE_* bits, ZSM_ERR_*, the GFX*_WIDTH/HEIGHT/STRIDE family.
#   Three examples here had each re-declared FPK_NONE/PICK/ALT by hand
#   for want of them.
#
#   the flattened source -- covers every module, which is the set that
#   matters, because the source is what this wrapper embeds and 64tass
#   actually assembles. ACME's symbol list normalises everything to hex;
#   the source spells constants in hex, binary AND decimal, so all three
#   forms have to be read here.
#
# Where both define a name the SOURCE wins: x16lib_src.asm is the file
# being assembled, so a constant disagreeing with it would be a lie.
def load_inc_syms():
    sym = {}
    for line in open(INC, encoding="utf-8"):
        m = re.match(r"^([A-Za-z_]\w*)\s*=\s*\$([0-9A-Fa-f]+)", line.strip())
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    return sym

_LIT = re.compile(r"^(?:\$([0-9A-Fa-f]+)|%([01]+)|([0-9]+))$")
_DEF = re.compile(r"^([A-Z][A-Z0-9_]*)\s*=\s*(\S+)\s*(?:;.*)?$")

def parse_lit(text):
    m = _LIT.match(text)
    if not m:
        return None                      # an expression, not a literal: skip
    hexv, binv, decv = m.groups()
    return int(hexv, 16) if hexv else int(binv, 2) if binv else int(decv)

def load_src_consts():
    """UPPER_SNAKE `NAME = <literal>` defined at column 0 of the flat source."""
    consts, ambiguous = {}, set()
    for line in open(os.path.join(PKG, "x16lib_src.asm"),
                     encoding="utf-8", errors="replace"):
        m = _DEF.match(line.rstrip("\n"))
        if not m:
            continue
        name = m.group(1)
        if name.startswith("X16_"):      # gates and the P/T zero-page block
            continue
        v = parse_lit(m.group(2))
        if v is None:
            continue
        if name in consts and consts[name] != v:
            ambiguous.add(name)          # defined per gate branch: no one answer
        else:
            consts[name] = v
    for n in ambiguous:
        consts.pop(n, None)
    return consts, ambiguous

def gen_consts(sym):
    consts = sorted((n, v) for n, v in sym.items()
                    if re.match(r"^[A-Z][A-Z0-9_]*$", n) and not n.startswith("X16_USE_"))
    out = ["; x16lib_const.p8 -- GENERATED by tools/gen_prog8_src.py, do not edit.",
           "; X16_Library constants (block x16c).", "",
           "x16c {", "    %option ignore_unused, no_symbol_prefixing", ""]
    for n, v in consts:
        typ = "ubyte" if v <= 0xFF else "uword" if v <= 0xFFFF else "long"
        out.append(f"    const {typ} {n} = ${v:X}")
    out += ["}", ""]
    return "\n".join(out)

# ---------------------------------------------------------------------
# 4. wrappers from sugar.asm  (reuse the blob generator's parser rules)
# ---------------------------------------------------------------------
# The library's zero page is P0-P7 then T0-T7, $22-$31. Both halves have
# to be substituted: a wrapper that emits "sta X16_T6" instead of "sta $30"
# names a symbol defined inside the library's own block, which the
# generated inline asm cannot see -- fs_save, the one routine that passes
# an argument in T, would not assemble at all.
PBLOCK = {f"X16_P{k}": 0x22 + k for k in range(8)}
PBLOCK.update({f"X16_T{k}": 0x2A + k for k in range(8)})
RET = {
    "A":  ("ubyte", "ret8",  ["sta p8v_ret8"]),
    "X":  ("ubyte", "ret8",  ["stx p8v_ret8"]),
    "Y":  ("ubyte", "ret8",  ["sty p8v_ret8"]),
    "AX": ("uword", "ret16", ["sta p8v_ret16", "stx p8v_ret16+1"]),
    "AY": ("uword", "ret16", ["sta p8v_ret16", "sty p8v_ret16+1"]),
    "XY": ("uword", "ret16", ["stx p8v_ret16", "sty p8v_ret16+1"]),
    "Pc": ("bool",  "retbit", ["lda #0", "rol  a", "sta p8v_retbit"]),
}

# ---------------------------------------------------------------------
# What a routine gives back.
#
# sugar.asm only carries a "-> ..." note where somebody wrote one, so the
# authoritative source is the routine's own header in the library. Those
# headers say "out: A = ...", "out: carry set if ...", or just "carry set
# if ..." -- and one header often covers several routines at once, so the
# text has to be split by routine name before it is read, or a sibling's
# outputs get attributed to the wrong wrapper.
# ---------------------------------------------------------------------
ROUTINE_DOC = {}                     # routine -> its header block, as a list
ROUTINE_NAMES = set()

def collect_headers(base):
    for root, _dirs, files in os.walk(base):
        if "tutorial" in root:
            continue
        for fn in files:
            if not fn.endswith(".asm"):
                continue
            lines = open(os.path.join(root, fn), encoding="utf-8",
                         errors="replace").read().split("\n")
            blocks, block = [], []
            for i, ln in enumerate(lines):
                if ln.startswith(";"):
                    block.append(ln)
                else:
                    if block:
                        blocks.append((i, block))
                    block = []
            for i, ln in enumerate(lines):
                m = re.match(r"^([a-z_][a-z0-9_]*)\s*$", ln)
                if not m:
                    continue
                name = m.group(1)
                for end_ln, blk in blocks:
                    if end_ln <= i and any(re.search(r"\b" + name + r"\b", b) for b in blk):
                        ROUTINE_DOC[name] = blk

def _segment(name, blk):
    """The part of a shared header block that describes `name`.

    Headers commonly cover a family at once:

        ; gfx8h_pset / gfx8h_read -- clipped pixel access
        ;   pset in: A = colour, ...
        ;   read out: carry clear, A = colour; carry set if off screen

    so a line tagged with a sibling's short name must not be read as ours.
    """
    siblings = set()
    for b in blk:
        for w in re.findall(r"\b([a-z_][a-z0-9_]{3,})\b", b):
            if w in ROUTINE_NAMES and w != name:
                siblings.add(w)
    # Such a block tags its lines with whatever part of the name tells the
    # family apart -- "read" vs "pset" at the end, "get" vs "set" in the
    # middle -- so compare on name components, and only on the ones that
    # actually distinguish us from our siblings.
    own_parts = set(name.split("_"))
    sib_parts = set()
    for sib in siblings:
        sib_parts |= set(sib.split("_"))
    own_tags = {name} | (own_parts - sib_parts)
    sib_tags = siblings | (sib_parts - own_parts)

    out, mine = [], not siblings          # a lone routine owns the whole block
    for b in blk:
        tag = re.match(r";\s*(\w+)\s+(?:in|out):", b)
        if tag:
            t = tag.group(1)
            if t in own_tags:
                mine = True
            elif t in sib_tags or t in siblings:
                mine = False
        elif re.search(r"\b" + name + r"\b", b):
            mine = True
        elif any(re.search(r"\b" + sib + r"\b", b) for sib in siblings):
            mine = False
        if mine:
            out.append(b)
    return " ".join(out)

def doc_return(target):
    """One of RET's keys, or None when the header is not clear enough.

    Silence is the safe answer: a wrapper with no return type is merely
    inconvenient, one with the wrong type is a bug in every program that
    trusts it. Anything ambiguous -- a routine that documents both a carry
    and a register, say -- is left for an explicit "-> ..." note in
    sugar.asm, where a person decides which one the caller wants.
    """
    blk = ROUTINE_DOC.get(target)
    if not blk:
        return None
    seg = _segment(target, blk)
    m = re.search(r"out:(.*)", seg)
    tail = (m.group(1) if m else seg).split("Behind ")[0]

    has_carry = bool(re.search(r"\bcarry (set|clear)\b", tail))
    regs = re.search(r"\bA\b\s*=", tail), re.search(r"\bX\b\s*=", tail), \
           re.search(r"\bY\b\s*=", tail)
    has_reg = any(regs)

    if has_carry and has_reg:
        return None                       # needs a human: see the docstring
    if has_carry:
        return "Pc"
    if not m:
        return None                       # no "out:" line at all
    lo_hi = lambda r1, r2: re.search(
        r"\b" + r1 + r"\b\s*=[^,;]*\blow\b.*\b" + r2 + r"\b\s*=[^,;]*\bhigh\b", tail)
    if lo_hi("A", "X") or re.search(r"\bA/X\b|\bAX\b", tail):
        return "AX"
    if lo_hi("A", "Y") or re.search(r"\bA/Y\b|\bAY\b", tail):
        return "AY"
    # "X/Y = ..." is one 16-bit answer, but the single-register patterns
    # above see only the Y half of it and would call the result a ubyte.
    if lo_hi("X", "Y") or re.search(r"\bX/Y\b|\bXY\b", tail):
        return "XY"
    if regs[1] and regs[2] and not regs[0]:
        return "XY"
    if regs[0]:
        return "A"
    if regs[1]:
        return "X"
    if regs[2]:
        return "Y"
    return None

RESERVED = set("""a x y if for while do when sub asmsub extsub return goto true
false and or not xor as to in step downto void ubyte byte uword word long float
str bool const struct enum alias inline private call on repeat unroll break
continue defer len sizeof abs min max sqrt sgn sin cos tan mkword msb lsb peek
peekw poke pokew rnd rndw swap sort reverse rol ror rol2 ror2 memory clamp divmod
setlsb setmsb cmp cx cy x16src x16c x16lib main start""".split())

MNEMONICS = set("""adc and asl bcc bcs beq bit bmi bne bpl bra brk bvc bvs clc
cld cli clv cmp cpx cpy dec dex dey eor inc inx iny jmp jsr lda ldx ldy lsr nop
ora pha php phx phy pla plp plx ply rol ror rti rts sbc sec sed sei sta stp stx
sty stz tax tay trb tsb tsx txa txs tya wai a x y""".split())

def rreg(tok):
    m = re.fullmatch(r"r(\d+)([LH]?)", tok)
    if not m:
        return None
    base = 0x02 + int(m.group(1)) * 2 + (1 if m.group(2) == "H" else 0)
    return base

class Macro: __slots__ = ("name", "args", "body", "doc")

def parse_sugar():
    macros, doc = [], []
    lines = open(SUGAR, encoding="utf-8").readlines()
    i, n = 0, len(lines)
    mhead = re.compile(r"^\s*!macro\s+xm_(\w+)\s*(.*?)\s*\{\s*$")
    while i < n:
        raw, s = lines[i], lines[i].strip()
        if s.startswith(";"):
            d = s.lstrip(";").strip()
            if d and not re.fullmatch(r"[=\-]{3,}.*", d):
                doc.append(d)
            i += 1; continue
        m = mhead.match(raw)
        if m:
            mc = Macro()
            mc.name = m.group(1)
            mc.args = [a.strip().lstrip(".") for a in m.group(2).split(",") if a.strip()]
            mc.doc = doc[:]
            body, i, depth = [], i + 1, 1
            while i < n and depth > 0:
                st = lines[i].strip()
                if st == "}":
                    depth -= 1
                    if depth == 0: i += 1; break
                body.append(st); i += 1
            mc.body = body
            macros.append(mc); doc = []
            continue
        if s and not s.startswith("!"):    # keep doc across !ifdef wrappers
            doc = []
        i += 1
    return macros

def translate(mc):
    body = [re.sub(r";.*$", "", b).rstrip() for b in mc.body]
    body = [b for b in body if b.strip()]
    target = None
    for b in body:
        m = re.match(r"jsr\s+(\w+)", b)
        if m: target = m.group(1)
    if not target:
        return None
    is16 = {a: False for a in mc.args}; used = set()
    for b in body:
        for a in mc.args:
            if re.search(r"#[<>]\(\." + re.escape(a) + r"\)", b): is16[a] = True; used.add(a)
            elif re.search(r"#\(\." + re.escape(a) + r"\)", b): used.add(a)
    for a in mc.args:                    # skip macros doing arithmetic on args
        probe = re.sub(r"#[<>]?\(\." + re.escape(a) + r"\)", "", "\n".join(body))
        if re.search(r"\." + re.escape(a) + r"\b", probe):
            return None
    asm = []
    for b in body:
        line = b
        for a in mc.args:
            line = re.sub(r"#<\(\." + re.escape(a) + r"\)", f"p8v_{a}", line)
            line = re.sub(r"#>\(\." + re.escape(a) + r"\)", f"p8v_{a}+1", line)
            line = re.sub(r"#\(\." + re.escape(a) + r"\)",  f"p8v_{a}", line)
        for pn, pa in PBLOCK.items():
            line = re.sub(r"\b" + pn + r"\b", f"${pa:02X}", line)
        line = re.sub(r"\br\d+[LH]?\b",
                      lambda m: f"${rreg(m.group(0)):02X}" if rreg(m.group(0)) is not None else m.group(0),
                      line)
        # qualify every library symbol (routine or data label) into x16src
        line = re.sub(r"\b[a-z_][a-z0-9_]*\b",
                      lambda m: "x16src." + m.group(0)
                      if (m.group(0) in LIBSYMS and m.group(0) not in MNEMONICS) else m.group(0),
                      line)
        asm.append(line)
    params = [(a, "uword" if is16[a] else "ubyte") for a in mc.args if a in used]
    ret = None
    dm = re.search(r"->\s*(.*)", " ".join(mc.doc))
    if dm:                                   # an explicit note in sugar.asm wins
        r = dm.group(1)
        if re.search(r"\bA/X\b|\bAX\b", r): ret = "AX"
        elif re.search(r"\bA/Y\b|\bAY\b", r): ret = "AY"
        elif re.search(r"carry|@ ?Pc", r): ret = "Pc"
        elif re.search(r"\bA\b", r): ret = "A"
    if ret is None:                          # otherwise ask the routine's header
        ret = doc_return(target)
    return params, asm, ret, target

def gen_lib(macros, routine_gate):
    ROUTINE_NAMES.update(routine_gate.keys())
    collect_headers(os.path.join(XLIB, "src_acme"))

    # ---- first pass: collect the wrappers (need all gates for weak defaults) --
    wrappers, seen, gated = [], set(), {}
    for mc in macros:
        if mc.name in seen: continue
        tr = translate(mc)
        if tr is None: continue
        seen.add(mc.name)
        params, asm, ret, target = tr
        gate = routine_gate.get(target)
        if gate: gated[mc.name] = gate
        wrappers.append((mc, params, asm, ret, gate))
    allgates = sorted({g for g in gated.values()})

    out = ["; x16lib.p8 -- GENERATED by tools/gen_prog8_src.py, do not edit.",
           "; Typed wrappers (block cx) over the embedded X16_Library 64tass source.",
           ";   %import x16lib          ->  cx.screen_puts(...), cx.shape_circle(...), ...",
           "; The build enables only the modules your cx.* calls touch. Modules named",
           "; with build.ps1 -Bank are relocated into an 8K RAM bank; their wrappers",
           "; far-call into it. See routine_gates.json / symbol_gates.json + build.ps1.", "",
           "cx {", "    %option ignore_unused", "",
           "    ubyte ret8", "    uword ret16", "    bool  retbit", "",
           "    ; bank configuration: x16lib_bankdefs.inc = weak 0 defaults for every",
           "    ; gate; x16lib_bankcfg.inc = the actual banked set (written by build.ps1)",
           '    %asminclude "x16lib_bankdefs.inc"',
           '    %asminclude "x16lib_bankcfg.inc"', "",
            "    ; loads the companion bank image(s) at startup; call once before any",
            "    ; banked cx.* routine. A no-op when nothing is banked.",
            "    sub load_banks() {",
            '        %asminclude "x16lib_bankload.inc"',
            "    }", ""]

    for mc, params, asm, ret, gate in wrappers:
        pdecl, rename = [], {}
        for a, t in params:
            pa = a + "_" if a in RESERVED else a
            if pa != a: rename[a] = pa
            pdecl.append(f"{t} {pa}")
        rtype = capvar = None; capture = []
        if ret: rtype, capvar, capture = RET[ret]
        rsig = f" -> {rtype}" if rtype else ""
        if mc.doc: out.append("    ; " + " ".join(mc.doc)[:110])
        out.append(f"    sub {mc.name}({', '.join(pdecl)}){rsig} {{")
        out.append("        %asm {{")
        if gate:                          # far-call trampoline when banked
            out += [f"        .if BANK_{gate}",     # BANK_<gate> = the RAM bank number (0 = low)
                    "            lda $00",
                    "            pha",
                    f"            lda #BANK_{gate}",
                    "            sta $00",
                    "        .endif"]
        for line in asm:
            for a, pa in rename.items():
                line = re.sub(r"\bp8v_" + re.escape(a) + r"\b", "p8v_" + pa, line)
            if line.strip(): out.append("            " + line)
        for line in capture: out.append("            " + line)
        if gate:
            out += [f"        .if BANK_{gate}",
                    "            pla",
                    "            sta $00",
                    "        .endif"]
        out.append("        }}")
        if capvar: out.append(f"        return {capvar}")
        out += ["    }", ""]

    out += ["}", "",
            "; ------------------------------------------------------------------",
            "; The X16_Library machine code, assembled inline from its 64tass source.",
            "; build.ps1 writes x16lib_gates.inc (which low-RAM modules) and",
            "; x16lib_bankaddr.inc (addresses of routines relocated into a RAM bank).",
            "; ------------------------------------------------------------------",
            "x16src {",
            "    %option force_output, ignore_unused, no_symbol_prefixing",
            '    %asminclude "x16lib_bankaddr.inc"',
            '    %asminclude "x16lib_gates.inc"',
            '    %asminclude "x16lib_src.asm"',
            "}", ""]
    return "\n".join(out), len(wrappers), gated

# ---------------------------------------------------------------------
def main():
    os.makedirs(PKG, exist_ok=True)
    nlines = write_flat()
    routine_gate = build_gate_map()
    sym = load_inc_syms()
    src_consts, ambiguous = load_src_consts()
    conflicts = {n: (sym[n], v) for n, v in src_consts.items()
                 if n in sym and sym[n] != v}
    sym.update(src_consts)
    with open(os.path.join(PKG, "x16lib_const.p8"), "w", newline="\n") as f:
        f.write(gen_consts(sym))
    for n, (old, new) in sorted(conflicts.items()):
        print(f"  const {n}: blob inc says ${old:X}, source says ${new:X} -- source wins")
    if ambiguous:
        print(f"  skipped {len(ambiguous)} gate-dependent constant(s): "
              + ", ".join(sorted(ambiguous)))
    macros = parse_sugar()
    lib, count, gated = gen_lib(macros, routine_gate)
    with open(os.path.join(PKG, "x16lib.p8"), "w", newline="\n") as f:
        f.write(lib)
    with open(os.path.join(PKG, "routine_gates.json"), "w", newline="\n") as f:
        json.dump(gated, f, indent=0, sort_keys=True)
    # full symbol -> gate map (every library label), for build.ps1 to pick which
    # bank-build symbols belong to the explicitly-banked modules.
    with open(os.path.join(PKG, "symbol_gates.json"), "w", newline="\n") as f:
        json.dump(routine_gate, f, indent=0, sort_keys=True)
    # weak-0 defaults for every bank gate, so `.if BANK_<gate>` always resolves
    allgates = sorted(set(gated.values()))
    with open(os.path.join(PKG, "x16lib_bankdefs.inc"), "w", newline="\n") as f:
        f.write("; GENERATED -- weak defaults so .if BANK_<gate> always resolves.\n")
        f.write(".weak\n")
        for g in allgates:
            f.write(f"BANK_{g} = 0\n")     # 0 = module stays in low RAM
        f.write(".endweak\n")
    # per-build include files: reset to clean defaults (build.ps1 overwrites
    # them for a specific program). Always rewritten so the committed repo
    # never carries one program's gate/bank selection.
    for name, body in (("x16lib_gates.inc",   "; enabled X16_USE_* gates (written by build.ps1)\n"),
                       ("x16lib_bankcfg.inc",  "; bank config (written by build.ps1)\n"),
                       ("x16lib_bankaddr.inc", "; banked routine addresses (written by build.ps1)\n"),
                       ("x16lib_bankload.inc", "; bank loader (written by build.ps1)\n")):
        open(os.path.join(PKG, name), "w", newline="\n").write(body)
    print(f"flattened {nlines} lines; {count} wrappers; "
          f"{len(gated)} routine->gate mappings ({len(set(gated.values()))} distinct gates)")

if __name__ == "__main__":
    main()
