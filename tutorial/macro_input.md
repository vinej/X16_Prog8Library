# Input Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_INPUT` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.joy_scan() / cx.joy_get(pad)`

| Field | Details |
|---|---|
| Macro | `cx.joy_scan()` / `cx.joy_get(pad)` |
| Purpose | sample / read a joystick |
| Input parameters | `pad` |
| Output parameters | A/X/Y = buttons) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.joy_scan()
    }
}
```

## `cx.mouse_show(cursor) / cx.mouse_hide() / cx.mouse_get()`

| Field | Details |
|---|---|
| Macro | `cx.mouse_show(cursor)` / `cx.mouse_hide()` / `cx.mouse_get()` |
| Purpose | mouse |
| Input parameters | `cursor` |
| Output parameters | P0/1 = x, P2/3 = y, A = buttons) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.mouse_show(cursor)
    }
}
```

## `cx.key_get() / cx.key_wait() / cx.key_peek()`

| Field | Details |
|---|---|
| Macro | `cx.key_get()` / `cx.key_wait()` / `cx.key_peek()` |
| Purpose | keyboard |
| Input parameters | No macro arguments. |
| Output parameters | A = PETSCII) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.key_get()
    }
}
```
