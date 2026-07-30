# X16_Library User Guide

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

X16_Library is an assembly library for the Commander X16: write 6502 programs
without re-deriving the machine's hardware surface every time. This guide
explains every routine — its parameters, its results, and a small working
example for each.

All examples are in **ACME** syntax (the reference dialect). The library also
ships as native ca65, 64tass and KickAssembler source trees with identical
routine contracts — see [Using another assembler](#using-another-assembler)
for the dialect differences. Everything else in this guide (registers,
parameters, behaviour) applies to all four unchanged.

---

## Table of contents

1. [Getting started](#getting-started)
2. [Core conventions](#core-conventions)
3. [Macros](#macros)
4. [VERA data ports (`X16_USE_VERA`)](#vera-data-ports)
5. [VERA display composer (`X16_USE_VERA_DC`)](#vera-display-composer)
6. [Screen and text (`X16_USE_SCREEN`)](#screen-and-text)
7. [Palette (`X16_USE_PALETTE`)](#palette)
8. [Tiles and layers (`X16_USE_TILE`)](#tiles-and-layers)
9. [Sprites (`X16_USE_SPRITE`)](#sprites)
10. [Bitmap graphics (`X16_USE_BITMAP8L/2H/2L/4L/4H/8H`)](#bitmap-graphics)
11. [Framebuffer, GRAPH and console (`X16_USE_FB`, `X16_USE_GRAPH`, `X16_USE_CONSOLE`)](#framebuffer-graph-and-console)
12. [Shapes (`X16_USE_SHAPES` and sub-gates)](#shapes)
13. [VERA FX (`X16_USE_VERAFX`)](#vera-fx)
14. [VERA FX utilities (`X16_USE_VERAFX_UTILS`)](#vera-fx-utilities)
15. [Interrupts (`X16_USE_IRQ`)](#interrupts)
16. [PSG audio (`X16_USE_PSG`)](#psg-audio)
17. [YM2151 FM synthesis (`X16_USE_YM`)](#ym2151-fm-synthesis)
18. [ROM audio API (`X16_USE_AUDIO_ROM`)](#rom-audio-api)
19. [PCM audio (`X16_USE_PCM`, `X16_USE_PCM_STREAM`)](#pcm-audio)
20. [ZSM playback (`X16_USE_ZSM`, `X16_USE_ZSM_PCM`)](#zsm-playback)
21. [ADPCM decoding (`X16_USE_ADPCM`)](#adpcm-decoding)
22. [Input (`X16_USE_INPUT`, `X16_USE_KEYBOARD`, `X16_USE_MOUSE`)](#input)
23. [Serial, WiFi, I2C and SPI](#serial-wifi-i2c-and-spi)
24. [Banked RAM (`X16_USE_BANK`)](#banked-ram)
25. [Bank allocator (`X16_USE_BANKALLOC`)](#bank-allocator)
26. [HIRAM stack and ringbuffer (`X16_USE_STACK`, `X16_USE_RINGBUFFER`)](#hiram-stack-and-ringbuffer)
27. [Block memory operations (`X16_USE_MEM`)](#block-memory-operations)
28. [Loading, saving, file I/O and IEC](#loading-saving-file-io-and-iec)
29. [DOS commands (`X16_USE_DOS`)](#dos-commands)
30. [BMX images (`X16_USE_BMX`)](#bmx-images)
31. [Clock and RTC (`X16_USE_CLOCK`)](#clock-and-rtc)
32. [Game math (`X16_USE_MATH`)](#game-math)
33. [Line clipping (`X16_USE_CLIP`)](#line-clipping)
34. [Ring buffer and stack (`X16_USE_BUFFERS`)](#ring-buffer-and-stack)
35. [Compression (`X16_USE_ZX0`, `X16_USE_TSC`)](#compression)
36. [Fixed point (`X16_USE_FIXED`)](#fixed-point)
37. [Collision (`X16_USE_COLLIDE`)](#collision)
38. [Bit helpers (`X16_USE_BITS`)](#bit-helpers)
39. [Number formatting (`X16_USE_NUMBER`)](#number-formatting)
40. [BCD arithmetic (`X16_USE_BCD`)](#bcd-arithmetic)
41. [16-bit integers (`X16_USE_INT16`)](#16-bit-integers)
42. [32-bit integers (`X16_USE_INT32`)](#32-bit-integers)
43. [Floating point (`X16_USE_FLOAT`)](#floating-point)
44. [Double precision (`X16_USE_DOUBLE`)](#double-precision)
45. [Strings (`X16_USE_STRING` and friends)](#strings)

---

## Getting started

### A minimal program

```prog8
%import x16lib



main {
    sub start() {
        %asm {{
            lda #<hello
            ldx #>hello
            jsr screen_puts
        }}
    }
}

%asm {{
    hello !text "HELLO, X16!", $0D, $00
}}

```

Assemble with the source tree on the include path and run it:

```
acme\acme -I src_acme -f cbm -o build\HELLO.PRG myprog.asm
emulator\x16emu -prg build\HELLO.PRG -run
```

Two rules, both enforced by ACME's pass model:

1. `x16.asm` comes **before** any code — macros must be defined before use.
2. `x16_code.asm` is sourced **exactly once**, wherever you want the
   library's machine code to sit (normally after your own code), and all
   `X16_USE_*` gates are defined before it.

### Picking modules

ACME has no linker, so unused routines can't be stripped automatically.
Instead, define only the gates you need. Each fine-grained gate pulls in one
source module, and section gates expand to a whole library area.
Dependencies resolve themselves (e.g. `X16_USE_SPRITE` pulls in
`X16_USE_VERA`; `X16_USE_PCM_STREAM` pulls in PCM and IRQ).

| Section gate | Enables |
|---|---|
| `X16_USE_VIDEO` | VERA, display composer, screen, palette, tile, and sprite modules. |
| `X16_USE_GRAPHICS` | Bitmap engines, shapes, framebuffer, graph, console, VERA FX, and VERA FX utilities. |
| `X16_USE_AUDIO` | PSG, YM, ROM audio wrappers, ZSM, PCM streaming, and ADPCM. |
| `X16_USE_INPUT_DEVICES` | Legacy input, keyboard, and mouse modules. |
| `X16_USE_COMMUNICATIONS` | I2C, VERA SPI, serial, and ZiModem modules. |
| `X16_USE_STORAGE` | Banked RAM, bank allocator, HIRAM stack/ring, memory, file I/O, IEC, LOAD/SAVE, DOS, and BMX. |
| `X16_USE_UTILITIES` | Math, clipping, buffers, compression, fixed point, BCD, collision, bits, number, integer, float, and double modules. |
| `X16_USE_STRINGS` | All five string modules. |
| `X16_USE_SYSTEM` | IRQ and clock modules. |

### Using another assembler

The same library exists as four native source trees with the same layout,
gates and contracts, each paired with a repo-local toolchain folder:

| Port | Sources | Toolchain | Build script |
|---|---|---|---|
| ACME (reference) | `src_acme\` | `acme\acme.exe` | `build_acme.ps1` |
| ca65 | `src_ca65\` | `cc65\ca65.exe` + `ld65.exe` | `build_ca65.ps1` |
| 64tass | `src_64tass\` | `64tass\64tass.exe` | `build_64tass.ps1` |
| KickAssembler | `src_kick\` | `kickass\KickAss.jar` | `build_kick.ps1` |

Dialect differences from the ACME examples in this guide:

- **ca65** — `.include "x16.asm"` instead of `!source`, no `+` prefix on
  macro calls, `X16_USE_*` gating via symbol definitions before the include.
- **64tass** — same `%import x16lib` spelling as ACME; gates default to 0
  via `.weak`.
- **KickAssembler** — `#define X16_USE_*` before `#import "x16_code.asm"`;
  zero-page overrides go before the `x16.asm` import.

There is also a **prebuilt binary** route needing no source tree at all:
`dist\x16lib.bin` (the whole library at `$5800`) plus a generated
`x16lib.inc` binding per dialect. See the README's "Prebuilt binary +
bindings" section.

---

## Core conventions

### Registers and the parameter block

Every routine takes small arguments in `A`, `X`, `Y`. When a routine needs
more than three bytes, the extra arguments go in the **parameter block** —
16 bytes of zero page at `$22` (relocatable: define `X16_ZP` before
sourcing `x16.asm`):

| Name | Bytes | Role |
|---|---|---|
| `X16_P0`..`X16_P7` | 8 | routine parameters (yours to write before a call) |
| `X16_T0`..`X16_T7` | 8 | library-private scratch — never rely on it across a call |
| `X16_PTR0`..`X16_PTR3` | — | 16-bit aliases over `P0/P1`, `P2/P3`, `P4/P5`, `P6/P7` |

Ground rules:

- `A`, `X`, `Y` and the flags are **clobbered** unless a routine's contract
  says otherwise.
- The parameter block is **caller-save**: some routines consume it
  (documented per routine).
- The KERNAL's virtual registers `r0`–`r15` (`$02`–`$21`) are available as
  named symbols; the library uses `r0`–`r5` freely.
- Errors come back in the **carry flag**: carry set = failure, with an
  error code in `A` where there is one.

Loading a 16-bit parameter looks like this throughout the guide:

```prog8
%asm {{
    lda #<320
    sta X16_P0
    lda #>320
    sta X16_P1
}}
```

### Values with their own registers

Three module families operate on values too wide for the parameter block.
They use named memory "registers" you write directly: `i16_a`/`i16_b`
(16-bit ints), `i32_a`/`i32_b` (32-bit), `cl_ax`.. (collide16),
`tri_x0`.. (fx_triangle), `clipl_x0`.. (clip_line). Each is documented in
its section.

### Interrupt safety

Everything here assumes main-program context. To call library routines
from an interrupt callback, bracket them with `irq_save_regs` /
`irq_restore_regs` — see [Interrupts](#interrupts).

---

## Macros

Defined in `core/macros.asm`, available after `%import x16lib`. Macros
emit inline code — no `jsr` needed, but also no gate required.

> These are the low-level plumbing macros. There is also an optional,
> higher-level convenience layer — `core/sugar.asm`, one `cx.xm_<routine>` macro
> per library call — documented separately in the [Macro Guide](macroguide.md).

### `cx.vera_addr(port, addr, inc)` — point a data port at VRAM

The workhorse. Points VERA data port 0 or 1 at a 17-bit VRAM address with
an auto-increment. `inc` is an **index**, not a byte amount — use the
`VERA_INC_*` constants (`VERA_INC_0/1/2/4/…/512` plus the special strides
`VERA_INC_40/80/160/320/640`). Clobbers `A` and flags.

```prog8
cx.vera_addr(0, VRAM_TEXT, VERA_INC_2)  ; text map, step 2 = chars only
%asm {{
    lda #$51; screen code of a ball
    sta VERA_DATA0; write, port steps by 2
    sta VERA_DATA0
}}
```

`cx.vera_addr_decr()` is the same with the port stepping backwards.

### `cx.vpoke(addr, value)` — one-off VRAM write

```prog8
cx.vpoke(VRAM_TEXT + 2*40, $01)  ; poke a char at row 1, col 0
```

### `cx.vera_addrsel(port)` — select which port's address registers show

`ADDRSEL` (bit 0 of `VERA_CTRL`) picks which port's `ADDR_L/M/H` are
visible at `$9F20`–`$9F22`. Done with read-modify-write so the `DCSEL`
field is preserved. Note `DATA0`/`DATA1` always talk to port 0/1
regardless of `ADDRSEL`.

```prog8
cx.vera_addrsel(0)  ; the KERNAL requires ADDRSEL = 0
```

### `cx.vera_dcsel(n)` — select the banked register set (0–63)

The registers at `$9F29`–`$9F2C` are banked by `DCSEL`. This macro
preserves `ADDRSEL` and never writes bit 7 (which would reset VERA).

```prog8
cx.vera_dcsel(2)  ; FX_CTRL bank
```

### `cx.set_rambank(n)` / `cx.set_rombank(n)` — bank switching

```prog8
cx.set_rambank(4)  ; bank 4 now visible at $A000-$BFFF
```

### `cx.jsrfar(addr, bank)` — call into another ROM/RAM bank

The KERNAL's own far-call mechanism (`$FF6E`): saves the caller's bank,
switches, calls, restores — preserving `A`, `X`, `Y` and flags, reentrant
(IRQ-safe). Do not hand-roll this.

```prog8
%asm {{
    lda #0; channel 0
    ldx #64; attenuation
}}
cx.jsrfar(rom_ym_setatten, BANK_AUDIO)
```

`cx.rom_call_fast(bank, entry)` is ~40 cycles cheaper but clobbers `A`,
leaves `ROM_BANK` switched, and is not IRQ-safe. You restore the bank
yourself.

### `cx.i16_const(dest, value)` / `cx.i32_const(dest, value)` — load literals

Load a 16/32-bit literal into a little-endian buffer (made for `i16_a`,
`i32_a` and friends).

```prog8
cx.i16_const(i16_a, 1000)
cx.i32_const(i32_b, 100000)
```

### `cx.basic_stub()` — autorun header

Emits `10 SYS 2061`. Must be the very first thing at `$0801`; your code
then starts immediately after (at `$080D` = 2061).

```prog8
main {
    sub start() {
    }
}
```

---

## VERA data ports

`X16_USE_VERA` — `video/vera.asm`. VRAM is reached through two
auto-incrementing data ports; these routines are the runtime counterparts
of the `cx.vera_addr()` macro plus the two bulk primitives everything else
builds on.

Fine-grained gates exist for size-sensitive builds: `X16_USE_VERA_CORE`
provides address setup/fill/probing, and `X16_USE_VERA_COPY` adds
`vera_copy`. The umbrella `X16_USE_VERA` enables both.

### `vera_set_addr0` / `vera_set_addr1` — point a port at a runtime address

- **In:** `A` = `ADDR_L`, `X` = `ADDR_M`, `Y` = `ADDR_H` (bank bit |
  `VERA_ADDR_H_DECR` | increment index << 4)

For addresses known at assembly time, prefer `cx.vera_addr()`.

```prog8
%asm {{
    lda my_addr; low byte, computed at run time
    ldx my_addr+1; middle byte
    ldy #(VERA_INC_1 << 4); bank 0, increment 1
    jsr vera_set_addr0
}}
```

### `vera_fill` — write one value N times through port 0

- **In:** `A` = byte value, `X`/`Y` = count low/high (16-bit; 0 writes nothing)
- **Pre:** port 0 already points at the destination with the increment you want

```prog8
cx.vera_addr(0, VRAM_TEXT, VERA_INC_2)
%asm {{
    lda #$2A; '*'
    ldx #<80
    ldy #>80
    jsr vera_fill; a row of stars
}}
```

The increment gives it shapes: `VERA_INC_320` stripes down a bitmap
column, `VERA_INC_2` walks the text map touching only characters.

### `vera_copy` — VRAM-to-VRAM copy, both ports

- **In:** `X`/`Y` = count low/high
- **Pre:** port 0 points at the **source**, port 1 at the **destination**,
  each with its own increment

```prog8
cx.vera_addr(0, VRAM_BITMAP, VERA_INC_1)  ; read from row 0
cx.vera_addr(1, VRAM_BITMAP + 320, VERA_INC_1)  ; write to row 1
%asm {{
    ldx #<320
    ldy #>320
    jsr vera_copy; duplicate a scanline
}}
```

Leaves `ADDRSEL` on port 1 — emit `cx.vera_addrsel(0)` before calling the
KERNAL afterwards (or print via `screen_chrout`, which does it for you).

### `vera_has_fx` — probe for the FX register set

- **Out:** carry set if the VERA firmware has FX (v0.3.1+); `A` = major
  version when carry is set

```prog8
%asm {{
    jsr vera_has_fx
    bcc no_fx; fall back to gfx8l_line etc.
    jsr fx_line
}}
```

---

## VERA display composer

`X16_USE_VERA_DC` - `video/vdc.asm`. These helpers wrap the display composer
registers behind `DCSEL`: output mode, visible layers, scale, border, active
display area and bitstream version. They leave `DCSEL = 0`.

### Video control and output

- `vdc_get_video` - out: `A = DC_VIDEO`.
- `vdc_set_video` - in: `A = DC_VIDEO`; bit 7 is ignored so it cannot reset VERA.
- `vdc_set_output` - in: `A = VERA_VIDEO_MODE_*`; preserves layer/chroma bits.
- `vdc_set_layers` - in: `A = VERA_VIDEO_LAYER0_EN | LAYER1_EN | SPRITES_EN`.
- `vdc_layer_on` / `vdc_layer_off` - set/clear layer enable bits in `A`.

### Scale, border and active display

- `vdc_get_scale` - out: `A = HSCALE`, `X = VSCALE`.
- `vdc_set_scale` - in: `A = HSCALE`, `X = VSCALE` (`$80` is 1:1).
- `vdc_get_border` / `vdc_set_border` - get/set the border palette index in `A`.
- `vdc_get_active_raw` - out: `A = HSTART`, `X = HSTOP`, `Y = VSTART`, `r0L = VSTOP`.
- `vdc_set_active_raw` - in: `A/X/Y/r0L` in the same raw register format.
- `vdc_set_active` - in: `X16_P0/P1 = hstart`, `P2/P3 = hstop`,
  `P4/P5 = vstart`, `P6/P7 = vstop`, in pixels.
- `vdc_fullscreen` - active area 0,0 to 640,480.
- `vdc_get_version` - carry set if valid; out: `A = major`, `X = minor`, `Y = build`.

Use the raw form when you already have VERA register values. Use
`vdc_set_active` for pixel coordinates; it converts horizontal `/4` and
vertical `/2` for you.

## Screen and text

`X16_USE_SCREEN` — `video/screen.asm`. Text output, screen modes, colours.
These wrappers exist because several KERNAL screen routines silently
require `ADDRSEL = 0`; every routine here that enters the KERNAL
establishes that first.

`X16_USE_SCREEN` enables both `X16_USE_SCREEN_CORE` and
`X16_USE_SCREEN_EXTRA`; the split gates exist for generated/prebuilt
size models.

### `screen_set_mode` — set the screen mode

- **In:** `A` = mode: `$00` 80×60, `$01` 80×30, `$02` 40×60, `$03` 40×30,
  `$04` 40×15, `$05` 20×30, `$06` 20×15, `$07` 22×23, `$08` 64×50,
  `$09` 64×25, `$0A` 32×50, `$0B` 32×25, `$80` 320×240@256c bitmap + 40×30 text
- **Out:** carry clear on success, set if the mode is unsupported

```prog8
%asm {{
    lda #$03; 40x30 text
    jsr screen_set_mode
}}
```

### `screen_get_mode` — read the current mode

- **Out:** `A` = mode

### `screen_reset` — restore the default text mode (KERNAL `CINT`)

### `screen_cls` — clear the text screen

```prog8
%asm {{
    jsr screen_cls
}}
```

### `screen_chrout` — print one character, safely

- **In:** `A` = PETSCII character

`CHROUT` with the `ADDRSEL = 0` precondition established. Use this (not
raw `CHROUT`) any time you may have touched data port 1.

```prog8
%asm {{
    lda #PETSCII_RETURN
    jsr screen_chrout
}}
```

### `screen_puts` — print a NUL-terminated string

- **In:** `A` = address low, `X` = address high (strings > 255 bytes are
  truncated)

```prog8
%asm {{
    lda #<msg
    ldx #>msg
    jsr screen_puts
    ...
    msg !text "SCORE: ", $00
}}
```

### `screen_color` — set the text colour

- **In:** `A` = foreground (0–15), `X` = background (0–15)

Affects every subsequent character print. Touches no VERA state.

```prog8
%asm {{
    lda #5; green ink
    ldx #0; black paper
    jsr screen_color
}}
```

### `screen_border` — set the border colour

- **In:** `A` = colour (0–15)

```prog8
%asm {{
    lda #2; red border
    jsr screen_border
}}
```

### `screen_locate` / `screen_get_cursor` — move/read the text cursor

- **In (locate):** `X` = row, `Y` = column
- **Out (get_cursor):** `X` = row, `Y` = column

```prog8
%asm {{
    ldx #10
    ldy #5
    jsr screen_locate; row 10, column 5
    lda #<msg : ldx #>msg
    jsr screen_puts
}}
```

### `screen_charset` — select a charset

- **In:** `A` = charset (1 = ISO, 2 = PETSCII upper/graphics,
  3 = PETSCII upper/lower, … 12 = Katakana)

```prog8
%asm {{
    lda #3; upper/lower
    jsr screen_charset
}}
```

---

## Palette

`X16_USE_PALETTE` — `video/palette.asm`. 256 entries × 2 bytes at VRAM
`$1FA00`; a 12-bit `$0RGB` colour stores little-endian: byte 0 =
`Green<<4 | Blue`, byte 1 = `Red`.

### `pal_set` — set one palette entry

- **In:** `X` = palette index (0–255), `A` = low byte (`G<<4|B`),
  `Y` = high byte (`R`)

```prog8
%asm {{
    ldx #1; entry 1 = pure red ($0F00)
    lda #$00
    ldy #$0F
    jsr pal_set
}}
```

### `pal_load` — bulk-load entries from RAM

- **In:** `X16_PTR0` = source (2 bytes/entry, low byte first),
  `A` = first index, `X` = entry count (1–128; 0 loads nothing)

```prog8
%asm {{
    lda #<mypal : sta X16_P0
    lda #>mypal : sta X16_P1
    lda #16; start at entry 16
    ldx #4; four entries
    jsr pal_load
    ...
    mypal !word $0000, $0F00, $00F0, $000F; black, red, green, blue
}}
```

Caution: the palette region of VRAM is write-only — reads return the last
value *you* wrote, not the hardware state after a reset.

---

## Tiles and layers

`X16_USE_TILE` — `video/tile.asm`. Layer configuration for both layers,
plus cell access to layer 1's tilemap (the text screen in the default
modes). The `tile_*` routines read `L1_CONFIG`/`L1_MAPBASE` at run time,
so they keep working after a mode change.

### `layer_on` / `layer_off` — enable/disable a layer

- **In:** `A` = layer (0 or 1)

```prog8
%asm {{
    lda #0
    jsr layer_on; show layer 0
}}
```

### `layer_set_config` — the layer's CONFIG byte

- **In:** `X` = layer, `A` = config: map height (7:6) | map width (5:4) |
  `VERA_LAYER_T256C` | `VERA_LAYER_BITMAP` | bpp (1:0)

```prog8
%asm {{
    ldx #0
    lda #(VERA_LAYER_MAPW_64 | VERA_LAYER_MAPH_32 | VERA_LAYER_BPP_4)
    jsr layer_set_config; 64x32 map of 4bpp tiles
}}
```

### `layer_set_mapbase` — where the map lives

- **In:** `X` = layer, `A` = VRAM address >> 9 (so the map is 512-byte
  aligned)

```prog8
%asm {{
    ldx #0
    lda #($10000 >> 9); map at VRAM $10000
    jsr layer_set_mapbase
}}
```

### `layer_set_tilebase` — where the tile images live

- **In:** `X` = layer, `A` = (base >> 11) << 2 | tile size bits
  (bit 0 = 16-px wide, bit 1 = 16-px tall)

```prog8
%asm {{
    ldx #0
    lda #(($12000 >> 11) << 2); 8x8 tiles at VRAM $12000
    jsr layer_set_tilebase
}}
```

### `layer_scroll_x` / `layer_scroll_y` — 12-bit hardware scroll

- **In:** `X` = layer, `X16_P0/P1` = scroll value (0–4095)

```prog8
%asm {{
    ldx #0
    lda scroll : sta X16_P0
    lda scroll+1 : sta X16_P1
    jsr layer_scroll_x; smooth-scroll layer 0
}}
```

### `tile_setptr` — point port 0 at a layer-1 map cell

- **In:** `X` = column, `Y` = row

Leaves `ADDRSEL = 0`, so it is KERNAL-safe afterwards.

### `tile_put` — write one cell

- **In:** `X` = column, `Y` = row, `X16_P0` = screen code,
  `X16_P1` = attribute (fg | bg<<4)

```prog8
%asm {{
    ldx #5; column 5
    ldy #3; row 3
    lda #$51 : sta X16_P0; ball glyph
    lda #$61 : sta X16_P1; white on dark grey
    jsr tile_put
}}
```

### `tile_get` — read one cell

- **In:** `X` = column, `Y` = row
- **Out:** `A` = screen code, `X` = attribute

```prog8
%asm {{
    ldx #5
    ldy #3
    jsr tile_get; what's at (5,3)?
    cmp #$51
    beq hit_ball
}}
```

---

## Sprites

`X16_USE_SPRITE` — `sprite/sprite.asm`. 128 hardware sprites, one 8-byte
attribute record each at VRAM `$1FC00`. That region is **write-only**:
read-modify-write routines (`sprite_z`) only work on records this program
already initialised — call `sprite_init_all` first.

### `sprite_init_all` — zero all 128 records

Disables every sprite and gives the write-only attribute RAM a known
shadow. Call once at startup.

```prog8
%asm {{
    jsr sprite_init_all
    jsr sprites_on
}}
```

### `sprites_on` / `sprites_off` — the sprite renderer as a whole

### `sprite_image` — point a sprite at its pixel data

- **In:** `X` = sprite (0–127), `X16_P0` = address low, `X16_P1` = address
  mid, `X16_P2` = address bit 16, `A` = `SPRITE_MODE_4BPP` or
  `SPRITE_MODE_8BPP`

The record stores address bits 16:5, so the image data must be 32-byte
aligned.

```prog8
%asm {{
    ldx #0; sprite 0
    lda #<$13000 : sta X16_P0; image at VRAM $13000
    lda #>$13000 : sta X16_P1
    lda #0       : sta X16_P2
    lda #SPRITE_MODE_8BPP
    jsr sprite_image
}}
```

### `sprite_pos` — set the 10-bit position

- **In:** `X` = sprite, `X16_P0/P1` = x, `X16_P2/P3` = y

```prog8
%asm {{
    ldx #0
    lda #<160 : sta X16_P0
    lda #>160 : sta X16_P1
    lda #120  : sta X16_P2
    stz X16_P3
    jsr sprite_pos; centre of a 320x240 screen
}}
```

### `sprite_get_pos` — read the position back

- **In:** `X` = sprite. **Out:** `X16_P0/P1` = x, `X16_P2/P3` = y

### `sprite_flags` — collision mask, Z-depth, flips (attribute byte 6)

- **In:** `X` = sprite, `A` = collision<<4 | Z | vflip | hflip

```prog8
%asm {{
    ldx #0
    lda #(SPRITE_Z_FRONT | SPRITE_HFLIP)
    jsr sprite_flags; visible in front, mirrored
}}
```

### `sprite_z` — change only the Z-depth

- **In:** `X` = sprite, `A` = `SPRITE_Z_DISABLED`/`BEHIND`/`MIDDLE`/`FRONT`

Read-modify-write on byte 6, preserving mask and flips. `SPRITE_Z_DISABLED`
hides the sprite without losing its setup.

```prog8
%asm {{
    ldx #0
    lda #SPRITE_Z_DISABLED
    jsr sprite_z; hide sprite 0
}}
```

### `sprite_size` — size codes and palette offset (attribute byte 7)

- **In:** `X` = sprite, `A` = width code, `Y` = height code
  (`SPRITE_SIZE_8/16/32/64`), `X16_P0` = palette offset (0–15)

```prog8
%asm {{
    ldx #0
    lda #SPRITE_SIZE_16
    tay; 16x16
    stz X16_P0; palette offset 0
    jsr sprite_size
}}
```

---

## Bitmap graphics

Bitmap gates are now explicit about resolution and storage. Low (`L`) engines
use normal VERA VRAM; high (`H`) engines use the MiSTer VERA_2 SDRAM bitmap
layer. Select the exact format you want, or use `X16_USE_GRAPHICS` when a
whole graphics-section build is really what you need.

| Gate | File | Geometry | Prefix |
|---|---|---|---|
| `X16_USE_BITMAP8L` | `gfx/bitmap8l.asm` | 320x240, 8 bpp | `gfx8l_*` |
| `X16_USE_BITMAP4L` | `gfx/bitmap4l.asm` | 320x240, 4 bpp | `gfx4l_*` |
| `X16_USE_BITMAP2L` | `gfx/bitmap2l.asm` | 320x240, 2 bpp | `gfx2l_*` |
| `X16_USE_BITMAP2H` | `gfx/bitmap2h.asm` | 640x480, 2 bpp | `gfx2h_*` |
| `X16_USE_BITMAP4H` | `gfx/bitmap4h.asm` | 640x480, 4 bpp | `gfx4h_*` |
| `X16_USE_BITMAP8H` | `gfx/bitmap8h.asm` | 640x480, 8 bpp | `gfx8h_*` |

### Low-resolution bitmap engines

`gfx8l_*`, `gfx4l_*` and `gfx2l_*` cover 320x240 drawing. The 8L and 4L
families include bitmap text helpers; the 2L family is pixel/shape oriented.

- `gfx8l_init`, `gfx4l_init`, `gfx2l_init` - initialize the corresponding bitmap mode.
- `*_clear` - in: `A = colour`.
- `*_setptr` where present - point VERA port 0 at `(x,y)` with an increment.
- `*_pset` - in: `X16_P0/P1 = x`, `X16_P2 = y`, `X16_P3 = colour`.
- `*_read` - in: coordinates as above; out: `A = colour`.
- `*_hline` / `*_vline` - line spans.
- `*_rect` / `*_frame` - filled and outline rectangles.
- `*_line` - Bresenham line.
- `*_pattern_set` / `*_pattern_rect` - 8x8 pattern fill.
- `gfx8l_char/text` and `gfx4l_char/text` - bitmap glyph and string drawing.
- `*_blit` / `*_blitm` - source-image blit; `blitm` uses colour-key masking.

The shape module defaults to `gfx2h_*`, but you can bind `SHP_PSET`, `SHP_READ`,
`SHP_HLINE`, `SHP_W` and `SHP_H` before sourcing code to draw through another
engine; see [Shapes](#shapes).

### High-resolution bitmap engines

`gfx2h_*`, `gfx4h_*` and `gfx8h_*` target 640x480. The 4H and 8H gates use the
new VERA_2 SDRAM layer and provide capability/setup helpers:

- `gfx4h_has` / `gfx8h_has` - carry set if the required VERA_2 layer is present.
- `gfx4h_init` / `gfx8h_init` and `gfx4h_off` / `gfx8h_off` - enable/disable.
- `gfx4h_passthru_on/off` / `gfx8h_passthru_on/off` - pass-through controls.
- `gfx4h_pal_set/load` / `gfx8h_pal_set/load` - SDRAM-layer palette helpers.
- `gfx4h_copy` / `gfx8h_copy` - copy SDRAM bitmap bytes.

The drawing family otherwise mirrors the low engines: `clear`, `setptr`,
`pset`, `read`, `hline`, `vline`, `rect`, `frame`, `line`, `pattern_set`,
`pattern_rect`, `blit` and `blitm`.

---

## Framebuffer, GRAPH and console

These three gates are thin wrappers around stable ROM/KERNAL APIs. They are
separate opt-ins so a program can use one layer without carrying the others.

### Framebuffer (`X16_USE_FB`)

`gfx/fb.asm` wraps the active KERNAL framebuffer driver. The default ROM driver
is 320x240 at 8 bpp, but GRAPH can install another driver.

- `fb_init` - initialize the active framebuffer driver.
- `fb_get_info` - out: `r0 = width`, `r1 = height`, `A = colour depth`.
- `fb_set_palette` - in: `r0 = palette data`, `A = start`, `X = count` (`0 = 256`).
- `fb_cursor_position` - in: `r0 = x`, `r1 = y`.
- `fb_cursor_next_line` - advance to the next scanline.
- `fb_get_pixel` / `fb_set_pixel` - read/write at the current cursor (`A = colour`).
- `fb_get_pixels` / `fb_set_pixels` - in: `r0 = memory pointer`, `r1 = count`.
- `fb_set_8_pixels` - in: `A = pattern`, `X = foreground`.
- `fb_set_8_pixels_opaque` - in: `A = mask`, `r0L = pattern`, `X = foreground`, `Y = background`.
- `fb_fill_pixels` - in: `r0 = count`, `r1 = step`, `A = colour`.
- `fb_filter_pixels` - in: `r0 = count`, `r1 = filter routine`; filter maps `A old -> A new`.
- `fb_move_pixels` - in: `r0 = sx`, `r1 = sy`, `r2 = tx`, `r3 = ty`, `r4 = count`.

### GRAPH (`X16_USE_GRAPH`)

`gfx/graph.asm` wraps the ROM GRAPH layer on top of the current framebuffer.

- `graph_init` - in: `r0 = FB_* driver pointer`, or `0` for default 320x240@8bpp.
- `graph_clear` - clear current GRAPH window to background colour.
- `graph_set_window` - in: `r0 = x`, `r1 = y`, `r2 = width`, `r3 = height`; all zero resets to full screen.
- `graph_set_colors` - in: `A = primary/stroke`, `X = secondary/fill`, `Y = background`.
- `graph_draw_line` - in: `r0 = x1`, `r1 = y1`, `r2 = x2`, `r3 = y2`.
- `graph_draw_rect` - in: `r0 = x`, `r1 = y`, `r2 = width`, `r3 = height`, `r4 = radius`; carry clear outline, carry set fill.
- `graph_move_rect` - in: `r0 = sx`, `r1 = sy`, `r2 = tx`, `r3 = ty`, `r4 = width`, `r5 = height`.
- `graph_draw_oval` - same rectangle input; carry clear outline, carry set fill.
- `graph_draw_image` - in: `r0 = x`, `r1 = y`, `r2 = image`, `r3 = width`, `r4 = height`.
- `graph_set_font` - in: `r0 = font pointer`, or `0` for system font.
- `graph_get_char_size` - in: `A = character`, `X = GRAPH_STYLE_*`; out: printable `C=0`, `A = baseline`, `X = width`, `Y = height`; control `C=1`, `X = new style`.
- `graph_put_char` - in: `A = character`, `r0 = x`, `r1 = y`; out: updated `r0/r1`, carry set if outside bounds.

### Console (`X16_USE_CONSOLE`)

`gfx/console.asm` wraps the ROM console API. It renders through GRAPH but is a
separate gate.

- `con_init` - in: `r0 = x`, `r1 = y`, `r2 = width`, `r3 = height`; all zero uses the full GRAPH window.
- `con_set_paging_message` - in: `r0 = zero-terminated prompt`.
- `con_disable_paging` - disable the pause prompt.
- `con_put_char` - in: `A = character`, carry clear character-wrap, carry set word-wrap.
- `con_get_char` - out: `A = character`.
- `con_put_image` - in: `r0 = image`, `r1 = width`, `r2 = height`.

---
## Shapes

`X16_USE_SHAPES` - `gfx/shapes.asm`. The shape routines are engine-agnostic:
they draw through `SHP_PSET`, `SHP_READ` and `SHP_HLINE`, and read bounds from
`SHP_W`/`SHP_H`. By default those bind to the high-resolution 2 bpp bitmap
engine (`gfx2h_*`). Predefine those symbols before sourcing `x16_code.asm` to
bind shapes to another bitmap engine.

### Core shapes (`X16_USE_SHAPES`)

- `shape_circle` / `shape_disc` - in: `X16_P0/P1 = cx`, `P2/P3 = cy`, `P4 = radius`, `A = colour`. Circle plots through `SHP_PSET`; disc fills spans through `SHP_HLINE`.
- `shape_ellipse` / `shape_fellipse` - in: `P0/P1 = cx`, `P2/P3 = cy`, `P4 = rx`, `P5 = ry`, `A = colour`.
- `shape_flood` - in: `P0/P1 = x`, `P2/P3 = y`, `A = colour`; carry set if the seed stack overflowed.

### Shape sub-gates

- `X16_USE_SHAPES_POLY` - `shape_polygon` / `shape_fpolygon`; regular convex N-gons, uses `X16_USE_MATH` for `sin8`/`cos8`.
- `X16_USE_SHAPES_RRECT` - `shape_rrect` / `shape_frrect`; rounded rectangle outline/fill.
- `X16_USE_SHAPES_ARC` - `shape_arc`; circle arc between two byte angles, pulls the shared line helper.
- `X16_USE_SHAPES_PIE` - `shape_pie`; filled wedge, pulls `SHAPES_ARC`.
- `X16_USE_SHAPES_BEZIER` - `shape_bezier`; cubic Bezier through four control points.

Angles use the same byte convention as `sin8`: `0 = east`, `64 = south`, one
full turn is 256.

---
## VERA FX

`X16_USE_VERAFX` — `gfx/verafx.asm`. Hardware multiply, cached
fills/copies, line/polygon/affine helpers. Requires VERA firmware v0.3.1+
(emulator R44+) — **probe with `vera_has_fx` first**; on older VERA these
write to registers that do not exist. Every routine leaves FX disabled and
`DCSEL` back at 0.

X16_USE_VERAFX is the umbrella gate. Size-sensitive programs can select
X16_USE_VERAFX_MULT, X16_USE_VERAFX_FILL, X16_USE_VERAFX_COPY,
X16_USE_VERAFX_TRANSP, X16_USE_VERAFX_AFFINE, X16_USE_VERAFX_LINE or
X16_USE_VERAFX_TRI; X16_USE_VERAFX_LINETRI is an internal shared helper
pulled by line/triangle.

### `fx_off` — disable FX

Safe to call whether or not FX was ever on; also forces `ADDRSEL` back to
port 0.

### `fx_mult` — signed 16×16 → 32 hardware multiply

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b
- **Out:** `X16_P4..P7` = product, low byte first

```prog8
cx.i16_const(X16_P0, -300)
cx.i16_const(X16_P2, 100)
%asm {{
    jsr fx_mult; X16_P4..P7 = -30000
}}
```

(The macro trick works because `X16_P0` names zero-page bytes; you can
also store the four bytes by hand.)

### `fx_fill` — cached VRAM fill (~4× a byte loop)

- **In:** `A` = byte value, `X16_P0/P1/P2` = destination (17-bit),
  `X16_P3/P4` = byte count

```prog8
%asm {{
    lda #0
    stz X16_P0 : stz X16_P1 : stz X16_P2; VRAM $00000
    lda #<19200 : sta X16_P3
    lda #>19200 : sta X16_P4
    lda #6; blue
    jsr fx_fill; top quarter of the bitmap
}}
```

### `fx_clear` — zero a VRAM region

- **In:** `X16_P0/P1/P2` = address, `X16_P3/P4` = byte count

### `fx_copy` — cached VRAM-to-VRAM copy (~4× a byte loop)

- **In:** `X16_P0/P1/P2` = source (any alignment),
  `X16_P3/P4/P5` = destination (**4-byte aligned**), `X16_P6/P7` = count

```prog8
%asm {{
    stz X16_P0 : stz X16_P1 : stz X16_P2; source: row 0
    lda #<(320*100) : sta X16_P3; dest: row 100
    lda #>(320*100) : sta X16_P4
    stz X16_P5
    lda #<320 : sta X16_P6
    lda #>320 : sta X16_P7
    jsr fx_copy
}}
```

### `fx_transp_on` / `fx_transp_off` — transparent writes

While on, a **zero byte** written to either data port (or flushed from
the cache) leaves the target untouched — colour 0 acts as transparency
for blits. Note the other `fx_*` helpers reset FX on exit, turning this
off again: enable, blit, disable.

```prog8
%asm {{
    jsr fx_transp_on
}}
; ...copy a sprite sheet region: 0-pixels don't overwrite...
%asm {{
    jsr fx_transp_off
}}
```

### `fx_line` — hardware-assisted line

- **In:** same as `gfx8l_line` (`X16_P0/P1` x0, `X16_P2` y0, `X16_P3/P4` x1,
  `X16_P5` y1, `X16_P6` colour)

VERA tracks the Bresenham error itself; the CPU does one store per pixel.
Assumes the standard 320x240 bitmap framebuffer, such as after `gfx8l_init`.
Does **not** clip.

### `fx_triangle` — filled triangle via the polygon helper

- **In:** the `tri_*` variables, written directly (too many for the
  parameter block): `tri_x0`/`tri_y0`, `tri_x1`/`tri_y1`,
  `tri_x2`/`tri_y2` (x words 0–319, y bytes 0–239), `tri_color`

Vertices in any order. Half-open rasterisation: the bottom row isn't
drawn, so adjacent triangles never double-paint a shared edge. No clipping.

```prog8
%asm {{
    lda #<160 : sta tri_x0
    lda #>160 : sta tri_x0+1
    lda #20   : sta tri_y0
}}
cx.i16_const(tri_x1, 60)
%asm {{
    lda #200  : sta tri_y1
}}
cx.i16_const(tri_x2, 260)
%asm {{
    lda #200  : sta tri_y2
    lda #4    : sta tri_color
    jsr fx_triangle
}}
```

### `fx_affine_on` / `fx_affine_ray` / `fx_affine_span` — rotozoom sampling

The mode-7 pipeline. `fx_affine_on` enters affine mode and describes a
square tile texture; `fx_affine_ray` aims a fixed-point sampling ray;
`fx_affine_span` streams texels to wherever port 0 points.

- **`fx_affine_on` in:** `X16_P0/P1/P2` = tile data VRAM address (2 KB
  aligned), `X16_P3/P4/P5` = tile map address (2 KB aligned), `X16_P6` =
  map size code (0=2×2, 1=8×8, 2=32×32, 3=128×128 tiles), `X16_P7` bit 0:
  1 = clip outside the map to tile 0, 0 = wrap
- **`fx_affine_ray` in:** `X16_P0/P1` = start x texel, `X16_P2/P3` = start
  y texel, `X16_P4/P5` = dx per read, `X16_P6/P7` = dy per read (signed,
  1/512-texel units: 512 = one texel per read)
- **`fx_affine_span` in:** `X16_P0/P1` = texel count; port 0 already aimed
  at the destination

One rotated, scaled scanline per ray+span pair; per-scanline dx/dy come
from `sin8`/`cos8` and your zoom factor:

```prog8
; per frame, per scanline y:
%asm {{
    jsr fx_affine_ray; X16_P0..P7 = start + direction
}}
cx.vera_addr(0, VRAM_BITMAP + y*320, VERA_INC_1)
cx.i16_const(X16_P0, 320)
%asm {{
    jsr fx_affine_span; one mode-7 scanline
}}
```

---

## VERA FX utilities

`X16_USE_VERAFX_UTILS` - `gfx/verafx_utils.asm`. These are lower-level helpers
for the FX register set: cache modes, accumulator and multiplier access,
16-bit hop, and polygon/tile/map primitives. They are separate from
`X16_USE_VERAFX` so programs can pay only for the utility layer they use.

- `fxu_off` - disable FX, leaving `DCSEL/ADDRSEL = 0`.
- `fxu_get_ctrl` / `fxu_set_ctrl` - read/write `FX_CTRL`.
- `fxu_ctrl_on` / `fxu_ctrl_off` - set/clear a mask in `FX_CTRL`.
- `fxu_addr1_mode` - set ADDR1 mode bits.
- `fxu_cache_write_on/off`, `fxu_cache_fill_on/off`, `fxu_cache_cycle_on/off` - cache mode bits.
- `fxu_transparent_on/off`, `fxu_4bit_on/off`, `fxu_hop_on/off` - transparent writes, 4-bit mode and 16-bit hop.
- `fxu_set_mult` - set multiplier; `fxu_set_cache` - write cache bytes.
- `fxu_reset_accum` / `fxu_accumulate` - accumulator helpers.
- `fxu_cache_fill0/1` and `fxu_cache_write0/1` - direct cache primitives.
- `fxu_set_incr`, `fxu_set_pos`, `fxu_set_subpos` - affine increment/position state.
- `fxu_get_poly_fill`, `fxu_set_tilebase`, `fxu_set_mapbase` - polygon fill and tile/map helpers.

---
## Interrupts

`X16_USE_IRQ` — `system/irq.asm`. Chains onto the KERNAL's `CINV` vector,
so the keyboard, mouse and cursor keep working. Callbacks run **inside**
the interrupt: keep them short, and save any VERA state you touch.

X16_USE_IRQ enables X16_USE_IRQ_CORE, X16_USE_IRQ_VSYNC,
X16_USE_IRQ_SPRCOL and X16_USE_IRQ_SPRCOL_API. The split gates are
available when you only need the handler core, VSYNC wait, collision
capture, or collision API.

### `irq_install` — hook the interrupt and start counting frames

Idempotent. Required before `vsync_wait`, the line/collision handlers and
the PCM streamer.

```prog8
%asm {{
    jsr irq_install
}}
```

### `irq_remove` — restore the previous handler, disable our sources

### `irq_frames` — read the frame counter

- **Out:** `A` = frames (wraps at 256; byte subtraction survives the wrap)

```prog8
%asm {{
    jsr irq_frames
    sta t0
}}
; ... work ...
%asm {{
    jsr irq_frames
    sec
    sbc t0; = frames elapsed
}}
```

### `vsync_wait` — block until the next frame boundary

Frame-locked (waits for the counter to *change*), so it can't miss a frame
or run twice in one. Needs `irq_install` and interrupts enabled. This is
the game loop's heartbeat:

```prog8
%asm {{
    game_loop
    jsr vsync_wait
    jsr update
    jsr draw
    bra game_loop
}}
```

### `irq_line_install` / `irq_line_remove` — raster line interrupt

- **In:** `A` = handler low, `X` = handler high, `X16_P0/P1` = scanline
  (0–511; visible display is 0–479)

The handler runs every frame at that scanline, inside the IRQ. The classic
use is a raster split: change a VERA register mid-frame, restore it in a
second handler or in the VSYNC path.

```prog8
%asm {{
    lda #<split : ldx #>split
}}
cx.i16_const(X16_P0, 240)
%asm {{
    jsr irq_line_install
    ...
    split; called at scanline 240 every frame
}}
; change scroll/palette here (registers are free to clobber)
%asm {{
    rts
}}
```

### `irq_sprcol_install` / `irq_sprcol_remove` — sprite collision interrupt

- **In:** `A`/`X` = handler address, or `A = X = 0` for polling only

VERA reports collisions between sprites whose collision masks (set via
`sprite_flags`) share a bit, once per frame. The handler gets the group
bits in `A`; with a null handler the groups still accumulate for:

### `sprite_collisions` — read and clear accumulated collision groups

- **Out:** `A` = group bits seen since the last call (Z set if none)

```prog8
%asm {{
    lda #0
    tax
    jsr irq_sprcol_install; polling mode
    game_frame
    jsr sprite_collisions
    beq no_hit; no collision groups this frame
}}
; handle the hit...
```

### `irq_save_regs` / `irq_restore_regs` — make callbacks library-safe

The parameter block and `r0`–`r15` belong to whatever code the interrupt
cut off. A callback that calls **any** library routine must bracket
itself:

```prog8
%asm {{
    my_handler
    jsr irq_save_regs
}}
; ...anything at all: mem_copy, psg_env_tick, gfx8l_pset...
%asm {{
    jsr irq_restore_regs
    rts
}}
```

One buffer, no nesting (interrupts don't nest here either).

---

## PSG audio

`X16_USE_PSG` — `audio/psg.asm`. VERA's 16-voice programmable sound
generator. `freq_word ≈ Hz × 2.68435`, so A4 (440 Hz) is 1181.

### `psg_init` — silence all 16 voices

```prog8
%asm {{
    jsr psg_init
}}
```

### `psg_set_freq` — set a voice's pitch

- **In:** `X` = voice (0–15), `X16_P0/P1` = frequency word

Written high byte first, so a pitch change never clicks.

```prog8
%asm {{
    ldx #0
}}
cx.i16_const(X16_P0, 1181)  ; A4
%asm {{
    jsr psg_set_freq
}}
```

### `psg_set_vol` — volume and panning

- **In:** `X` = voice, `A` = volume (0–63), `Y` = pan
  (`PSG_PAN_LEFT`/`PSG_PAN_RIGHT`/`PSG_PAN_BOTH`)

### `psg_set_wave` — waveform

- **In:** `X` = voice, `A` = `PSG_WAVE_PULSE`/`SAWTOOTH`/`TRIANGLE`/`NOISE`,
  `Y` = pulse width / XOR (0–63)

### `psg_note_off` — volume to zero, everything else kept

- **In:** `X` = voice

A complete beep:

```prog8
%asm {{
    ldx #0
}}
cx.i16_const(X16_P0, 1181)
%asm {{
    jsr psg_set_freq
    ldx #0
    lda #PSG_WAVE_TRIANGLE
    ldy #0
    jsr psg_set_wave
    ldx #0
    lda #48
    ldy #PSG_PAN_BOTH
    jsr psg_set_vol; sounding now
}}
; ... later ...
%asm {{
    ldx #0
    jsr psg_note_off
}}
```

### `psg_env_start` — trigger an attack/sustain/release envelope

- **In:** `A` = voice, `X16_P0` = peak volume (0–63), `X16_P1` = attack
  step per tick (0 = jump to peak), `X16_P2` = sustain ticks (0 = release
  immediately, 255 = hold until `psg_env_release`), `X16_P3` = release
  step per tick (0 = hold until `psg_env_stop`)

Set the voice's frequency, wave and pan first; the envelope drives only
the volume bits.

### `psg_env_release` / `psg_env_stop` — enter release / silence now

- **In:** `A` = voice

### `psg_env_tick` — advance all envelopes one step

Call once per frame (from your `vsync_wait` loop, or a VSYNC callback
bracketed with `irq_save_regs`).

```prog8
%asm {{
    lda #0; voice 0
    lda #48 : sta X16_P0; peak 48
    lda #8  : sta X16_P1; fast attack
    lda #10 : sta X16_P2; hold 10 frames
    lda #2  : sta X16_P3; gentle fade
    lda #0
    jsr psg_env_start
    game_loop
    jsr vsync_wait
    jsr psg_env_tick; the envelope plays itself
    bra game_loop
}}
```

---

## YM2151 FM synthesis

`X16_USE_YM` — `audio/ym.asm`. The FM chip at `$9F40`. Two routes that do
not mix freely: `ym_write` hits the chip raw (fast, complete access, but
leaves the ROM driver's volume/pan shadows stale); everything else goes
through the ROM audio driver, keeping them coherent.

**The ROM-driver calls take the channel in `A` and the payload in `X`** —
the opposite of what you'd guess. Getting it backwards plays a
valid-looking note on the wrong channel.

### `ym_init` — reset the chip, load default patches

- **Out:** carry set on failure. Must run before `ym_patch`.

### `ym_write` — raw register write

- **In:** `A` = value, `X` = register. **Out:** carry set if the chip
  stayed busy. Preserves `A`/`X`.

### `ym_poke` — register write through the ROM driver

- **In:** `A` = value, `X` = register. Keeps the shadows coherent.

### `ym_busy` — out: carry set while the chip is busy

### `ym_patch` — load an instrument

- **In:** `A` = channel (0–7); carry **set**: `X` = ROM patch index
  (0–162); carry **clear**: `X`/`Y` = address of a patch in RAM
- **Out:** carry set on failure

### `ym_note` — play a raw key code

- **In:** `A` = channel, `X` = KC (key code), `Y` = KF (key fraction);
  carry clear to retrigger the envelope, set to just change pitch

### `ym_note_bas` — play a packed note (the one you want for tunes)

- **In:** `A` = channel, `X` = `(octave << 4) | note 1..12` (0 releases);
  carry clear to retrigger
- **Out:** carry set on failure

```prog8
%asm {{
    jsr ym_init
    bcs fail
    lda #0; channel 0
    sec
    ldx #3; ROM patch 3
    jsr ym_patch
    lda #0
    ldx #$4A; octave 4, note 10 (A-4)
    clc; retrigger
    jsr ym_note_bas
}}
```

### `ym_release_note` — in: `A` = channel

### `ym_vol` — in: `A` = channel, `X` = attenuation (0 = patch volume, larger = quieter)

### `ym_pan` — in: `A` = channel, `X` = 0 off, 1 left, 2 right, 3 both

### `ym_get_vol` / `ym_get_pan` — in: `A` = channel; out: `X` = value

Read the ROM driver's shadows — only meaningful if you've been writing
through the driver, not raw `ym_write`.

### `ym_drum` — in: `A` = channel, `X` = drum note (25–87)

```prog8
%asm {{
    lda #7
    ldx #36; kick drum
    jsr ym_drum
}}
```

---

## ROM audio API

`X16_USE_AUDIO_ROM` - `audio/rom.asm`. These routines call the ROM `BANK_AUDIO`
API and are useful when you want the ROM's PSG/YM shadows, note conversion,
play-string/chord parser, or YM chip probing rather than only the local raw PSG
and YM helpers.

### General and play strings

- `ar_audio_init` - initialize YM, PSG and default patches.
- `ar_playstring_voice` - in: `A = voice/channel` for the next play-string call.
- `ar_fmplaystring`, `ar_fmchordstring`, `ar_psgplaystring`, `ar_psgchordstring` - in: `A = length`, `X/Y = string pointer`.

### FM and PSG note helpers

- `ar_fmfreq` / `ar_fmfreq_no_retrigger` - in: `A = channel`, `X/Y = Hz`.
- `ar_fmnote` / `ar_fmnote_no_retrigger` - in: `A = channel`, `X = (octave<<4)|note`, `Y = KF`.
- `ar_fmvib` - in: `A = LFO speed`, `X = depth`.
- `ar_psgfreq` - in: `A = voice`, `X/Y = Hz`.
- `ar_psgnote` - in: `A = voice`, `X = (octave<<4)|note`, `Y = KF`.
- `ar_psgwav` - in: `A = voice`, `X = waveformcx.duty`.

### Note conversion

Converters cover BASIC, FM key-code, MIDI, frequency and PSG frequency forms:
`ar_note_bas2fm/midi/psg`, `ar_note_fm2bas/midi/psg`,
`ar_note_freq2bas/fm/midi/psg`, `ar_note_midi2bas/fm/psg`, and
`ar_note_psg2bas/fm/midi`. Inputs and outputs follow the comments in
`audio/rom.asm`: BASIC/MIDI/FM notes are in `X` or `A/X`; frequencies are in
`X/Y`; PSG conversions return `X/Y = PSG freq`; conversions with fine pitch use
`Y = KF`.

### ROM PSG and YM shadows

- PSG: `ar_psg_init`, `ar_psg_playfreq`, `ar_psg_read`, `ar_psg_setatten`, `ar_psg_setfreq`, `ar_psg_setpan`, `ar_psg_setvol`, `ar_psg_write`, `ar_psg_write_fast`, `ar_psg_getatten`, `ar_psg_getpan`.
- YM: `ar_ym_init`, `ar_ym_loaddefpatches`, `ar_ym_loadpatch`, `ar_ym_loadpatchlfn`, `ar_ym_playdrum`, `ar_ym_playnote`, `ar_ym_setatten`, `ar_ym_setdrum`, `ar_ym_setnote`, `ar_ym_setpan`, `ar_ym_read`, `ar_ym_release`, `ar_ym_trigger`, `ar_ym_write`, `ar_ym_getatten`, `ar_ym_getpan`, `ar_ym_get_chip_type`.

`ar_psg_read` and `ar_ym_read` use carry set for the cooked/shadowed form and
carry clear for raw reads. `ar_ym_get_chip_type` returns `A = 0` none, `1` OPP,
`2` OPM, `3` unexpected.

---
## PCM audio

`X16_USE_PCM` — `audio/pcm.asm`. VERA's 4 KB sample FIFO. Samples are
signed two's-complement; the rate register runs 0 (stop) to 128
(48828 Hz). Golden rule: **prime the FIFO before setting the rate**, or
it underruns at t=0.

### `pcm_ctrl` — format, volume, reset

- **In:** `A` = control byte: volume (0–15) | `PCM_STEREO` | `PCM_16BIT` |
  `PCM_FIFO_RESET`

### `pcm_rate` — in: `A` = rate (0 stops, 128 = full speed)

### `pcm_reset` — clear the FIFO, keeping format and volume

### `pcm_full` / `pcm_empty` — out: carry set if full / empty

### `pcm_put` — in: `A` = one sample byte (silently dropped if full)

### `pcm_write` — push a block

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = byte count

Does not throttle — intended for priming up to 4 KB. Pace longer data
with `pcm_full`.

```prog8
%asm {{
    lda #(PCM_FIFO_RESET | 8); mono 8-bit, volume 8
    jsr pcm_ctrl
    lda #<sample : sta X16_P0
    lda #>sample : sta X16_P1
    lda #<2048   : sta X16_P2
    lda #>2048   : sta X16_P3
    jsr pcm_write; prime first...
    lda #43; ...then start (~16.4 kHz)
    jsr pcm_rate
}}
```

### PCM streaming (`X16_USE_PCM_STREAM`)

For anything longer than the FIFO. VERA's AFLOW interrupt refills the
FIFO from your buffer automatically; needs interrupts enabled (installs
the IRQ hook itself). Set format/volume with `pcm_ctrl` first; set
`pcm_str_loop` nonzero to repeat.

#### `pcm_stream_start` — stream from low RAM

- **In:** `X16_P0/P1` = sample data, `X16_P2/P3` = byte count,
  `A` = rate (1–128)

#### `pcm_stream_start_bank` — stream from banked RAM

- **In:** `X16_P0/P1` = offset within the bank window (0–8191),
  `X16_P2/P3/P4` = byte count (24-bit — whole songs), `X16_P5` = starting
  bank, `A` = rate

The refiller maps banks in as it goes and always restores the interrupted
code's `RAM_BANK`.

#### `pcm_stream_stop` — stop refilling (queued audio finishes; use `pcm_reset` for instant silence)

#### `pcm_stream_active` — out: `A` = 1 while data remains, 0 when done (Z mirrors A)

```prog8
%asm {{
    lda #(PCM_FIFO_RESET | 10)
    jsr pcm_ctrl
    stz X16_P0 : stz X16_P1; bank offset 0
    lda #<24576 : sta X16_P2; 24 KB = banks 2,3,4
    lda #>24576 : sta X16_P3
    stz X16_P4
    lda #2      : sta X16_P5; starting at bank 2
    lda #64; ~24.4 kHz
    jsr pcm_stream_start_bank
    wait
    jsr pcm_stream_active
    bne wait; play to the end
}}
```

---

## ZSM playback

`X16_USE_ZSM` - `audio/zsm.asm`. Compact tick-driven ZSM revision 1 player for
streams loaded in normal 16-bit address space. It handles PSG writes, YM2151
register batches, delay commands, EOF/loop, and PCM channel 0 control/rate
commands.

### Base player (`X16_USE_ZSM`)

- `zsm_init` - in: `r0 = pointer to 16-byte ZSM header`; out: carry clear on success, carry set with `A = ZSM_ERR_*` on failure.
- `zsm_init_stream` - in: `r0 = raw stream pointer`, `r1 = loop pointer or 0`; assumes 60 Hz.
- `zsm_play` / `zsm_stop` / `zsm_rewind` - playback state controls.
- `zsm_get_tickrate` - out: `A = low`, `X = high` ticks/sec from the header.
- `zsm_status` - out: `A = ZSM_FLAG_*`, carry set if active.
- `zsm_tick` - call once per player tick; out is the same as `zsm_status`.

Only 16-bit loop offsets are supported. A loop offset with bit 16 set returns
`ZSM_ERR_RANGE`.

### PCM instruments (`X16_USE_ZSM_PCM`)

`X16_USE_ZSM_PCM` pulls in `X16_USE_ZSM` and `X16_USE_PCM_STREAM`. It parses the
optional ZSM PCM table and handles PCM EXTCMD channel 0 command `2` by starting
the referenced instrument through the AFLOW PCM streamer.

- `zsm_pcm_present` - carry set if a supported PCM table was found by `zsm_init`.
- `zsm_pcm_trigger` - in: `A = instrument index`; starts that sample if valid.

This first PCM layer supports memory-resident sample data in the normal 16-bit
address space. 24-bit PCM sample offsets or lengths are rejected/ignored for now;
large banked sample sets belong in a richer sample-management layer.

---
## ADPCM decoding

`X16_USE_ADPCM` — `audio/adpcm.asm`. IMA ADPCM: 16-bit samples stored as
4-bit deltas (4:1). One second of 16-bit mono at 16 kHz becomes 8 KB —
one RAM bank — which is what makes disk streaming practical. Standard
IMA/DVI (the WAV flavour, low nibble first). Decoder state (`adpcm_pred`,
`adpcm_index`) is exposed; IMA WAV block headers carry initial values —
store them before decoding the block payload.

### `adpcm_init` — reset the decoder (predictor 0, index 0)

### `adpcm_nibble` — decode one 4-bit code

- **In:** `A` = code (0–15). **Out:** `A`/`X` = sample low/high (signed).

### `adpcm_block` — decode a run of bytes

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = destination (4 bytes out per
  byte in), `X16_P4/P5` = **source** byte count

Pointers advance and state carries across calls, so slicing a block works.

```prog8
%asm {{
    jsr adpcm_init
    lda #<packed : sta X16_P0
    lda #>packed : sta X16_P1
    lda #<pcmbuf : sta X16_P2
    lda #>pcmbuf : sta X16_P3
}}
cx.i16_const(X16_P4, 512)  ; 512 bytes in -> 1024 samples out
%asm {{
    jsr adpcm_block
}}
```

---

## Input

`X16_USE_INPUT` — `input/input.asm`. Joystick, mouse, keyboard, through
the KERNAL.

X16_USE_INPUT enables X16_USE_INPUT_CORE plus X16_USE_INPUT_KEYWAIT;
the split gates let a build omit the blocking/peek keyboard helpers.

### `joy_get` — read a joystick

- **In:** `A` = joystick (0 = keyboard joystick, 1–4 = gamepads)
- **Out:** `A` = buttons byte 0 (`JOY_B/Y/SELECT/START/UP/DOWN/LEFT/RIGHT`),
  `X` = byte 1 (`JOY_A/X/L/R`), `Y` = `$00` present / `$FF` absent

Bits are **active low** — test with a mask and branch on zero:

```prog8
%asm {{
    lda #0
    jsr joy_get
    tay; keep byte 0
    and #JOY_LEFT
    beq move_left; bit clear = pressed
    tya
    and #JOY_RIGHT
    beq move_right
}}
```

### `joy_scan` — sample the joysticks yourself

Only needed if you've taken over the IRQ; the KERNAL's handler normally
does it every frame.

### `mouse_show` / `mouse_hide` — the mouse pointer

- **In (show):** `A` = `$00` hide, `$FF` show without changing the cursor,
  or n = show cursor sprite n. Screen size is left unchanged.

### `mouse_get` — position and buttons

- **Out:** `X16_P0/P1` = x, `X16_P2/P3` = y, `A` = buttons (bit 0 left,
  1 right, 2 middle)

```prog8
%asm {{
    lda #$FF
    jsr mouse_show
    poll
    jsr mouse_get
    and #%00000001
    beq poll; wait for a left click
}}
```

### `key_get` — out: `A` = PETSCII code, 0 if none (non-blocking)

### `key_wait` — block until a key; out: `A` = PETSCII code

### `key_peek` — out: `A` = next key without consuming; `X` = queue depth (Z set when empty)

```prog8
%asm {{
    jsr key_wait
    cmp #'Q'
    beq quit
}}
```

---

### Standalone keyboard (`X16_USE_KEYBOARD`)

`input/keyboard.asm` wraps the KERNAL keyboard queue/keymap calls and modifier
state. Use it when you want keyboard-only ROM access without the whole
`X16_USE_INPUT` bundle.

- `kbd_scan` - scan/update keyboard state.
- `kbd_peek` - out: `A = next key`, `X = queue depth`, non-consuming.
- `kbd_put` - in: `A = key`; push a key into the queue.
- `kbd_get_modifiers` - out: `A = KBD_MOD_*` (`SHIFT`, `ALT`, `CTRL`, `CAPS`, `ALTGR`).
- `kbd_get_keymap` - out: `r0 = current keymap name pointer`.
- `kbd_set_keymap` - in: `r0 = zero-terminated keymap name`.

### Standalone mouse (`X16_USE_MOUSE`)

`input/mouse.asm` wraps the KERNAL mouse API. Use it when you want mouse-only
access without `X16_USE_INPUT`.

- `mse_config` - in: `A = cursor`, `X = width/8`, `Y = height/8`.
- `mse_scan` - sample/update mouse state.
- `mse_get` - out: `r0 = x`, `r1 = y`, `A = buttons`.
- `mse_get_to` - in: `A = zero-page destination`; writes x/y/buttons there.
- `mse_show`, `mse_show_keep`, `mse_hide` - pointer visibility controls.

---
## Serial, WiFi, I2C and SPI

`X16_USE_SERIAL` — `comms/serial.asm`. The serial / WiFi card carries up to
two 16C550 UARTs in the expansion window; the standard card sits at `$9F60`
(UART 0) and `$9F68` (UART 1). Pay-per-use: set the gate directly or use
`X16_USE_COMMUNICATIONS`. `ser_init` remembers the UART you hand it, so the
byte routines take no address afterwards. Receiving is non-blocking by
default. Baud rates are `SER_BAUD_*` constants (`SER_BAUD_300` …
`SER_BAUD_921600`).

### `ser_detect` — find the UART chips

- **Out:** `A` = number found (0–2), carry clear if any; `ser_u0`/`ser_u1` =
  the two base addresses (0 if absent)

Fingerprints each candidate by registers a bare bus cannot fake, with
interrupts held off across the probe.

It **writes** to every slot it examines, before it knows what is there. The
VERA_2 hi-res card at `$9F60-$9F6F` is recognised by its signature and
skipped, but any other card in `$9F60-$9FF8` is written to blind - so if you
already know the base, call `ser_init` with it instead of scanning.

### `ser_init` — program a UART for 8N1

- **In:** `A` = base low, `X` = base high; `X16_P0/P1` = baud divisor

8 data bits, no parity, 1 stop; FIFOs and auto-flow on; interrupts off. The
UART becomes the current one for every routine below.

```prog8
%asm {{
    jsr ser_detect
    lda ser_u0 : ldx ser_u0+1; the first UART found
    lda #<SER_BAUD_9600 : sta X16_P0
    lda #>SER_BAUD_9600 : sta X16_P1
    jsr ser_init
    lda #<hello : ldx #>hello
    jsr ser_puts
    poll:
    jsr ser_get; carry set = nothing waiting
    bcs poll
}}
; A = the received byte
%asm {{
    hello !text "hello, world", $0d, $0a, 0
}}
```

### `ser_avail` / `ser_get` / `ser_get_wait` — receive

- `ser_avail` → carry set if a byte is ready
- `ser_get` → carry clear + `A` = byte, or carry set if the FIFO was empty
  (never blocks)
- `ser_get_wait` → `A` = byte, blocking until one arrives (for a known device)

### `ser_put` / `ser_puts` / `ser_write` — transmit

- `ser_put` — **In:** `A` = byte
- `ser_puts` — **In:** `A`/`X` = NUL-terminated string
- `ser_write` — **In:** `A`/`X` = data, `Y` = length (binary-safe)

Each waits for room in the transmit FIFO.

### `ser_read_until` / `ser_discard_until` — match a needle

- `ser_read_until` — **In:** `A`/`X` = needle (NUL-terminated), `X16_P0/P1` =
  buffer, `X16_P2/P3` = max bytes. **Out:** `X16_P4/P5` = bytes stored
- `ser_discard_until` — **In:** `A`/`X` = needle

Both read until the needle is seen (it is included) or, for `read_until`, the
buffer is full. They block on the UART, so they are for a connected device.

### ZiModem (WiFi) — `X16_USE_SERIAL_ZIMODEM`

`comms/zimodem.asm`. The card's WiFi half is an ESP32 running ZiModem
firmware, a Hayes-style modem you drive with `AT` commands over UART 0. This
layer frames the commands and matches the replies on top of the `ser_*`
primitives (it pulls `X16_USE_SERIAL` in). It is *interactive*: most routines
block reading the board's reply, so they only do something useful with a real
card attached.

- `zi_init` — **In:** `A`/`X` = UART base, `X16_P0/P1` = baud divisor. Settle
  the board, abort any stream, apply the standard config, wait for `OK`.
- `zi_cmd` — **In:** `A`/`X` = `AT…` string. Send it with the CR/LF the
  firmware expects (transmit only; follow with `zi_wait_ok`).
- `zi_wait_ok` — read and discard the reply up to `OK\r\n`.
- `zi_reset` — issue `ATZ`.
- `zi_get_ip` — **In:** `A`/`X` = buffer (≥ 25 bytes). The IPv4 address as a
  NUL-terminated string (via `ATI2`).
- `zi_hex_open` — **In:** `A`/`X` = filename/URL. **Out:** carry clear =
  transfer started, carry set = not found. Begin a hex-mode download.
- `zi_hex_chunk` — **In:** `A`/`X` = buffer (≥ 44 bytes). **Out:** `A` = bytes
  decoded, 0 when the file is done. Pull it in a loop until it returns 0.
- `zi_hex_close` — swallow the trailing `OK` after the payload.
- `zi_hexdecode` — **In:** `A`/`X` = ASCII-hex source, `Y` = digit count,
  `X16_P0/P1` = destination. **Out:** `A` = bytes written (`Y`/2). The one
  piece of ZiModem you can use standalone.

```prog8
%asm {{
    lda #<uart : ldx #>uart; a base from ser_detect
    lda #<SER_BAUD_115200 : sta X16_P0
    lda #>SER_BAUD_115200 : sta X16_P1
    jsr zi_init
    lda #<url : ldx #>url
    jsr zi_hex_open
    bcs not_found
    next:
    lda #<buf : ldx #>buf
    jsr zi_hex_chunk; A = bytes this chunk
    beq done
}}
; ...consume A bytes from buf...
%asm {{
    bra next
    done:
    jsr zi_hex_close
}}
```

A note on testing: because ZiModem talks to a board the emulator does not
provide, its command/response flows are verified on real hardware. The test
suite pins what it can run headless — `zi_hexdecode` against a known vector,
`zi_cmd`'s transmit path, and byte-for-byte identical output across all seven
assemblers.

---

### I2C (`X16_USE_I2C`)

`comms/i2c.asm` wraps the KERNAL I2C jump table. Carry set means NAK/error.

- `i2c_read_byte` - in: `X = 7-bit device`, `Y = offset`; out: `A = value`, carry set on error.
- `i2c_write_byte` - in: `A = value`, `X = 7-bit device`, `Y = offset`; carry set on error.
- `i2c_batch_read` - in: `X = device`, `r0 = buffer`, `r1 = count`, carry clear to advance `r0`, carry set to keep it fixed; carry set on error.
- `i2c_batch_write` - in: `X = device`, `r0 = buffer`, `r1 = count`; out: `r2 = bytes written`, carry set on error.

### VERA SPI (`X16_USE_VERA_SPI`)

`comms/spi.asm` controls the VERA SPI registers. Writing `VERA_SPI_DATA` starts a
full-duplex transfer; `VERA_SPI_BUSY` clears when the received byte is ready.
Buffer routines use `r0 = pointer`, `r1 = count`; they advance `r0` and leave
`r1 = 0`.

- `spi_get_ctrl` / `spi_set_ctrl` - read/write `VERA_SPI_*` control bits.
- `spi_wait` - wait for the active transfer to finish.
- `spi_select` / `spi_deselect` - assert/release chip select.
- `spi_slow` / `spi_fast` - choose the slow or fast SPI clock.
- `spi_autotx_on` / `spi_autotx_off` - Auto-TX mode for reads.
- `spi_transfer` - in: `A = byte`; out: `A = received byte`.
- `spi_write` - in: `A = byte`; discard received byte.
- `spi_read` - transmit `$FF`, out: `A = received byte`.
- `spi_autotx_read` - wait/read in Auto-TX mode, starting the next `$FF` transfer.
- `spi_read_bytes` / `spi_write_bytes` - block transfers through `r0/r1`.

---
## Banked RAM

`X16_USE_BANK` — `storage/bank.asm`. `RAM_BANK` (`$00`) selects which
8 KB bank appears at `$A000`–`$BFFF`. Bank 0 belongs to the KERNAL; banks
1–255 are yours. All routines here save and restore `RAM_BANK`. Offsets
are 0–8191 into the window; the bulk copies roll across bank boundaries
automatically.

### `bank_set` / `bank_get` — in/out: `A` = the mapped bank

### `bank_peek` — read a byte from any bank

- **In:** `A` = bank, `X16_P0/P1` = offset (0–8191). **Out:** `A` = byte.

### `bank_poke` — write a byte into any bank

- **In:** `A` = byte, `X` = bank, `X16_P0/P1` = offset

```prog8
%asm {{
    lda #$42
    ldx #3
}}
cx.i16_const(X16_P0, 100)
%asm {{
    jsr bank_poke; bank 3, offset 100 = $42
    lda #3
    jsr bank_peek; A = $42 (same X16_P0)
}}
```

### `mem_to_bank` — copy low RAM into banked RAM

- **In:** `X16_P0/P1` = source, `X16_P2` = destination bank,
  `X16_P3/P4` = destination offset, `X16_P5/P6` = byte count

### `bank_to_mem` — the inverse

- **In:** `X16_P0` = source bank, `X16_P1/P2` = source offset,
  `X16_P3/P4` = destination address, `X16_P5/P6` = byte count

```prog8
%asm {{
    lda #<level : sta X16_P0; stash 2 KB of level data
    lda #>level : sta X16_P1
    lda #5      : sta X16_P2; into bank 5
    stz X16_P3  : stz X16_P4; offset 0
}}
cx.i16_const(X16_P5, 2048)
%asm {{
    jsr mem_to_bank
}}
```

### `bank_copy_far` — banked RAM to banked RAM

- **In:** `X16_P0` = source bank, `X16_P1/P2` = source offset,
  `X16_P3` = destination bank, `X16_P4/P5` = destination offset,
  `X16_P6/P7` = byte count. The parameter block is consumed.

---

## Bank allocator

`X16_USE_BANKALLOC` — `storage/bankalloc.asm`. A bitmap allocator that
hands out whole bank **numbers** (it never touches `RAM_BANK` itself).

### `bank_alloc_init` — define the pool

- **In:** `A` = first bank, `X` = last bank (inclusive). Calling again
  resets the pool.

### `bank_alloc` — take the lowest free bank

- **Out:** carry clear, `A` = bank — or carry set: pool exhausted

### `bank_free` — in: `A` = bank number. Returns it to the pool.

### `bank_reserve` — claim a specific bank

- **In:** `A` = bank. **Out:** carry clear = now yours; carry set =
  already taken or outside the pool.

```prog8
%asm {{
    lda #1
    ldx #63; manage banks 1-63 (512K machine)
    jsr bank_alloc_init
    jsr bank_alloc
    bcs out_of_memory
    sta sample_bank; got one
    ...
    lda sample_bank
    jsr bank_free; give it back
}}
```

---

## HIRAM stack and ringbuffer

`X16_USE_STACK` and `X16_USE_RINGBUFFER` provide 8 KB containers backed by one
whole HIRAM bank at `$A000-$BFFF`. Every routine saves and restores `RAM_BANK`,
so the container can live in one bank while your main code temporarily maps
another. There are no implicit over/underflow guards; check the state routines
before pushing or popping when capacity matters.

### Stack (`X16_USE_STACK`)

`storage/stack.asm` is a last-in-first-out stack. It grows downward from offset
8191 and has 8191 usable bytes.

- `stack_init` - in: `A = HIRAM bank number`; empties the stack.
- `stack_push` - in: `A = byte`.
- `stack_pushw` - in: `A = low`, `X = high`.
- `stack_pop` - out: `A = byte`.
- `stack_popw` - out: `A = low`, `X = high`, carry clear. Carry **set**
  means fewer than two bytes were stored and nothing was popped -
  `stack_isempty` cannot say that, since one byte left is not empty but is
  not a word either.
- `stack_size` / `stack_free` - out: `A/X = bytes used/free`.
- `stack_isempty` / `stack_isfull` - carry set if empty/full.

### Ringbuffer (`X16_USE_RINGBUFFER`)

`storage/ringbuffer.asm` is a first-in-first-out queue. Capacity is 8191 bytes;
one slot remains unused so full and empty stay distinct.

- `ring_init` - in: `A = HIRAM bank number`; empties the queue.
- `ring_put` - in: `A = byte`.
- `ring_putw` - in: `A = low`, `X = high`.
- `ring_get` - out: `A = byte`.
- `ring_getw` - out: `A = low`, `X = high`, carry clear. Carry **set**
  means fewer than two bytes were queued and nothing was dequeued, for the
  reason given for `stack_popw` above.
- `ring_size` / `ring_free` - out: `A/X = bytes queued/free`.
- `ring_isempty` / `ring_isfull` - carry set if empty/full.

For tiny low-RAM containers that do not use a bank, see
[Ring buffer and stack](#ring-buffer-and-stack) (`X16_USE_BUFFERS`).

---
## Block memory operations

`X16_USE_MEM` — `storage/mem.asm`. KERNAL block routines with one special
property: addresses in `$9F00`–`$9FFF` are **not incremented** during the
operation. Point a VERA data port somewhere and pass `VERA_DATA0` as
source or target, and these stream into or out of VRAM at the port's own
increment.

### `mem_fill` — set a block to one value

- **In:** `X16_P0/P1` = target, `X16_P2/P3` = byte count, `A` = value

```prog8
%asm {{
    lda #<buf : sta X16_P0
    lda #>buf : sta X16_P1
}}
cx.i16_const(X16_P2, 1000)
%asm {{
    lda #0
    jsr mem_fill; zero a kilobyte
}}
```

### `mem_copy` — copy a block (regions may overlap)

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = target, `X16_P4/P5` = count

Uploading to VRAM:

```prog8
cx.vera_addr(0, VRAM_BITMAP, VERA_INC_1)
%asm {{
    lda #<image : sta X16_P0
    lda #>image : sta X16_P1
    lda #<VERA_DATA0 : sta X16_P2; the magic target
    lda #>VERA_DATA0 : sta X16_P3
}}
cx.i16_const(X16_P4, 4096)
%asm {{
    jsr mem_copy; 4 KB straight into video memory
}}
```

### `mem_crc` — CRC-16/IBM-3740 of a block

- **In:** `X16_P0/P1` = address, `X16_P2/P3` = count.
  **Out:** `A` = CRC low, `X` = CRC high. (Empty block ⇒ `$FFFF`.)

### `mem_decompress` — unpack an LZSA2 block

- **In:** `X16_P0/P1` = compressed data, `X16_P2/P3` = output address
- **Out:** `A`/`X` = one past the last output byte

Compress with `lzsa -r -f2 in out` (raw LZSA2). Cannot decompress in
place. Target `VERA_DATA0` (port pointed first) to unpack assets straight
into VRAM with no staging buffer.

---

## Loading, saving, file I/O and IEC

`X16_USE_LOAD` — `storage/load.asm`. KERNAL LOAD/SAVE on device 8 (the SD
card). Filenames are (address, length), not NUL-terminated.

### `fs_load` — load a file

- **In:** `X16_P0/P1` = filename address, `X16_P2` = length,
  `X16_P3` = device (usually 8), `X16_P4` = secondary address:
  `FS_SA_ADDR` (0: skip the 2-byte PRG header, load at your address),
  `FS_SA_HEADER` (1: load where the header says),
  `FS_SA_RAW` (2: no header, load everything at your address);
  `X16_P5/P6` = destination (ignored for `FS_SA_HEADER`)
- **Out:** carry clear on success (`X`/`Y` = one past the last byte);
  carry set with `A` = KERNAL error code

```prog8
%asm {{
    lda #<name : sta X16_P0
    lda #>name : sta X16_P1
    lda #9     : sta X16_P2; length of "LEVEL.BIN"
    lda #8     : sta X16_P3
    lda #FS_SA_ADDR : sta X16_P4
    lda #<$4000 : sta X16_P5
    lda #>$4000 : sta X16_P6
    jsr fs_load
    bcs load_failed
    ...
    name !text "LEVEL.BIN"
}}
```

### `fs_save` — save a memory block as a PRG

- **In:** `X16_P0/P1` = filename, `X16_P2` = length, `X16_P3` = device,
  `X16_P5/P6` = start address, `X16_T6/T7` = end address (one past the
  last byte — it rides in T-space because the P block is full)
- **Out:** carry clear on success; carry set with `A` = error code

```prog8
%asm {{
    lda #<name2 : sta X16_P0
    lda #>name2 : sta X16_P1
    lda #8      : sta X16_P2
    lda #8      : sta X16_P3
    lda #<$4000 : sta X16_P5
    lda #>$4000 : sta X16_P6
    lda #<$4800 : sta X16_T6; save $4000-$47FF
    lda #>$4800 : sta X16_T7
    jsr fs_save
    ...
    name2 !text "SAVE.PRG"
}}
```

### `fs_vload` — load a file straight into VRAM

- **In:** as `fs_load`, but `X16_P4` = VRAM bank (0/1) and
  `X16_P5/P6` = the VRAM address within that bank. PRG header is skipped.

```prog8
%asm {{
    lda #<img : sta X16_P0
    lda #>img : sta X16_P1
    lda #7    : sta X16_P2
    lda #8    : sta X16_P3
    stz X16_P4; VRAM bank 0
    stz X16_P5 : stz X16_P6; address $00000: the bitmap
    jsr fs_vload
    ...
    img !text "PIC.BIN"
}}
```

### `fs_setname` — in: `X16_P0/P1` = filename, `A` = length

The low-level piece (`fs_load`/`fs_save` call it for you).

---

### File I/O (`X16_USE_FILEIO`)

`storage/fileio.asm` wraps the KERNAL logical-file API and adds small named-open
helpers. It is lower level than `fs_load`/`fs_save`: you manage logical file
numbers, secondary addresses and current input/output channels yourself.

- `fio_set_lfs` - in: `A = logical file`, `X = device`, `Y = secondary`.
- `fio_set_name` - in: `A/X = filename pointer`, `Y = length`.
- `fio_open` / `fio_close` - KERNAL open/close by current logical file.
- `fio_open_named` - in: filename in `A/X/Y`, plus `X16_P0 = logical`, `P1 = device`, `P2 = secondary`.
- `fio_open_read` / `fio_open_write` - named open with read/write secondary setup.
- `fio_close_named` - close logical file and clear channels.
- `fio_chkin`, `fio_chkout`, `fio_clrchn`, `fio_chrin`, `fio_chrout`, `fio_readst`, `fio_getin` - channel byte I/O.
- `fio_close_all` / `fio_close_device` - close many files.

Constants: `FIO_DEV_KEYBOARD`, `FIO_DEV_SCREEN`, `FIO_DEV_DISK`,
`FIO_LFN_COMMAND`, `FIO_SA_NONE`, `FIO_SA_COMMAND`.

### IEC (`X16_USE_IEC`)

`storage/iec.asm` exposes the low-level serial-bus KERNAL calls. Use this for
custom IEC protocols or when you need more control than logical files provide.

- `iec_listen`, `iec_talk`, `iec_second`, `iec_tksa`, `iec_ciout`, `iec_acptr`, `iec_unlisten`, `iec_untalk` - raw IEC bus calls.
- `iec_set_timeout` - in: `A = timeout control`.
- `iec_readst` - out: `A = status`.
- `iec_macptr` - in: `r0 = destination`, `r1 = count`; receive multiple bytes.
- `iec_mciout` - in: `r0 = source`, `r1 = count`; transmit multiple bytes.
- `iec_open_channel`, `iec_data_channel`, `iec_talk_channel`, `iec_close_channel` - in: `A = device`, `X = secondary`; compose common IEC channel commands.

Constants include `IEC_CMD_DATA`, `IEC_CMD_CLOSE` and `IEC_CMD_OPEN`.

---
## DOS commands

`X16_USE_DOS` — `storage/dos.asm`. `fs_load`/`fs_save` report *that* they
failed; channel 15 says *why*. Codes below 20 are success, 20+ are errors
(CBM DOS convention). The device defaults to 8 — store to `dos_device` to
change it. All the wrappers return like `dos_cmd`.

### `dos_status` — read the drive's pending status line

- **Out:** `A` = status code (0–99; 255 if the channel wouldn't open),
  carry set when it's an error, `dos_msg` = the full NUL-terminated text,
  `Y` = its length

The first read after power-on returns 73 (the DOS version banner) by
design.

```prog8
%asm {{
    jsr fs_load
    bcc ok
    jsr dos_status; carry was set -- ask why
}}
; A = 62 for FILE NOT FOUND; dos_msg = "62,FILE NOT FOUND,00,00"
%asm {{
    lda #<dos_msg : ldx #>dos_msg
    jsr screen_puts
}}
```

### `dos_cmd` — send a raw DOS command

- **In:** `A` = command low, `X` = command high, `Y` = length (0 = just
  read status). **Out:** as `dos_status`.

### `dos_delete` / `dos_mkdir` / `dos_rmdir` / `dos_chdir`

- **In:** `A` = name low, `X` = name high, `Y` = name length

Scratch a file / make / remove / change directory (`"//"` is the root).

```prog8
%asm {{
    lda #<fname : ldx #>fname : ldy #8
    jsr dos_delete; S:OLD.SAVE
    bcs drive_said_no
    ...
    fname !text "OLD.SAVE"
}}
```

### `dos_rename` — rename a file

- **In:** old name in `X16_P0/P1` with length in `X16_P2`; new name in
  `A`/`X` with length in `Y`

```prog8
%asm {{
    lda #<oldn : sta X16_P0
    lda #>oldn : sta X16_P1
    lda #7     : sta X16_P2
    lda #<newn : ldx #>newn : ldy #7
    jsr dos_rename; R:NEW=OLD
}}
```

---

## BMX images

`X16_USE_BMX` — `storage/bmx.asm`. BMX is the X16's native bitmap file
format (the one Prog8 and the community tools write): a 16-byte header,
the palette, then pixels. Rows land in VRAM `bmx_stride` bytes apart
(default 320) — a full-width image is a plain load, a narrower one is a
"stamp" that leaves its surroundings alone.

Errors: `BMX_ERR_IO` (1) open/read/write failed or file truncated,
`BMX_ERR_FORMAT` (2) not a BMX / not version 1, `BMX_ERR_PACKED` (3)
compressed BMX unsupported.

### `bmx_load` — load: palette into VERA, pixels into VRAM

- **In:** `X16_P0/P1` = filename, `X16_P2` = length, `X16_P3` = device,
  `X16_P4` = VRAM bank, `X16_P5/P6` = VRAM address
- **Out:** carry clear on success; carry set with `A` = `BMX_ERR_*`.
  `bmx_width/height/bpp/palstart/palcount/border` reflect the file.

```prog8
%asm {{
    jsr gfx8l_init; 320x240@8bpp bitmap mode
    lda #<pic : sta X16_P0
    lda #>pic : sta X16_P1
    lda #9    : sta X16_P2
    lda #8    : sta X16_P3
    stz X16_P4; bank 0
    stz X16_P5 : stz X16_P6; VRAM $00000
    jsr bmx_load
    bcs show_error; A = BMX_ERR_*
    ...
    pic !text "TITLE.BMX"
}}
```

### `bmx_save` — write a BMX from VRAM

- **In:** same filename/device/VRAM parameters; `bmx_width`, `bmx_height`,
  `bmx_bpp`, `bmx_palstart`, `bmx_palcount`, `bmx_border`, `bmx_stride`
  describe what to save (defaults: 8 bpp, stride 320)
- **Out:** carry clear on success; carry set with `A` = `BMX_ERR_IO`

Caveat: the palette written comes from VRAM's host-write shadow, so it is
only meaningful if this program set those entries itself (`pal_set` /
`pal_load` / a previous `bmx_load`).

```prog8
cx.i16_const(bmx_width, 320)  ; describe the screen
cx.i16_const(bmx_height, 240)
%asm {{
    lda #<shot : sta X16_P0
    lda #>shot : sta X16_P1
    lda #8     : sta X16_P2
    lda #8     : sta X16_P3
    stz X16_P4
    stz X16_P5 : stz X16_P6
    jsr bmx_save; screenshot to SHOT.BMX
    ...
    shot !text "SHOT.BMX"
}}
```

---

## Clock and RTC

`X16_USE_CLOCK` - `system/clock.asm`. Thin wrappers for the KERNAL timer and RTC
entry points.

### `clock_update` - advance KERNAL time state

Calls `UDTIM`, the classic KERNAL clock update routine.

### `clock_get_timer` / `clock_set_timer` - 24-bit 60 Hz timer

- `clock_get_timer` out: `A = low`, `X = middle`, `Y = high`.
- `clock_set_timer` in: `A = low`, `X = middle`, `Y = high`.

```prog8
%asm {{
    jsr clock_get_timer
    sta t0
    stx t1
    sty t2
}}
```

### `clock_get_date_time` / `clock_set_date_time` - RTC date/time

Both use the KERNAL `r0..r3` layout:

| Register | Value |
|---|---|
| `r0L` | year since 1900 |
| `r0H` | month |
| `r1L` | day |
| `r1H` | hours |
| `r2L` | minutes |
| `r2H` | seconds |
| `r3L` | jiffies |
| `r3H` | weekday |

---
## Game math

`X16_USE_MATH` — `util/math.asm`. Angles are bytes: a full circle is 256,
so 64 = 90°, and wrap-around is free. Angle 0 points east (+x), 64 points
south (+y, down the screen) — `atan2` and the sine tables agree, so
`x += cos8(a)*speed>>7 : y += sin8(a)*speed>>7` moves along a returned
heading.

### `rnd_seed` — seed the PRNG

- **In:** `A` = low, `X` = high (a zero seed is nudged to 1)

### `rnd8` / `rnd16` — next pseudo-random value

- **Out:** `A` = byte (`rnd16` also: `X` = high byte)

16-bit xorshift: period 65535, a handful of cycles.

```prog8
%asm {{
    lda #$34
    ldx #$12
    jsr rnd_seed; deterministic sequence from here
    jsr rnd8
    and #7; 0-7: pick a spawn point
}}
```

### `sin8` / `cos8` — signed sine/cosine

- **In:** `A` = angle 0–255. **Out:** `A` = −127..127. Preserve `X`.

### `sin8u` / `cos8u` — unsigned variants

- **Out:** `A` = 1..255 (128 + signed value — handy for volumes/scales)

### `atan2` — the angle of a vector

- **In:** `A` = dx, `X` = dy (signed bytes). **Out:** `A` = angle 0–255.

```prog8
; aim at the player
%asm {{
    lda player_x
    sec : sbc enemy_x; dx
    tay
    lda player_y
    sec : sbc enemy_y; dy
    tax
    tya
    jsr atan2; A = heading
    sta enemy_dir
    jsr cos8; A = cos(heading), -127..127
}}
; scale by speed, >> 7, add to enemy_x; same with sin8 for y
```

### `lerp8` — linear interpolation

- **In:** `X16_P0` = a, `X16_P1` = b, `A` = t (0 = a … 255 = b)
- **Out:** `A` = the interpolated value (exact at both ends)

```prog8
%asm {{
    lda #0   : sta X16_P0
    lda #63  : sta X16_P1
    lda fade_t
    jsr lerp8; volume fades 0 -> 63 as t rises
}}
```

---

## Line clipping

`X16_USE_CLIP` — `util/clip.asm`. Cohen–Sutherland. Give it a segment in
16-bit **signed** coordinates (±4095) and it rejects it or hands back the
visible part **already loaded into `gfx8l_line`/`fx_line`'s parameter
block**. The rectangle is inclusive, defaulting to the full 320×240.

### `clip_set` — change the rectangle

- **In:** `X16_P0/P1` = xmin, `X16_P2/P3` = ymin, `X16_P4/P5` = xmax,
  `X16_P6/P7` = ymax (inclusive)

### `clip_line` — clip the segment in `clipl_x0/y0/x1/y1`

- **In:** the four `clipl_*` words, written directly
- **Out:** carry set = entirely outside; carry clear = `X16_P0..P5` are
  loaded for the line drawers

```prog8
cx.i16_const(clipl_x0, -50)  ; starts off screen
cx.i16_const(clipl_y0, 10)
cx.i16_const(clipl_x1, 400)  ; ends off screen too
cx.i16_const(clipl_y1, 200)
%asm {{
    jsr clip_line
    bcs nothing_visible
    lda #1
    sta X16_P6; colour is the only thing left to set
    jsr gfx8l_line; draws exactly the on-screen part
}}
```

---

## Ring buffer and stack

`X16_USE_BUFFERS` — `util/buffers.asm`. One static byte ring buffer and
one byte stack, 255 capacity each. If one side runs in an IRQ, wrap the
other side's calls in `php`/`sei` … `plp`.

### `rb_init` / `rb_put` / `rb_get` / `rb_count`

- `rb_put` in: `A` = byte; carry set = full, not stored
- `rb_get` out: `A` = byte; carry set = empty
- `rb_count` out: `A` = bytes queued (Z reflects it)
- put/get preserve `X`/`Y`

```prog8
%asm {{
    jsr rb_init
    lda #42
    jsr rb_put; queue
    jsr rb_get; A = 42, FIFO order
    bcs was_empty
}}
```

### `stk_init` / `stk_push` / `stk_pop` / `stk_depth`

Same contracts, LIFO order.

```prog8
%asm {{
    jsr stk_init
    lda #1 : jsr stk_push
    lda #2 : jsr stk_push
    jsr stk_pop; A = 2 -- last in, first out
}}
```

---

## Compression

Three decompressors, one trade-off dial. All are RAM→RAM, forward-only,
and cannot decompress in place:

| Routine | Gate | Format | Character |
|---|---|---|---|
| `mem_decompress` | `X16_USE_MEM` | LZSA2 (`lzsa -r -f2`) | free (ROM), can target VRAM |
| `zx0_decompress` | `X16_USE_ZX0` | ZX0 v2 (`salvador`/`zx0`) | packs tightest |
| `tsc_decompress` | `X16_USE_TSC` | TSCrunch (`tscrunch`) | unpacks fastest |

### `zx0_decompress` / `tsc_decompress`

- **In:** `X16_P0/P1` = compressed data, `X16_P2/P3` = output address
- **Out:** `A`/`X` = one past the last output byte (`X16_P0..P3` consumed)

```prog8
%asm {{
    lda #<data_zx0 : sta X16_P0
    lda #>data_zx0 : sta X16_P1
    lda #<$5000    : sta X16_P2
    lda #>$5000    : sta X16_P3
    jsr zx0_decompress; A/X = end of the unpacked data
}}
```

(`tsc_decompress` is called identically.)

---

## Fixed point

`X16_USE_FIXED` — `util/fixed.asm`.

### `umul16` — unsigned 16×16 → 32

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b
- **Out:** `X16_P4..P7` = product, low byte first

```prog8
cx.i16_const(X16_P0, 1000)
cx.i16_const(X16_P2, 500)
%asm {{
    jsr umul16; X16_P4..P7 = 500000
}}
```

### `mul88` — signed 8.8 fixed-point multiply

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b (signed 8.8)
- **Out:** `X16_P0/P1` = `(a*b) >> 8`

The tool for fractional sprite speeds: keep positions in 8.8, add an 8.8
velocity per frame, take the high byte as the pixel.

```prog8
cx.i16_const(X16_P0, $0180)  ; 1.5
cx.i16_const(X16_P2, $0200)  ; 2.0
%asm {{
    jsr mul88; X16_P0/P1 = $0300 = 3.0
}}
```

---

## Collision

`X16_USE_COLLIDE` — `util/collide.asm`. Axis-aligned box overlap. Edges
that merely touch do **not** collide.

### `collide8` — 8-bit boxes

- **In:** `X16_P0..P3` = ax, ay, aw, ah; `X16_P4..P7` = bx, by, bw, bh
  (unsigned bytes)
- **Out:** carry set if they overlap

```prog8
%asm {{
    lda px : sta X16_P0
    lda py : sta X16_P1
    lda #16 : sta X16_P2 : sta X16_P3; player: 16x16
    lda ex : sta X16_P4
    lda ey : sta X16_P5
    lda #8 : sta X16_P6 : sta X16_P7; enemy: 8x8
    jsr collide8
    bcs hit
}}
```

### `collide16` — 16-bit boxes

- **In:** the `cl_*` words, written directly (eight 16-bit fields don't
  fit the parameter block): `cl_ax/ay/aw/ah`, `cl_bx/by/bw/bh`
- **Out:** carry set if they overlap

Needed in display space: the default 80×60 text screen is 640×480, past
what a byte can address.

```prog8
cx.i16_const(cl_ax, 600)  ; a box on the right half
cx.i16_const(cl_ay, 100)
cx.i16_const(cl_aw, 32)
cx.i16_const(cl_ah, 32)
cx.i16_const(cl_bx, 610)
cx.i16_const(cl_by, 90)
cx.i16_const(cl_bw, 16)
cx.i16_const(cl_bh, 40)
%asm {{
    jsr collide16
    bcs hit
}}
```

---

## Bit helpers

`X16_USE_BITS` — `util/bits.asm`.

### `catnib` — in: `A` = high nibble, `X` = low. Out: `A` = `(A<<4)|X`.

### `hinib` / `lonib` — in: `A` = byte. Out: `A` = that nibble in bits 3:0.

```prog8
%asm {{
    lda #$0C
    ldx #$05
    jsr catnib; A = $C5
    jsr hinib; A = $0C again
}}
```

### `bit_set` / `bit_clr` / `bit_put` / `bit_test` — masked bits in memory

- **In:** `X16_PTR0` = address, `A` = mask; `bit_put` also `X` (≠0 set,
  0 clear)
- **`bit_test` out:** Z clear if any masked bit is set

```prog8
%asm {{
    lda #<flags : sta X16_P0
    lda #>flags : sta X16_P1
    lda #%00000100
    jsr bit_set; flags |= 4
    lda #%00000100
    jsr bit_test
    bne flag_is_on
}}
```

---

## Number formatting

`X16_USE_NUMBER` — `util/number.asm`. Results land in a shared buffer the
next call overwrites; copy the string out to keep it.

### `u16_to_dec` — unsigned 16-bit to decimal

- **In:** `X16_P0/P1` = value (consumed)
- **Out:** `A`/`X` = buffer low/high, `Y` = length; NUL-terminated

```prog8
%asm {{
    lda score   : sta X16_P0
    lda score+1 : sta X16_P1
    jsr u16_to_dec
    jsr screen_puts; A/X are already the arguments
}}
```

### `u16_to_hex` — four hex digits

- **In:** `X16_P0/P1` = value. **Out:** `A`/`X` = buffer, `Y` = 4.

### `dec_to_u16` — parse decimal digits

- **In:** `X16_P0/P1` = string address, `X16_P2` = length
- **Out:** `X16_P4/P5` = value; carry set if a non-digit was found

```prog8
%asm {{
    lda #<input : sta X16_P0
    lda #>input : sta X16_P1
    lda #3      : sta X16_P2
    jsr dec_to_u16
    bcs not_a_number; X16_P4/P5 = 123
    ...
    input !text "123"
}}
```

---

## BCD arithmetic

`X16_USE_BCD` - `util/bcd.asm`. Packed-BCD add/subtract for game scores,
clocks and counters that need to print as decimal cheaply. Each byte stores two
decimal digits, low byte first: `$0987 + $1111 = $2098`.

Values live in named registers:

- `bcd_a` - accumulator, overwritten by add/sub routines.
- `bcd_b` - operand.

Routines:

- `bcd_add8`, `bcd_add16`, `bcd_add32` - `bcd_a += bcd_b`; carry set on overflow.
- `bcd_sub8`, `bcd_sub16`, `bcd_sub32` - `bcd_a -= bcd_b`; carry clear on borrow.
- `bcd_addto` - in: `A/X = pointer` to a 4-byte packed-BCD value; adds `bcd_b` in place.
- `bcd_subfrom` - in: `A/X = pointer`; subtracts `bcd_b` in place.

These routines enter decimal mode during the operation and clear it before
returning. If your own interrupt handler does `ADC`/`SBC`, make it decimal-safe
or bracket BCD calls with interrupts disabled.

```prog8
cx.i32_const(bcd_a, $00000987)
cx.i32_const(bcd_b, $00001111)
%asm {{
    jsr bcd_add32; bcd_a = $00002098
}}
```

---
## 16-bit integers

`X16_USE_INT16` — `util/int16.asm` (pulls in `X16_USE_NUMBER`). Values
live in named two-byte registers you write directly: `i16_a` (the
accumulator — most routines read and overwrite it), `i16_b` (the
operand), `i16_r` (remainder from the divides). Add, subtract, negate,
multiply and left shift serve signed and unsigned alike; comparison,
division, right shift and printing come in signed/unsigned pairs.

### Loading: `cx.i16_const()`, `i16_from_u8`, `i16_from_s8`

- macro: `cx.i16_const(i16_a, 1000)`
- `i16_from_u8` / `i16_from_s8` — in: `A`; `i16_a` = A zero-/sign-extended

### `i16_add` / `i16_sub` — `i16_a ± i16_b → i16_a`

### `i16_neg` / `i16_abs` — negate / absolute value of `i16_a`

### `i16_shl` / `i16_shr` / `i16_asr` — shift `i16_a` one bit

Left / logical right / arithmetic right; carry = the bit shifted out.

### `i16_cmpu` / `i16_cmps` — compare `i16_a` with `i16_b`

- **Out:** `A` = `$FF` if a < b, 0 if equal, 1 if a > b (Z set on equal);
  operands unmodified

### `i16_mul` — `i16_a = i16_a * i16_b` (low 16 bits)

For the full 32-bit product use `umul16`.

### `i16_divmod` — unsigned divide

- `i16_a = i16_a / i16_b`, `i16_r` = remainder
- **Out:** carry set if `i16_b` was zero (nothing changed)

### `i16_divmod_s` — signed divide, truncating toward zero

Remainder takes the dividend's sign (like C): −7 / 2 = −3 rem −1.

### `i16_sqrt` — floor(√`i16_a`)

- **Out:** `A` = the root (0–255). Consumes `i16_a`.

### `i16_to_dec` / `i16_to_dec_s` — to decimal text

- **Out:** `A`/`X` = buffer, `Y` = length; NUL-terminated. Consume `i16_a`.

Putting it together:

```prog8
cx.i16_const(i16_a, -1000)
cx.i16_const(i16_b, 7)
%asm {{
    jsr i16_divmod_s; i16_a = -142, i16_r = -6
    jsr i16_to_dec_s
    jsr screen_puts; prints -142
}}
```

```prog8
cx.i16_const(i16_a, 1024)
%asm {{
    jsr i16_sqrt; A = 32
}}
```

---

## 32-bit integers

`X16_USE_INT32` — `util/int32.asm`. Same shape as int16, one size up:
`i32_a`, `i32_b`, `i32_r` are four-byte little-endian registers.

### Loading: `cx.i32_const()`, `i32_from_u16`, `i32_from_s16`, `i32_to_s16`

- macro: `cx.i32_const(i32_a, 100000)`
- `i32_from_u16`/`i32_from_s16` — in: `A` = low, `X` = high, zero-/sign-extended
- `i32_to_s16` — out: `A` = low, `X` = high (top bytes lost)

### `i32_add` / `i32_sub` / `i32_neg` / `i32_abs` — as int16

### `i32_shl` / `i32_shr` / `i32_asr` — one-bit shifts, carry = bit out

### `i32_cmpu` / `i32_cmps` — out: `A` = $FF / 0 / 1 (operands unmodified)

### `i32_mul` — `i32_a = i32_a * i32_b` (low 32 bits)

### `i32_divmod` — unsigned divide; carry set if `i32_b` was zero

### `i32_to_dec` — to decimal text

- **Out:** `A`/`X` = buffer, `Y` = length; NUL-terminated. Consumes
  `i32_a` **and** `i32_b`.

```prog8
cx.i32_const(i32_a, 1000000)
cx.i32_const(i32_b, 7)
%asm {{
    jsr i32_divmod; i32_a = 142857, i32_r = 1
    jsr i32_to_dec
    jsr screen_puts; prints 142857
}}
```

---

## Floating point

`X16_USE_FLOAT` — `util/float.asm`. A **binding** to the ROM's complete
C128/C65-compatible FP library in `BANK_BASIC` — not a reimplementation.
Everything operates on FAC, the floating accumulator; a float in memory
is 5 bytes (`FP_SIZE`) — reserve with `!fill 5, 0`. Pointer arguments are
`A` = low, `Y` = high.

Every call crosses a ROM bank (via `jsrfar`), which is not free: for hot
per-frame maths prefer 8.8 fixed point or int32.

### Loading and storing

- `f_load` — in: `A`/`Y` = address. FAC = the float there.
- `f_store` — in: `A`/`Y` = address. Store round(FAC) there.
- `f_from_u8` — in: `A` = 0–255. FAC = A.
- `f_from_s16` — in: `A` = low, `X` = high. FAC = the signed value.
- `f_to_s16` — out: `A` = low, `X` = high. **Floors** (via the ROM's
  `qint`), so `0.04 * 100` comes out 3 — round by adding 0.5 first.
- `f_from_str` — in: `A`/`Y` = string address, `X` = length. FAC = its value.
- `f_to_str` — out: `A`/`X` = a NUL-terminated string (in `$0100`; copy it
  out before pushing the stack deep or converting again). Positive numbers
  get BASIC's leading space; `f_to_str_trim` skips it.

### Arithmetic (FAC op memory)

- `f_add` / `f_mul` — FAC = FAC + / × mem
- `f_sub` / `f_div` — FAC = FAC − / ÷ mem (the intuitive direction)
- `f_rsub` / `f_rdiv` — FAC = mem − / ÷ FAC (the ROM's native order — one
  bank crossing instead of three; `f_rdiv` is the reciprocal form)
- `f_pow` — FAC = FAC ^ mem; `f_rpow` — FAC = mem ^ FAC

### Unary and tests

- `f_zero` — FAC = 0; `f_neg` — FAC = −FAC; `f_abs` — FAC = |FAC|
- `f_int` — FAC = int(FAC), toward −∞
- `f_sgn` — out: `A` = $FF / 0 / 1
- `f_cmp` — in: `A`/`Y` = address; out: `A` = $FF (FAC < mem), 0, 1

### Transcendentals

`f_sqrt`, `f_ln`, `f_exp`, `f_sin`, `f_cos`, `f_tan`, `f_atan` — each
replaces FAC (the trig ones also destroy ARG).

A complete calculation — the hypotenuse of (30, 40):

```prog8
%asm {{
    lda #30 : jsr f_from_u8; FAC = 30
    lda #<fa : ldy #>fa : jsr f_store; fa = 30
    lda #<fa : ldy #>fa : jsr f_mul; FAC = 30*30
    lda #<fb : ldy #>fb : jsr f_store; fb = 900
    lda #40 : jsr f_from_u8
    lda #<fa : ldy #>fa : jsr f_store; fa = 40
    lda #<fa : ldy #>fa : jsr f_mul; FAC = 40*40
    lda #<fb : ldy #>fb : jsr f_add; FAC = 2500
    jsr f_sqrt; FAC = 50
    jsr f_to_s16; A = 50, X = 0
    ...
    fa !fill 5, 0
    fb !fill 5, 0
}}
```

---

## Double precision

`X16_USE_DOUBLE` - `util/double.asm`. Software IEEE-754 binary64: 8-byte
little-endian doubles with about 15-16 significant digits. The accumulator is
`d_ac`; a memory operand is an 8-byte value addressed by `A = low`, `Y = high`.

### Loading and conversion

- `d_load` / `d_store` - load/store `d_ac` from/to an 8-byte memory value.
- `d_from_s16` - in: `A = low`, `X = high`; signed 16-bit to `d_ac`.
- `d_from_s32` - in: `X16_P0..P3`; signed 32-bit to `d_ac`.
- `d_to_s32` - out: `X16_P0..P3`; carry set on overflow or NaN.
- `d_from_str` - in: `A/Y = string`, `X = length`; parse decimal text.
- `d_to_str` - out: `A/X = NUL-terminated text buffer`.

### Operations

- `d_neg`, `d_abs` - sign operations on `d_ac`.
- `d_cmp` - in: `A/Y = operand`; out: `A = $FF`, `0`, or `1`.
- `d_add`, `d_sub`, `d_mul`, `d_div` - `d_ac` with memory operand.
- `d_sqrt`, `d_exp`, `d_ln`, `d_pow` - scientific functions.
- `d_sin`, `d_cos`, `d_tan`, `d_atan`, `d_sinh`, `d_cosh`, `d_tanh` - trig/hyperbolic functions.

Use `X16_USE_FLOAT` for fast ROM 5-byte BASIC floats; use `X16_USE_DOUBLE` when
range and precision matter more than code size.

---
## Strings

Five independent, pay-per-use gates over `string/`. NUL-terminated strings
are passed by pointer in `A` (low) / `X` (high); a second string (a copy
target, the other side of a compare) goes in `X16_P0/P1`; a character to
find or classify goes in `A` or `Y`. Lengths are bytes, so strings are at
most 255 characters. Number ↔ string conversion is *not* here — it lives in
`NUMBER`, `INT16`/`INT32`, `FLOAT` and `DOUBLE`, next to the numbers.

### `X16_USE_STRING` — the fundamentals

- `str_length` — **in:** `A`/`X`. **out:** `Y` = length.
- `str_copy` — **in:** `A`/`X` = source, `X16_P0/P1` = target. **out:** `Y` = length.
- `str_ncopy` — as `str_copy` plus `Y` = maximum length.
- `str_append` — **in:** `A`/`X` = target, `X16_P0/P1` = suffix. **out:** `A` = new length.
- `str_nappend` — as `str_append` plus `Y` = maximum length (leaves the target
  untouched if the suffix would overflow it).
- `str_compare` — **in:** `A`/`X` = string1, `X16_P0/P1` = string2. **out:**
  `A` = `$FF` (−1) / `0` / `1` for string1 sorting before / equal to / after.
- `str_hash` — **in:** `A`/`X`. **out:** `A` = an 8-bit rolling hash.

```prog8
%asm {{
    lda #<src : ldx #>src
    lda #<dst : sta X16_P0
    lda #>dst : sta X16_P1
    jsr str_copy; dst = src, Y = length
    lda #<dst : ldx #>dst
    lda #<"!" : sta X16_P0
    lda #>"!" : sta X16_P1
    jsr str_append; dst = "...!" , A = new length
}}
```

### `X16_USE_STRING_CTYPE` — character classification

Each takes the character in `A` and answers in the carry (set = yes):
`str_isdigit`, `str_isxdigit` and `str_isspace` are the same in either
encoding. The case-sensitive ones come in pairs — `str_islower`,
`str_isupper`, `str_isletter`, `str_isprint` classify for PETSCII, and
`str_islower_iso` / `str_isupper_iso` / `str_isletter_iso` /
`str_isprint_iso` for ISO.

PETSCII puts the cases where ASCII does not: **lower case is 65–90**, and
upper case is 97–122 *and* 193–218. So `str_islower(65)` is true while
`str_isupper(65)` is false, and both are the other way round for 97. The
ISO forms read the ranges the familiar way, and also cover the accented
letters (`$C0`–`$DE` upper, `$E0`–`$FE` lower, less the `$D7` and `$F7`
sign characters).

### `X16_USE_STRING_CASE` — case folding

`str_lower` / `str_upper` fold a whole string in place (returning `Y` = length);
`str_lowerchar` / `str_upperchar` fold the one character in `A`. Each has an
`_iso` sibling. `str_compare_nocase` / `_iso` compare like `str_compare` but
fold both sides first. Because PETSCII and ISO swap the letter ranges,
PETSCII `str_lower` is numerically ISO `str_upper` — pick the pair that
matches the encoding your text is in.

### `X16_USE_STRING_FIND` — searching

- `str_find` — **in:** `A`/`X` = string, `Y` = character. **out:** carry set +
  `A` = index if found, else carry clear + `A` = 255.
- `str_rfind` — the same, scanning from the right.
- `str_find_eol` — index of the first CR (13) or LF (10).
- `str_contains` — carry set if the character occurs.
- `str_pattern_match` — **in:** `A`/`X` = string, `X16_P0/P1` = pattern. `?`
  matches any one character, `*` any run (including none); case-sensitive.
  **out:** carry set (and `A` = 1) on a match. It uses no CPU stack and no
  recursion, so any number of `*` is safe and a pattern like `a*a*a*a*b`
  cannot make it backtrack exponentially.

```prog8
%asm {{
    lda #<path : ldx #>path
    ldy #'/'
    jsr str_rfind; index of the last '/', carry set if any
}}
```

### `X16_USE_STRING_SLICE` — substrings and trimming

- `str_left` / `str_right` — **in:** `A`/`X` = source, `X16_P0/P1` = target,
  `Y` = length. Copy that many characters off the given end.
- `str_slice` — as above plus `X16_P2` = start index.
- `str_ltrim` / `str_rtrim` / `str_trim` — **in:** `A`/`X` = string. Drop
  whitespace off the left / right / both ends, in place, returning `Y` = the
  new length. Whitespace is the `str_isspace` set (space, TAB, CR, LF and the
  two shifted forms).

You must size target buffers yourself and keep lengths within the source —
like the rest of the library, these routines trust their arguments.

---

## Where to go next

- `examples/` — `hello.asm`, `bounce.asm` (sprites, PSG envelopes, VSYNC),
  `numbers.asm` (int16/int32/float output) are working programs built on
  everything above.
- `test_acme/runner.asm` — every routine in this guide has at least one
  on-target test there; when in doubt about a contract, the test is the
  executable answer.
- The README's "Things the hardware will get you wrong" section — the
  ADDRSEL trap, the write-only VRAM ranges, the non-linear increment
  codes — is worth reading once before debugging anything VERA-related.
