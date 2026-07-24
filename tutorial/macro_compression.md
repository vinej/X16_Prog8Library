# Compression Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_ZX0, X16_USE_TSC` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.zx0_decompress(src, dst)`

| Field | Details |
|---|---|
| Macro | `cx.zx0_decompress(src, dst)` |
| Purpose | decompress ZX0; -> A/X = one past the last output byte |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the last output byte |
| More info | Available when `X16_USE_ZX0, X16_USE_TSC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zx0_decompress(src, dst)
    }
}
```

## `cx.tsc_decompress(src, dst)`

| Field | Details |
|---|---|
| Macro | `cx.tsc_decompress(src, dst)` |
| Purpose | decompress TSC; -> A/X = one past the last output byte |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the last output byte |
| More info | Available when `X16_USE_ZX0, X16_USE_TSC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.tsc_decompress(src, dst)
    }
}
```
