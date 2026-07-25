# Keyboard Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_KEYBOARD` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.kbd_scan() / cx.kbd_peek() / cx.kbd_put(key)`

| Field | Details |
|---|---|
| Macro | `cx.kbd_scan()` / `cx.kbd_peek()` / `cx.kbd_put(key)` |
| Purpose | keyboard scan/read/write helpers |
| Input parameters | `key` |
| Output parameters | keyboard scan/read/write helpers |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; keyboard scan/read/write helpers
        cx.kbd_scan()
        cx.kbd_peek()
        cx.kbd_put('Y')
    }
}

```

## `cx.kbd_get_modifiers()`

| Field | Details |
|---|---|
| Macro | `cx.kbd_get_modifiers()` |
| Purpose | read modifier state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; read modifier state
        cx.kbd_get_modifiers()
    }
}

```

## `cx.kbd_get_keymap() / cx.kbd_set_keymap(name)`

| Field | Details |
|---|---|
| Macro | `cx.kbd_get_keymap()` / `cx.kbd_set_keymap(name)` |
| Purpose | keymap helpers |
| Input parameters | `name` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; keymap helpers
        cx.kbd_get_keymap()
        cx.kbd_set_keymap(file_name)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

```
