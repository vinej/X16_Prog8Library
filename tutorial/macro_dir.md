# Directory Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_DIR` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

A drive hands its directory over as a BASIC program listing -- link
bytes, the block count posing as a line number, the name in quotes, the
type as text. `dir_open`/`dir_next` walk that so you never see it.

The header line comes back as `DIR_TYPE_HOST` and the trailing "BLOCKS
FREE." line as `DIR_TYPE_NONE` with an empty name. They are not hidden:
a file browser skips them, a disk-info panel shows them, and neither has
to parse anything twice.

## `cx.dir_open(path, len, device)`

| Field | Details |
|---|---|
| Macro | `cx.dir_open(path, len, device)` |
| Purpose | open a directory for reading |
| Input parameters | `path, len, device` -- a `len` of 0 asks for the current directory |
| Output parameters | carry set if the directory could not be opened |
| More info | Available when `X16_USE_DIR` is enabled. |
| Example | See below. |

## `cx.dir_next(buf, size)`

| Field | Details |
|---|---|
| Macro | `cx.dir_next(buf, size)` |
| Purpose | read the next entry's name into `buf` |
| Input parameters | `buf, size` -- the size is honoured, so a long name cannot overrun it |
| Output parameters | carry **set** if an entry was read, **clear** at the end of the listing |
| More info | `dir_type` (A = `DIR_TYPE_*`) and `dir_blocks` (X/Y) then describe it. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        cx.dir_open(path, 0, 8)  ; 0 = the current directory
        %asm {{
            bcs no_dir
        }}

        %asm {{
            loop
        }}
        cx.dir_next(namebuf, 40)
        %asm {{
            bcc done; carry CLEAR: the listing ended
            jsr dir_type
            cmp #DIR_TYPE_PRG; programs only
            bne loop
            lda #<namebuf
            ldx #>namebuf
            jsr screen_puts
            lda #13
            jsr screen_chrout
            bra loop
        }}

        %asm {{
            done
            jsr dir_close
            no_dir
        }}
    }
}

%asm {{
    path        !text "$"
    namebuf     !fill 40, 0
}}

```
