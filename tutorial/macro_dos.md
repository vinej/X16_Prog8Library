# DOS Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_DOS` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.dos_cmd(cmd, len)`

| Field | Details |
|---|---|
| Macro | `cx.dos_cmd(cmd, len)` |
| Purpose | execute command; -> A = status |
| Input parameters | `cmd, len` |
| Output parameters | A = status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.dos_cmd(cmd, len)
    }
}
```

## `cx.dos_status()`

| Field | Details |
|---|---|
| Macro | `cx.dos_status()` |
| Purpose | read DOS status |
| Input parameters | No macro arguments. |
| Output parameters | read DOS status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.dos_status()
    }
}
```

## `cx.dos_delete(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.dos_delete(name, len)` |
| Purpose | delete file |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.dos_delete(name, len)
    }
}
```
