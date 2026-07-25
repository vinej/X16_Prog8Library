# Console Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_CONSOLE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.con_init_fullscreen() / cx.con_init(x, y, w, h)`

| Field | Details |
|---|---|
| Macro | `cx.con_init_fullscreen()` / `cx.con_init(x, y, w, h)` |
| Purpose | initialize console |
| Input parameters | `x, y, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; initialize console
        cx.con_init_fullscreen()
        cx.con_init(32, 40, 96, 64)
    }
}

```

## `cx.con_set_paging_message(msg) / cx.con_disable_paging()`

| Field | Details |
|---|---|
| Macro | `cx.con_set_paging_message(msg)` / `cx.con_disable_paging()` |
| Purpose | paging controls |
| Input parameters | `msg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; paging controls
        cx.con_set_paging_message(1)
        cx.con_disable_paging()
    }
}

```

## `cx.con_put_char_wrap(char) / cx.con_put_char_word(char)`

| Field | Details |
|---|---|
| Macro | `cx.con_put_char_wrap(char)` / `cx.con_put_char_word(char)` |
| Purpose | print with wrapping |
| Input parameters | `char` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; print with wrapping
        cx.con_put_char_wrap(1)
        cx.con_put_char_word(1)
    }
}

```

## `cx.con_get_char()`

| Field | Details |
|---|---|
| Macro | `cx.con_get_char()` |
| Purpose | read one console character |
| Input parameters | No macro arguments. |
| Output parameters | read one console character |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; read one console character
        cx.con_get_char()
    }
}

```

## `cx.con_put_image(image, w, h)`

| Field | Details |
|---|---|
| Macro | `cx.con_put_image(image, w, h)` |
| Purpose | draw console image data |
| Input parameters | `image, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; draw console image data
        cx.con_put_image(1, 96, 64)
    }
}

```
