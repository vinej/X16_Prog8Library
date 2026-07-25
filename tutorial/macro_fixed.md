# Fixed point Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_FIXED` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.umul16(a, b)`

| Field | Details |
|---|---|
| Macro | `cx.umul16(a, b)` |
| Purpose | unsigned 16x16 multiply; -> P4..P7 = product |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; unsigned 16x16 multiply; -> P4..P7 = product
        cx.umul16($20, $a0)
    }
}

```

## `cx.mul88(a, b)`

| Field | Details |
|---|---|
| Macro | `cx.mul88(a, b)` |
| Purpose | signed 8.8 multiply; -> P0/1 |
| Input parameters | `a, b` |
| Output parameters | P0/1 |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; signed 8.8 multiply; -> P0/1
        cx.mul88($20, $a0)
    }
}

```
