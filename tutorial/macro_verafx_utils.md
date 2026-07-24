# VERA FX utilities Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_VERAFX_UTILS` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.fxu_off() / cx.fxu_get_ctrl() / cx.fxu_set_ctrl(ctrl)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_off()` / `cx.fxu_get_ctrl()` / `cx.fxu_set_ctrl(ctrl)` |
| Purpose | FX control |
| Input parameters | `ctrl` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_off()
    }
}
```

## `cx.fxu_ctrl_on(mask) / cx.fxu_ctrl_off(mask)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_ctrl_on(mask)` / `cx.fxu_ctrl_off(mask)` |
| Purpose | set/clear FX bits |
| Input parameters | `mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_ctrl_on(mask)
    }
}
```

## `cx.fxu_addr1_mode(mode)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_addr1_mode(mode)` |
| Purpose | ADDR1 mode bits |
| Input parameters | `mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_addr1_mode(mode)
    }
}
```

## `cx.fxu_cache_write_on/off, cx.fxu_cache_fill_on/off, cx.fxu_cache_cycle_on/off`

| Field | Details |
|---|---|
| Macro | `cx.fxu_cache_write_on/off`, `cx.fxu_cache_fill_on/off`, `cx.fxu_cache_cycle_on/off` |
| Purpose | cache modes |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_cache_write_on()
    }
}
```

## `cx.fxu_transparent_on/off, cx.fxu_4bit_on/off, cx.fxu_hop_on/off`

| Field | Details |
|---|---|
| Macro | `cx.fxu_transparent_on/off`, `cx.fxu_4bit_on/off`, `cx.fxu_hop_on/off` |
| Purpose | transparent, 4-bit, 16-bit hop |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_transparent_on()
    }
}
```

## `cx.fxu_set_mult(mult) / cx.fxu_set_cache(b0, b1, b2, b3)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_set_mult(mult)` / `cx.fxu_set_cache(b0, b1, b2, b3)` |
| Purpose | multiplier/cache registers |
| Input parameters | `mult`; `b0, b1, b2, b3` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_set_mult(mult)
    }
}
```

## `cx.fxu_reset_accum() / cx.fxu_accumulate()`

| Field | Details |
|---|---|
| Macro | `cx.fxu_reset_accum()` / `cx.fxu_accumulate()` |
| Purpose | accumulator helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_reset_accum()
    }
}
```

## `cx.fxu_cache_fill0/1 / cx.fxu_cache_write0/1 mask`

| Field | Details |
|---|---|
| Macro | `cx.fxu_cache_fill0/1` / `cx.fxu_cache_write0/1 mask` |
| Purpose | cache fill/write primitives |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_cache_fill0()
    }
}
```

## `cx.fxu_set_incr(xinc, yinc) / cx.fxu_set_pos(xpos, ypos) / cx.fxu_set_subpos(xsub, ysub)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_set_incr(xinc, yinc)` / `cx.fxu_set_pos(xpos, ypos)` / `cx.fxu_set_subpos(xsub, ysub)` |
| Purpose | affine stepping state |
| Input parameters | `xinc, yinc`; `xpos, ypos`; `xsub, ysub` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_set_incr(xinc, yinc)
    }
}
```

## `cx.fxu_get_poly_fill() / cx.fxu_set_tilebase(value) / cx.fxu_set_mapbase(value)`

| Field | Details |
|---|---|
| Macro | `cx.fxu_get_poly_fill()` / `cx.fxu_set_tilebase(value)` / `cx.fxu_set_mapbase(value)` |
| Purpose | polygon/tile/map helpers |
| Input parameters | `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fxu_get_poly_fill()
    }
}
```
