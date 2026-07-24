# x16lib Macro Guide — the friendly `xm_*` layer

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Every routine in x16lib is called by loading an argument block and doing a
`jsr`: a 16-bit coordinate into `X16_P0`/`X16_P1`, a colour into `A`, and so on.
That is precise and fast, but writing a dozen `lda`/`sta` lines per call is a
chore. `core/sugar.asm` removes the chore: **one macro per routine**, named
`xm_<routine>`, that takes the arguments in order and makes the call.

```prog8
cx.shape_frrect(40, 40, 200, 110, 28, FILL)  ; a filled rounded rectangle
```

is exactly

```prog8
%asm {{
    lda #<40  : sta rr_x  : lda #>40  : sta rr_x+1
    lda #<40  : sta rr_y  : lda #>40  : sta rr_y+1
    lda #<200 : sta rr_w  : lda #>200 : sta rr_w+1
    lda #<110 : sta rr_h  : lda #>110 : sta rr_h+1
    lda #28   : sta rr_r
    lda #FILL
    jsr shape_frrect
}}
```

This is the same idea as the CXRF `asmsdk` `cxm_*` layer, adapted to x16lib.
It is **optional** — it changes nothing about the library, and this guide is a
companion to the [User Guide](userguide.md), which documents the routines
themselves. If a macro's behaviour is unclear, read its routine there; the macro
just fills in the argument block.

---

## Table of contents

