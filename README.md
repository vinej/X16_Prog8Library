# X16_Prog8Library

[Prog8](https://prog8.readthedocs.io/) is created by **Irmen de Jong**, and is
arguably the finest language available for writing programs for the Commander X16.

A [Prog8](https://prog8.readthedocs.io/) wrapper for the
[X16_Library](../x16_library) — call the library's hand-written 6502 routines
from Prog8 with typed subroutines, on the Commander X16.

**Every** library routine is available, and your PRG contains only the modules
you actually call.

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
| `examples/` | `hello.p8`, `shapes.p8` |
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
.\build.ps1                       # build examples\hello.p8 -> build\hello.prg
.\build.ps1 examples\shapes.p8    # a specific program
.\build.ps1 examples\hello.p8 -Run    # ...and launch it in the emulator
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

## Banking heavy modules into 8K RAM (`-Bank`)

For big programs, you can relocate chosen library modules out of low RAM into 8K
RAM banks (`$A000-$BFFF`), freeing that space for your program. The modules stay
fully callable — their wrappers switch the bank, call, and switch back.

**Bank-layout file (recommended)** — one line per bank, `bank <N>, "mod,mod"`:

```
# examples\twobank.banks
bank 22, "shapes,bitmap2h"
bank 23, "string"
```
```powershell
.\build.ps1 examples\twobank.p8 -BankFile examples\twobank.banks
```
That yields a **503-byte** main PRG plus `build\BANK22.BIN` (graphics) and
`build\BANK23.BIN` (strings) — the whole library footprint is out of low RAM.

**Inline single bank** (shorthand for one line):
```powershell
.\build.ps1 examples\shapes.p8 -Bank "shapes,bitmap2h" -BankNum 22
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
TIFF, …), plus HEIC/HEIF when `pillow-heif` is installed. `examples/imgview.p8`
shows it with a single library call:

```powershell
python tools\img2bmx.py photo.jpg build\IMAGE.BMX     # fit + letterbox (--stretch to fill)
.\build.ps1 examples\imgview.p8 -Run
```

```prog8
cx.gfx8h_init()                                   ; 640x480 @ 8bpp (needs -bitmap2)
cx.bmx_load_hires(&filename, len(filename), 8)    ; palette + 307 KB of pixels, one call
```

The 307 KB of image data never touches main RAM — it streams straight from disk
into VERA_2 SDRAM, so the program stays ~3 KB. `cx.bmx_load_hires` requires
X16_Library ≥ v0.11.6. (Filenames are lowercase in the source on purpose — Prog8's
PETSCII maps `a-z` to `$41-$5A`, which the KERNAL reads as the upper-case host name.)

## The call ABI

The wrappers mirror the library's conventions exactly:

* Up to three byte/word arguments go in `A` / `X` / `Y`; anything more goes in
  the zero-page block `X16_P0..P7` (`$22`–`$29`). The generator emits the right
  loads for each routine.
* Word arguments are passed whole (the wrapper splits them into low/high).
* **Return values** (`-> ubyte` / `-> uword` / `-> bool`) are *best-effort*,
  derived from each routine's header note (register in `A`, `A/X`, or carry).
  When a routine returns something more elaborate, consult the X16_Library docs.

Example — a filled rounded rectangle (all args in the P block, colour in `A`):

```prog8
cx.shape_frrect(40, 40, 200, 110, 28, 1)
```

## Coverage

The wrapper exposes **519 routines** across every X16_Library module — VERA,
screen, palette, sprites, tiles, all six bitmap engines, shapes (circle, disc,
poly, rrect, arc, pie, bezier), graph/framebuffer/console, PSG/YM/PCM/ADPCM and
the ROM-audio API, serial/I2C/SPI/ZiModem, keyboard/mouse, clock, banking,
file/DOS/IEC, math, strings, BCD, fixed/float/double, and more — plus **423
constants**. Any of them can be called; only the modules you use are linked.

The only routines not wrapped are those whose "friendly macro" does
assemble-time arithmetic on an argument (they assume a compile-time constant and
can't be driven with a runtime value). Call those directly via inline asm.

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

The library owns ZP `$22-$31`. Prog8's `%zeropage basicsafe` allocates its own
variables from a free list and generally coexists; if you hit corruption in a
program that leans heavily on both, use `%zeropage dontuse` (slower, but keeps
ZP entirely clear for the library).
