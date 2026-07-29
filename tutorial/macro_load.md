# Load/save Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_LOAD` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.fs_setname(name, len)`

| Field | Details |
|---|---|
| Macro | `cx.fs_setname(name, len)` |
| Purpose | set KERNAL filename |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; set KERNAL filename
        cx.fs_setname(file_name, 16)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

```

## `cx.fs_load(name, len, device, sa, dst)`

| Field | Details |
|---|---|
| Macro | `cx.fs_load(name, len, device, sa, dst)` |
| Purpose | load to RAM; -> carry set = error, A = code |
| Input parameters | `name, len, device, sa, dst` |
| Output parameters | carry set = error, A = code |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; load to RAM; -> carry set = error, A = code
        cx.fs_load(file_name, 16, 8, 1, work_buffer)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
    work_buffer !fill 64, 0
}}

```

## `cx.fs_vload(name, len, device, vbank, vaddr)`

| Field | Details |
|---|---|
| Macro | `cx.fs_vload(name, len, device, vbank, vaddr)` |
| Purpose | load to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; load to VRAM
        cx.fs_vload(file_name, 16, 8, 1, $10000)
    }
}

%asm {{
    file_name   !text "SAVEGAME,S,R", 0
}}

```

## `cx.fs_prg_entry(name, len, device)`

| Field | Details |
|---|---|
| Macro | `cx.fs_prg_entry(name, len, device)` |
| Purpose | a PRG's entry address, read without loading the file |
| Input parameters | `name, len, device` |
| Output parameters | X/Y = the SYS address out of the file's BASIC stub, or `$0000` if it cannot be read or has no stub |
| More info | Available when `X16_USE_LOAD` is enabled. |
| Example | See below. |

A launcher has to know where to `jsr` before it hands the machine over,
and loading the program to find out is the one thing it cannot do: the
load overwrites the code asking the question. This reads the first few
bytes off the disk and parses the BASIC stub where it lies. `$0000`
doubles as "no entry here", since no PRG can start there.

Read the address, never assume it. A compiler emitting `SYS 2071` today
moves that number the moment its stub text changes.

```prog8
%import x16lib



main {
    sub start() {
        ; where does GAME.PRG start?
        cx.fs_prg_entry(file_name, 8, 8)
        %asm {{
            stx entry
            sty entry+1
            cpx #0
            bne @ok
            cpy #0
            beq @no_such_program; $0000: unreadable, or not a PRG
            @ok
        }}
    }
}

%asm {{
    @no_such_program
    rts
}}

%asm {{
    file_name   !text "GAME.PRG"
    entry       !word 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of load

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.fs_save(name, len, device, start, end)`

| Field | Details |
|---|---|
| Macro | `cx.fs_save(name, len, device, start, end)` |
| Purpose | save a block of memory as a PRG |
| Input parameters | `name`, `len`, `device`, `start`, `end` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_LOAD` is enabled. |
