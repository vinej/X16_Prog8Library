# File I/O Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_FILEIO` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.fio_set_lfs(logical, device, secondary) / cx.fio_set_name(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.fio_set_lfs(logical, device, secondary)` / `cx.fio_set_name(name, len)` |
| Purpose | KERNAL file setup |
| Input parameters | `logical, device, secondary`; `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_set_lfs(logical, device, secondary)
    }
}
```

## `cx.fio_open_named/open_read/open_write name, len, logical, device, secondary`

| Field | Details |
|---|---|
| Macro | `cx.fio_open_named/open_read/open_write name, len, logical, device, secondary` |
| Purpose | open helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_open_named()
    }
}
```

## `cx.fio_close(logical) / cx.fio_close_named(logical)`

| Field | Details |
|---|---|
| Macro | `cx.fio_close(logical)` / `cx.fio_close_named(logical)` |
| Purpose | close helpers |
| Input parameters | `logical` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_close(logical)
    }
}
```

## `cx.fio_chkin(logical) / cx.fio_chkout(logical) / cx.fio_clrchn()`

| Field | Details |
|---|---|
| Macro | `cx.fio_chkin(logical)` / `cx.fio_chkout(logical)` / `cx.fio_clrchn()` |
| Purpose | channel helpers |
| Input parameters | `logical` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_chkin(logical)
    }
}
```

## `cx.fio_chrin() / cx.fio_chrout(byte) / cx.fio_getin()`

| Field | Details |
|---|---|
| Macro | `cx.fio_chrin()` / `cx.fio_chrout(byte)` / `cx.fio_getin()` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_chrin()
    }
}
```

## `cx.fio_readst()`

| Field | Details |
|---|---|
| Macro | `cx.fio_readst()` |
| Purpose | read KERNAL status |
| Input parameters | No macro arguments. |
| Output parameters | read KERNAL status |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_readst()
    }
}
```

## `cx.fio_close_all() / cx.fio_close_device(device)`

| Field | Details |
|---|---|
| Macro | `cx.fio_close_all()` / `cx.fio_close_device(device)` |
| Purpose | bulk close helpers |
| Input parameters | `device` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.fio_close_all()
    }
}
```
