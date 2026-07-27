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
; A BMX is a fixed-size picture: the header says how big it is and the
; pixels land 1:1 from the top left. 640x480 fills the screen; the
; 320x240 wallpaper (wallo.bmx) covers the top-left quarter and is
; meant to -- it is the picture for a machine with no VERA_2 board.
;
; Press O -- or click [files] in the top right corner -- to open
; another, ESC to leave. Returning rather than looping
; forever is what lets examples\desktop launch this and get control back.
;
; %zeropage dontuse is not optional: the library owns ZP $22-$31 and
; basicsafe hands those same bytes to Prog8 variables -- with the
; browser on screen that shows up as a panel drawn in pieces across the
; display, because screen_addr calculates through those very bytes.

%import x16lib
%import x16lib_const
%import launcharg
%zeropage dontuse

main {
    ; The browser's answers, from the library's ui/filepick.asm. They are
    ; not in x16lib_const because the fixed-size blob cannot carry a 3 KB
    ; browser, and that is where the generated constants come from.
    const ubyte FPK_NONE = 0
    const ubyte FPK_PICK = 1
    const ubyte FPK_ALT  = 2

    ; lowercase on purpose: Prog8's PETSCII maps a-z to $41-$5A, which the
    ; KERNAL/host filesystem reads as the UPPER-CASE name IMAGE.BMX.
    str filename = "image.bmx"
    str pattern  = "*.bmx"
    str heading  = "pictures in "
    str footing  = "double click opens   esc closes"
    ubyte[64] picked                ; the path, copied out of the browser
    str btntext  = "[files]"
    const ubyte BTNW = 7

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

        ; The text layer stays ON over the picture, in PASSTHRU. Every
        ; cell is painted with background 0, which is transparent, so
        ; the photograph shows through all of it except the one place
        ; something is drawn: the button. That is the same arrangement
        ; the desktop uses for its wallpaper, and it is what lets a
        ; mouse have anything to click on.
        cx.screen_charset(3)
        cx.gfx8h_passthru_on()
        @(x16c.VERA_CTRL) = 0
        @(x16c.VERA_DC_VIDEO) |= x16c.VERA_VIDEO_LAYER1_EN
        clear_glass()
        draw_button()
        cx.mse_config(1, 80, 60)        ; the KERNAL pointer, over the picture

        bool down = false
        while true {
            ubyte k = cx.key_get()
            if k == $1B or k == $03
                break
            if k == 'o' or k == 'O' {
                browse()
                continue
            }
            ubyte btn = cx.mse_get()
            uword mx = peekw(x16c.X16_P0)
            uword my = peekw(x16c.X16_P0 + 2)
            if btn & 1 != 0 {
                if not down {
                    down = true
                    ; the button lives in the top right corner
                    if my < 8 and mx >= (80 - BTNW) * 8 {
                        browse()
                        down = true     ; the opening click is spent
                    }
                }
            } else {
                down = false
            }
        }
        cx.mse_hide()
        cx.gfx8h_off()                  ; CINT restores the primary VERA only,
        cx.screen_reset()               ; so drop the VERA_2 bitmap ourselves
    }                                   ; or it hides whatever comes next

    ; Every cell transparent: background 0 is a window onto the bitmap.
    sub clear_glass() {
        ubyte r = 0
        while r < 60 {
            cx.screen_addr(r, 0)
            cx.screen_blitfill(80, 1 | (0 << 4), ' ')
            r++
        }
    }

    sub draw_button() {
        cx.screen_addr(0, 80 - BTNW)
        cx.screen_blit(&btntext, BTNW, 6 | (15 << 4))   ; blue on light grey
    }

    ; Pick another picture and show it. -> true if the user asked to
    ; leave from inside the browser (Run/Stop), which the caller honours
    ; rather than swallowing.
    sub browse() -> bool {
        cx.fp_filter(&pattern)
        cx.fp_heading(&heading)
        cx.fp_footing(&footing)
        cx.fp_cache($2000, 1)         ; the listing: VRAM $12000
        ubyte act = cx.fp_open()
        cx.fp_close()
        clear_glass()                 ; the panel leaves the glass dirty
        draw_button()
        cx.mse_config(1, 80, 60)
        if act != FPK_PICK
            return false
        ; Copy the path out rather than following a pointer into the
        ; browser: unbanked that would work, banked it would hand back
        ; an empty string, and this way it is right either way.
        ubyte pn = cx.fp_copy_path(&picked, len(picked))
        if pn != 0 {
            ; A BMX carries its own size and is loaded 1:1 from the top
            ; left -- 640x480 fills the screen, 320x240 covers a quarter
            ; of it. Clear first, or the picture before this one stays
            ; visible around the edges of a smaller one.
            cx.gfx8h_clear(0)
            cx.bmx_load_hires(&picked, pn, 8)
        }
        return false
    }
}
