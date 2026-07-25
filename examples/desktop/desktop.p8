; =====================================================================
; desktop.p8 -- a desktop launcher for the Commander X16.
;
; Icons are VERA sprites. Drag one with the mouse to move it; double
; click it to run the program it stands for. When that program returns,
; the desktop comes back with the icons where you left them.
;
; Coming back is the whole trick, and it is explained in relaunch.p8:
; a PRG loads at $0801 and overwrites its launcher, so the launcher
; cannot even be the thing that loads it. A trampoline in golden RAM
; ($0400-$07FF, which the KERNAL, BASIC and Prog8 all leave alone) does
; both loads from outside $0801 and jumps back here afterwards. Icon
; positions ride along in golden RAM too, so they survive the round trip
; without touching the disk.
;
; A program is launchable if it RETURNS -- Prog8's start() falling off
; the end is an RTS straight back into the trampoline. A program that
; ends in an endless loop never comes back, and one that uses golden RAM
; for itself will break the return.
;
;   .\build.ps1 -Run
; =====================================================================
%import x16lib
%import x16lib_const
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    ; ---- golden RAM ---------------------------------------------------
    const uword STUB     = $0400      ; the trampoline
    const uword CHILDVEC = $0440
    const uword SELFVEC  = $0442
    const uword CNAMLEN  = $0480      ; the program being launched
    const uword CNAME    = $0481
    const uword SNAMLEN  = $04C0      ; ourselves
    const uword SNAME    = $04C1
    const uword STATE    = $0500      ; magic word, then the icon positions
    const uword POSNS    = $0502
    const uword MAGIC    = $D50C
    const ubyte JSRAT    = 25         ; the JSR operand inside stub

    ; ---- the desktop --------------------------------------------------
    const ubyte NICON  = 4
    const uword IVRAM  = $4000        ; sprite pixels, 32-byte aligned
    const ubyte IVBANK = 1            ; ...at $14000, clear of the KERNAL
    const ubyte IW     = 32           ; icons are 32x32
    const uword IBYTES = 512          ; ...so 512 bytes of 4bpp pixels
    const ubyte SCRW   = 79
    const ubyte SCRH   = 60

    str[] files = ["kalk.prg", "imgview.prg", "hello.prg", "child.prg"]
    str[] labels = ["Kalk", "Image", "Hello", "Child"]
    ubyte[] fills = [3, 13, 8, 12]     ; body: cyan, green, orange, grey
    ubyte[] bars  = [11, 5, 9, 11]     ; a dark title stripe; never the
                                      ; desktop blue, which would read as a hole
    ubyte[] edges = [1, 1, 1, 1]

    uword[NICON] ix
    uword[NICON] iy

    uword[] defx = [48, 176, 304, 432]
    uword[] defy = [80, 80, 80, 80]

    ubyte drag = 255                  ; which icon is being dragged
    uword dragdx
    uword dragdy
    bool  mdown
    uword lastclick
    ubyte lasticon = 255

    str title = " X16 Desktop -- drag an icon, double click or press 1-4 to run, Run/Stop quits"
    str s_fail = "cannot read that program"

    ; ---- the trampoline, verbatim from relaunch.p8 --------------------
    ubyte[] stub = [
        $AD, $80, $04,                ; lda CNAMLEN
        $A2, $81,                     ; ldx #<CNAME
        $A0, $04,                     ; ldy #>CNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1
        $A2, $08,                     ; ldx #8
        $A0, $01,                     ; ldy #1        SA 1: use the header
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0
        $20, $D5, $FF,                ; jsr LOAD
        $20, $00, $00,                ; jsr <child entry>   (patched)
        $AD, $C0, $04,                ; lda SNAMLEN
        $A2, $C1,                     ; ldx #<SNAME
        $A0, $04,                     ; ldy #>SNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1
        $A2, $08,                     ; ldx #8
        $A0, $01,                     ; ldy #1
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0
        $20, $D5, $FF,                ; jsr LOAD
        $6C, $42, $04                 ; jmp (SELFVEC)
    ]
    str self = "desktop.prg"


    sub start() {
        cx.load_banks()
        ; Do not trust what ran before us: a program that left the VERA_2
        ; bitmap on would hide this whole desktop behind it.
        cx.gfx8h_off()
        void cx.screen_set_mode(0)
        cx.screen_charset(3)
        load_positions()
        make_icons()
        paint()
        cx.sprites_on()
        cx.mse_config(1, 80, 60)      ; the pointer needs real bounds
        run()
        cx.mse_hide()
        cx.sprites_off()
        cx.screen_reset()
    }


; =====================================================================
; icon positions, kept in golden RAM so a launch does not lose them
; =====================================================================
    sub load_positions() {
        ubyte i = 0
        if peekw(STATE) == MAGIC {
            while i < NICON {
                ix[i] = peekw(POSNS + i * 4)
                iy[i] = peekw(POSNS + i * 4 + 2)
                i++
            }
            return
        }
        while i < NICON {
            ix[i] = defx[i]
            iy[i] = defy[i]
            i++
        }
    }

    sub save_positions() {
        pokew(STATE, MAGIC)
        ubyte i = 0
        while i < NICON {
            pokew(POSNS + i * 4, ix[i])
            pokew(POSNS + i * 4 + 2, iy[i])
            i++
        }
    }


; =====================================================================
; drawing
; =====================================================================
    ; point VERA port 0 at a 17-bit address, auto-incrementing
    sub vgoto(uword lo16, ubyte hi) {
        void cx.vera_set_addr0(lsb(lo16), msb(lo16), $10 | hi)
    }

    ; One pixel of an icon: a little window, framed, with a title stripe
    ; across the top and the corners nipped off. Colour 0 is transparent,
    ; so the nipped corners show the desktop through them.
    sub icon_pixel(ubyte row, ubyte col, ubyte n) -> ubyte {
        bool cornerrow = row < 2 or row >= IW - 2
        bool cornercol = col < 2 or col >= IW - 2
        if cornerrow and cornercol
            return 0
        if row == 0 or row == IW - 1 or col == 0 or col == IW - 1
            return edges[n]
        if row < 8
            return bars[n]
        return fills[n]
    }

    ; 32x32 at 4bpp: two pixels to a byte, sixteen bytes to a row.
    sub make_icons() {
        ubyte n = 0
        while n < NICON {
            uword off = n              ; n * IBYTES overflows a byte, so
            off *= IBYTES              ; keep the multiply in a word
            uword base = IVRAM + off
            vgoto(base, IVBANK)
            ubyte row = 0
            while row < IW {
                ubyte col = 0
                while col < IW {
                    ubyte hi = icon_pixel(row, col, n)
                    ubyte lo = icon_pixel(row, col + 1, n)
                    @(x16c.VERA_DATA0) = (hi << 4) | lo
                    col += 2
                }
                row++
            }
            ; attach the image and give the sprite its shape
            cx.sprite_image_at(n + 1, IVBANK, base, x16c.SPRITE_MODE_4BPP)
            cx.sprite_size(n + 1, x16c.SPRITE_SIZE_32, x16c.SPRITE_SIZE_32, 0)
            cx.sprite_z(n + 1, x16c.SPRITE_Z_FRONT)
            n++
        }
    }

    sub place_all() {
        ubyte i = 0
        while i < NICON {
            cx.sprite_pos(i + 1, ix[i], iy[i])
            i++
        }
    }

    ; the backdrop, the title bar, and a caption under every icon
    sub paint() {
        ubyte attr_desk = 6 | (6 << 4)        ; blue on blue
        ubyte attr_bar  = 0 | (15 << 4)       ; black on light grey
        ubyte r = 0
        while r < SCRH {
            cx.screen_addr(r, 0)
            cx.screen_blitfill(SCRW, attr_desk, ' ')
            r++
        }
        cx.screen_addr(0, 0)
        cx.screen_blit(&title, len(title), attr_bar)
        cx.screen_blitfill(SCRW - len(title), attr_bar, ' ')
        ubyte i = 0
        while i < NICON {
            caption(i)
            i++
        }
        place_all()
    }

    ; Where an icon's caption goes: centred on the icon, on the first text
    ; row entirely below it. Rounding down would put the row under the
    ; icon's last few pixels once the icon is dragged off the 8-pixel grid,
    ; and the sprite would sit on top of its own label.
    ubyte caprow
    ubyte capcol
    ubyte caplen

    sub caption_pos(ubyte i) -> bool {
        caplen = slen(labels[i])
        uword r = iy[i]
        r += IW + 7
        r >>= 3                       ; ceil((y + 16) / 8)
        if r >= SCRH
            return false
        caprow = lsb(r)
        uword mid = ix[i] + IW / 2
        ubyte col = lsb(mid >> 3)
        if col >= caplen / 2
            col -= caplen / 2
        else
            col = 0
        if col + caplen > SCRW
            col = SCRW - caplen
        capcol = col
        return true
    }

    sub caption(ubyte i) {
        if not caption_pos(i)
            return
        cx.screen_addr(caprow, capcol)
        cx.screen_blit(labels[i], caplen, 1 | (6 << 4))
    }

    ; blank a caption where it currently is, so a drag can redraw it
    sub uncaption(ubyte i) {
        if not caption_pos(i)
            return
        cx.screen_addr(caprow, capcol)
        cx.screen_blitfill(caplen, 6 | (6 << 4), ' ')
    }


