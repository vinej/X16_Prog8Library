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
        cx.layer_on(layer)
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
        cx.layer_set_config(layer, cfg)
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
        cx.layer_set_mapbase(layer, base)
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
        cx.layer_scroll_x(layer, val)
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
        cx.tile_setptr(col, row)
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
        cx.tile_put(col, row, code, attr)
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
        cx.tile_get(col, row)
    }
}
```
