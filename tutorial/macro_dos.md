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
        ; execute command; -> A = status
        cx.dos_cmd(1, 16)
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
        ; read DOS status
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
        ; delete file
        cx.dos_delete(file_name, 16)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of dos

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.dos_mkdir(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.dos_mkdir(name, len)` |
| Purpose | make a directory |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `cx.dos_rmdir(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.dos_rmdir(name, len)` |
| Purpose | remove a directory |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `cx.dos_chdir(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.dos_chdir(name, len)` |
| Purpose | change directory ("//" is the root) |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `cx.dos_rename(newname, newlen, oldname, oldlen)`

| Field | Details |
|---|---|
| Macro | `cx.dos_rename(newname, newlen, oldname, oldlen)` |
| Purpose | One-call wrappers. Each takes A = name low, X = name high, |
| Input parameters | `newname`, `newlen`, `oldname`, `oldlen` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |
