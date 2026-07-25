# Block memory Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_MEM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.mem_fill(dst, count, val)`

| Field | Details |
|---|---|
| Macro | `cx.mem_fill(dst, count, val)` |
| Purpose | fill (streams to VERA too) |
| Input parameters | `dst, count, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; fill (streams to VERA too)
        cx.mem_fill(work_buffer, 32, $20)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

## `cx.mem_copy(src, dst, count)`

| Field | Details |
|---|---|
| Macro | `cx.mem_copy(src, dst, count)` |
| Purpose | copy |
| Input parameters | `src, dst, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; copy
        cx.mem_copy(pixel_run, work_buffer, 32)
    }
}

%asm {{
    pixel_run   !byte 1, 2, 3, 4, 4, 3, 2, 1
    work_buffer !fill 64, 0
}}

```

## `cx.mem_crc(addr, count)`

| Field | Details |
|---|---|
| Macro | `cx.mem_crc(addr, count)` |
| Purpose | CRC-16 |
| Input parameters | `addr, count` |
| Output parameters | A/X) |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; CRC-16
        cx.mem_crc(work_buffer, 32)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

## `cx.mem_decompress(src, dst)`

| Field | Details |
|---|---|
| Macro | `cx.mem_decompress(src, dst)` |
| Purpose | LZSA2 |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the end) |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; LZSA2
        cx.mem_decompress(packed_data, work_buffer)
    }
}

%asm {{
    packed_data !binary "asset.packed"
    work_buffer !fill 64, 0
}}

```
