; imgview.p8 -- show a converted image on the 640x480 8bpp VERA_2 bitmap.
;
; The X16 cannot decode PNG/JPG itself, so convert on the PC first:
;     python tools\img2bmx.py photo.jpg build\IMAGE.BMX
; then build + run this (the emulator's -fsroot is build\, where IMAGE.BMX is):
;     .\build.ps1 examples\imgview\imgview.p8 -Run
;
; On the X16 it is a single library call: cx.bmx_load_hires() streams the
; palette into the VERA_2 palette and the pixels into VERA_2 SDRAM.

%import x16lib
%import x16lib_const
%zeropage basicsafe

main {
    ; lowercase on purpose: Prog8's PETSCII maps a-z to $41-$5A, which the
    ; KERNAL/host filesystem reads as the UPPER-CASE name IMAGE.BMX.
    str filename = "image.bmx"

    sub start() {
        cx.load_banks()                 ; no-op unless modules were -Bank'd
        cx.gfx8h_init()                 ; 640x480 @ 8bpp (needs VERA_2 / -bitmap2)
        cx.bmx_load_hires(&filename, len(filename), 8)
        repeat { }
    }
}
