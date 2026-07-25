# Mouse Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_MOUSE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.mse_config(cursor, width8, height8)`

| Field | Details |
|---|---|
| Macro | `cx.mse_config(cursor, width8, height8)` |
| Purpose | configure mouse cursor |
| Input parameters | `cursor, width8, height8` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; configure mouse cursor
        cx.mse_config(0, 1, 1)
    }
}

```

## `cx.mse_scan() / cx.mse_get() / cx.mse_get_to(zp)`

| Field | Details |
|---|---|
| Macro | `cx.mse_scan()` / `cx.mse_get()` / `cx.mse_get_to(zp)` |
| Purpose | mouse sample/read helpers |
| Input parameters | `zp` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; mouse sample/read helpers
        cx.mse_scan()
        cx.mse_get()
        cx.mse_get_to(1)
    }
}

```

## `cx.mse_show(cursor) / cx.mse_show_keep() / cx.mse_hide()`

| Field | Details |
|---|---|
| Macro | `cx.mse_show(cursor)` / `cx.mse_show_keep()` / `cx.mse_hide()` |
| Purpose | mouse visibility helpers |
| Input parameters | `cursor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; mouse visibility helpers
        cx.mse_show(0)
        cx.mse_show_keep()
        cx.mse_hide()
    }
}

```
