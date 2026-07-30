# VERA FX Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_VERAFX` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.fx_off()`

| Field | Details |
|---|---|
| Macro | `cx.fx_off()` |
| Purpose | disable FX (leaves DCSEL/ADDRSEL = 0) |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; disable FX (leaves DCSEL/ADDRSEL = 0)
        cx.fx_off()
    }
}

```

## `cx.fx_mult(a, b)`

| Field | Details |
|---|---|
| Macro | `cx.fx_mult(a, b)` |
| Purpose | signed 16x16 |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product) |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; signed 16x16
        cx.fx_mult($20, $a0)
    }
}

```

## `cx.fx_fill(val, addr, count)`

| Field | Details |
|---|---|
| Macro | `cx.fx_fill(val, addr, count)` |
| Purpose | fast fill of `count` VRAM bytes at `addr` |
| Input parameters | `val, addr, count` — `addr` must be a multiple of 4 |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; fill 32 bytes of VRAM at $10000 with $20
        cx.fx_fill($20, $10000, 32)
    }
}

```

## `cx.fx_clear(addrlo, addrmid, addrhi, count)`

| Field | Details |
|---|---|
| Macro | `cx.fx_clear(addrlo, addrmid, addrhi, count)` |
| Purpose | zero a VRAM region |
| Input parameters | `addrlo, addrmid, addrhi, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; zero a VRAM region
        cx.fx_clear($00, $20, $10, 32)
    }
}

```

## `cx.fx_transp_on() / cx.fx_transp_off()`

| Field | Details |
|---|---|
| Macro | `cx.fx_transp_on()` / `cx.fx_transp_off()` |
| Purpose | transparent VRAM writes |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; transparent VRAM writes
        cx.fx_transp_on()
        cx.fx_transp_off()
    }
}

```

## `cx.fx_line(x0, y0, x1, y1, col)`

| Field | Details |
|---|---|
| Macro | `cx.fx_line(x0, y0, x1, y1, col)` |
| Purpose | hardware-assisted line |
| Input parameters | `x0, y0, x1, y1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; hardware-assisted line
        cx.fx_line(24, 32, 96, 96, 14)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of verafx

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.fx_triangle()`

| Field | Details |
|---|---|
| Macro | `cx.fx_triangle()` |
| Purpose | filled triangle via the polygon helper |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_TRI` is enabled. |

## `cx.fx_copy(src, srchi, dst, dsthi, count)`

| Field | Details |
|---|---|
| Macro | `cx.fx_copy(src, srchi, dst, dsthi, count)` |
| Purpose | VRAM to VRAM through the 32-bit cache (~4x a byte loop) |
| Input parameters | `src`, `srchi`, `dst`, `dsthi`, `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_COPY` is enabled. |

## `cx.fx_affine_on(tiledata, tiledatahi, tilemap, tilemaphi, mapsize, clip)`

| Field | Details |
|---|---|
| Macro | `cx.fx_affine_on(tiledata, tiledatahi, tilemap, tilemaphi, mapsize, clip)` |
| Purpose | enter affine mode and describe the texture |
| Input parameters | `tiledata`, `tiledatahi`, `tilemap`, `tilemaphi`, `mapsize`, `clip` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |

## `cx.fx_affine_ray(x, y, dx, dy)`

| Field | Details |
|---|---|
| Macro | `cx.fx_affine_ray(x, y, dx, dy)` |
| Purpose | aim the sampler |
| Input parameters | `x`, `y`, `dx`, `dy` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |

## `cx.fx_affine_span(count)`

| Field | Details |
|---|---|
| Macro | `cx.fx_affine_span(count)` |
| Purpose | fetch texels along the ray into VRAM |
| Input parameters | `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |
