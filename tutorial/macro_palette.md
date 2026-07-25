# Palette Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_PALETTE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.pal_set(index, rgb)`

| Field | Details |
|---|---|
| Macro | `cx.pal_set(index, rgb)` |
| Purpose | set one entry; `rgb` is a 12-bit `$0RGB` value |
| Input parameters | `index, rgb` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Install a small four-color palette.
        cx.pal_set(1, $0f00)
    }
}

```

## `cx.pal_load(src, first, count)`

| Field | Details |
|---|---|
| Macro | `cx.pal_load(src, first, count)` |
| Purpose | bulk-load `count` entries from RAM |
| Input parameters | `src, first, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Install a small four-color palette.
        cx.pal_load(palette_data, 0, 4)
    }
}

%asm {{
    palette_data !word $000, $00f, $0f0, $f00
}}

```
