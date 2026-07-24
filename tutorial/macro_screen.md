# Screen Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SCREEN` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.screen_set_mode(mode)`

| Field | Details |
|---|---|
| Macro | `cx.screen_set_mode(mode)` |
| Purpose | set the screen mode |
| Input parameters | `mode` |
| Output parameters | carry set if unsupported) |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_set_mode(mode)
    }
}
```

## `cx.screen_reset()`

| Field | Details |
|---|---|
| Macro | `cx.screen_reset()` |
| Purpose | restore the default text mode |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_reset()
    }
}
```

## `cx.screen_cls()`

| Field | Details |
|---|---|
| Macro | `cx.screen_cls()` |
| Purpose | clear the text screen |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_cls()
    }
}
```

## `cx.screen_chrout(ch)`

| Field | Details |
|---|---|
| Macro | `cx.screen_chrout(ch)` |
| Purpose | print one character, safely |
| Input parameters | `ch` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_chrout(ch)
    }
}
```

## `cx.screen_color(fg, bg)`

| Field | Details |
|---|---|
| Macro | `cx.screen_color(fg, bg)` |
| Purpose | text foreground / background (0-15) |
| Input parameters | `fg, bg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_color(fg, bg)
    }
}
```

## `cx.screen_border(col)`

| Field | Details |
|---|---|
| Macro | `cx.screen_border(col)` |
| Purpose | border colour (0-15) |
| Input parameters | `col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_border(col)
    }
}
```

## `cx.screen_locate(row, col)`

| Field | Details |
|---|---|
| Macro | `cx.screen_locate(row, col)` |
| Purpose | move the text cursor |
| Input parameters | `row, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_locate(row, col)
    }
}
```

## `cx.screen_charset(cs)`

| Field | Details |
|---|---|
| Macro | `cx.screen_charset(cs)` |
| Purpose | select a charset |
| Input parameters | `cs` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_charset(cs)
    }
}
```

## `cx.screen_puts(addr)`

| Field | Details |
|---|---|
| Macro | `cx.screen_puts(addr)` |
| Purpose | print a NUL-terminated string |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.screen_puts(addr)
    }
}
```
