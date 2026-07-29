# Bitmap graphics Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` macro gates.

Set the gate before sourcing the macro layer:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. The bitmap macros
are immediate-argument helpers over the `gfx*` routines: pass assembly-time
coordinates, colours, lengths, pattern pointers, or string pointers.

## `X16_USE_BITMAP8L / gfx8l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8L` / `gfx8l` |
| Purpose | 320x240, 8 bpp, VERA VRAM; init, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, char/text |
| Input parameters | Depends on the selected `cx.gfx8l_*` macro. Coordinates are 16-bit X and 8-bit Y; colour is an 8-bit palette index. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw an 8 bpp status panel with text in low-resolution VRAM.
        cx.gfx8l_init()
        cx.gfx8l_clear(0)
        cx.gfx8l_frame(16, 16, 144, 64, 15)
        cx.gfx8l_rect(18, 18, 140, 60, 2)
        cx.gfx8l_text(panel_msg, 28, 36, 15)
    }
}

%asm {{
    panel_msg !text "READY", 0
}}

```

## `X16_USE_BITMAP4L / gfx4l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4L` / `gfx4l` |
| Purpose | 320x240, 4 bpp, VERA VRAM; same as 8L, with 4-bit pixels |
| Input parameters | Depends on the selected `cx.gfx4l_*` macro. Colours are 0-15. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw a compact 16-colour dialog box.
        cx.gfx4l_init()
        cx.gfx4l_clear(0)
        cx.gfx4l_frame(24, 24, 128, 56, 12)
        cx.gfx4l_text(title, 40, 40, 15)
    }
}

%asm {{
    title !text "PAUSED", 0
}}

```

## `X16_USE_BITMAP2L / gfx2l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2L` / `gfx2l` |
| Purpose | 320x240, 2 bpp, VERA VRAM; init, clear, setptr, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm |
| Input parameters | Depends on the selected `cx.gfx2l_*` macro. Colours are 0-3. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw a 2 bpp minimap frame and a filled marker.
        cx.gfx2l_init()
        cx.gfx2l_clear(0)
        cx.gfx2l_frame(8, 8, 96, 64, 3)
        cx.gfx2l_rect(44, 32, 10, 10, 2)
        cx.gfx2l_line(8, 8, 103, 71, 1)
    }
}

```

## `X16_USE_BITMAP2H / gfx2h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2H` / `gfx2h` |
| Purpose | 640x480, 2 bpp, MiSTer VERA_2 SDRAM; same as 2L at high resolution |
| Input parameters | Depends on the selected `cx.gfx2h_*` macro. X and Y are 16-bit coordinates; colours are 0-3. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw high-resolution crosshairs on the VERA_2 SDRAM bitmap.
        cx.gfx2h_init()
        cx.gfx2h_clear(0)
        cx.gfx2h_hline(260, 240, 120, 3)
        cx.gfx2h_vline(320, 180, 120, 3)
        cx.gfx2h_frame(240, 160, 160, 160, 1)
    }
}

```

## `X16_USE_BITMAP4H / gfx4h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4H` / `gfx4h` |
| Purpose | 640x480, 4 bpp, MiSTer VERA_2 SDRAM; `has/init/off`, passthru, palette, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, copy |
| Input parameters | Depends on the selected `cx.gfx4h_*` macro. X/Y/width/height are 16-bit where applicable; colours are 0-15. |
| Output parameters | `cx.gfx4h_has()` reports VERA_2 support; draw helpers update the SDRAM bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw a high-resolution 16-colour panel when VERA_2 is present.
        cx.gfx4h_has()
        %asm {{
            bcs .no_vera2
        }}
        cx.gfx4h_init()
        cx.gfx4h_clear(0)
        cx.gfx4h_pal_set(1, $0f, $00)
        cx.gfx4h_frame(96, 72, 448, 304, 1)
        cx.gfx4h_pattern_set(hatch, 0, 2)
        cx.gfx4h_pattern_rect(112, 88, 416, 272)
        %asm {{
            .no_vera2
        }}
    }
}

%asm {{
    hatch !byte %10101010, %01010101, %10101010, %01010101
    !byte %10101010, %01010101, %10101010, %01010101
}}

