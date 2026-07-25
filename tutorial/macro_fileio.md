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
        ; KERNAL file setup
        cx.fio_set_lfs(1, 8, 0)
        cx.fio_set_name(file_name, 16)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

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
        ; open helpers
        cx.fio_open_named(file_name, 16, 1, 8, 0)
        cx.fio_open_read(file_name, 16, 1, 8, 0)
        cx.fio_open_write(file_name, 16, 1, 8, 0)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

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
        ; close helpers
        cx.fio_close(1)
        cx.fio_close_named(1)
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
        ; channel helpers
        cx.fio_chkin(1)
        cx.fio_chkout(1)
        cx.fio_clrchn()
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
        ; byte I/O helpers
        cx.fio_chrin()
        cx.fio_chrout('A')
        cx.fio_getin()
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
        ; read KERNAL status
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
        ; bulk close helpers
        cx.fio_close_all()
        cx.fio_close_device(8)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of fileio

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.fio_open()`

| Field | Details |
|---|---|
| Macro | `cx.fio_open()` |
| Purpose | carry set on error, A = the KERNAL error code |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FILEIO` is enabled. |