; =====================================================================
; the event loop
; =====================================================================
    ; Prog8's len() wants an identifier, and these are table entries
    sub slen(uword s) -> ubyte {
        ubyte n = 0
        while @(s + n) != 0
            n++
        return n
    }

    sub icon_at(uword mx, uword my) -> ubyte {
        ubyte i = NICON
        while i != 0 {
            i--
            if mx >= ix[i] and my >= iy[i] {
                if mx - ix[i] < IW and my - iy[i] < IW
                    return i
            }
        }
        return 255
    }

    sub run() {
        while true {
            ubyte k = cx.key_get()
            if k == $03                       ; Run/Stop
                return
            if k >= '1' and k < '1' + NICON   ; keyboard shortcut per icon
                launch(k - '1')

            ubyte btn = cx.mse_get()
            uword mx = peekw(x16c.X16_P0)
            uword my = peekw(x16c.X16_P0 + 2)

            if btn & 1 != 0 {
                if not mdown {
                    mdown = true
                    press(mx, my)
                } else {
                    if drag != 255
                        moveto(mx, my)
                }
            } else {
                if mdown {
                    mdown = false
                    if drag != 255 {
                        drag = 255
                        save_positions()
                        paint()               ; captions follow the icons
                    }
                }
            }
        }
    }

    sub press(uword mx, uword my) {
        ubyte i = icon_at(mx, my)
        if i == 255
            return
        uword now = cx.clock_get_timer()
        if i == lasticon {
            uword gap = now - lastclick
            if gap < 30 {                     ; 60 Hz ticks: half a second
                lasticon = 255
                launch(i)
                return
            }
        }
        lastclick = now
        lasticon = i
        drag = i
        dragdx = mx - ix[i]
        dragdy = my - iy[i]
    }

    sub moveto(uword mx, uword my) {
        uword nx = 0
        uword ny = 0
        if mx > dragdx
            nx = mx - dragdx
        if my > dragdy
            ny = my - dragdy
        if nx > 640 - IW
            nx = 640 - IW
        if ny > 480 - IW
            ny = 480 - IW
        if ny < 8
            ny = 8                            ; keep clear of the title bar
        if nx == ix[drag] and ny == iy[drag]
            return                    ; nothing moved, leave the screen alone
        uncaption(drag)               ; rub the label out where it was...
        ix[drag] = nx
        iy[drag] = ny
        caption(drag)                 ; ...and put it back under the icon
        cx.sprite_pos(drag + 1, nx, ny)
    }


; =====================================================================
; launching  (see relaunch.p8 for why it has to be done this way)
; =====================================================================
    sub putname(uword lenaddr, uword straddr, uword s, ubyte n) {
        @(lenaddr) = n
        ubyte i = 0
        while i < n {
            @(straddr + i) = @(s + i)
            i++
        }
    }

    sub launch(ubyte i) {
        uword name = files[i]
        ubyte n = slen(files[i])
        uword centry = cx.fs_prg_entry(name, n, 8)
        if centry == 0 {
            cx.screen_addr(SCRH - 1, 0)
            cx.screen_blit(&s_fail, len(s_fail), 2 | (6 << 4))
            return
        }
        save_positions()
        putname(CNAMLEN, CNAME, name, n)
        putname(SNAMLEN, SNAME, &self, len(self))
        pokew(CHILDVEC, centry)
        pokew(SELFVEC, cx.fs_prg_entry(&self, len(self), 8))

        ; leave the screen as the child expects to find it
        cx.mse_hide()
        cx.sprites_off()
        cx.screen_reset()

        ubyte k = 0
        while k < len(stub) {
            @(STUB + k) = stub[k]
            k++
        }
        pokew(STUB + JSRAT, centry)
        goto STUB
    }
}
