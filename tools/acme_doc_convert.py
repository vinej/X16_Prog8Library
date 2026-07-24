#!/usr/bin/env python3
"""Convert ACME tutorial Markdown to another assembler's syntax.

The assembly converters operate on source files. Tutorial files need a
lighter pass: convert fenced asm snippets, inline macro spellings, and
source-tree references while leaving explanatory prose intact.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Dialect:
    key: str
    display: str
    src_dir: str
    include: str
    cpu: str
    origin: tuple[str, ...]
    macro_prefix: str
    macro_style: str = "prefix"
    gate_style: str = "assign"
    comment: str = ";"
    byte: str = ".byte"
    word: str = ".word"
    text: str = ".byte"
    fill: str = ".res"


DIALECTS: dict[str, Dialect] = {
    "ca65": Dialect(
        "ca65", "ca65", "src_ca65", '.include "{name}"',
        '.setcpu "65C02"',
        ('.segment "LOADADDR"', '    .word $0801', '.segment "CODE"'),
        "",
        byte=".byte", word=".word", text=".byte", fill=".res",
    ),
    "tass": Dialect(
        "tass", "64tass", "src_64tass", '.include "{name}"',
        '.cpu "65c02"', ("* = $0801",), "#",
        byte=".byte", word=".word", text=".text", fill=".fill",
    ),
    "dasm": Dialect(
        "dasm", "dasm", "src_dasm", 'include "{name}"',
        "processor 65c02", ("    org $0801",), "",
        byte="dc.b", word="dc.w", text="dc.b", fill="ds",
    ),
    "kick": Dialect(
        "kick", "KickAssembler", "src_kick", '#import "{name}"',
        ".cpu _65c02", ('.pc = $0801 "code"',), "",
        macro_style="kick", gate_style="define", comment="//",
        byte=".byte", word=".word", text=".text", fill=".fill",
    ),
    "mads": Dialect(
        "mads", "MADS", "src_mads", '    icl "{name}"',
        "; MADS: assemble for 65C02", ("    org $0801",), "",
        byte=".byte", word=".word", text=".byte", fill=":({count}) dta {value}",
    ),
    "vasm": Dialect(
        "vasm", "vasm", "src_vasm", '    include "{name}"',
        "; vasm: pass -c02 on the command line", ("    org $0801",), "",
        byte="byte", word="word", text="byte", fill="ds.b",
    ),
}


FENCE_RE = re.compile(r"^(```+)([A-Za-z0-9_-]*)\s*$")
GATE_RE = re.compile(r"^(\s*)(X16_USE_[A-Z0-9_]+)\s*=\s*1(\s*(?:;|//).*)?$")
SOURCE_RE = re.compile(r'^(\s*)!source\s+"([^"]+)"(\s*(?:;.*)?)?$')
CPU_RE = re.compile(r"^\s*!cpu\s+65c02\s*$", re.IGNORECASE)
ORIGIN_RE = re.compile(r"^(\s*)\*\s*=\s*\$0801(\s*(?:;.*)?)?$", re.IGNORECASE)
LEADING_MACRO_RE = re.compile(r"^(\s*)\+([A-Za-z_][A-Za-z0-9_]*)(?:\s+(.*?))?(\s*;.*)?$")
INLINE_CODE_RE = re.compile(r"`([^`\n]+)`")


def split_comment(line: str) -> tuple[str, str]:
    in_quote = False
    for idx, ch in enumerate(line):
        if ch == '"':
            in_quote = not in_quote
        elif ch == ";" and not in_quote:
            return line[:idx].rstrip(), line[idx:]
    return line.rstrip(), ""


def convert_comment(comment: str, dialect: Dialect) -> str:
    if not comment:
        return ""
    comment = convert_plus_tokens(comment, dialect)
    if dialect.comment == "//":
        return re.sub(r"^\s*;", " //", comment)
    return "  " + comment.lstrip()


def convert_bank_ops(line: str, dialect: Dialect) -> str:
    if dialect.key == "tass":
        return re.sub(r"\^(?=[A-Za-z_($])", "`", line)
    if dialect.key == "kick":
        line = re.sub(r"\^\(([^)]+)\)", r"((\1) >> 16)", line)
        return re.sub(r"\^([A-Za-z_][A-Za-z0-9_]*)", r"((\1) >> 16)", line)
    return line


def macro_call(name: str, args: str | None, dialect: Dialect) -> str:
    args = convert_bank_ops((args or "").strip(), dialect)
    if dialect.macro_style == "kick":
        return f"{name}({args})" if args else f"{name}()"
    return f"{dialect.macro_prefix}{name}" + (f" {args}" if args else "")


def convert_macro_segment(segment: str, dialect: Dialect) -> str:
    m = re.match(r"^\+([A-Za-z_][A-Za-z0-9_]*)(?:\s+(.*))?$", segment.strip())
    if not m:
        return segment
    return macro_call(m.group(1), m.group(2), dialect)


def convert_plus_tokens(text: str, dialect: Dialect) -> str:
    prefix = dialect.macro_prefix if dialect.macro_style != "kick" else ""
    return re.sub(r"\+([A-Za-z_][A-Za-z0-9_]*)", prefix + r"\1", text)


def convert_inline_code(match: re.Match[str], dialect: Dialect) -> str:
    content = match.group(1)
    stripped = content.strip()

    if stripped.startswith("!source "):
        m = re.match(r'!source\s+"([^"]+)"$', stripped)
        if m:
            return "`" + dialect.include.format(name=m.group(1)).strip() + "`"

    if "+" not in content:
        return match.group(0)

    if content.count("+") == 1 and "/" not in content and "<" not in content:
        return "`" + convert_macro_segment(content, dialect) + "`"

    return "`" + convert_plus_tokens(content, dialect) + "`"


def convert_directives(code: str, dialect: Dialect) -> str:
    code = re.sub(r"\s*!byte\b", " " + dialect.byte, code)
    code = re.sub(r"\s*!word\b", " " + dialect.word, code)
    code = re.sub(r"\s*!text\b", " " + dialect.text, code)

    if dialect.key == "mads":
        m = re.match(r"^(\s*)([A-Za-z_][A-Za-z0-9_]*)?\s*!fill\s+([^,]+)(?:,\s*(.*?))?$", code)
        if m:
            ind, label, count, value = m.groups()
            value = value or "0"
            prefix = f"{label}\n" if label else ""
            return prefix + f"{ind}:({count.strip()}) dta {value.strip()}"
    else:
        code = re.sub(r"\s*!fill\b", " " + dialect.fill, code)
    return code


def convert_code_line(line: str, dialect: Dialect) -> list[str]:
    if CPU_RE.match(line):
        return [dialect.cpu]

    m = SOURCE_RE.match(line)
    if m:
        ind, name, comment = m.groups()
        converted = dialect.include.format(name=name)
        if not converted.startswith((" ", "\t")):
            converted = ind + converted
        return [converted + convert_comment(comment or "", dialect)]

    m = GATE_RE.match(line)
    if m and dialect.gate_style == "define":
        ind, gate, comment = m.groups()
        return [f"{ind}#define {gate}" + convert_comment(comment or "", dialect)]

    m = ORIGIN_RE.match(line)
    if m:
        comment = convert_comment(m.group(2) or "", dialect)
        lines = list(dialect.origin)
        if comment:
            lines[-1] += comment
        return lines

    code, comment = split_comment(line)
    m = LEADING_MACRO_RE.match(line)
    if m:
        ind, name, args, comment = m.groups()
        return [ind + macro_call(name, args, dialect) + convert_comment(comment or "", dialect)]

    code = convert_directives(code, dialect)
    code = convert_bank_ops(code, dialect)
    comment = convert_comment(comment, dialect)
    if dialect.comment == "//" and code.lstrip().startswith(";"):
        code = re.sub(r"^(\s*);", r"\1//", code)
    return [code + comment]


def convert_markdown(text: str, dialect: Dialect) -> str:
    out: list[str] = []
    in_fence = False
    asm_fence = False
    fence_marker = ""
    inserted_note = False

    for line in text.splitlines():
        m = FENCE_RE.match(line)
        if m:
            if not in_fence:
                in_fence = True
                asm_fence = m.group(2).lower() in {"asm", "6502"}
                fence_marker = m.group(1)
            elif line.startswith(fence_marker):
                in_fence = False
                asm_fence = False
                fence_marker = ""
            out.append(line)
            continue

        if in_fence and asm_fence:
            out.extend(convert_code_line(line, dialect))
            continue

        line = line.replace("src_acme/", dialect.src_dir + "/")
        line = line.replace("ACME wrappers", dialect.display + " macros")
        line = line.replace("ACME macro", dialect.display + " macro")
        line = INLINE_CODE_RE.sub(lambda mm: convert_inline_code(mm, dialect), line)
        if dialect.key == "kick":
            line = re.sub(r"`X16_USE_([A-Z0-9_]+) = 1`", r"`#define X16_USE_\1`", line)

        out.append(line)
        if not inserted_note and line.startswith("# "):
            out.append("")
            out.append(
                f"> Generated {dialect.display} edition from "
                "`src_acme/tutorial`. Do not edit this copy by hand."
            )
            inserted_note = True

    return "\n".join(out).rstrip() + "\n"


def convert_tree(src: Path, dst: Path, dialect: Dialect) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.glob("*.md")):
        text = f.read_text(encoding="utf-8")
        converted = convert_markdown(text, dialect)
        (dst / f.name).write_text(converted, encoding="utf-8", newline="\n")
        print(f"doc   {f.name}")


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        keys = ", ".join(sorted(DIALECTS))
        print(f"usage: {Path(argv[0]).name} <{keys}> <src_tutorial> <dst_tutorial>", file=sys.stderr)
        return 2
    key = argv[1]
    if key not in DIALECTS:
        print(f"unknown dialect: {key}", file=sys.stderr)
        return 2
    convert_tree(Path(argv[2]), Path(argv[3]), DIALECTS[key])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
