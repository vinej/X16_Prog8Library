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
        ; Calculate small game-control values from constants.
        cx.rnd_seed($ace1)
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
        ; Calculate small game-control values from constants.
        cx.sin8(32)
        cx.cos8(32)
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
        ; Calculate small game-control values from constants.
        cx.sin8u(32)
        cx.cos8u(32)
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
        ; Calculate small game-control values from constants.
        cx.atan2(40, -16)
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
        ; Calculate small game-control values from constants.
        cx.lerp8($20, $a0, 96)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of math

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.rnd16()`

| Field | Details |
|---|---|
| Macro | `cx.rnd16()` |
| Purpose | A = low, X = high |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_MATH` is enabled. |
