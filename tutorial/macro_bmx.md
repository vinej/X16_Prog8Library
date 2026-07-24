# BMX Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BMX` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.bmx_load(name, len, device, vbank, vaddr)`

| Field | Details |
|---|---|
| Macro | `cx.bmx_load(name, len, device, vbank, vaddr)` |
| Purpose | load BMX image to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BMX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bmx_load(name, len, device, vbank, vaddr)
    }
}
```

## `cx.bmx_load_hires(name, len, device)`

| Field | Details |
|---|---|
| Macro | `cx.bmx_load_hires(name, len, device)` |
| Purpose | load a BMX image into the VERA_2 640x480 8bpp SDRAM bitmap (the `gfx8h` engine) |
| Input parameters | `name`: filename address; `len`: filename length; `device`: device number (usually 8) |
| Output parameters | Carry clear on success; carry set with `A` = `BMX_ERR_*` on failure. `bmx_width`/`bmx_height`/`bmx_bpp`/`bmx_palstart`/`bmx_palcount`/`bmx_border` reflect the file. |
| More info | Like `bmx_load`, but the palette streams into the VERA_2 palette and the pixels stream (via MACPTR) into VERA_2 SDRAM starting at offset 0, rather than into VERA VRAM. Select the hi-res 8bpp mode first with `gfx8h_init`. Rows land 640 bytes apart, so a full-width 640x480 image is a plain contiguous load. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.gfx8h_init()  ; 640x480 @ 8bpp (needs VERA_2)
        cx.bmx_load_hires(name, len, device)
    }
}
```
