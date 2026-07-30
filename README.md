# X16_Prog8Library

[Prog8](https://prog8.readthedocs.io/) is created by **Irmen de Jong**, and is
arguably the finest language available for writing programs for the Commander X16.

A [Prog8](https://prog8.readthedocs.io/) wrapper for the
[X16_Library](../x16_library) — call the library's hand-written 6502 routines
from Prog8 with typed subroutines, on the Commander X16.

Generated from **X16_Library** at commit `6992b4d` (2026-07-30). The library
carries no version number of its own, so the commit is what identifies a sync.

Every library module is available, and your PRG contains only the ones you
actually call.

```prog8
%import x16lib          ; typed wrappers + the (gated) embedded library source
%import x16lib_const    ; VERA_*, BANK_*, VRAM_* constants
%zeropage basicsafe

main {
    str msg = "hello from prog8! "
    sub start() {
        cx.screen_puts(&msg)
        cx.screen_puts(cx.u16_to_dec(1234))   ; returns the decimal string ptr
        cx.screen_chrout($0d)
    }
}
```

Every routine lives in the **`cx`** block: `cx.screen_puts(...)`,
`cx.shape_frrect(...)`, `cx.sin8(...)`, and so on.

## How it works (pay-per-use)

The X16_Library has no per-function linker — it selects code by **module gate**
(`X16_USE_*`). This wrapper embeds the library's **64tass source port** (which
Prog8 assembles with the same 64tass it already uses) and gates it automatically
from your calls:

1. `build.ps1` scans your program (and the local modules it `%import`s) for
   `cx.<routine>(...)` calls.
2. It maps each call to the routine's `X16_USE_*` gate via `routine_gates.json`
   and writes `x16lib/x16lib_gates.inc` with just those gates.
3. Prog8 + 64tass assemble only those modules of the embedded source; the
   library pulls in each module's dependencies automatically. Everything else is
   left out.

So `hello.p8` (screen + number + VERA) is **under 1 KB of library code**, while a
program that draws shapes pulls in the shape + bitmap engines and nothing else.
The whole library at once is ~42 KB and would not fit in low RAM — which is
exactly why gating matters.

| File | What |
|---|---|
| `x16lib/x16lib_src.asm` | the whole X16_Library 64tass source, flattened into one file (all `.include`s inlined), still gated by `X16_USE_*` |
| `x16lib/x16lib.p8` | typed Prog8 `sub` per routine (block `cx`) that reproduces the register / `X16_P0..P7` ABI and `jsr`s into the embedded source; plus block `x16src` that `%asminclude`s the gates + the source |
| `x16lib/x16lib_const.p8` | all `UPPER_SNAKE` constants (block `x16c`) — `x16c.VRAM_TEXT`, `x16c.BANK_AUDIO`, … |
| `x16lib/routine_gates.json` | routine → `X16_USE_*` gate map, consumed by `build.ps1` |
| `x16lib/x16lib_gates.inc` | generated per build: the gates enabled for the current program |
| `tools/gen_prog8_src.py` | the generator that produces all of the above |
| `examples/` | one folder per example — see below |
| `build.ps1` | scan gates, compile, optionally run |
| `tutorial/` | the X16_Library tutorial, Prog8 edition (generated — see below) |

The library machine code is assembled inline into your program (no fixed load
address, no memory gap). The library claims zero page `$22-$31`.

## Building

Needs, all repo-local:

* `prog8-sdk/prog8c.jar` — the Prog8 compiler (**Java 17+**; the script
  auto-detects an Eclipse Adoptium / Java JDK ≥ 17, e.g. JDK 21).
* `prog8-sdk/64tass.exe` — the assembler Prog8 shells out to.
* `emulator/x16emu.exe` + `rom.bin` — the Commander X16 emulator (r49).

```powershell
.\build.ps1                       # build examples\hello\hello.p8 -> build\hello.prg
.\build.ps1 examples\shapes\shapes.p8    # a specific program
.\build.ps1 examples\hello\hello.p8 -Run    # ...and launch it in the emulator
```

Each build prints the modules it enabled, e.g.
`Modules enabled (5): X16_USE_NUMBER, X16_USE_SCREEN, ...`.

The emulator is launched with **`-bitmap2`** so the library's VERA_2 SDRAM
high-resolution bitmap engines (`gfx2h`, `gfx4h`, `gfx8h`) work; it is harmless
for programs that don't use them.

> **Compiling without `build.ps1`?** Then `x16lib_gates.inc` is not regenerated,
> so no modules are enabled and `cx.*` calls won't link. Either use `build.ps1`,
> or write the `X16_USE_* = 1` lines you want into `x16lib/x16lib_gates.inc`
> yourself before running `prog8c`.

## Examples

One folder per example, each self-contained — the `.p8` sources it needs, its
bank layout, any data file it loads, and **its own `build.ps1`** carrying that
example's arguments:

| Folder | Build | What it shows |
|---|---|---|
| `examples/hello/` | `.\build.ps1 [-Run]` | the smallest thing that links: `screen_puts` + `u16_to_dec` |
| `examples/shapes/` | `.\build.ps1 [-Bank] [-Run]` | the shape + bitmap engines; `-Bank` relocates them into RAM bank 22 |
| `examples/sortdemo/` | `.\build.ps1 [-Run]` | `sort_u16` and `str_sort` |
| `examples/imgview/` | `.\build.ps1 [-Image f.jpg] [-Stretch] [-Run]` | a 640×480 8bpp image streamed into VERA_2 SDRAM; `-Image` converts it first |
| `examples/twobank/` | `.\build.ps1 [-Flat] [-Run]` | library modules split across two 8K RAM banks |
| `examples/kalk/` | `.\build.ps1 [-Test] [-Run]` | a whole application: the `kalk` spreadsheet — has its own [README](examples/kalk/README.md) |

Each of those is a thin wrapper around the root `build.ps1` (which does the
gate scan and drives `prog8c`), so it works from any directory:

```powershell
.\examples\kalk\build.ps1 -Run          # from the repo root
cd examples\kalk;  .\build.ps1 -Run     # or from the example's folder
```

The root script still takes any program directly, which is what you want for
your own code:

```powershell
.\build.ps1 examples\shapes\shapes.p8 -Bank "shapes,bitmap2h" -BankNum 22
```

`build.ps1` resolves a program's local `%import`s next to that program, so an
example's own modules live in its folder; only the wrapper package is shared
(via `-srcdirs x16lib`). Output always lands in `build\<name>.prg`.

## Banking heavy modules into 8K RAM (`-Bank`)

For big programs, you can relocate chosen library modules out of low RAM into 8K
RAM banks (`$A000-$BFFF`), freeing that space for your program. The modules stay
fully callable — their wrappers switch the bank, call, and switch back.

**Bank-layout file (recommended)** — one line per bank, `bank <N>, "mod,mod"`:

```
# examples\twobank\twobank.banks
bank 22, "shapes,bitmap2h"
bank 23, "string"
```
```powershell
.\build.ps1 examples\twobank\twobank.p8 -BankFile examples\twobank\twobank.banks
```
That yields a **509-byte** main PRG plus `build\BANK22.BIN` (graphics) and
`build\BANK23.BIN` (strings) — the whole library footprint is out of low RAM.

**Inline single bank** (shorthand for one line):
```powershell
.\build.ps1 examples\shapes\shapes.p8 -Bank "shapes,bitmap2h" -BankNum 22
```
For `shapes.p8` this drops the main PRG from **~6 KB to ~0.6 KB** of low RAM.

How it works:

1. Each bank's named modules, plus their dependency closure, are assembled
   `.logical $A000` into a self-contained companion image `build\BANK<N>.BIN`.
2. Each banked routine's wrapper gets a far-call trampoline that pages in *its*
   bank (`save $00; sta #N; call; restore`); everything else is a direct low-RAM call.
3. Your program calls **`cx.load_banks()`** once at startup to load every image
   (a no-op when nothing is banked). `-Run` points the emulator's `-fsroot` at
   `build\` so the `LOAD`s find the `.BIN` files.

Constraints (the honest limits):

* **One bank = one self-contained group** (≤ 8 KB each; the build errors if it
  overflows). Banked code may call low-RAM and KERNAL freely, but not code in
  another bank — so put a subsystem and the modules it drives in the *same* bank.
* A module may live in only one bank. Shared dependencies are duplicated into
  each bank that needs them (each image is self-contained).
* **Not bankable:** IRQ-resident code (`irq`, `pcm_stream`) and any module whose
  data low-RAM code touches between calls.
* Reserves the named RAM banks — keep them clear of the library's `bank_alloc`
  and prog8's own bank use.
* The companion `BANK<N>.BIN` files must ship alongside the `.PRG`.

## Displaying images (640×480 8bpp)

The X16 can't decode images at runtime, so convert on the PC and load the result.
`tools/img2bmx.py` (Pillow) turns any image into a BMX file sized for the VERA_2
640×480 8bpp bitmap — **any format Pillow reads** (JPG, PNG, WEBP, AVIF, GIF, BMP,
TIFF, …), plus HEIC/HEIF when `pillow-heif` is installed. `examples/imgview/imgview.p8`
shows it with a single library call:

```powershell
python tools\img2bmx.py photo.jpg build\IMAGE.BMX     # fit + letterbox (--stretch to fill)
.\build.ps1 examples\imgview\imgview.p8 -Run
```

```prog8
cx.gfx8h_init()                                   ; 640x480 @ 8bpp (needs -bitmap2)
cx.bmx_load_hires(&filename, len(filename), 8)    ; palette + 307 KB of pixels, one call
```

`--lores` targets the other 8bpp bitmap instead: 320x240 on VERA layer 0, which
the KERNAL's screen mode `$80` pairs with a 40x30 text layer, so text can sit
*over* the image. That is the way to get a background on a **stock** X16, where
there is no VERA_2 layer and VRAM cannot hold a 640x480 image at more than 2bpp.
Its palette is quantized to 240 colours placed at index 16, leaving alone the 16
system colours the text layer draws with — get that wrong and the background
repaints every character on screen.

`examples/desktop/` does not need it: with a VERA_2 layer present it puts a full
640x480 photograph behind the text and sprites using **passthru**, whose palette
is separate from VERA's entirely.

```powershell
python tools\img2bmx.py photo.jpg build\WALL.BMX --lores --stretch
```

The 307 KB of image data never touches main RAM — it streams straight from disk
into VERA_2 SDRAM, so the program stays ~3 KB. `cx.bmx_load_hires` requires
X16_Library ≥ v0.11.6. (Filenames are lowercase in the source on purpose — Prog8's
PETSCII maps `a-z` to `$41-$5A`, which the KERNAL reads as the upper-case host name.)

## `kalk` — a spreadsheet in the examples

`examples/kalk/` is a port of [zserge's **kalk**](https://github.com/zserge/kalk),
a VisiCalc-style terminal spreadsheet — a worked example of building a whole
application on this wrapper. Every run-time service (floating point, screen,
keyboard, files, banked memory) is a `cx.*` call, with nothing from Prog8's own
stdlib. A 26 x 256 sheet with formulas, cell formats, replicate, title locking
and CSV files; the grid itself lives in eight 8K RAM banks.

```powershell
.\build.ps1 examples\kalk\kalk.p8 -Run
.\build.ps1 examples\kalk\kalktest.p8 -Run    # the engine self-test
```

**See [`examples/kalk/README.md`](examples/kalk/README.md)** for the key and
command reference, the formula syntax, how it maps onto the library, and the
two Prog8 pitfalls it ran into (zero-page collisions with `X16_P0..P7`, and
static locals in a recursive parser).

## `filepick` — a file browser any program can put on screen

`x16lib/filepick.p8` is the desktop's directory panel, lifted out so there is
one copy rather than one per program: mouse and keyboard, scrolling, descent
into folders, and an absolute path handed back.

```prog8
%import filepick

filepick.filter("*.bmx")              ; what to list
if filepick.open() == filepick.PICK
    load_it(filepick.path())          ; absolute, ready to open
filepick.close()
```

The filter is a `;`-separated list — `"*.prg"`, `"*.bmx;*.png"`, `"*.klk;*.csv"`,
or `"*.*"` for everything. Directories are always listed whatever the filter
says, or there would be no way to reach the file you wanted, and matching folds
case because the drive answers in ASCII while Prog8 source is PETSCII.

Everything else is optional: `cache(addr, bank)` for the 2.5 KB listing,
`style()`, `heading()`/`footing()`, `charset()`, `start_dir()`, and
`saveunder(bank)` — which keeps the characters under the panel in a RAM bank
and puts them back on close, for a program that cannot simply repaint. Set
`primary("*.prg")` alongside `filter("*.*")` and anything that does not match
is marked `[dat]`: that is how the desktop distinguishes what it can run from
what it can only hand to another program.

**`%zeropage dontuse` is required.** The browser calls library routines that
own ZP `$22-$31`, and `basicsafe` hands Prog8 those same bytes — the symptom is
a panel drawn in fragments across the screen, because `screen_addr` calculates
through them.

**Cost:** about **4 KB** of low RAM. That is Prog8 code, so `-Bank` cannot move
it — banking relocates library modules only.

**Which is why the browser is now in X16_Library too**, as `X16_USE_FILEPICK`
(`cx.fp_*`). Same panel, same filters, written in ACME so it *can* be banked:

```
# examples\kalk\kalk.banks
bank 20, "filepick,dos,mouse"
```

`dir` is deliberately absent: the library forces `X16_USE_DIR` on wherever
`X16_USE_FILEPICK` is on, so it lands in the bank image anyway, and naming a
module kalk never calls itself only earns a warning.

kalk is the program that proves the point. As a Prog8 module the browser put it
**3,927 bytes over** the low-RAM ceiling and banking every library module it
uses freed only 1,745 — those modules are thin KERNAL bindings, there is not
4 KB of them to move. As a library module the browser costs kalk a handful of
far-call wrappers in low RAM, with **6,396 bytes** living in bank 20.

Every program here uses the library one now — the desktop, imgview and kalk —
so there is a single browser, in a single language, and `x16lib/filepick.p8` is
gone. Only kalk banks it; the other two have the room and keep it in low RAM.

The result codes are `x16c.FPK_NONE` / `FPK_PICK` / `FPK_ALT` (0/1/2), plus
`FPK_HERE` for "this folder". They live in `x16lib_const` like every other
constant: the generator reads the embedded source as well as the distribution
blob, and the blob — an everything-build against a hard `$9EFF` ceiling — has no
room for a 3 KB browser, so its symbol list alone would not have them.

## `launcharg` — telling a program which file to open

The X16 has no `argv`. A program launched from a desktop or a shell knows only
its own name, so anything that wanted to open a particular file had to ask for
it again — which is why a file browser kept wanting to be copied into every
program that reads files.

`x16lib/launcharg.p8` is the cheaper answer: the launcher leaves the path in
golden RAM, and the program picks it up on the way in.

```prog8
%import launcharg

; in the launcher
launcharg.set(&path, n)          ; ...then load and run the program

; in the program
uword p = launcharg.get()        ; 0 when nothing was passed
if p != 0
    open_that(p)
else
    use_a_default()
```

`$0500`–`$057F`: a two-byte magic, a length, then the NUL-terminated path.
Golden RAM is the block the KERNAL and BASIC leave alone and a PRG at `$0801`
does not cover, so it survives both the LOAD and the launch. The magic matters
because golden RAM holds whatever the last program left there — a launcher that
passes nothing must call `launcharg.clear()`, which the desktop does before
every launch.

The desktop drives it from the browser: on a data file, Enter asks **which of
the programs on the desktop** should open it. `examples/imgview` shows the
picture it was handed and falls back to `image.bmx` otherwise; `examples/kalk`
loads the sheet it was handed and starts empty otherwise. Both still run
standalone from BASIC, unchanged.

## The call ABI

The wrappers mirror the library's conventions exactly:

* Up to three byte/word arguments go in `A` / `X` / `Y`; anything more goes in
  the zero-page block `X16_P0..P7` (`$22`–`$29`). The generator emits the right
  loads for each routine.
* Word arguments are passed whole (the wrapper splits them into low/high).
* **Return values** (`-> ubyte` / `-> uword` / `-> bool`) come from the
  routine's `out:` header — see *Coverage* below for exactly how, and for the
  cases the generator deliberately leaves untyped.

Example — a filled rounded rectangle (all args in the P block, colour in `A`):

```prog8
cx.shape_frrect(40, 40, 200, 110, 28, 1)
```

## Coverage

The wrapper exposes **707 routines** across every X16_Library module — VERA,
screen, palette, sprites, tiles, all six bitmap engines, shapes (circle, disc,
poly, rrect, arc, pie, bezier), graph/framebuffer/console, PSG/YM/PCM/ADPCM and
the ROM-audio API, serial/I2C/SPI/ZiModem, keyboard/mouse, clock, banking,
file/DOS/IEC, math, strings, BCD, the 8 KB LIFO stack and FIFO ring, character
classification, 16/32-bit integers, fixed/float/double, and more — plus **550
constants**. Only the modules you use are linked.

A wrapper exists for a routine when the library gives it an `xm_` "friendly
macro" — that is what the generator reads to learn the calling convention. The
one gap left is that a handful of macros do **assemble-time arithmetic on an
argument**: they assume a compile-time constant and cannot be driven with a
runtime value, so no wrapper is generated. Call those through inline asm — or
better, ask for a macro that takes the argument pre-split, which is how
`sprite_image_at` came to exist alongside the constant-only `sprite_image`.
A routine the library adds and forgets to give a macro is unreachable the same
way; where that has happened (`str_islower_iso`, whose whole ctype family has
one) the generator's `EXTRA_SUGAR` supplies the missing macro in the library's
own syntax, so the ABI is still read, never guessed.
**Return values** (`-> ubyte` / `-> uword` / `-> bool`) are read from each
routine's `out:` header in the library: `A` or `X` or `Y` becomes a `ubyte`,
`A = low, X = high` a `uword`, and a documented carry a `bool`. **193** of the
wrappers carry one. The derivation refuses to guess — a routine that documents
both a carry and a register (`gfx8h_read`: "carry clear, A = colour; carry set
if off screen") gets no return type rather than a plausible-looking wrong one,
because a wrapper with the wrong type is a bug in every program that trusts it.
For those, add an explicit `; -> ...` note above the macro in `sugar.asm`, which
always wins, or read the register with a two-line asm shim. Where the answer has
already been decided here — `stack_popw` / `ring_getw` give back the word and
leave the underflow to `*_isempty`, `str_islower` is its carry — it is written
down in `RETURN_OVERRIDE` in the generator, so a resync cannot silently take it
away when the library rewords a header.

**Arguments** are `ubyte` or `uword` by which halves of them the macro stores —
except a whole 17-bit VRAM address, written `<`, `>` and `^`, which arrives as
Prog8's `long` (`cx.fx_fill($20, $10000, 32)`).

## Regenerating

`x16lib_src.asm`, `x16lib.p8`, `x16lib_const.p8` and `routine_gates.json` are
**generated** — do not hand-edit them. They are derived from the X16_Library:

* `src_64tass/` — the 64tass source port (flattened and embedded)
* `src_acme/core/sugar.asm` — one `xm_<routine>` macro per routine (the ABI)
* `dist/64tass/x16lib.inc` — constants
* `src_64tass/x16_code.asm` + module files — the routine → gate map

```powershell
python tools\gen_prog8_src.py [path\to\x16_library]   # default: c:\quartus\projects\x16_library
```

### Testing a regeneration

The examples call maybe a tenth of the wrapper, so a broken wrapper normally
surfaces in somebody's program rather than here. `tools\smoke_wrappers.py`
builds, for every `X16_USE_*` gate, a program that calls **every** wrapper in
it — arguments all zero, nothing is run, it is an assembly test — through
`build.ps1`, gate scan and all:

```powershell
python tools\smoke_wrappers.py                 # all 89 gates, ~5 minutes
python tools\smoke_wrappers.py X16_USE_STACK   # one gate
```

It exits with the number of gates that failed and prints each assembler error.
Two are known to fail today, both in the library's 64tass port rather than in
anything generated here (see *Known upstream gaps* below).

## Known upstream gaps

The 64tass port carries two constructs 64tass cannot assemble. They only bite
when the module is actually gated on, which is why the library's own test
targets pass:

| Where | What |
|---|---|
| `src_64tass/gfx/bitmap4h.asm:281` | `++  lda g4h_n` — ACME's second-level anonymous label. 64tass accepts `+` as a *definition* and `++` only as a *reference* ("second following `+`"), so the definition must be a plain `+`. Breaks any build with `X16_USE_BITMAP4H`. |
| `src_64tass/video/vdc.asm:239` | `_vdc_store_active_t` is a shared tail three sibling routines `jmp` to. In ACME a leading `_` means nothing; in 64tass it makes the label *cheap-local* to the routine above it, so the earlier jumps cannot see it. Breaks any build with `X16_USE_VERA_DC`. |

Until the library fixes them, `cx.gfx4h_*` and `cx.vdc_set_active*` /
`cx.vdc_fullscreen` cannot be linked.

## Tutorial

`tutorial/` is the X16_Library tutorial re-spelled for Prog8 — the same set of
pages (`userguide.md`, `macroguide.md`, and one `macro_<module>.md` per module),
generated from the library's `src_acme/tutorial` by `tools/acme_doc2prog8.py`.
Prose is left intact; the code snippets and inline macro spellings are rewritten:

| ACME | Prog8 |
|---|---|
| `+xm_pal_set index, rgb` | `cx.pal_set(index, rgb)` |
| `!source "x16.asm"` | `%import x16lib` |
| `X16_USE_PALETTE = 1` | *(dropped — gates are automatic)* |
| `main` … `rts` | `main { sub start() { … } }` |
| `<expr` / `>expr` / `^expr` | `lsb(expr)` / `msb(expr)` / `(expr >> 16)` |

Like the wrapper, these are **generated** — do not hand-edit. Regenerate with:

```powershell
python tools\acme_doc2prog8.py [src_tutorial] [dst_tutorial]
# defaults: c:\quartus\projects\x16_library\src_acme\tutorial  ->  tutorial\
```

## Zero-page note

The library owns ZP `$22-$31` (`X16_P0..P7` for arguments, `X16_T0..` for
scratch). Prog8's `%zeropage basicsafe` **also** hands out `$22-$31` — it is
BASIC-safe, not library-safe — so as soon as a program has more than a couple
of variables in ZP, every `cx.*` call silently corrupts them. The symptom is
nasty: values that change on their own across a library call.

Small programs like `hello.p8` get away with it because nothing lands there.
Anything larger should use **`%zeropage dontuse`**, which keeps ZP entirely
clear for the library (a little slower, since Prog8's variables move to
absolute addresses). `examples/kalk/kalk.p8` does exactly that; it was the first
program here big enough to hit the collision.

## Launching the Prog8 compiler

`build.ps1` wraps all of this (it locates a JDK 17+, puts `64tass` on `PATH`, and
passes `-target cx16 -srcdirs x16lib`), but you can drive `prog8c.jar` directly.
The compiler needs **Java 17+**, and `64tass` on `PATH` for the final assembly.

```
java -jar prog8-sdk\prog8c.jar -target cx16 -srcdirs x16lib -out build myprog.p8
```

A `-target` is **required**. Everything else is optional:

| Option | What it does |
|---|---|
| `-target cx16` | compile for the Commander X16 (also: `c64`, `c128`, `pet32`, `virtual`, or a custom target file) — required |
| `-srcdirs x16lib` | extra `;`-separated directories to search for `%import`ed modules (this repo's wrapper lives in `x16lib`) |
| `-out build` | write the `.prg`/`.asm` into this directory instead of the current one |
| `-D NAME=VALUE` | define an assembly symbol (this is how module gates could be forced; `build.ps1` uses generated includes instead) |
| `-emu` / `-emu2` | auto-start the (alternative) emulator after a successful build |
| `-check` | parse and type-check only — fast, produces no output |
| `-noopt` | skip code optimizations (faster build, larger/slower code) |
| `-asmlist` | also emit an assembler listing file |
| `-nosourcelines` | omit the original Prog8 lines as comments in the generated `.asm` |
| `-watch` | continuous mode: recompile on file changes |
| `-quiet` / `-quietasm` | suppress compiler / assembler chatter |
| `-warnshadow`, `-warnimplicitcasts` | extra warnings |
| `-dumpsymbols` / `-dumpvars` | print the program's symbols / variables |
| `-varshigh N` / `-slabshigh N` | put variables / memory slabs in HIRAM bank `N` |
| `-breakinstr brk\|stp` | which CPU instruction `%breakpoint` emits |
| `-version` / `-help` | print the version / full option list |

Run `java -jar prog8-sdk\prog8c.jar -help` for the complete, authoritative list.

> **Note:** compiling directly this way does **not** run `build.ps1`'s gate scan,
> so `x16lib\x16lib_gates.inc` isn't regenerated — no library modules are enabled
> and `cx.*` calls won't link. Use `build.ps1`, or write the `X16_USE_* = 1` lines
> you need into `x16lib\x16lib_gates.inc` yourself first (see the pay-per-use
> and banking sections above for how the gate includes work).

### `%option no_sysinit` — start without resetting the machine

By default Prog8 runs an `init_system` routine before `main.start()` that resets
the cx16 to a clean state: `CINT` (video back to the default VGA text mode), a
screen clear, default colors/border, `IOINIT`/`RESTOR`, audio silenced, mouse off.
Put `%option no_sysinit` at the top of your main file to **skip that** and start
in whatever state the machine is already in.

```prog8
%option no_sysinit
%import x16lib
%import x16lib_const
%zeropage basicsafe

main {
    sub start() {
        cx.gfx8h_init()        ; you own the video setup; Prog8 won't force VGA text first
        ...
    }
}
```

It's a module-level directive, and it pairs naturally with this library: programs
here usually pick their own video mode (`cx.screen_set_mode`, `cx.gfx8h_init`,
`cx.gfx2h_init`, …), so skipping Prog8's default screen reset avoids a flash of
cleared text mode and a redundant re-init. The trade-off: with `no_sysinit` you
own any initialization you need — if you rely on the default text mode, colors, or
restored KERNAL vectors, do that setup yourself.
