# ADPCM Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_ADPCM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.adpcm_init()`

| Field | Details |
|---|---|
| Macro | `cx.adpcm_init()` |
| Purpose | initialize ADPCM state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.adpcm_init()
    }
}
```

## `cx.adpcm_nibble(code)`

| Field | Details |
|---|---|
| Macro | `cx.adpcm_nibble(code)` |
| Purpose | decode one ADPCM nibble |
| Input parameters | `code` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.adpcm_nibble(code)
    }
}
```

## `cx.adpcm_block(src, dst, count)`

| Field | Details |
|---|---|
| Macro | `cx.adpcm_block(src, dst, count)` |
| Purpose | decode a block |
| Input parameters | `src, dst, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.adpcm_block(src, dst, count)
    }
}
```