```

## `X16_USE_BITMAP8H / gfx8h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8H` / `gfx8h` |
| Purpose | 640x480, 8 bpp, MiSTer VERA_2 SDRAM; same as 4H, with 8-bit pixels |
| Input parameters | Depends on the selected `cx.gfx8h_*` macro. Colours are full 8-bit palette indexes. |
| Output parameters | `cx.gfx8h_has()` reports VERA_2 support; draw helpers update the SDRAM bitmap. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Draw a high-resolution 256-colour loading bar when VERA_2 is present.
        cx.gfx8h_has()
        %asm {{
            bcs .no_vera2
        }}
        cx.gfx8h_init()
        cx.gfx8h_clear(0)
        cx.gfx8h_frame(120, 220, 400, 24, 15)
        cx.gfx8h_rect(124, 224, 192, 16, 42)
        cx.gfx8h_line(120, 252, 520, 252, 63)
        %asm {{
            .no_vera2
        }}
    }
}

```

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `gfx2h_setptr` | point data port 0 at the byte holding pixel (x,y) | A = increment index (VERA_INC_*) X16_P0/P1 = x, X16_P2/P3 = y | A = x & 3 (the pixel's position within the byte) y*160 = (y<<5) + (y<<5)<<2, so no multiply is needed; the result is 17-bit. Stepping by VERA_INC_160 then walks straight down a column. |
| `gfx2h_pset` | set one pixel, clipped | A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y | -- |
| `gfx2h_read` | read one pixel | X16_P0/P1 = x, X16_P2/P3 = y | carry clear, A = colour (0-3); carry set if (x,y) is off screen (A undefined) |
| `gfx2h_rect` | filled rectangle (no clipping) | A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width, X16_P6/P7 = height | -- |
| `gfx2h_line` | Bresenham, any direction; plots through gfx2h_pset so | A = colour (0-3) X16_P0/P1 = x0, X16_P2/P3 = y0 X16_P4/P5 = x1, X16_P6/P7 = y1 | -- |
| `gfx2h_pattern_set` | expand an 8x8 1bpp pattern for gfx2h_pattern_rect | A = pattern low, X = pattern high (8 row bytes, top first bit 7 is the leftmost pixel) Y = colours: (background << 2) \| foreground Patterns tile from the screen origin, so each row expands to exactly two 2bpp bytes (16 bits); which of the pair a framebuffer byte uses is the parity of its address. The expansion is cached in g2h_pat. | -- |
| `gfx2h_pattern_rect` | fill a rectangle with the current pattern | X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width, X16_P6/P7 = height (no clipping) | -- |
| `gfx2h_blit` | copy a byte-aligned image from CPU RAM into the bitmap | A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR X16_P0/P1 = x (bits 1:0 ignored: byte-aligned), X16_P2/P3 = y, X16_P4 = width in BYTES (4-pixel units), X16_P5 = height in rows, X16_P6/P7 = source (row-major) The source pointer is X16_PTR3 -- P6/P7 double as real zero page, so (PTR3),y addressing costs nothing extra. No clipping. The three RMW ops share one loop whose opcode at .g2h_blit_op is patched from .g2h_optab (ora/and/eor (zp),y) -- the 8bpp module's gfx8l_blit does the same. | -- |
| `gfx2h_blitm` | masked blit of pre-shifted column-major data | X16_P0/P1 = x (any pixel position), X16_P2/P3 = y, X16_P4 = height in rows (1-127), X16_P5 = width in COLUMNS (framebuffer bytes), X16_P6/P7 = source The source holds, for each of the P5 columns, P4 (mask, data) byte PAIRS walking down the rows: fb' = (fb AND mask) OR data. The caller supplies data already shifted for this x's pixel phase (x & 3) -- pre-shifted glyph caches are the whole point: at 833 cycles per 8x8 glyph this is what makes proportional text affordable (spike-proven see the CXRF project). No clipping. | -- |
| `gfx2l_setptr` | point data port 0 at the byte holding pixel (x,y) | A = increment index (VERA_INC_*) X16_P0/P1 = x, X16_P2/P3 = y | A = x & 3 (the pixel's position within the byte) y*80 = (y<<4) + (y<<4)<<2, so no multiply is needed; the result is 17-bit. Stepping by VERA_INC_80 then walks straight down a column. |
| `gfx2l_pset` | set one pixel, clipped | A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y | -- |
| `gfx2l_read` | read one pixel | X16_P0/P1 = x, X16_P2/P3 = y | carry clear, A = colour (0-3); carry set if (x,y) is off screen (A undefined) |
| `gfx2l_hline` | horizontal span (no clipping) | A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length in pixels Head and tail partials are read-modify-write; the middle whole bytes are one vera_fill. | -- |
| `gfx2l_vline` | vertical span (no clipping) | A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length in pixels One column of read-modify-writes: port 1 reads, port 0 writes, both stepping a whole row per access. | -- |
| `gfx2l_pattern_set` | expand an 8x8 1bpp pattern for gfx2l_pattern_rect | A = pattern low, X = pattern high (8 row bytes, top first bit 7 is the leftmost pixel) Y = colours: (background << 2) \| foreground Patterns tile from the screen origin, so each row expands to exactly two 2bpp bytes (16 bits); which of the pair a framebuffer byte uses is the parity of its address. The expansion is cached in g2l_pat. | -- |
| `gfx2l_pattern_rect` | fill a rectangle with the current pattern | X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width, X16_P6/P7 = height (no clipping) | -- |
| `gfx2l_blit` | copy a byte-aligned image from CPU RAM into the bitmap | A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR X16_P0/P1 = x (bits 1:0 ignored: byte-aligned), X16_P2/P3 = y, X16_P4 = width in BYTES (4-pixel units), X16_P5 = height in rows, X16_P6/P7 = source (row-major) The source pointer is X16_PTR3 -- P6/P7 double as real zero page, so (PTR3),y addressing costs nothing extra. No clipping. The three RMW ops share one loop whose opcode at .g2l_blit_op is patched from .g2l_optab (ora/and/eor (zp),y) -- the 8bpp module's gfx8l_blit does the same. | -- |
| `gfx2l_blitm` | masked blit of pre-shifted column-major data | X16_P0/P1 = x (any pixel position), X16_P2/P3 = y, X16_P4 = height in rows (1-127), X16_P5 = width in COLUMNS (framebuffer bytes), X16_P6/P7 = source The source holds, for each of the P5 columns, P4 (mask, data) byte PAIRS walking down the rows: fb' = (fb AND mask) OR data. The caller supplies data already shifted for this x's pixel phase (x & 3) -- pre-shifted glyph caches are the whole point: at 833 cycles per 8x8 glyph this is what makes proportional text affordable (spike-proven see the CXRF project). No clipping. | -- |
| `gfx4h_passthru_off` | -- | -- | -- |
| `gfx4h_pal_load` | -- | -- | -- |
| `gfx4h_pal_gray` | -- | -- | -- |
| `gfx4h_setptr` | point VERA_2 DATA at byte holding pixel (x,y) | A = VERA2_INC_* stride index, X16_P0/P1 = x, X16_P2/P3 = y | -- |
| `gfx4h_pset` | clipped pixel access | -- | -- |
| `gfx4h_read` | -- | -- | -- |
| `gfx4h_hline` | spans, no clipping | A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length hline: RMW the odd leading/trailing nibbles, STREAM the interior as whole two-pixel bytes through DATA at stride +1 -- one sta per two pixels instead of a full pset (address calc + RMW) per pixel. | -- |
| `gfx4h_vline` | -- | -- | -- |
| `gfx4h_rect` | rectangles, no clipping | A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width, X16_P6/P7 = height | -- |
| `gfx4h_line` | Bresenham line, clipped by gfx4h_pset | A = colour, P0/P1=x0, P2/P3=y0, P4/P5=x1, P6/P7=y1 | -- |
| `gfx4h_blit` | packed RAM pixels to framebuffer | -- | -- |
| `gfx4h_blitm` | -- | -- | -- |
| `gfx4h_copy_wait` | -- | -- | -- |
| `gfx4l_setptr` | point data port 0 at the byte holding pixel (x,y) | A = increment index (VERA_INC_*) X16_P0/P1 = x, X16_P2 = y | -- |
| `gfx4l_pset` | set one pixel, clipped | X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour | -- |
| `gfx4l_read` | read one pixel | X16_P0/P1 = x, X16_P2 = y | A = the colour |
| `gfx4l_hline` | horizontal span (no clipping) | X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour, X16_P4/P5 = length in pixels | -- |
| `gfx4l_vline` | vertical span (no clipping) | X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour, X16_P4 = length (1-255) | -- |
| `gfx4l_rect` | filled rectangle | X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour, X16_P4/P5 = width, X16_P6 = height | -- |
| `gfx4l_blit` | rows of pixels from RAM to the framebuffer | A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in pixels (1-255), X16_P5 = height in rows, X16_P6/P7 = source (row-major) | -- |
| `gfx4l_blitm` | a masked blit: colour 0 is transparent | X16_P0/P1 = x, X16_P2 = y, X16_P4 = width (1-255), X16_P5 = height, X16_P6/P7 = source (row-major) | -- |
| `gfx4l_pattern_set` | cache an 8x8 1bpp pattern for gfx4l_pattern_rect | A = pattern low, X = pattern high X16_P4 = background colour, X16_P5 = foreground colour | -- |
| `gfx4l_pattern_rect` | fill a rectangle with the cached pattern | X16_P0/P1 = x, X16_P2 = y, X16_P4/P5 = width, X16_P6 = height | -- |
| `gfx4l_line` | Bresenham, any direction | X16_P0/P1 = x0, X16_P2 = y0 X16_P4/P5 = x1, y1 in P6/P7? (compatible with gfx4l_line macros) X16_P6 = colour | -- |
| `gfx8h_passthru_off` | -- | -- | -- |
| `gfx8h_pal_load` | -- | -- | -- |
| `gfx8h_pal_gray` | -- | -- | -- |
| `gfx8h_setptr` | point VERA_2 DATA at pixel (x,y) | A = VERA2_INC_* stride index, X16_P0/P1 = x, X16_P2/P3 = y | -- |
| `gfx8h_pset` | clipped pixel access | -- | -- |
| `gfx8h_read` | -- | -- | -- |
| `gfx8h_hline` | spans, no clipping | A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length | -- |
| `gfx8h_vline` | -- | -- | -- |
| `gfx8h_pattern_set` | -- | -- | -- |
| `gfx8h_pattern_rect` | -- | -- | -- |
| `gfx8h_blit` | RAM to framebuffer, row-major source | -- | -- |
| `gfx8h_blitm` | -- | -- | -- |
| `gfx8h_copy_wait` | -- | -- | -- |
| `gfx8l_setptr` | point data port 0 at pixel (x,y) | A = increment index (VERA_INC_*) X16_P0/P1 = x, X16_P2 = y y*320 = (y<<8) + (y<<6), so no multiply is needed. Result is 17-bit. Stepping by VERA_INC_320 then walks straight down a column. | -- |
| `gfx8l_hline` | in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour, | -- | -- |
| `gfx8l_vline` | in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour, | -- | -- |
| `gfx8l_read` | read one pixel | X16_P0/P1 = x, X16_P2 = y | A = the colour |
| `gfx8l_pattern_set` | cache an 8x8 1bpp pattern for gfx8l_pattern_rect | A = pattern low, X = pattern high (8 row bytes, top first bit 7 is the leftmost pixel) X16_P4 = background colour, X16_P5 = foreground colour The full-colour pair is the one deliberate departure from the 2bpp signature, whose Y packs two 2-bit colours; 8bpp colours need bytes. | -- |
| `gfx8l_pattern_rect` | fill a rectangle with the cached pattern | X16_P0/P1 = x, X16_P2 = y, X16_P4/P5 = width, X16_P6 = height (P2 and P6 are consumed) Tiles from the screen origin, like the 2bpp module: the pattern cell under a pixel depends only on the pixel, not the rectangle. | -- |
| `gfx8l_blit` | rows of pixel bytes from RAM to the framebuffer | A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in PIXELS (1-255), X16_P5 = height in rows, X16_P6/P7 = source (row-major) The source pointer is X16_PTR3 -- P6/P7 double as real zero page, the 2bpp module's own trick. No clipping. P2 and P5 are consumed. The three RMW ops share one loop: the opcode of the instruction at .gb8l_opcode is patched from .gb8l_optab (ora/and/eor abs), the gfx8l_text trick one byte earlier. | -- |
| `gfx8l_blitm` | a masked blit: byte $00 is transparent | X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in PIXELS (1-255), X16_P5 = height, X16_P6/P7 = source (row-major) At 8bpp the mask IS the data: colour 0 means "leave the screen alone" (a read still advances the port, which is the whole trick). The 2bpp module needs interleaved mask bytes; one byte per pixel does not. P2 and P5 are consumed. | -- |
