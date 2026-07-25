# Tiles and layers Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_TILE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.layer_on(layer) / cx.layer_off(layer)`

| Field | Details |
|---|---|
| Macro | `cx.layer_on(layer)` / `cx.layer_off(layer)` |
| Purpose | enable / disable a layer |
| Input parameters | `layer` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.layer_on(0)
        cx.layer_off(0)
    }
}

```

## `cx.layer_set_config(layer, cfg)`

| Field | Details |
|---|---|
| Macro | `cx.layer_set_config(layer, cfg)` |
| Purpose | the layer's CONFIG byte |
| Input parameters | `layer, cfg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.layer_set_config(0, $10)
    }
}

```

## `cx.layer_set_mapbase(layer, base)`

| Field | Details |
|---|---|
| Macro | `cx.layer_set_mapbase(layer, base)` |
| Purpose | where the map lives (VRAM >> 9) |
| Input parameters | `layer, base` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.layer_set_mapbase(0, $9f60)
    }
}

```

## `cx.layer_scroll_x(layer, val) / cx.layer_scroll_y(layer, val)`

| Field | Details |
|---|---|
| Macro | `cx.layer_scroll_x(layer, val)` / `cx.layer_scroll_y(layer, val)` |
| Purpose | 12-bit hardware scroll |
| Input parameters | `layer, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.layer_scroll_x(0, $20)
        cx.layer_scroll_y(0, $20)
    }
}

```

## `cx.tile_setptr(col, row)`

| Field | Details |
|---|---|
| Macro | `cx.tile_setptr(col, row)` |
| Purpose | point port 0 at a layer-1 map cell |
| Input parameters | `col, row` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.tile_setptr(14, 5)
    }
}

```

## `cx.tile_put(col, row, code, attr)`

| Field | Details |
|---|---|
| Macro | `cx.tile_put(col, row, code, attr)` |
| Purpose | write one cell |
| Input parameters | `col, row, code, attr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.tile_put(14, 5, 'A', $10)
    }
}

```

## `cx.tile_get(col, row)`

| Field | Details |
|---|---|
| Macro | `cx.tile_get(col, row)` |
| Purpose | read one cell |
| Input parameters | `col, row` |
| Output parameters | A = code, X = attribute) |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write one tile into layer 0's map.
        cx.tile_get(14, 5)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of tile

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.layer_set_tilebase(layer, base)`

| Field | Details |
|---|---|
| Macro | `cx.layer_set_tilebase(layer, base)` |
| Purpose | in: X = layer, A = base>>11<<2 | tile size bits |
| Input parameters | `layer`, `base` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_TILE` is enabled. |
