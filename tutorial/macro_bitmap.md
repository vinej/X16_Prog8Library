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
