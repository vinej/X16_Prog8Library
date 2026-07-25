# GRAPH Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_GRAPH` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.graph_init_default() / cx.graph_init(driver)`

| Field | Details |
|---|---|
| Macro | `cx.graph_init_default()` / `cx.graph_init(driver)` |
| Purpose | init GRAPH with default/custom FB driver |
| Input parameters | `driver` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; init GRAPH with default/custom FB driver
        cx.graph_init_default()
        cx.graph_init(1)
    }
}

```

## `cx.graph_clear() / cx.graph_set_window(x, y, w, h)`

| Field | Details |
|---|---|
| Macro | `cx.graph_clear()` / `cx.graph_set_window(x, y, w, h)` |
| Purpose | clear/window |
| Input parameters | `x, y, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; clear/window
        cx.graph_clear()
        cx.graph_set_window(32, 40, 96, 64)
    }
}

```

## `cx.graph_set_colors(stroke, fill, background)`

| Field | Details |
|---|---|
| Macro | `cx.graph_set_colors(stroke, fill, background)` |
| Purpose | drawing colours |
| Input parameters | `stroke, fill, background` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; drawing colours
        cx.graph_set_colors(1, 1, 1)
    }
}

```

## `cx.graph_draw_line(x1, y1, x2, y2)`

| Field | Details |
|---|---|
| Macro | `cx.graph_draw_line(x1, y1, x2, y2)` |
| Purpose | line |
| Input parameters | `x1, y1, x2, y2` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; line
        cx.graph_draw_line(96, 96, 160, 48)
    }
}

```

## `cx.graph_draw_rect_outline/fill x, y, w, h, radius`

| Field | Details |
|---|---|
| Macro | `cx.graph_draw_rect_outline/fill x, y, w, h, radius` |
| Purpose | rectangles |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; rectangles
        cx.graph_draw_rect_outline(32, 40, 96, 64, 1)
        cx.graph_draw_rect_fill(32, 40, 96, 64, 1)
    }
}

```

## `cx.graph_move_rect(sx, sy, tx, ty, w, h)`

| Field | Details |
|---|---|
| Macro | `cx.graph_move_rect(sx, sy, tx, ty, w, h)` |
| Purpose | move rectangle |
| Input parameters | `sx, sy, tx, ty, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; move rectangle
        cx.graph_move_rect(8, 16, 40, 16, 96, 64)
    }
}

```

## `cx.graph_draw_oval_outline/fill x, y, w, h`

| Field | Details |
|---|---|
| Macro | `cx.graph_draw_oval_outline/fill x, y, w, h` |
| Purpose | ovals |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; ovals
        cx.graph_draw_oval_outline(32, 40, 96, 64)
        cx.graph_draw_oval_fill(32, 40, 96, 64)
    }
}

```

## `cx.graph_draw_image(x, y, image, w, h)`

| Field | Details |
|---|---|
| Macro | `cx.graph_draw_image(x, y, image, w, h)` |
| Purpose | image bytes |
| Input parameters | `x, y, image, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; image bytes
        cx.graph_draw_image(32, 40, 1, 96, 64)
    }
}

```

## `cx.graph_set_font_default() / cx.graph_set_font(font)`

| Field | Details |
|---|---|
| Macro | `cx.graph_set_font_default()` / `cx.graph_set_font(font)` |
| Purpose | font |
| Input parameters | `font` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; font
        cx.graph_set_font_default()
        cx.graph_set_font(1)
    }
}

```

## `cx.graph_get_char_size(char, style) / cx.graph_put_char(char, x, y)`

| Field | Details |
|---|---|
| Macro | `cx.graph_get_char_size(char, style)` / `cx.graph_put_char(char, x, y)` |
| Purpose | text metrics/draw |
| Input parameters | `char, style`; `char, x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; text metrics/draw
        cx.graph_get_char_size(1, 1)
        cx.graph_put_char(1, 32, 40)
    }
}

```
