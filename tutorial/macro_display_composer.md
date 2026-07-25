# Display composer Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_VERA_DC` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.vdc_get_video() / cx.vdc_set_video(video)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_get_video()` / `cx.vdc_set_video(video)` |
| Purpose | read/write `DC_VIDEO` |
| Input parameters | `video` |
| Output parameters | read/write `DC_VIDEO` |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; read/write `DC_VIDEO`
        cx.vdc_get_video()
        cx.vdc_set_video($11)
    }
}

```

## `cx.vdc_set_output(mode)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_set_output(mode)` |
| Purpose | set output mode while preserving other video bits |
| Input parameters | `mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; set output mode while preserving other video bits
        cx.vdc_set_output(0)
    }
}

```

## `cx.vdc_set_layers(mask) / cx.vdc_layer_on(mask) / cx.vdc_layer_off(mask)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_set_layers(mask)` / `cx.vdc_layer_on(mask)` / `cx.vdc_layer_off(mask)` |
| Purpose | layer/sprite enables |
| Input parameters | `mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; layer/sprite enables
        cx.vdc_set_layers($01)
        cx.vdc_layer_on($01)
        cx.vdc_layer_off($01)
    }
}

```

## `cx.vdc_get_scale() / cx.vdc_set_scale(hscale, vscale)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_get_scale()` / `cx.vdc_set_scale(hscale, vscale)` |
| Purpose | read/write composer scale |
| Input parameters | `hscale, vscale` |
| Output parameters | read/write composer scale |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; read/write composer scale
        cx.vdc_get_scale()
        cx.vdc_set_scale(64, 64)
    }
}

```

## `cx.vdc_get_border() / cx.vdc_set_border(color)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_get_border()` / `cx.vdc_set_border(color)` |
| Purpose | border palette index |
| Input parameters | `color` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; border palette index
        cx.vdc_get_border()
        cx.vdc_set_border(14)
    }
}

```

## `cx.vdc_get_active_raw() / cx.vdc_set_active_raw(hstart, hstop, vstart, vstop)`

| Field | Details |
|---|---|
| Macro | `cx.vdc_get_active_raw()` / `cx.vdc_set_active_raw(hstart, hstop, vstart, vstop)` |
| Purpose | raw active-display registers |
| Input parameters | `hstart, hstop, vstart, vstop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; raw active-display registers
        cx.vdc_get_active_raw()
        cx.vdc_set_active_raw(0, 640, 0, 480)
    }
}

```

## `cx.vdc_set_active(hstart, hstop, vstart, vstop) / cx.vdc_fullscreen()`

| Field | Details |
|---|---|
| Macro | `cx.vdc_set_active(hstart, hstop, vstart, vstop)` / `cx.vdc_fullscreen()` |
| Purpose | pixel-coordinate active display |
| Input parameters | `hstart, hstop, vstart, vstop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; pixel-coordinate active display
        cx.vdc_set_active(0, 640, 0, 480)
        cx.vdc_fullscreen()
    }
}

```

## `cx.vdc_get_version()`

| Field | Details |
|---|---|
| Macro | `cx.vdc_get_version()` |
| Purpose | VERA bitstream version |
| Input parameters | No macro arguments. |
| Output parameters | carry set if valid) |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; VERA bitstream version
        cx.vdc_get_version()
    }
}

```
