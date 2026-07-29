# File Browser Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_FILEPICK` macro gate, and its
editing half `X16_USE_FILEPICK_EDIT`.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

A directory panel with a mouse and a keyboard: scrolling, descent into
folders, and one question answered -- *which file?* The caller decides
what the answer means.

```prog8
cx.fp_filter(pattern)  ; what to list
%asm {{
    jsr fp_open; A = FPK_NONE / FPK_PICK / FPK_ALT / FPK_HERE
    cmp #FPK_PICK
    bne @nothing
}}
cx.fp_copy_path(buf, 64)  ; A = length
%asm {{
    @nothing
    jsr fp_close
}}
```

The **filter** is a list of patterns separated by `;`:

| Pattern | Lists |
|---|---|
| `"*.prg"` | programs |
| `"*.bmx;*.png"` | either kind of picture |
| `"*.*"` | every file, whatever it is called |

Directories are always listed whatever the filter says, or there would
be no way to reach the file you wanted. Matching folds case, because a
drive answers in ASCII and a pattern written in a PETSCII source is
lower-case.

## What `fp_open` comes back with

| Answer | Means |
|---|---|
| `FPK_NONE` | cancelled: ESC, Run/Stop, or the panel's `x` box |
| `FPK_PICK` | a file was chosen -- double click, Enter, or `r` |
| `FPK_ALT` | the second gesture on a file: right click, or `a` |
| `FPK_HERE` | `h`: the DIRECTORY being shown, for "save into..." |

`FPK_ALT` is whatever the caller wants it to be -- a launcher uses it
for "keep this on the desktop". `FPK_HERE` exists so ESC can go on
meaning cancel: without it, a caller wanting a place has to read ESC as
"use this one" and then has no way left to mean "no".

The drive is left standing in the directory the panel was showing, so a
bare filename written afterwards lands there.

## `cx.fp_filter(pattern)` / `cx.fp_primary(pattern)`

| Field | Details |
|---|---|
| Macro | `cx.fp_filter(pattern)`, `cx.fp_primary(pattern)` |
| Purpose | which files to list; which of those the caller can act on |
| Input parameters | a NUL-terminated `;` list of `*.ext` patterns |
| More info | Set `primary` alongside a `"*.*"` filter and everything that does not match is marked `[dat]`: a launcher can run a `.prg` but can only hand a `.bmx` to a program that opens it. `fp_is_primary` reports which kind was chosen. |

## `cx.fp_open()` / `cx.fp_resume()` / `cx.fp_close()`

| Field | Details |
|---|---|
| Macro | `cx.fp_open()`, `cx.fp_resume()`, `cx.fp_close()` |
| Purpose | put the panel up; put it up again unchanged; take it down |
| Output parameters | A = `FPK_*` |
| More info | `fp_resume` returns to the same directory and selection, for a caller that acted on an `FPK_ALT` and wants the browser back. `fp_close` restores the screen under the panel and hides the pointer. |

## `cx.fp_copy_path(dest, size)` / `cx.fp_copy_name()` / `cx.fp_copy_dir()`

| Field | Details |
|---|---|
| Macro | `cx.fp_copy_path(dest, size)`, `cx.fp_copy_name(dest, size)`, `cx.fp_copy_dir(dest, size)` |
| Purpose | the absolute path / the bare name / the directory, copied into your memory |
| Output parameters | A = characters copied, terminator aside |
| More info | **Use these from a banked filepick.** `fp_path`, `fp_name` and `fp_dir` return pointers instead, and those name storage that travels into the RAM bank with the module -- the wrapper maps the bank out again before the caller reads them. |

## `cx.fp_cache(addr, hibit)` / `cx.fp_saveunder(on, addr, hibit)`

| Field | Details |
|---|---|
| Macro | `cx.fp_cache(addr, hibit)`, `cx.fp_saveunder(on, addr, hibit)` |
| Purpose | where the listing lives; where the screen under the panel is kept |
| Input parameters | a VRAM address: low 16 bits, then bit 16 |
| More info | VRAM rather than a RAM bank, and not by preference: a banked module cannot page a bank into the window it is executing from. The listing is 2,560 bytes (`$12000` by default), the save-under 5,712 at 80 columns (`$14000`). A caller that repaints its own screen does not need the second one. |

## `cx.fp_style(panel, bar, sel)` / `cx.fp_heading(text)` / `cx.fp_footing(text)` / `cx.fp_charset(n)` / `cx.fp_start_dir(path)`

| Field | Details |
|---|---|
| Purpose | colours, the two labels, the charset the panel is drawn in, and where it opens |
| More info | All optional. `fp_charset` takes 255 to leave whatever the caller had -- there is no way to ask the KERNAL which charset is loaded, so the module cannot put back what it does not know. The name prompt is drawn blue on yellow whatever the style: a field that looks like the rows around it is a field nobody sees. |

## `cx.fp_match(name, pattern)`

| Field | Details |
|---|---|
| Macro | `cx.fp_match(name, pattern)` |
| Purpose | does this name match a `;` list of patterns? |
| Output parameters | carry set when it matches |
| More info | The same matcher the panel filters with, exposed because a caller often wants to ask it about a name of its own. |

## `cx.fp_panel_top()` / `_left` / `_width` / `_rows`

| Field | Details |
|---|---|
| Purpose | where the panel is, for a caller drawing its own rows inside it |
| Output parameters | A = the cell coordinate or size |
| More info | Valid once `fp_open` has run: the panel sizes itself to the screen it finds (80x60 or 40x30). `fp_redraw` paints it again afterwards. |

## Managing files: `X16_USE_FILEPICK_EDIT`

```prog8
```

No macros of its own -- it adds commands inside `fp_open`:

| Key | Does |
|---|---|
| `n` | make a folder here |
| `e` | rename the selected entry (`r` already runs or picks it) |
| `d` | delete it, after a y/n confirm; a folder must be empty |
| `c` | remember the selected file |
| `v` | write it into the folder on show |

Every one re-reads the directory afterwards, so the panel never shows
something the drive no longer has. It is gated separately because a
program that only asks *which file?* should not carry delete to get it.

## Worth banking

The browser is around 3 KB and a program only needs it while the panel
is up, which makes it the module most worth relocating:

```
bank 20, "filepick,dir,dos,mouse"
```

A spreadsheet within 3 KB of the low-RAM ceiling went from *3,927 bytes
over* as low-RAM code to **434 bytes** of far-call wrappers, with the
browser itself in the bank. Two rules follow, both covered above: take
the answers by copy, and give it VRAM for its own storage.

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `fp_panel_left` | -- | -- | -- |
| `fp_panel_width` | -- | -- | -- |
| `fp_panel_rows` | -- | -- | -- |