1. [Using the layer](#using-the-layer)
2. [The three rules](#the-three-rules)
3. [Before and after](#before-and-after)
4. [Run-time values and argument-free calls](#run-time-values-and-argument-free-calls)
5. [Reference](#reference)
   - Modules are listed there as bold entries, for example
     `**VERA (X16_USE_VERA)**`.
6. [Worked examples](#worked-examples)
7. [Other assemblers](#other-assemblers)

---

## Using the layer

Set your `X16_USE_*` gates first, then source the layer — **after** the gates and
**before** your own code:

```prog8
%import x16lib



main {
    sub start() {
        cx.gfx2h_init()
        cx.gfx2h_clear(0)
        cx.pal_set(1, $0F00)  ; entry 1 = red
        cx.shape_frrect(40, 40, 200, 110, 28, 1)
    }
}

```

Order matters for two reasons. `x16.asm` defines `X16_P0…P7` and the constants
the macros use, so it comes first. And each module's macros are wrapped in that
module's gate (see the next section), so the gates must be set before the layer
is sourced.

---

## The three rules

**1. It is purely additive.** A program that does not source `core/sugar.asm`, or
sources it but invokes no macro, assembles to byte-for-byte the same bytes as
before. Each macro expands to exactly the hand-written setup plus the `jsr` — no
hidden cost, no wrapper subroutine, nothing at run time.

**2. Macros are gated by their module.** `xm_pal_set` only exists when
`X16_USE_PALETTE` is set, `xm_shape_arc` only when `X16_USE_SHAPES_ARC` is set,
and so on. This keeps a macro from ever naming a routine you did not build (which
the stricter assemblers reject outright). The practical consequence: **set the
gate to get its macros.** The sub-gates (`SHAPES_RRECT`, `PCM_STREAM`, …) each
gate their own — enabling `X16_USE_SHAPES` gives you `xm_shape_circle` but not
`xm_shape_rrect` until you also set `X16_USE_SHAPES_RRECT`.

**3. Arguments are immediates.** A macro loads each argument with `lda #arg`, so
pass **constants or assemble-time expressions**. You cannot feed a macro a value
held in a variable:

```prog8
cx.shape_polygon(320, 240, 80, 6, angle, 1)  ; WRONG if `angle` is a variable
```

`#angle` is the *address* of `angle`, not the rotation stored there. When an
argument is computed at run time, set the block by hand and `jsr` the routine —
see [Run-time values](#run-time-values-and-argument-free-calls).

---

## Before and after

A hexagon, outlined, at a fixed rotation:

```prog8
; --- by hand ---
%asm {{
    lda #<320 : sta X16_P0 : lda #>320 : sta X16_P1
    lda #<240 : sta X16_P2 : lda #>240 : sta X16_P3
    lda #80   : sta X16_P4
    lda #6    : sta X16_P5
    lda #0    : sta X16_P6
    lda #1
    jsr shape_polygon
}}

; --- with the macro ---
cx.shape_polygon(320, 240, 80, 6, 0, 1)
```

Both assemble to the same machine code. The macro is just a name for the
argument order.

---

## Run-time values and argument-free calls

Two kinds of call keep the hand-written form, on purpose.

**Run-time arguments.** Anything that changes as the program runs — a sprite's
live position, a decaying volume, a frame counter — has to go into the argument
block by hand, because the macro would try to load the *address* of the variable
instead of its value:

```prog8
%asm {{
    draw_sprite
    lda pos_x+1; the live 16-bit position
    sta X16_P0
    lda pos_x+2
    sta X16_P1
    lda pos_y+1
    sta X16_P2
    lda pos_y+2
    sta X16_P3
    ldx #0
    jmp sprite_pos; not +xm_sprite_pos: the position is run-time
}}
```

`examples/m_bounce.asm` is the honest picture: the one-shot setup (constant
arguments) is all `xm_*` macros, while the per-frame work on live values stays
hand-written.

**Argument-free routines.** Routines that take no arguments — the accumulator
operations (`i16_add`, `i16_mul`, `f_sqrt`, `f_sin`, `d_exp`), the toggles
(`sprites_on`, `fx_off`), the queries (`vera_has_fx`, `irq_frames`) — have **no
macro**. A wrapper would be nothing but `jsr name`, so just write that:

```prog8
cx.i16_const(i16_a, 1000)  ; load the operands (a macro from core/macros.asm)
cx.i16_const(i16_b, 7)
%asm {{
    jsr i16_divmod; the operation itself takes no arguments
}}
```

Load operands into `i16_a`/`i16_b`, `FAC`, `d_ac` with the existing
`cx.i16_const()`/`cx.i32_const()` macros or the `xm_*_load`/`xm_*_from_*` macros, then
`jsr` the operation.

---

## Reference

Every macro, grouped by module. Each takes the routine's arguments in order;
16-bit values (coordinates, sizes, addresses) are passed whole and split inside
the macro. A `→` note is what the routine returns — the macro does not capture
it, so read it from the registers/flags/P-block afterwards. Angles are the
`sin8`/`cos8` byte convention: `0` = east, `64` = south.

**VERA (X16_USE_VERA)**

[Detailed macro reference](macro_vera.md)

| Macro | Does |
|---|---|
| `cx.vera_set_addr0(l, m, h)` | point data port 0 (compose the H byte yourself) |
| `cx.vera_set_addr1(l, m, h)` | point data port 1 |
| `cx.vera_fill(val, count)` | write `val` `count` times from the current address |
| `cx.vera_copy(count)` | copy `count` bytes port 0 → port 1 (both pre-pointed) |

**Display composer (X16_USE_VERA_DC)**

[Detailed macro reference](macro_display_composer.md)

| Macro | Does |
|---|---|
| `cx.vdc_get_video()` / `cx.vdc_set_video(video)` | read/write `DC_VIDEO` |
| `cx.vdc_set_output(mode)` | set output mode while preserving other video bits |
| `cx.vdc_set_layers(mask)` / `cx.vdc_layer_on(mask)` / `cx.vdc_layer_off(mask)` | layer/sprite enables |
| `cx.vdc_get_scale()` / `cx.vdc_set_scale(hscale, vscale)` | read/write composer scale |
| `cx.vdc_get_border()` / `cx.vdc_set_border(color)` | border palette index |
| `cx.vdc_get_active_raw()` / `cx.vdc_set_active_raw(hstart, hstop, vstart, vstop)` | raw active-display registers |
| `cx.vdc_set_active(hstart, hstop, vstart, vstop)` / `cx.vdc_fullscreen()` | pixel-coordinate active display |
| `cx.vdc_get_version()` | VERA bitstream version (-> carry set if valid) |

**Screen (X16_USE_SCREEN)**

[Detailed macro reference](macro_screen.md)

| Macro | Does |
|---|---|
| `cx.screen_set_mode(mode)` | set the screen mode (→ carry set if unsupported) |
| `cx.screen_reset()` | restore the default text mode |
| `cx.screen_cls()` | clear the text screen |
| `cx.screen_chrout(ch)` | print one character, safely |
| `cx.screen_color(fg, bg)` | text foreground / background (0–15) |
| `cx.screen_border(col)` | border colour (0–15) |
| `cx.screen_locate(row, col)` | move the text cursor |
| `cx.screen_charset(cs)` | select a charset |
| `cx.screen_puts(addr)` | print a NUL-terminated string |

**Palette (X16_USE_PALETTE)**

[Detailed macro reference](macro_palette.md)

| Macro | Does |
|---|---|
| `cx.pal_set(index, rgb)` | set one entry; `rgb` is a 12-bit `$0RGB` value |
| `cx.pal_load(src, first, count)` | bulk-load `count` entries from RAM |

**Tiles and layers (X16_USE_TILE)**

[Detailed macro reference](macro_tiles.md)

| Macro | Does |
|---|---|
| `cx.layer_on(layer)` / `cx.layer_off(layer)` | enable / disable a layer |
| `cx.layer_set_config(layer, cfg)` | the layer's CONFIG byte |
| `cx.layer_set_mapbase(layer, base)` | where the map lives (VRAM ≫ 9) |
| `cx.layer_scroll_x(layer, val)` / `cx.layer_scroll_y(layer, val)` | 12-bit hardware scroll |
| `cx.tile_setptr(col, row)` | point port 0 at a layer-1 map cell |
| `cx.tile_put(col, row, code, attr)` | write one cell |
| `cx.tile_get(col, row)` | read one cell (→ A = code, X = attribute) |

**Sprites (X16_USE_SPRITE)**

[Detailed macro reference](macro_sprites.md)

| Macro | Does |
|---|---|
| `cx.sprites_on()` / `cx.sprites_off()` | the sprite renderer as a whole |
| `cx.sprite_init_all()` | zero all 128 attribute records |
| `cx.sprite_pos(sprite, x, y)` | set a sprite's 10-bit position |
| `cx.sprite_get_pos(sprite)` | read it back (→ P0/1 = x, P2/3 = y) |
| `cx.sprite_image(sprite, vaddr, mode)` | point at pixels; `mode` = `SPRITE_MODE_4BPP`/`8BPP` |
| `cx.sprite_flags(sprite, flags)` | byte 6: collision mask, Z, flips |
| `cx.sprite_z(sprite, z)` | change only the Z-depth |
| `cx.sprite_size(sprite, wcode, hcode, paloff)` | size codes + palette offset |

**Bitmap graphics (X16_USE_BITMAP8L/2H/2L/4L/4H/8H)**

[Detailed macro reference](macro_bitmap.md)

| Gate / prefix | Does |
|---|---|
| `X16_USE_BITMAP8L` / `gfx8l` | 320x240, 8 bpp, VERA VRAM; init, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, char/text |
| `X16_USE_BITMAP4L` / `gfx4l` | 320x240, 4 bpp, VERA VRAM; same as 8L, with 4-bit pixels |
| `X16_USE_BITMAP2L` / `gfx2l` | 320x240, 2 bpp, VERA VRAM; init, clear, setptr, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm |
| `X16_USE_BITMAP2H` / `gfx2h` | 640x480, 2 bpp, MiSTer VERA_2 SDRAM; same as 2L at high resolution |
| `X16_USE_BITMAP4H` / `gfx4h` | 640x480, 4 bpp, MiSTer VERA_2 SDRAM; `has/init/off`, passthru, palette, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, copy |
| `X16_USE_BITMAP8H` / `gfx8h` | 640x480, 8 bpp, MiSTer VERA_2 SDRAM; same as 4H, with 8-bit pixels |

**Framebuffer (X16_USE_FB)**

[Detailed macro reference](macro_framebuffer.md)

| Macro | Does |
|---|---|
| `cx.fb_init()` / `cx.fb_get_info()` | active KERNAL framebuffer driver |
| `cx.fb_set_palette(data, start, count)` | set palette entries |
| `cx.fb_cursor_position(x, y)` / `cx.fb_cursor_next_line()` | framebuffer cursor |
| `cx.fb_get_pixel(x, y)` / `cx.fb_set_pixel(x, y, color)` | one pixel |
| `cx.fb_get_pixels(dest, count)` / `cx.fb_set_pixels(src, count)` | pixel runs |
| `cx.fb_set_8_pixels(pattern, color)` / `cx.fb_set_8_pixels_opaque(mask, pattern, fg, bg)` | 8-pixel pattern helpers |
| `cx.fb_fill_pixels(count, step, color)` / `cx.fb_filter_pixels(count, filter)` | fill/filter from cursor |
| `cx.fb_move_pixels(sx, sy, tx, ty, count)` | move a horizontal span |

**GRAPH (X16_USE_GRAPH)**

[Detailed macro reference](macro_graph.md)

| Macro | Does |
|---|---|
| `cx.graph_init_default()` / `cx.graph_init(driver)` | init GRAPH with default/custom FB driver |
| `cx.graph_clear()` / `cx.graph_set_window(x, y, w, h)` | clear/window |
| `cx.graph_set_colors(stroke, fill, background)` | drawing colours |
| `cx.graph_draw_line(x1, y1, x2, y2)` | line |
| `cx.graph_draw_rect_outline/fill x, y, w, h, radius` | rectangles |
| `cx.graph_move_rect(sx, sy, tx, ty, w, h)` | move rectangle |
| `cx.graph_draw_oval_outline/fill x, y, w, h` | ovals |
| `cx.graph_draw_image(x, y, image, w, h)` | image bytes |
| `cx.graph_set_font_default()` / `cx.graph_set_font(font)` | font |
| `cx.graph_get_char_size(char, style)` / `cx.graph_put_char(char, x, y)` | text metrics/draw |

**Console (X16_USE_CONSOLE)**

[Detailed macro reference](macro_console.md)

| Macro | Does |
|---|---|
| `cx.con_init_fullscreen()` / `cx.con_init(x, y, w, h)` | initialize console |
| `cx.con_set_paging_message(msg)` / `cx.con_disable_paging()` | paging controls |
| `cx.con_put_char_wrap(char)` / `cx.con_put_char_word(char)` | print with wrapping |
| `cx.con_get_char()` | read one console character |
| `cx.con_put_image(image, w, h)` | draw console image data |

**Shapes (X16_USE_SHAPES + sub-gates)**

[Detailed macro reference](macro_shapes.md)

| Macro | Does |
|---|---|
| `SHP_*` bindings | engine selection; default is 2 bpp |
| `cx.shape_circle(cx, cy, r, col)` / `cx.shape_disc(...)` | `SHAPES` gate |
| `cx.shape_ellipse(cx, cy, rx, ry, col)` / `cx.shape_fellipse(...)` | `SHAPES` gate |
| `cx.shape_flood(x, y, col)` | `SHAPES` gate; → carry set = stack overflowed |
| `cx.shape_polygon(cx, cy, r, sides, rot, col)` / `cx.shape_fpolygon(...)` | `SHAPES_POLY` gate |
| `cx.shape_rrect(x, y, w, h, r, col)` / `cx.shape_frrect(...)` | `SHAPES_RRECT` gate |
| `cx.shape_arc(cx, cy, r, a0, a1, col)` | `SHAPES_ARC` gate |
| `cx.shape_pie(cx, cy, r, a0, a1, col)` | `SHAPES_PIE` gate |
| `cx.shape_bezier(x0, y0, x1, y1, x2, y2, x3, y3, col)` | `SHAPES_BEZIER` gate |

**VERA FX (X16_USE_VERAFX)**

[Detailed macro reference](macro_verafx.md)

| Macro | Does |
|---|---|
| `cx.fx_off()` | disable FX (leaves DCSEL/ADDRSEL = 0) |
| `cx.fx_mult(a, b)` | signed 16×16 (→ P4..P7 = product) |
| `cx.fx_fill(val, count)` | fast fill from the current address |
| `cx.fx_clear(addrlo, addrmid, addrhi, count)` | zero a VRAM region |
| `cx.fx_transp_on()` / `cx.fx_transp_off()` | transparent VRAM writes |
| `cx.fx_line(x0, y0, x1, y1, col)` | hardware-assisted line |

**VERA FX utilities (X16_USE_VERAFX_UTILS)**

[Detailed macro reference](macro_verafx_utils.md)

| Macro | Does |
|---|---|
| `cx.fxu_off()` / `cx.fxu_get_ctrl()` / `cx.fxu_set_ctrl(ctrl)` | FX control |
| `cx.fxu_ctrl_on(mask)` / `cx.fxu_ctrl_off(mask)` | set/clear FX bits |
| `cx.fxu_addr1_mode(mode)` | ADDR1 mode bits |
| `cx.fxu_cache_write_on/off`, `cx.fxu_cache_fill_on/off`, `cx.fxu_cache_cycle_on/off` | cache modes |
| `cx.fxu_transparent_on/off`, `cx.fxu_4bit_on/off`, `cx.fxu_hop_on/off` | transparent, 4-bit, 16-bit hop |
| `cx.fxu_set_mult(mult)` / `cx.fxu_set_cache(b0, b1, b2, b3)` | multiplier/cache registers |
| `cx.fxu_reset_accum()` / `cx.fxu_accumulate()` | accumulator helpers |
| `cx.fxu_cache_fill0/1` / `cx.fxu_cache_write0/1 mask` | cache fill/write primitives |
| `cx.fxu_set_incr(xinc, yinc)` / `cx.fxu_set_pos(xpos, ypos)` / `cx.fxu_set_subpos(xsub, ysub)` | affine stepping state |
| `cx.fxu_get_poly_fill()` / `cx.fxu_set_tilebase(value)` / `cx.fxu_set_mapbase(value)` | polygon/tile/map helpers |

**Interrupts (X16_USE_IRQ)**

[Detailed macro reference](macro_interrupts.md)

| Macro | Does |
|---|---|
| `cx.irq_install()` / `cx.irq_remove()` | hook / unhook the frame counter |
| `cx.vsync_wait()` | block until the next frame boundary |
| `cx.irq_line_install(handler)` | call a handler at a scanline |
| `cx.irq_sprcol_install(handler)` (`handler` = 0 polls) / `cx.irq_sprcol_remove()` | sprite-collision interrupt |

**PSG (X16_USE_PSG)**

[Detailed macro reference](macro_psg.md)

| Macro | Does |
|---|---|
| `cx.psg_init()` | silence all 16 voices |
| `cx.psg_set_freq(voice, freq)` | frequency word |
| `cx.psg_set_vol(voice, vol, pan)` | volume (0–63) + pan |
| `cx.psg_set_wave(voice, wave, width)` | waveform + pulse width |
| `cx.psg_note_off(voice)` | volume to zero, keep the rest |
| `cx.psg_env_start / _release / _stop voice` | ASR envelope control |
| `cx.psg_env_tick()` | advance every armed envelope (once a frame) |

**YM2151 (X16_USE_YM)**

[Detailed macro reference](macro_ym2151.md)

| Macro | Does |
|---|---|
| `cx.ym_init()` | reset the chip, load the default patches |
| `cx.ym_write(reg, val)` / `cx.ym_poke(reg, val)` | raw register write / shadowed write |
| `cx.ym_patch_rom(channel, index)` | load a built-in ROM patch (0–162) |
| `cx.ym_note(channel, kc, kf)` | play a raw key code |
| `cx.ym_note_bas(channel, note)` | play a packed note (0 releases) |
| `cx.ym_release_note(channel)` | release |
| `cx.ym_vol(channel, atten)` / `cx.ym_pan(channel, pan)` | volume / pan |
| `cx.ym_drum(channel, note)` | a drum voice |

**ROM audio (X16_USE_AUDIO_ROM)**

[Detailed macro reference](macro_rom_audio.md)

| Macro | Does |
|---|---|
| Scope | thin ROM `BANK_AUDIO` wrappers; separate from local PSG/YM modules |
| `cx.ar_audio_init()`, `cx.ar_playstring_voice(voice)` | general ROM audio helpers |
| `cx.ar_fmplaystring(str, len)`, `cx.ar_fmchordstring(str, len)`, `cx.ar_psgplaystring(str, len)`, `cx.ar_psgchordstring(str, len)` | play strings/chords |
| `cx.ar_fmfreq(channel, hz)`, `cx.ar_fmfreq_no_retrigger(channel, hz)`, `cx.ar_fmnote(channel, note, kf)`, `cx.ar_fmnote_no_retrigger(channel, note, kf)`, `cx.ar_fmvib(speed, depth)` | FM helpers |
| `cx.ar_psgfreq(voice, hz)`, `cx.ar_psgnote(voice, note, kf)`, `cx.ar_psgwav(voice, wave)` | PSG helpers |
| `cx.ar_note_bas2fm()`, `bas2midi`, `bas2psg`, `fm2bas`, `fm2midi`, `fm2psg`, `freq2bas/fm/midi/psg`, `midi2bas/fm/psg`, `psg2bas/fm/midi` | note conversion |
| `cx.ar_psg_init()`, `cx.ar_psg_playfreq()`, `cx.ar_psg_read_raw/cooked`, `cx.ar_psg_setatten/freq/pan/vol`, `cx.ar_psg_write()`, `cx.ar_psg_write_fast()`, `cx.ar_psg_getatten/pan` | ROM PSG shadows |
| `cx.ar_ym_init()`, `cx.ar_ym_loaddefpatches()`, `cx.ar_ym_loadpatch_rom()`, `cx.ar_ym_loadpatchlfn()`, `cx.ar_ym_playdrum/playnote`, `cx.ar_ym_setatten/drum/note/pan`, `cx.ar_ym_read_raw/cooked`, `cx.ar_ym_release()`, `cx.ar_ym_trigger()`, `cx.ar_ym_trigger_no_retrigger()`, `cx.ar_ym_write()`, `cx.ar_ym_getatten/pan`, `cx.ar_ym_get_chip_type()` | ROM YM shadows |

**PCM (X16_USE_PCM, X16_USE_PCM_STREAM)**

[Detailed macro reference](macro_pcm.md)

| Macro | Does |
|---|---|
| `cx.pcm_ctrl(byte)` / `cx.pcm_rate(rate)` / `cx.pcm_reset()` | `PCM` gate |
| `cx.pcm_put(sample)` / `cx.pcm_write(src, count)` | `PCM` gate |
| `cx.pcm_stream_start(src, count, loop)` / `cx.pcm_stream_stop()` | `PCM_STREAM` gate |

**ZSM (X16_USE_ZSM, X16_USE_ZSM_PCM)**

[Detailed macro reference](macro_zsm.md)

| Macro | Does |
|---|---|
| `cx.zsm_init(header)` / `cx.zsm_init_stream(stream, loop)` | `ZSM` gate |
| `cx.zsm_play()` / `cx.zsm_stop()` / `cx.zsm_rewind()` | `ZSM` gate |
| `cx.zsm_get_tickrate()` / `cx.zsm_status()` / `cx.zsm_tick()` | `ZSM` gate |
| `cx.zsm_pcm_present()` / `cx.zsm_pcm_trigger(instrument)` | `ZSM_PCM` gate |

**ADPCM (X16_USE_ADPCM)**

[Detailed macro reference](macro_adpcm.md)

| Macro | Does |
|---|---|
| `cx.adpcm_init()` | initialize ADPCM state |
| `cx.adpcm_nibble(code)` | decode one ADPCM nibble |
| `cx.adpcm_block(src, dst, count)` | decode a block |

**Input (X16_USE_INPUT)**

[Detailed macro reference](macro_input.md)

| Macro | Does |
|---|---|
| `cx.joy_scan()` / `cx.joy_get(pad)` | sample / read a joystick (→ A/X/Y = buttons) |
| `cx.mouse_show(cursor)` / `cx.mouse_hide()` / `cx.mouse_get()` | mouse (→ P0/1 = x, P2/3 = y, A = buttons) |
| `cx.key_get()` / `cx.key_wait()` / `cx.key_peek()` | keyboard (→ A = PETSCII) |

**Keyboard (X16_USE_KEYBOARD)**

[Detailed macro reference](macro_keyboard.md)

| Macro | Does |
|---|---|
| `cx.kbd_scan()` / `cx.kbd_peek()` / `cx.kbd_put(key)` | keyboard scan/read/write helpers |
| `cx.kbd_get_modifiers()` | read modifier state |
| `cx.kbd_get_keymap()` / `cx.kbd_set_keymap(name)` | keymap helpers |

**Mouse (X16_USE_MOUSE)**

[Detailed macro reference](macro_mouse.md)

| Macro | Does |
|---|---|
| `cx.mse_config(cursor, width8, height8)` | configure mouse cursor |
| `cx.mse_scan()` / `cx.mse_get()` / `cx.mse_get_to(zp)` | mouse sample/read helpers |
| `cx.mse_show(cursor)` / `cx.mse_show_keep()` / `cx.mse_hide()` | mouse visibility helpers |

**Serial (X16_USE_SERIAL)**

[Detailed macro reference](macro_serial.md)

| Macro | Does |
|---|---|
| `base` / `divisor` | `base` is from `ser_detect` or `$9F60`; `divisor` is a `SER_BAUD_*` constant |
| `cx.ser_detect()` | scan for UARTs (→ A = count, `ser_u0`/`ser_u1` = bases) |
| `cx.ser_init(base, divisor)` | 8N1, FIFOs, auto-flow; selects that UART |
| `cx.ser_avail()` | → carry set if a byte is waiting |
| `cx.ser_get()` | non-blocking read (→ carry set = empty, else A = byte) |
| `cx.ser_get_wait()` | blocking read (→ A = byte) |
| `cx.ser_put(byte)` | send one byte |
| `cx.ser_puts(addr)` | send a NUL-terminated string |
| `cx.ser_write(addr, len)` | send `len` bytes (binary-safe) |
| `cx.ser_read_until(match, buffer, max)` | read into buffer until `match` (→ P4/5 = count) |
| `cx.ser_discard_until(match)` | read and discard until `match` |

**ZiModem (X16_USE_SERIAL_ZIMODEM)**

[Detailed macro reference](macro_zimodem.md)

| Macro | Does |
|---|---|
| Scope | ESP32 WiFi modem helpers on top of Serial; most block on real hardware replies |
| `cx.zi_init(base, divisor)` | reset the modem to a known state |
| `cx.zi_cmd(addr)` | send an `AT…` command line (+ CR/LF) |
| `cx.zi_wait_ok()` | read/discard the reply up to `OK\r\n` |
| `cx.zi_reset()` | `ATZ` |
| `cx.zi_get_ip(buffer)` | IPv4 address into buffer (via `ATI2`) |
| `cx.zi_hex_open(filename)` | begin a hex-mode download (→ carry set = not found) |
| `cx.zi_hex_chunk(buffer)` | next payload chunk (→ A = bytes, 0 = done) |
| `cx.zi_hex_close()` | swallow the trailing `OK` |
| `cx.zi_hexdecode(src, digits, dest)` | pack ASCII hex → bytes (→ A = `digits`/2) |

**I2C (X16_USE_I2C)**

[Detailed macro reference](macro_i2c.md)

| Macro | Does |
|---|---|
| `cx.i2c_read_byte(device, offset)` | read one byte |
| `cx.i2c_write_byte(value, device, offset)` | write one byte |
| `cx.i2c_batch_read(device, buffer, count)` | read a sequence |
| `cx.i2c_batch_read_fixed(device, buffer, count)` | read from a fixed register |
| `cx.i2c_batch_write(device, buffer, count)` | write a sequence |

**VERA SPI (X16_USE_VERA_SPI)**

[Detailed macro reference](macro_vera_spi.md)

| Macro | Does |
|---|---|
| `cx.spi_get_ctrl()` / `cx.spi_set_ctrl(ctrl)` | read/write SPI control |
| `cx.spi_select()` / `cx.spi_deselect()` | chip select helpers |
| `cx.spi_slow()` / `cx.spi_fast()` | clock speed helpers |
| `cx.spi_autotx_on()` / `cx.spi_autotx_off()` | auto-transmit controls |
| `cx.spi_wait()` | wait for SPI ready |
| `cx.spi_transfer(byte)` | transfer one byte |
| `cx.spi_read()` / `cx.spi_write(byte)` / `cx.spi_autotx_read()` | byte I/O helpers |
| `cx.spi_read_bytes(buffer, count)` / `cx.spi_write_bytes(buffer, count)` | block I/O helpers |

**Banked RAM (X16_USE_BANK)**

[Detailed macro reference](macro_banked_ram.md)

| Macro | Does |
|---|---|
| `cx.bank_set(bank)` | map a RAM bank at `$A000` |
| `cx.bank_peek(bank, offset)` (→ A = byte) / `cx.bank_poke(bank, offset, byte)` | one byte |
| `cx.mem_to_bank(src, bank, offset, count)` | copy low RAM into a bank |

**Bank allocator (X16_USE_BANKALLOC)**

[Detailed macro reference](macro_bank_allocator.md)

| Macro | Does |
|---|---|
| `cx.bank_alloc_init(first, last)` | initialize allocator range |
| `cx.bank_alloc()` | allocate one bank; → carry clear, A = bank |
| `cx.bank_free(bank)` | free one bank |
| `cx.bank_reserve(bank)` | reserve one bank |

**Block memory (X16_USE_MEM)**

[Detailed macro reference](macro_block_memory.md)

| Macro | Does |
|---|---|
| `cx.mem_fill(dst, count, val)` | fill (streams to VERA too) |
| `cx.mem_copy(src, dst, count)` | copy |
| `cx.mem_crc(addr, count)` | CRC-16 (→ A/X) |
| `cx.mem_decompress(src, dst)` | LZSA2 (→ A/X = one past the end) |

**Load/save (X16_USE_LOAD)**

[Detailed macro reference](macro_load.md)

| Macro | Does |
|---|---|
| `cx.fs_setname(name, len)` | set KERNAL filename |
| `cx.fs_load(name, len, device, sa, dst)` | load to RAM; → carry set = error, A = code |
| `cx.fs_vload(name, len, device, vbank, vaddr)` | load to VRAM |

**File I/O (X16_USE_FILEIO)**

[Detailed macro reference](macro_fileio.md)

| Macro | Does |
|---|---|
| `cx.fio_set_lfs(logical, device, secondary)` / `cx.fio_set_name(name, len)` | KERNAL file setup |
| `cx.fio_open_named/open_read/open_write name, len, logical, device, secondary` | open helpers |
| `cx.fio_close(logical)` / `cx.fio_close_named(logical)` | close helpers |
| `cx.fio_chkin(logical)` / `cx.fio_chkout(logical)` / `cx.fio_clrchn()` | channel helpers |
| `cx.fio_chrin()` / `cx.fio_chrout(byte)` / `cx.fio_getin()` | byte I/O helpers |
| `cx.fio_readst()` | read KERNAL status |
| `cx.fio_close_all()` / `cx.fio_close_device(device)` | bulk close helpers |

**IEC (X16_USE_IEC)**

[Detailed macro reference](macro_iec.md)

| Macro | Does |
|---|---|
| `cx.iec_listen(device)` / `cx.iec_talk(device)` | bus attention helpers |
| `cx.iec_second(command)` / `cx.iec_tksa(command)` | secondary address helpers |
| `cx.iec_ciout(byte)` / `cx.iec_acptr()` | byte I/O helpers |
| `cx.iec_unlisten()` / `cx.iec_untalk()` | release bus helpers |
| `cx.iec_set_timeout(control)` / `cx.iec_readst()` | timeout/status helpers |
| `cx.iec_macptr(dest, count)` / `cx.iec_mciout(src, count)` | block I/O helpers |
| `cx.iec_open_channel(device, secondary)` / `cx.iec_data_channel(device, secondary)` / `cx.iec_talk_channel(device, secondary)` / `cx.iec_close_channel(device, secondary)` | channel helpers |

**DOS (X16_USE_DOS)**

[Detailed macro reference](macro_dos.md)

| Macro | Does |
|---|---|
| `cx.dos_cmd(cmd, len)` | execute command; → A = status |
| `cx.dos_status()` | read DOS status |
| `cx.dos_delete(name, len)` | delete file |

**BMX (X16_USE_BMX)**

[Detailed macro reference](macro_bmx.md)

| Macro | Does |
|---|---|
| `cx.bmx_load(name, len, device, vbank, vaddr)` | load BMX image to VRAM |

**Clock (X16_USE_CLOCK)**

[Detailed macro reference](macro_clock.md)

| Macro | Does |
|---|---|
| `cx.clock_update()` | update clock state |
| `cx.clock_get_timer()` / `cx.clock_set_timer(ticks)` | jiffy timer helpers |
| `cx.clock_get_date_time()` | read date/time |
| `cx.clock_set_date_time_raw(year1900, month, day, hours, minutes, seconds, jiffies, weekday)` | set raw date/time |
| `cx.clock_set_date_time(year, month, day, hours, minutes, seconds, weekday)` | set date/time |

**Math (X16_USE_MATH)**

[Detailed macro reference](macro_math.md)

| Macro | Does |
|---|---|
| `cx.rnd_seed(seed)` | seed the PRNG (16-bit) |
| `cx.sin8(angle)` / `cx.cos8(angle)` | → A = −127..127 |
| `cx.sin8u(angle)` / `cx.cos8u(angle)` | → A = 1..255 |
| `cx.atan2(dx, dy)` | → A = angle 0–255 (`dx`,`dy` signed bytes) |
| `cx.lerp8(a, b, t)` | → A = interpolated value |

**Collision (X16_USE_COLLIDE)**

[Detailed macro reference](macro_collision.md)

| Macro | Does |
|---|---|
| `cx.collide8(ax, ay, aw, ah, bx, by, bw, bh)` | 8-bit AABB test; → carry set if overlap |
| `cx.collide16(...)` | 16-bit AABB test; → carry set if overlap |

**Bits (X16_USE_BITS)**

[Detailed macro reference](macro_bits.md)

| Macro | Does |
|---|---|
| `cx.catnib(hi, lo)` | combine two nibbles |
| `cx.hinib(byte)` / `cx.lonib(byte)` | extract high/low nibble |
| `cx.bit_set(addr, mask)` / `cx.bit_clr(addr, mask)` / `cx.bit_test(addr, mask)` | bit operations |

**Number (X16_USE_NUMBER)**

[Detailed macro reference](macro_number.md)

| Macro | Does |
|---|---|
| `cx.u16_to_dec(value)` / `cx.u16_to_hex(value)` | format unsigned 16-bit; → A/X = buffer, Y = length |
| `cx.dec_to_u16(str, len)` | parse decimal; → P4/5 = value, carry set on bad digit |

**Fixed point (X16_USE_FIXED)**

[Detailed macro reference](macro_fixed.md)

| Macro | Does |
|---|---|
| `cx.umul16(a, b)` | unsigned 16x16 multiply; → P4..P7 = product |
| `cx.mul88(a, b)` | signed 8.8 multiply; → P0/1 |

**Integers (X16_USE_INT16, X16_USE_INT32)**

[Detailed macro reference](macro_integers.md)

| Macro / routine | Does |
|---|---|
| `i16_add`, `i16_mul`, `i32_divmod`, … | argument-free routines; load `i16_a`/`i16_b` or `i32_a`/`i32_b`, then `jsr` |
| `cx.i16_from_u8(byte)` / `cx.i16_from_s8(byte)` | integer loaders |
| `cx.i32_from_u16(value)` / `cx.i32_from_s16(value)` | integer loaders |

**Float (X16_USE_FLOAT)**

[Detailed macro reference](macro_float.md)

| Macro | Does |
|---|---|
| `FAC` / `addr` | accumulator / pointer to a 5-byte float in memory |
| `f_sqrt`, `f_sin`, `f_ln`, `f_int`, … | argument-free unary routines; call directly |
| `cx.f_from_u8(byte)` / `cx.f_from_s16(value)` | build FAC from an integer |
| `cx.f_from_str(str, len)` | parse a string into FAC |
| `cx.f_load(addr)` / `cx.f_store(addr)` | FAC ↔ memory |
| `cx.f_add / _sub / _mul / _div addr` | FAC ⊕ mem |
| `cx.f_rsub(addr)` / `cx.f_rdiv(addr)` | mem − FAC / mem ÷ FAC |
| `cx.f_pow(addr)` | FAC = FAC ^ mem |
| `cx.f_cmp(addr)` | → A = −1 / 0 / 1 |

**Double (X16_USE_DOUBLE)**

[Detailed macro reference](macro_double.md)

| Macro | Does |
|---|---|
| `d_ac` / `addr` | accumulator / pointer to an 8-byte double in memory |
| `d_exp`, `d_sqrt`, `d_sin`, … | argument-free unary routines; call directly |
| `cx.d_from_s16(value)` / `cx.d_from_str(str, len)` | build d_ac |
| `cx.d_load(addr)` / `cx.d_store(addr)` | d_ac ↔ memory |
| `cx.d_add / _sub / _mul / _div addr` | d_ac ⊕ mem |
| `cx.d_pow(addr)` | d_ac = d_ac ^ mem |
| `cx.d_cmp(addr)` | → A = −1 / 0 / 1 |

**Clip (X16_USE_CLIP)**

[Detailed macro reference](macro_clip.md)

| Macro | Does |
|---|---|
| `cx.clip_set(xmin, ymin, xmax, ymax)` | set the clip rectangle |

**Buffers (X16_USE_BUFFERS)**

[Detailed macro reference](macro_buffers.md)

| Macro | Does |
|---|---|
| `cx.rb_init()` / `cx.rb_count()` | ring buffer init / count |
| `cx.rb_put(byte)` | ring buffer put; → carry set = full |
| `cx.rb_get()` | ring buffer get; → A = byte, carry set = empty |
| `cx.stk_init()` / `cx.stk_push(byte)` / `cx.stk_pop()` / `cx.stk_depth()` | byte stack helpers |

**Compression (X16_USE_ZX0, X16_USE_TSC)**

[Detailed macro reference](macro_compression.md)

| Macro | Does |
|---|---|
| `cx.zx0_decompress(src, dst)` | decompress ZX0; → A/X = one past the last output byte |
| `cx.tsc_decompress(src, dst)` | decompress TSC; → A/X = one past the last output byte |

**Strings (X16_USE_STRING and friends)**

[Detailed macro reference](macro_strings.md)

| Macro | Does |
|---|---|
| Gates / arguments | each string gate is separate; `str`/`src`/`dst` are addresses, `ch` and lengths are immediates |
| `cx.str_length(str)` | → Y = length |
| `cx.str_copy(src, dst)` | copy (→ Y = length) |
| `cx.str_ncopy(src, dst, max)` | copy, capped |
| `cx.str_append(tgt, suffix)` | → A = new length |
| `cx.str_nappend(tgt, suffix, max)` | append, capped |
| `cx.str_compare(s1, s2)` | → A = −1 / 0 / 1 |
| `cx.str_hash(str)` | → A = hash |
| `cx.str_lower(str)` / `cx.str_lower_iso(str)` | lower-case in place |
| `cx.str_upper(str)` / `cx.str_upper_iso(str)` | upper-case in place |
| `cx.str_compare_nocase(s1, s2)` (+ `_iso`) | case-insensitive compare |
| `cx.str_find(str, ch)` / `cx.str_rfind(str, ch)` | → carry + A = index |
| `cx.str_find_eol(str)` | first CR/LF |
| `cx.str_contains(str, ch)` | → carry set if present |
| `cx.str_pattern_match(str, pattern)` | `?`/`*` match → carry |
| `cx.str_left(src, dst, len)` / `cx.str_right(…)` | copy an end |
| `cx.str_slice(src, dst, start, len)` | copy a middle run |
| `cx.str_ltrim(str)` / `cx.str_rtrim(str)` / `cx.str_trim(str)` | trim whitespace in place |
| `str_isdigit`, `str_lowerchar`, … | character already in `A`; call directly |

---

## Worked examples

A four-colour scene, entirely through the layer:

```prog8
; ...
cx.gfx2h_init()
cx.gfx2h_clear(0)
cx.pal_set(1, $0FFF)  ; white
cx.pal_set(2, $00F0)  ; green
cx.shape_frrect(40, 40, 200, 110, 28, 2)  ; a green panel
cx.shape_rrect(40, 40, 200, 110, 28, 1)  ; white outline on top
cx.shape_arc(400, 240, 90, 0, 128, 1)  ; a white half-circle
```

Setup versus per-frame (from `examples/m_bounce.asm`):

```prog8
; setup: constant arguments -> macros
cx.sprite_image(0, $13000, SPRITE_MODE_8BPP)
cx.sprite_size(0, SPRITE_SIZE_16, SPRITE_SIZE_16, 0)
cx.sprite_flags(0, SPRITE_Z_FRONT)
cx.sprites_on()

%asm {{
    loop
}}
cx.vsync_wait()
%asm {{
    jsr move_sprite; per-frame: the live position is
    jsr draw_sprite;   hand-written inside these
    ...
}}
```

The plain examples each have a macro edition — `m_hello.asm`, `m_polygons.asm`,
`m_polyspin.asm`, `m_bounce.asm`, `m_numbers.asm` — that show the layer in use.
Run one with `run.bat m_bounce`. (`m_numbers.asm` prints output identical to
`numbers.asm`, so it doubles as a check that the macros carry the right bytes.)

---

## Other assemblers

`core/sugar.asm` is written for ACME and, like the rest of the library, the six
other dialect trees are generated from it, so the same macros exist in ca65,
64tass, KickAssembler, dasm, MADS and vasm — you just invoke them in each
assembler's own way (`cx.pal_set(…)` in ACME, `xm_pal_set …` in ca65,
`xm_pal_set(…)` in KickAssembler, and so on; the converters handle it). Source
the converted `core/sugar` from your tree after setting the gates, exactly as
above.
