; imgview.p8 -- show a converted image on the 640x480 8bpp VERA_2 bitmap.
;
; The X16 cannot decode PNG/JPG itself, so convert on the PC first:
;     python tools\img2bmx.py photo.jpg build\IMAGE.BMX
; then build + run this (the emulator's -fsroot is build\, where IMAGE.BMX is):
;     .\build.ps1 examples\imgview\imgview.p8 -Run
;
; On the X16 it is a single library call: cx.bmx_load_hires() streams the
; palette into the VERA_2 palette and the pixels into VERA_2 SDRAM.
;
; Press ESC to leave. Returning rather than looping forever is what
; lets examples\desktop launch this and get control back afterwards.

%import x16lib
%import x16lib_const
%import launcharg
%zeropage basicsafe

main {
    ; lowercase on purpose: Prog8's PETSCII maps a-z to $41-$5A, which the
    ; KERNAL/host filesystem reads as the UPPER-CASE name IMAGE.BMX.
    str filename = "image.bmx"

    sub start() {
        cx.load_banks()                 ; no-op unless modules were -Bank'd
        ; A launcher can say which picture to show: the desktop's "open
        ; with" leaves the path in golden RAM and launcharg.get() hands
        ; it back. Nothing passed -- run from BASIC, or from a launcher
        ; that knows nothing about the convention -- and the old default
        ; still applies, so this stays a program you can just RUN.
        uword name = launcharg.get()
        ubyte n = launcharg.length()
        if name == 0 {
            name = &filename
            n = len(filename)
        }
        cx.gfx8h_init()                 ; 640x480 @ 8bpp (needs VERA_2 / -bitmap2)
        cx.bmx_load_hires(name, n, 8)
        while true {                    ; ESC leaves; other keys are ignored
            ubyte k = cx.key_wait()      ; so a stray press cannot dismiss it
            if k == $1B or k == $03
                break
        }
        cx.gfx8h_off()                  ; CINT restores the primary VERA only,
        cx.screen_reset()               ; so drop the VERA_2 bitmap ourselves
    }                                   ; or it hides whatever comes next
}
