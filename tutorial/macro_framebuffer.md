# Framebuffer Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_FB` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.fb_init() / cx.fb_get_info()`

| Field | Details |
|---|---|
| Macro | `cx.fb_init()` / `cx.fb_get_info()` |
| Purpose | active KERNAL framebuffer driver |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_init()
        cx.fb_get_info()
    }
}

```

## `cx.fb_set_palette(data, start, count)`

| Field | Details |
|---|---|
| Macro | `cx.fb_set_palette(data, start, count)` |
| Purpose | set palette entries |
| Input parameters | `data, start, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_set_palette(palette_data, 4, 4)
    }
}

%asm {{
    palette_data !word $000, $00f, $0f0, $f00
}}

```

## `cx.fb_cursor_position(x, y) / cx.fb_cursor_next_line()`

| Field | Details |
|---|---|
| Macro | `cx.fb_cursor_position(x, y)` / `cx.fb_cursor_next_line()` |
| Purpose | framebuffer cursor |
| Input parameters | `x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_cursor_position(32, 40)
        cx.fb_cursor_next_line()
    }
}

```

## `cx.fb_get_pixel(x, y) / cx.fb_set_pixel(x, y, color)`

| Field | Details |
|---|---|
| Macro | `cx.fb_get_pixel(x, y)` / `cx.fb_set_pixel(x, y, color)` |
| Purpose | one pixel |
| Input parameters | `x, y`; `x, y, color` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_get_pixel(32, 40)
        cx.fb_set_pixel(32, 40, 14)
    }
}

```

## `cx.fb_get_pixels(dest, count) / cx.fb_set_pixels(src, count)`

| Field | Details |
|---|---|
| Macro | `cx.fb_get_pixels(dest, count)` / `cx.fb_set_pixels(src, count)` |
| Purpose | pixel runs |
| Input parameters | `dest, count`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_get_pixels(work_buffer, 8)
        cx.fb_set_pixels(pixel_run, 8)
    }
}

%asm {{
    work_buffer !fill 64, 0
    pixel_run   !byte 1, 2, 3, 4, 4, 3, 2, 1
}}

```

## `cx.fb_set_8_pixels(pattern, color) / cx.fb_set_8_pixels_opaque(mask, pattern, fg, bg)`

| Field | Details |
|---|---|
| Macro | `cx.fb_set_8_pixels(pattern, color)` / `cx.fb_set_8_pixels_opaque(mask, pattern, fg, bg)` |
| Purpose | 8-pixel pattern helpers |
| Input parameters | `pattern, color`; `mask, pattern, fg, bg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_set_8_pixels(%10101010, 14)
        cx.fb_set_8_pixels_opaque($01, %10101010, 15, 0)
    }
}

```

## `cx.fb_fill_pixels(count, step, color) / cx.fb_filter_pixels(count, filter)`

| Field | Details |
|---|---|
| Macro | `cx.fb_fill_pixels(count, step, color)` / `cx.fb_filter_pixels(count, filter)` |
| Purpose | fill/filter from cursor |
| Input parameters | `count, step, color`; `count, filter` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_fill_pixels(32, 1, 14)
        cx.fb_filter_pixels(32, 1)
    }
}

```

## `cx.fb_move_pixels(sx, sy, tx, ty, count)`

| Field | Details |
|---|---|
| Macro | `cx.fb_move_pixels(sx, sy, tx, ty, count)` |
| Purpose | move a horizontal span |
| Input parameters | `sx, sy, tx, ty, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw through the KERNAL framebuffer cursor.
        cx.fb_move_pixels(8, 16, 40, 16, 32)
    }
}

```
