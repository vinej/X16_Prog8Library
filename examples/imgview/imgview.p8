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
; Which picture, in order of preference:
;   1. whatever a launcher handed over (launcharg -- the desktop's
;      "open with" does this)
;   2. whatever you pick with O, which opens the file browser filtered
;      to *.bmx
;   3. image.bmx, the old default, so RUN still works from BASIC
;
; Press O to open another, ESC to leave. Returning rather than looping
; forever is what lets examples\desktop launch this and get control back.
;
; %zeropage dontuse is not optional: the library owns ZP $22-$31 and
; basicsafe hands those same bytes to Prog8 variables -- with the
; browser on screen that shows up as a panel drawn in pieces across the
; display, because screen_addr calculates through those very bytes.

%import x16lib
%import x16lib_const
%import launcharg
%import filepick
%zeropage dontuse

main {
    ; lowercase on purpose: Prog8's PETSCII maps a-z to $41-$5A, which the
    ; KERNAL/host filesystem reads as the UPPER-CASE name IMAGE.BMX.
    str filename = "image.bmx"
    str pattern  = "*.bmx"
    str heading  = "pictures in "
    str footing  = "double click opens   esc closes"

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

        while true {
            ubyte k = cx.key_wait()     ; a stray press cannot dismiss it
            if k == $1B or k == $03
                break
            if k == 'o' or k == 'O' {
                if browse()
                    break               ; the browser failed to give us one
            }
        }
        cx.gfx8h_off()                  ; CINT restores the primary VERA only,
        cx.screen_reset()               ; so drop the VERA_2 bitmap ourselves
    }                                   ; or it hides whatever comes next

    ; Pick another picture and show it. -> true if the user asked to
    ; leave from inside the browser (Run/Stop), which the caller honours
    ; rather than swallowing.
    sub browse() -> bool {
        ; The panel is drawn on the text layer, which imgview keeps
        ; switched off -- a photograph with a READY prompt over it is not
        ; a photograph. Turning it back on is not enough on its own:
        ; without PASSTHRU the VERA_2 bitmap covers VERA completely and
        ; the panel is drawn where nobody can see it. Passthru lets
        ; VERA's opaque pixels through, which is exactly the arrangement
        ; the desktop uses for its wallpaper.
        cx.screen_cls()
        @(x16c.VERA_CTRL) = 0
        @(x16c.VERA_DC_VIDEO) |= x16c.VERA_VIDEO_LAYER1_EN
        cx.gfx8h_passthru_on()

        filepick.filter(&pattern)
        filepick.heading(&heading)
        filepick.footing(&footing)
        ubyte act = filepick.open()
        filepick.close()

        ; Off again, and cleared, so nothing of the panel survives over
        ; the picture. cls before the layer goes dark, or the old text
        ; flashes up the next time it is turned on.
        cx.screen_cls()
        cx.gfx8h_passthru_off()
        @(x16c.VERA_CTRL) = 0
        @(x16c.VERA_DC_VIDEO) &= ~x16c.VERA_VIDEO_LAYER1_EN

        if act != filepick.PICK
            return false
        uword p = filepick.path()
        ubyte pn = 0
        while @(p + pn) != 0
            pn++
        cx.bmx_load_hires(p, pn, 8)
        return false
    }
}
