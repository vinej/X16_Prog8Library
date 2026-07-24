# IEC Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_IEC` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.iec_listen(device) / cx.iec_talk(device)`

| Field | Details |
|---|---|
| Macro | `cx.iec_listen(device)` / `cx.iec_talk(device)` |
| Purpose | bus attention helpers |
| Input parameters | `device` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_listen(device)
    }
}
```

## `cx.iec_second(command) / cx.iec_tksa(command)`

| Field | Details |
|---|---|
| Macro | `cx.iec_second(command)` / `cx.iec_tksa(command)` |
| Purpose | secondary address helpers |
| Input parameters | `command` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_second(command)
    }
}
```

## `cx.iec_ciout(byte) / cx.iec_acptr()`

| Field | Details |
|---|---|
| Macro | `cx.iec_ciout(byte)` / `cx.iec_acptr()` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_ciout(byte)
    }
}
```

## `cx.iec_unlisten() / cx.iec_untalk()`

| Field | Details |
|---|---|
| Macro | `cx.iec_unlisten()` / `cx.iec_untalk()` |
| Purpose | release bus helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_unlisten()
    }
}
```

## `cx.iec_set_timeout(control) / cx.iec_readst()`

| Field | Details |
|---|---|
| Macro | `cx.iec_set_timeout(control)` / `cx.iec_readst()` |
| Purpose | timeout/status helpers |
| Input parameters | `control` |
| Output parameters | timeout/status helpers |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_set_timeout(control)
    }
}
```

## `cx.iec_macptr(dest, count) / cx.iec_mciout(src, count)`

| Field | Details |
|---|---|
| Macro | `cx.iec_macptr(dest, count)` / `cx.iec_mciout(src, count)` |
| Purpose | block I/O helpers |
| Input parameters | `dest, count`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_macptr(dest, count)
    }
}
```

## `cx.iec_open_channel(device, secondary) / cx.iec_data_channel(device, secondary) / cx.iec_talk_channel(device, secondary) / cx.iec_close_channel(device, secondary)`

| Field | Details |
|---|---|
| Macro | `cx.iec_open_channel(device, secondary)` / `cx.iec_data_channel(device, secondary)` / `cx.iec_talk_channel(device, secondary)` / `cx.iec_close_channel(device, secondary)` |
| Purpose | channel helpers |
| Input parameters | `device, secondary` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.iec_open_channel(device, secondary)
    }
}
```
