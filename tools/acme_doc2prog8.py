#!/usr/bin/env python3
"""acme_doc2prog8.py -- convert the X16_Library ACME tutorial Markdown into a
Prog8 edition.

Same idea as the X16_Library's acme_doc2<dialect>.py converters, but the target
here is the Prog8 *language*, not another assembler dialect. Prose is left
intact; fenced ``asm`` snippets and inline macro spellings are rewritten:

    +xm_pal_set index, rgb        ->  cx.pal_set(index, rgb)
    +xm_vera_fill $2A, 80         ->  cx.vera_fill($2a, 80)
    !source "x16.asm"             ->  %import x16lib
    X16_USE_PALETTE = 1           ->  (dropped -- the blob carries everything)
    main / ... / rts              ->  main { sub start() { ... } }
    <expr / >expr / ^expr         ->  lsb(expr) / msb(expr) / (expr >> 16)

Raw 6502 lines that have no high-level equivalent are wrapped in a Prog8
`%asm {{ ... }}` block verbatim.

Usage:
    python tools/acme_doc2prog8.py [SRC_TUTORIAL] [DST_TUTORIAL]
      SRC default: c:/quartus/projects/x16_library/src_acme/tutorial
      DST default: <this repo>/tutorial
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEF_SRC = Path(r"c:/quartus/projects/x16_library/src_acme/tutorial")
DEF_DST = HERE.parent / "tutorial"

FENCE_RE   = re.compile(r"^(```+)([A-Za-z0-9_-]*)\s*$")
GATE_RE    = re.compile(r"^\s*X16_USE_[A-Z0-9_]+\s*=\s*1\s*(?:;.*)?$")
CPU_RE     = re.compile(r"^\s*!cpu\b.*$", re.IGNORECASE)
ORIGIN_RE  = re.compile(r"^\s*\*\s*=\s*\$0801\b.*$", re.IGNORECASE)
SOURCE_RE  = re.compile(r'^\s*!source\s+"([^"]+)".*$')
ASSIGN_RE  = re.compile(r"^\s*([A-Za-z_]\w*)\s*=\s*(.+?)\s*(;.*)?$")
INLINE_RE  = re.compile(r"`([^`\n]+)`")

# 6502 / 65c02 mnemonics -- lines starting with one of these are raw asm.
MNEMONICS = set("""
adc and asl bcc bcs beq bit bmi bne bpl bra brk bvc bvs clc cld cli clv cmp cpx
cpy dec dex dey eor inc inx iny jmp jsr lda ldx ldy lsr nop ora pha php phx phy
pla plp plx ply rol ror rti rts sbc sec sed sei sta stp stx sty stz tax tay trb
tsb tsx txa txs tya wai
""".split())


def split_comment(line: str) -> tuple[str, str]:
    inq = False
    for i, ch in enumerate(line):
        if ch == '"':
            inq = not inq
        elif ch == ";" and not inq:
            return line[:i].rstrip(), line[i:]
    return line.rstrip(), ""


def convert_args(args: str) -> str:
    """Rewrite ACME argument spellings into Prog8 expression syntax."""
    s = args.strip()
    if not s:
        return ""
    # bank byte  ^expr  ->  (expr >> 16)
    s = re.sub(r"\^\(([^)]+)\)", r"((\1) >> 16)", s)
    s = re.sub(r"\^([A-Za-z_]\w*)", r"(\1 >> 16)", s)
    # low / high byte prefix operators  <expr / >expr
    s = re.sub(r"(?<![\w)>])<\s*(\([^)]*\)|[A-Za-z_]\w*)", r"lsb(\1)", s)
    s = re.sub(r"(?<![\w)<])>\s*(\([^)]*\)|[A-Za-z_]\w*)", r"msb(\1)", s)
    # drop immediate '#'
    s = re.sub(r"#(?=[\$%\w'(])", "", s)
    # any stray macro spelling inside args (compact multi-macro headings)
    s = re.sub(r"\+(?:xm_)?([A-Za-z_]\w*)", r"cx.\1", s)
    return s


def to_call(name: str, args: str | None) -> str:
    if name.startswith("xm_"):
        name = name[3:]
    return f"cx.{name}({convert_args(args or '')})"


def is_raw_asm(code: str) -> bool:
    st = code.strip()
    if not st:
        return False
    return st.split()[0].lower() in MNEMONICS


def convert_asm_block(lines: list[str]) -> list[str]:
    out: list[str] = []
    asm_buf: list[str] = []
    wrapped = False
    body = ""            # indent for statements inside main/start

    def flush_asm():
        nonlocal asm_buf
        if not asm_buf:
            return
        ind = body
        out.append(f"{ind}%asm {{{{")
        for a in asm_buf:
            out.append(f"{ind}    {a}")
        out.append(f"{ind}}}}}")
        asm_buf = []

    for raw in lines:
        code, comment = split_comment(raw)
        st = code.strip()

        if not st and not comment:
            flush_asm()
            out.append("")
            continue
        if not st and comment:                 # comment-only line -> Prog8 comment
            flush_asm()
            out.append(body + comment.lstrip())
            continue
        if GATE_RE.match(raw) or CPU_RE.match(raw) or ORIGIN_RE.match(raw):
            continue
        m = SOURCE_RE.match(raw)
        if m:
            if "x16.asm" in m.group(1):     # the library umbrella include
                flush_asm()
                out.append("%import x16lib")
            continue                        # x16_code.asm etc. -> dropped
        if st in ("+basic_stub", "basic_stub"):
            continue
        if st in ("main", "main:"):
            flush_asm()
            out.append("main {")
            out.append("    sub start() {")
            wrapped = True
            body = "        "
            continue
        if st == "rts" and wrapped:
            flush_asm()
            out.append("    }")
            out.append("}")
            wrapped = False
            body = ""
            continue

        mm = re.match(r"^\s*\+([A-Za-z_]\w*)(?:\s+(.*?))?$", code)
        if mm:
            flush_asm()
            c = convert_comment(comment)
            out.append(body + to_call(mm.group(1), mm.group(2)) + c)
            continue

        am = ASSIGN_RE.match(raw)
        if am and not is_raw_asm(code):
            flush_asm()
            val = am.group(2).strip()
            typ = "uword"
            hexm = re.fullmatch(r"\$([0-9A-Fa-f]+)", val)
            if hexm:
                n = int(hexm.group(1), 16)
                typ = "ubyte" if n <= 0xFF else "uword" if n <= 0xFFFF else "long"
            out.append(f"{body}const {typ} {am.group(1)} = {val}"
                       + convert_comment(am.group(3) or ""))
            continue

        # anything else: raw assembly, buffer for a %asm block
        asm_buf.append(code.strip() + comment)

    flush_asm()
    if wrapped:
        out.append("    }")
        out.append("}")
    return out


def convert_comment(comment: str) -> str:
    if not comment:
        return ""
    return "  " + comment.lstrip()


def convert_inline(m: re.Match[str]) -> str:
    content = m.group(1)
    s = content.strip()
    sm = re.match(r'!source\s+"([^"]+)"$', s)
    if sm:
        return "`%import x16lib`" if "x16.asm" in sm.group(1) else m.group(0)
    # one or more "+macro args" segments joined by " / " (each fully parseable)
    if s.startswith("+"):
        parts = re.split(r"\s+/\s+", s)
        pms = [re.match(r"^\+([A-Za-z_]\w*)(?:\s+(.*))?$", p.strip()) for p in parts]
        if all(pms):
            calls = [to_call(pm.group(1), pm.group(2)) for pm in pms]
            return "`" + " / ".join(calls) + "`"
    if re.fullmatch(r"X16_USE_[A-Z0-9_]+\s*=\s*1", s):
        return "`%import x16lib`"
    # fallback: compact notations (variant "name/fill" shorthand, comma lists)
    # -- just swap the macro spelling token-by-token, leaving the shorthand.
    if "+" in content:
        return "`" + re.sub(r"\+(?:xm_)?([A-Za-z_]\w*)", r"cx.\1", content) + "`"
    return m.group(0)


def convert_markdown(text: str) -> str:
    out: list[str] = []
    in_fence = False
    asm_fence = False
    marker = ""
    fence_lines: list[str] = []
    noted = False

    for line in text.splitlines():
        fm = FENCE_RE.match(line)
        if fm and not in_fence:
            in_fence = True
            asm_fence = fm.group(2).lower() in {"asm", "6502"}
            marker = fm.group(1)
            fence_lines = []
            out.append("```prog8" if asm_fence else line)
            continue
        if in_fence and fm and line.startswith(marker):
            if asm_fence:
                out.extend(convert_asm_block(fence_lines))
            in_fence = False
            asm_fence = False
            marker = ""
            out.append(line)
            continue
        if in_fence:
            if asm_fence:
                fence_lines.append(line)
            else:
                out.append(line)
            continue

        # prose
        line = line.replace("ACME wrappers", "Prog8 wrappers")
        line = line.replace("ACME macro", "Prog8 subroutine")
        line = line.replace("ACME wrapper", "Prog8 subroutine")
        line = INLINE_RE.sub(convert_inline, line)
        out.append(line)
        if not noted and line.startswith("# "):
            out.append("")
            out.append("> Prog8 edition, generated from the X16_Library "
                       "`src_acme/tutorial` by `tools/acme_doc2prog8.py`. "
                       "Do not edit this copy by hand. Macros become calls in "
                       "the `cx` block; constants live in `x16c`.")
            noted = True

    return "\n".join(out).rstrip() + "\n"


def main(argv: list[str]) -> int:
    src = Path(argv[1]) if len(argv) > 1 else DEF_SRC
    dst = Path(argv[2]) if len(argv) > 2 else DEF_DST
    if not src.is_dir():
        print(f"source tutorial not found: {src}", file=sys.stderr)
        return 2
    dst.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted(src.glob("*.md")):
        converted = convert_markdown(f.read_text(encoding="utf-8"))
        (dst / f.name).write_text(converted, encoding="utf-8", newline="\n")
        print(f"doc   {f.name}")
        n += 1
    print(f"converted {n} tutorial files -> {dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
