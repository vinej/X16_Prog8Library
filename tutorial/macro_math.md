# Math Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_MATH` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.rnd_seed(seed)`

| Field | Details |
|---|---|
| Macro | `cx.rnd_seed(seed)` |
| Purpose | seed the PRNG (16-bit) |
| Input parameters | `seed` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.rnd_seed(seed)
    }
}
```

## `cx.sin8(angle) / cx.cos8(angle)`

| Field | Details |
|---|---|
| Macro | `cx.sin8(angle)` / `cx.cos8(angle)` |
| Purpose | -> A = -127..127 |
| Input parameters | `angle` |
| Output parameters | A = -127..127 |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sin8(angle)
    }
}
```

## `cx.sin8u(angle) / cx.cos8u(angle)`

| Field | Details |
|---|---|
| Macro | `cx.sin8u(angle)` / `cx.cos8u(angle)` |
| Purpose | -> A = 1..255 |
| Input parameters | `angle` |
| Output parameters | A = 1..255 |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sin8u(angle)
    }
}
```

## `cx.atan2(dx, dy)`

| Field | Details |
|---|---|
| Macro | `cx.atan2(dx, dy)` |
| Purpose | -> A = angle 0-255 (`dx`,`dy` signed bytes) |
| Input parameters | `dx, dy` |
| Output parameters | A = angle 0-255 (`dx`,`dy` signed bytes) |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.atan2(dx, dy)
    }
}
```

## `cx.lerp8(a, b, t)`

| Field | Details |
|---|---|
| Macro | `cx.lerp8(a, b, t)` |
| Purpose | -> A = interpolated value |
| Input parameters | `a, b, t` |
| Output parameters | A = interpolated value |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.lerp8(a, b, t)
    }
}
```
