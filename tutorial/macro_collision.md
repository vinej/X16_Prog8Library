# Collision Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_COLLIDE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.collide8(ax, ay, aw, ah, bx, by, bw, bh)`

| Field | Details |
|---|---|
| Macro | `cx.collide8(ax, ay, aw, ah, bx, by, bw, bh)` |
| Purpose | 8-bit AABB test; -> carry set if overlap |
| Input parameters | `ax, ay, aw, ah, bx, by, bw, bh` |
| Output parameters | carry set if overlap |
| More info | Available when `X16_USE_COLLIDE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; 8-bit AABB test; -> carry set if overlap
        cx.collide8(1, 1, 1, 1, 1, 1, 1, 1)
    }
}

```

## `cx.collide16(...)`

| Field | Details |
|---|---|
| Macro | `cx.collide16(...)` |
| Purpose | 16-bit AABB test; -> carry set if overlap |
| Input parameters | No macro arguments. |
| Output parameters | carry set if overlap |
| More info | Available when `X16_USE_COLLIDE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; 16-bit AABB test; -> carry set if overlap
        cx.collide16(1, 1, 1, 1, 1, 1, 1, 1)
    }
}

```
