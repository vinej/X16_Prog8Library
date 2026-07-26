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
%import launcharg
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    ; ---- golden RAM ---------------------------------------------------
    const uword STUB     = $0400      ; the trampoline, 88 bytes
    const uword SELFVEC  = $0470      ; where the trampoline returns to
    const uword LOADERR  = $0472      ; a failed child LOAD's error code
    const uword LOADMAG  = $0473      ; ...valid only when this says $C5:
                                      ; golden RAM boots as garbage, and a
                                      ; cart boot otherwise reports it as a
                                      ; phantom "kernal error" on arrival
    const uword CNAMLEN  = $04A0      ; the program: its FULL path
    const uword CNAME    = $04A1
    const uword SNAMLEN  = $04D0      ; ourselves, also by full path
    const uword SNAME    = $04D1
    const uword CDLEN    = $04E0      ; "cd:<folder>", run by the stub
    const uword IMAIN    = $0302      ; BASIC's main-loop vector
    const uword IMAINSAV = $0476      ; ...and what it was before we hooked it
    const uword WALLMAG  = $0478      ; $A7: the wallpaper below is ours
    const uword WALLSUM  = $0479      ; ...and this is its fingerprint
    const ubyte RELOADAT = 61         ; offset of the stub's "fetch me back"
    const uword CARTMAG  = $04F0      ; $CAFE when the cartridge booted us:
                                      ; then there is no BASIC underneath,
                                      ; and a BASIC program cannot be run
    const uword CDCMD    = $04E1
    const ubyte JSRAT    = 59         ; the JSR operand inside stub

    ; ---- the desktop --------------------------------------------------
    ; What the desktop holds is a list on disk, not a table in the source.
    ; One fixed-size record per entry keeps reading and writing it to a
    ; couple of loops, which is what you want on a 6502; the cost is a
    ; ceiling on the path and the label, stated here rather than found
    ; out later by a truncated name.
    const ubyte MAXICON  = 16
    const ubyte R_SIZE   = 64         ; bytes per record
    const ubyte R_USED   = 0          ; 0 = a free slot
    const ubyte R_ICON   = 1          ; which preset it is drawn with
    const ubyte R_X      = 2          ; uword
    const ubyte R_Y      = 4          ; uword
    const ubyte R_LABEL  = 6          ; 16 bytes, NUL-terminated
    const ubyte R_PATH   = 22         ; 42 bytes, NUL-terminated
    const ubyte L_MAX    = 15         ; label characters, terminator aside
    const ubyte P_MAX    = 41         ; path characters
    const uword CFG_LEN  = 16 + 16 * 64

    str cfgname = "desktop.cfg"
    ; 1040 bytes is past Prog8's 256-byte array ceiling, so the list lives
    ; in a banked-RAM window and is reached by address. Bank 1 is set once
    ; at start-up and never changed: nothing else here uses banked RAM,
    ; and the list is re-read from disk on every entry anyway, so a
    ; launched program is welcome to have trampled the bank meanwhile.
    ; The last bank of the 512 KB the machine has: 8 KB windows numbered
    ; 0-63, so 63. Low banks are where programs put things -- kalk alone
    ; takes 1 through 10 for its sheet -- and while the list is re-read
    ; from disk on every entry, sharing a bank with whatever was just
    ; launched is a collision waiting for the one program that does not
    ; tidy up.
    const ubyte CFGBANK = 63
    const uword CFG     = $A000
    ubyte nicons = 0                  ; how many records are in use

    ; Icon presets: body, title stripe, edge. The picker offers these by
    ; showing them, so the numbers only ever have to look different from
    ; one another, not mean anything.
    ubyte[] pfill = [3, 13, 8, 12, 7, 5, 10, 14, 2, 4, 6, 15]
    ubyte[] pbar  = [11, 5, 9, 11, 9, 11, 2, 6, 9, 11, 12, 12]
    ubyte[] pedge = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
    const ubyte NPRESET = 12

    const ubyte NICON  = 2            ; the seed list, first run only
    const uword IVRAM  = $4000        ; sprite pixels, 32-byte aligned
    const ubyte IVBANK = 1            ; ...at $14000, clear of the KERNAL
    ; ---- two screens, chosen at run time ------------------------------
    ; The wallpaper can live in one of two places, and which one decides
    ; the whole geometry:
    ;
    ;   VERA_2 present -> 640x480 on that board's own SDRAM, 80x60 text,
    ;                     32x32 icons. Needs the MiSTer core (-bitmap2).
    ;   otherwise      -> 320x240 on VERA layer 0 (screen mode $80), which
    ;                     any X16 can do, with 40x30 text and 16x16 icons.
    ;
    ; Everything below reads iw/scrw/scrh rather than a constant, so the
    ; same code draws both. Positions are STORED in the 640x480 space and
    ; halved for the small screen, so one list serves either machine.
    ubyte iw                          ; icon size in pixels
    uword iww                         ; ...the same value, uword, for the
                                      ; hit test's comparisons
    uword ibytes                      ; ...and the 4bpp bytes that costs
    ubyte scrw                        ; text columns
    ubyte scrh                        ; text rows
    ubyte sprsize                     ; SPRITE_SIZE_* code
    ubyte posshift                    ; 0 = store as-is, 1 = halve for lores
    bool  hires                       ; is the VERA_2 board there?

    const ubyte IW_HI   = 32
    const ubyte IW_LO   = 16
    const uword IB_HI   = 512
    const uword IB_LO   = 128

    ; The wallpaper is 640x480 at 8bpp on the VERA_2 layer: 307,200 bytes,
    ; which is why it lives in that board's own SDRAM rather than in VRAM,
    ; where it would not fit. Its palette is independent of VERA's, so it
    ; cannot disturb the 16 colours the text layer draws with.
    str wall   = "wall.bmx"           ; 640x480, VERA_2
    str wall_lo = "wallo.bmx"         ; 320x240, VERA layer 0

    ; What a fresh card gets before anyone has arranged anything. Just the
    ; two programs that ship beside the desktop: everything else is a
    ; question of what is actually on the card, which is the picker's job
    ; to answer rather than this list's to guess.
    str[] files = ["kalk.prg", "imgview.prg"]
    str[] labels = ["Kalk", "Image"]
    ubyte[] fills = [3, 13, 8, 12, 7]     ; body: cyan, green, orange, grey
    ubyte[] bars  = [11, 5, 9, 11, 9]     ; a dark title stripe; never the
                                      ; desktop blue, which would read as a hole
    ubyte[] edges = [1, 1, 1, 1, 1]

    uword[MAXICON] ix
    uword[MAXICON] iy

    uword[] defx = [48, 176, 304, 432, 560]
    uword[] defy = [80, 80, 80, 80, 80]

    ubyte drag = 255                  ; which icon is being dragged
    bool  moved                       ; ...and whether it actually went anywhere
    uword dragdx
    uword dragdy
    bool  mdown
    uword lastclick
    ubyte lasticon = 255
    ; How long the second click of a double click may take to arrive, in
    ; 60ths. Half a second is what Windows allows at MOST, so anyone
    ; clicking at a relaxed pace misses it -- and the first double click
    ; then does nothing while the second appears to work, which is a
    ; baffling thing to be told about your own launcher. A second is
    ; generous and costs nothing: the worst it can do is launch something
    ; from two deliberate clicks, which is what was wanted anyway.
    const uword DBLCLICK = 60

    str title    = " X16 Desktop -- drag an icon, double click runs it, Run/Stop quits"
    str title_lo = " X16 Desktop"

    sub titletext() -> uword {
        if hires
            return &title
        return &title_lo
    }
    sub titlelen() -> ubyte {
        if hires
            return len(title)
        return len(title_lo)
    }
    str s_fail  = "cannot read that program"
    str s_norun = "that file is not a runnable program"
    str s_nobas = "basic programs need the desktop started from basic, not the cart"

    ; ---- the trampoline, verbatim from relaunch.p8 --------------------
    ubyte[] stub = [
        ; load the child by its FULL path -- the working directory has
        ; been seen to revert between the desktop and here, and a path
        ; in the name cannot be wrong-footed by that
        $AD, $A0, $04,                ; lda CNAMLEN
        $A2, $A1,                     ; ldx #<CNAME
        $A0, $04,                     ; ldy #>CNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1
        $A2, $08,                     ; ldx #8
        $A0, $01,                     ; ldy #1        SA 1: use the header
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0
        $20, $D5, $FF,                ; jsr LOAD
        ; a LOAD that fails must NOT fall through: the entry address
        ; points into whatever junk is at $0801, and JSRing it lands in
        ; the monitor. Note the code and go straight home instead.
        $90, $05,                     ; bcc +5        loaded: go on
        $8D, $72, $04,                ; sta LOADERR
        $80, $1E,                     ; bra +30       to the self-reload
        ; give the child ITS OWN directory as the current one -- it will
        ; open its data files by bare name -- by running "cd:<folder>"
        ; on the command channel. Done HERE because nothing after this
        ; point can undo it.
        $AD, $E0, $04,                ; lda CDLEN
        $A2, $E1,                     ; ldx #<CDCMD
        $A0, $04,                     ; ldy #>CDCMD
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $0F,                     ; lda #15
        $A2, $08,                     ; ldx #8
        $A0, $0F,                     ; ldy #15       the command channel
        $20, $BA, $FF,                ; jsr SETLFS
        $20, $C0, $FF,                ; jsr OPEN      sends the command
        $A9, $0F,                     ; lda #15
        $20, $C3, $FF,                ; jsr CLOSE
        $20, $00, $00,                ; jsr <child entry>   (patched)
        ; Whether we got here by the child returning or by BASIC's main
        ; loop jumping at us, put BASIC's vector back FIRST. Doing it here
        ; rather than in the desktop means the hook is disarmed before any
        ; Prog8 code runs -- otherwise quitting the desktop afterwards
        ; jumped into BASIC, which jumped straight back to us, forever.
        $AD, $76, $04,                ; lda IMAINSAV
        $8D, $02, $03,                ; sta $0302
        $AD, $77, $04,                ; lda IMAINSAV+1
        $8D, $03, $03,                ; sta $0303
        ; the child returned: fetch ourselves back off the disk
        $AD, $D0, $04,                ; lda SNAMLEN
        $A2, $D1,                     ; ldx #<SNAME
        $A0, $04,                     ; ldy #>SNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1
        $A2, $08,                     ; ldx #8
        $A0, $01,                     ; ldy #1
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0
        $20, $D5, $FF,                ; jsr LOAD
        $6C, $70, $04                 ; jmp (SELFVEC)
    ]
    ; Absolute, because by the time the trampoline reloads us the working
    ; directory belongs to whatever we launched. A path works in a
    ; filename anywhere the KERNAL takes one, so the stub needs no
    ; notion of directories at all -- it just names us from the root.
    str self = "/desktop.prg"
    ; "/" and not "//": CD:// is accepted by the emulator's host-filesystem
    ; emulation but answers 62, FILE NOT FOUND on a real card, and a failed
    ; chdir is silent. Launch a game out of /GAMES/SOMETHING and the desktop
    ; came back still inside it -- where wall.bmx is not -- so the wallpaper
    ; quietly gave up and the backdrop went blue. The card's own launcher
    ; uses DOS"CD:/", which should have been the clue.
    str root = "/"
    ubyte[64] folder                  ; the launched program's directory
    ubyte[32] leaf                    ; ...and its filename within it


    sub start() {
        cx.load_banks()
        ; A program that returns need not have tidied up, and many do not:
        ; a file left open holds its logical number, and the next OPEN of
        ; that number fails. The wallpaper loads on logical file 2 -- a
        ; popular choice -- so a program that came back with file 2 still
        ; open left the desktop with a blue backdrop and no explanation.
        cx.fio_close_all()
        ; A launched program was given its own directory to run in, and may
        ; have moved again from there. Everything below assumes the root,
        ; so go there rather than trusting where we landed.
        cx.dos_chdir(&root, len(root))
        cx.bank_set(CFGBANK)          ; the window the list is read into
        imain_init()                  ; learn (or undo) BASIC's main-loop vector
        ; Do not trust what ran before us: a program that left the VERA_2
        ; bitmap on would hide this whole desktop behind it.
        cx.gfx8h_off()                ; whatever ran before us may have left it on

        hires = cx.gfx8h_has()
        if hires {
            iw = IW_HI
            iww = IW_HI
            ibytes = IB_HI
            scrw = 80
            scrh = 60
            sprsize = x16c.SPRITE_SIZE_32
            posshift = 0
            if cx.screen_get_mode() != 0
                void cx.screen_set_mode(0)
        } else {
            iw = IW_LO
            iww = IW_LO
            ibytes = IB_LO
            scrw = 40
            scrh = 30
            sprsize = x16c.SPRITE_SIZE_16
            posshift = 1
            ; mode $80 is the KERNAL's 320x240 bitmap with 40x30 text over
            ; it -- the same arrangement, at half the size
            if cx.screen_get_mode() != $80
                void cx.screen_set_mode($80)
        }
        blank()                       ; nothing shows until the desktop is whole
        cx.screen_charset(3)
        cfg_load()
        make_icons()
        paint()
        cx.sprites_on()
        reveal()                      ; ...and only now does any of it show
        if @(LOADMAG) == $C5 and @(LOADERR) != 0 {
            ; the last launch never started: its LOAD failed
            cx.screen_addr(scrh - 1, 0)
            cx.screen_blit("that program did not load, kernal error ", 40,
                           2 | (6 << 4))
            cx.screen_blit(cx.u8_to_hex(@(LOADERR)), 2, 2 | (6 << 4))
            @(LOADERR) = 0
        }
        @(LOADMAG) = 0                ; one report per launch, and none on boot
        cx.mse_config(1, scrw, scrh)  ; the pointer needs real bounds
        run()
        cx.mse_hide()
        cx.sprites_off()
        cx.gfx8h_off()
        imain_restore()               ; or Run/Stop would reload us forever
        cx.screen_reset()
        ; Do not RTS. Arriving through BASIC's main-loop vector leaves a
        ; stack that belongs to BASIC, so returning from here lands
        ; nowhere in particular -- Run/Stop simply did nothing. Entering
        ; BASIC explicitly is a defined exit from any of the three ways
        ; in (RUN, the trampoline, or the hook).
        if @(CARTMAG) == $CA and @(CARTMAG + 1) == $FE {
            %asm {{
                sec             ; cart: BASIC has never initialised
                jmp  $FF47
            }}
        }
        %asm {{
            clc                 ; warm: keep the screen we just restored
            jmp  $FF47
        }}
    }


; =====================================================================
; icon positions, kept in golden RAM so a launch does not lose them
; =====================================================================
    ; ---- the records ---------------------------------------------------
    sub rec(ubyte i) -> uword {
        uword a = i
        a *= R_SIZE
        return CFG + 16 + a
    }
    sub rec_label(ubyte i) -> uword {
        return rec(i) + R_LABEL
    }
    sub rec_path(ubyte i) -> uword {
        return rec(i) + R_PATH
    }
    sub rec_icon(ubyte i) -> ubyte {
        return @(rec(i) + R_ICON)
    }

    sub put_str(uword dst, uword src, ubyte maxn) {
        ubyte i = 0
        while i < maxn and @(src + i) != 0 {
            @(dst + i) = @(src + i)
            i++
        }
        @(dst + i) = 0
    }

    ; Add a program: used by the picker, and by the first-run seeding.
    ; -> false when the list is full.
    sub add_entry(uword path, uword label, ubyte icon) -> bool {
        if nicons >= MAXICON
            return false
        uword r = rec(nicons)
        @(r + R_USED) = 1
        @(r + R_ICON) = icon
        put_str(r + R_LABEL, label, L_MAX)
        put_str(r + R_PATH, path, P_MAX)
        ; A free spot on an 8-across grid, wrapping down the screen. The
        ; column offset is worked out in a uword: (i % 8) * 76 reaches 532,
        ; and in a ubyte that wraps round to put the fifth icon on top of
        ; the first.
        ; Eight across on the wide screen, four on the narrow one. The
        ; pitch has to clear the CAPTION, not the icon -- a 16-pixel icon
        ; with a nine-character label under it needs 72 pixels, or the
        ; names run into each other.
        ubyte percol = 8
        if not hires
            percol = 4
        uword col = nicons % percol
        uword row = nicons / percol
        if hires {
            col *= 76
            row *= 64
            ix[nicons] = 48 + col
            iy[nicons] = 80 + row
        } else {
            col *= 72
            row *= 56
            ix[nicons] = 16 + col
            iy[nicons] = 40 + row
        }
        nicons++
        return true
    }

    ; ---- the list on disk ------------------------------------------------
    sub cfg_load() {
        nicons = 0
        ; fs_load hands back the carry, and the carry means FAILURE -- so
        ; true here is "there is no list yet", not "there is one". Reading
        ; it the other way round wipes the magic on every successful load,
        ; and the desktop silently re-seeds itself each time you come back.
        if cx.fs_load(&cfgname, len(cfgname), 8, x16c.FS_SA_ADDR, CFG)
            @(CFG) = 0                ; no file yet: fall through to the seed
        if @(CFG) == 'd' and @(CFG+1) == 'k' and @(CFG+2) == 't' and @(CFG+3) == '1' {
            nicons = @(CFG+4)
            if nicons > MAXICON
                nicons = MAXICON
            ubyte i = 0
            while i < nicons {
                uword r = rec(i)
                ix[i] = peekw(r + R_X) >> posshift
                iy[i] = peekw(r + R_Y) >> posshift
                i++
            }
            return
        }
        seed()
    }

    sub cfg_save() {
        @(CFG) = 'd'
        @(CFG+1) = 'k'
        @(CFG+2) = 't'
        @(CFG+3) = '1'
        @(CFG+4) = nicons
        ubyte i = 0
        while i < nicons {
            uword r = rec(i)
            pokew(r + R_X, ix[i] << posshift)   ; always stored full size
            pokew(r + R_Y, iy[i] << posshift)
            i++
        }
        ; SAVE writes to the CURRENT directory and ignores a path in the
        ; name -- unlike OPEN, which honours one. The picker leaves us
        ; wherever it was browsing, so without this the list gets written
        ; into whatever folder you happened to be looking at: a stray
        ; DESKTOP.CFG turned up inside a game's directory this way.
        cx.dos_chdir(&root, len(root))
        void cx.dos_delete(&cfgname, len(cfgname))  ; SAVE will not overwrite
        void cx.fs_save(&cfgname, len(cfgname), 8, CFG, CFG + CFG_LEN)
    }

    ; What the desktop looks like before anyone has arranged it.
    sub seed() {
        ubyte i = 0
        while i < NICON {
            void add_entry(files[i], labels[i], i)
            i++
        }
        cfg_save()
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
        bool cornerrow = row < 2 or row >= iw - 2
        bool cornercol = col < 2 or col >= iw - 2
        if cornerrow and cornercol
            return 0
        if row == 0 or row == iw - 1 or col == 0 or col == iw - 1
            return pedge[rec_icon(n)]
        if row < iw / 4
            return pbar[rec_icon(n)]
        return pfill[rec_icon(n)]
    }

    ; 32x32 at 4bpp: two pixels to a byte, sixteen bytes to a row.
    sub make_icons() {
        ubyte n = 0
        while n < nicons {
            uword off = n              ; n * ibytes overflows a byte, so
            off *= ibytes              ; keep the multiply in a word
            uword base = IVRAM + off
            vgoto(base, IVBANK)
            ubyte row = 0
            while row < iw {
                ubyte col = 0
                while col < iw {
                    ubyte hi = icon_pixel(row, col, n)
                    ubyte lo = icon_pixel(row, col + 1, n)
                    @(x16c.VERA_DATA0) = (hi << 4) | lo
                    col += 2
                }
                row++
            }
            ; attach the image and give the sprite its shape
            cx.sprite_image_at(n + 1, IVBANK, base, x16c.SPRITE_MODE_4BPP)
            cx.sprite_size(n + 1, sprsize, sprsize, 0)
            cx.sprite_z(n + 1, x16c.SPRITE_Z_FRONT)
            n++
        }
    }

    sub place_all() {
        ubyte i = 0
        while i < nicons {
            cx.sprite_pos(i + 1, ix[i], iy[i])
            i++
        }
    }

    ; the wallpaper, the title bar, and a caption under every icon
    sub paint() {
        ; With the VERA_2 layer in PASSTHRU, VERA's opaque pixels draw over
        ; the bitmap and the bitmap fills in wherever VERA is transparent.
        ; Background colour 0 is transparent, so a cell painted with it is
        ; a window onto the photograph: the text layer stops being a
        ; backdrop and becomes a sheet of glass with writing on it. The
        ; sprites ride over the top on the same rule, for free.
        ;
        ; Without the layer there is no photograph to show through to, so
        ; the desktop paints its old blue backdrop and looks as it always
        ; did. Everything below here is identical either way.
        ;
        ; The layer stays DARK through all of this. bmx_load_hires never
        ; touches CTRL, so 307 KB can stream into SDRAM unseen while the
        ; text is drawn on top of nothing; reveal() then turns the whole
        ; desktop on in a single register write. Enabling it first meant
        ; watching the previous contents flash up, the new photograph
        ; wipe down over them, and the text land last.
        ubyte attr_desk = 6 | (6 << 4)
        havewall = false
        if hires and wall_cached() {
            havewall = true               ; still in SDRAM: nothing to fetch
        } else {
            if hires {
                ; 640x480 into the VERA_2 board's own SDRAM
                cx.bmx_load_hires(&wall, len(wall), 8)
            } else {
                ; 320x240 into VERA layer 0 at $00000. Its palette starts
                ; at index 16 (img2bmx --lores puts it there) so the 16
                ; system colours the text draws with survive the load.
                void cx.bmx_load(&wall_lo, len(wall_lo), 8, 0, $0000)
            }
            if cx.bmx_lasterr() == 0 {    ; the carry is unreachable from
                havewall = true           ; here, but the code behind it
                if hires                  ; is not: no photo, no glass
                    wall_stamp()
            }
        }
        if havewall
            attr_desk = 1 | (0 << 4)
        backdrop = attr_desk
        paint_text()
    }

    ; ---- the photograph, kept between visits ---------------------------
    ; 307 KB off the card is about two and a half seconds, and it was
    ; being fetched again on every return from a program: that was the
    ; black screen. But VERA_2's SDRAM is not VERA's VRAM -- the only way
    ; into it is through $9F65, so a program that never touches those
    ; registers leaves the picture exactly where we left it. Fingerprint
    ; what is there and compare on the way back: same picture, no load.
    ;
    ; The fingerprint is the sum of the leftmost column, one byte per
    ; row. A program that did use the layer will have changed those 480
    ; bytes, and anything that resets the machine clears SDRAM outright,
    ; so both cases fall back to loading. Reading DATA is not gated by
    ; the layer being enabled, which is what makes this legal while the
    ; screen is still dark.
    sub wall_sum() -> uword {
        @(x16c.VERA2_ADDR_L) = 0
        @(x16c.VERA2_ADDR_M) = 0
        ; the upper nibble of ADDR_H is the auto-increment stride: +640
        ; is one whole row per read, so the pointer walks down column 0
        @(x16c.VERA2_ADDR_H) = x16c.VERA2_INC_640 << 4
        uword s = 0
        uword r = 0
        while r < 480 {
            s += @(x16c.VERA2_DATA)
            r++
        }
        return s
    }

    sub wall_cached() -> bool {
        if @(WALLMAG) != $A7              ; golden RAM boots as garbage
            return false
        uword s = wall_sum()
        if s == 0                         ; a black framebuffer is never
            return false                  ; our photograph
        return s == mkword(@(WALLSUM + 1), @(WALLSUM))
    }

    sub wall_stamp() {
        uword s = wall_sum()
        @(WALLSUM) = lsb(s)
        @(WALLSUM + 1) = msb(s)
        @(WALLMAG) = $A7
    }

    ; Everything except the photograph, which only has to be fetched once
    ; per visit -- the picker closing must not cost another 307 KB.
    sub paint_text() {
        ubyte attr_desk = backdrop
        ; Blue on light grey, not black: index 0 is transparent in the
        ; FOREGROUND as well, so black lettering would be cut out of the
        ; title bar and show the photograph through the strokes.
        ubyte attr_bar  = 6 | (15 << 4)
        ubyte r = 0
        while r < scrh {
            cx.screen_addr(r, 0)
            cx.screen_blitfill(scrw, attr_desk, ' ')
            r++
        }
        cx.screen_addr(0, 0)
        cx.screen_blit(titletext(), titlelen(), attr_bar)
        cx.screen_blitfill(scrw - titlelen(), attr_bar, ' ')
        ; the right end of the title bar is a button: click it and the
        ; file explorer opens, same as pressing p
        cx.screen_addr(0, scrw - 10)
        cx.screen_blit("[programs]", 10, 1 | (11 << 4))   ; the same plate
        captions()
        place_all()
    }

    ; Blank and reveal. The desktop is rebuilt from nothing on every entry
    ; -- mode, charset, sprite pixels, 307 KB of photograph, then all the
    ; text -- and doing that on a live screen is what the flicker was: a
    ; mode change, a clear, a backdrop, captions arriving one by one. So
    ; the text layer goes off first and comes back with the bitmap, and
    ; the whole desktop appears in a single frame instead of assembling
    ; itself in front of you.
    sub blank() {
        @(x16c.VERA_CTRL) = 0             ; DCSEL 0: DC_VIDEO is visible here
        @(x16c.VERA_DC_VIDEO) &= ~x16c.VERA_VIDEO_LAYER1_EN
    }

    ; One write, one frame: enable + 8bpp + passthru together. gfx8h_init
    ; is no use here -- it reloads a grayscale palette, which would throw
    ; away the one the photograph just brought with it.
    sub reveal() {
        if havewall and hires
            @(x16c.VERA2_CTRL) = x16c.VERA2_CTRL_ENABLE |
                                 x16c.VERA2_CTRL_MODE_8BPP |
                                 x16c.VERA2_CTRL_PASSTHRU
        @(x16c.VERA_CTRL) = 0
        @(x16c.VERA_DC_VIDEO) |= x16c.VERA_VIDEO_LAYER1_EN
    }

    ; Every caption, which is what a drop needs: blanking the dragged
    ; label at press can clip a neighbour's if the two overlapped, and
    ; redrawing the moved one alone would leave that damage on screen.
    sub captions() {
        ubyte i = 0
        while i < nicons {
            caption(i)
            i++
        }
    }

    ; Where an icon's caption goes: centred on the icon, on the first text
    ; row entirely below it. Rounding down would put the row under the
    ; icon's last few pixels once the icon is dragged off the 8-pixel grid,
    ; and the sprite would sit on top of its own label.
    ubyte caprow
    ubyte capcol
    ubyte caplen
    ubyte backdrop = 6 | (6 << 4)     ; what a blanked cell goes back to
    bool  havewall                    ; is there a photograph behind us?

    sub caption_pos(ubyte i) -> bool {
        caplen = slen(rec_label(i))
        uword r = iy[i]
        r += iw + 7
        r >>= 3                       ; ceil((y + 16) / 8)
        if r >= scrh
            return false
        caprow = lsb(r)
        uword mid = ix[i] + iw / 2
        ubyte col = lsb(mid >> 3)
        if col >= caplen / 2
            col -= caplen / 2
        else
            col = 0
        if col + caplen > scrw
            col = scrw - caplen
        capcol = col
        return true
    }

    ; White on dark grey rather than on the wallpaper: a label plate. Over
    ; a photograph, white text on transparent is a coin toss.
    sub caption(ubyte i) {
        if not caption_pos(i)
            return
        cx.screen_addr(caprow, capcol)
        cx.screen_blit(rec_label(i), caplen, 1 | (11 << 4))
    }

    ; blank a caption where it currently is, so a drag can redraw it
    sub uncaption(ubyte i) {
        if not caption_pos(i)
            return
        cx.screen_addr(caprow, capcol)
        cx.screen_blitfill(caplen, backdrop, ' ')
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
        ubyte i = nicons
        while i != 0 {
            i--
            if mx >= ix[i] and my >= iy[i] {
                ; The distances stay in explicit uwords. Compared straight
                ; against the ubyte variable `iw`, Prog8 matched low bytes
                ; SIGNED: a click 476 pixels away gave $DC = -36, "within"
                ; a 32-pixel icon -- so far-away clicks grabbed sprites.
                ; (As a const 32 it compiled correctly, which is why this
                ; appeared only when the icon size became a variable.)
                uword dx = mx - ix[i]
                uword dy = my - iy[i]
                if dx < iww and dy < iww
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
            if k == 'p'
                open_picker()

            ubyte btn = cx.mse_get()
            uword mx = peekw(x16c.X16_P0)
            uword my = peekw(x16c.X16_P0 + 2)

            if btn & 1 != 0 {
                if not mdown {
                    mdown = true
                    uword zx = scrw
                    zx -= 10
                    zx <<= 3          ; the [programs] button, in pixels
                    if my < 8 and mx >= zx
                        open_picker()
                    else
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
                        ; Only write the list back if an icon actually went
                        ; somewhere. Saving on every release put a disk
                        ; write between the two halves of a double click,
                        ; which took longer than the half second they have
                        ; to arrive within -- so nothing ever launched on
                        ; the first try.
                        if moved
                            cfg_save()
                        captions()            ; the label reappears, moved
                    }
                }
            }
        }
    }

    ; The explorer, opened from the p key or the title-bar button. The
    ; mouse pointer stays visible: the panel is mouse-driven now.
    ; Hide OUR sprites only. sprites_off kills the whole layer, which the
    ; KERNAL's mouse driver turns straight back on to draw its pointer --
    ; so the icons came back and floated over the panel. Z-depth is
    ; per-sprite, and the pointer is sprite 0, so this leaves it alone.
    sub icons_z(ubyte z) {
        ubyte i = 0
        while i < nicons {
            cx.sprite_z(i + 1, z)
            i++
        }
    }

    ; Some programs do not RTS back to the trampoline -- they jump into
    ; BASIC, and you land at READY with the desktop gone. BASIC reaches
    ; its main loop through a vector at $0302, so pointing that at the
    ; stub's reload half means "returned to BASIC" fetches the desktop
    ; back just as an RTS would.
    ;
    ; The vector must be put back before the desktop itself exits, or
    ; Run/Stop would reload the desktop forever instead of quitting.
    sub imain_hook() {
        pokew(IMAIN, STUB + RELOADAT)
    }

    sub imain_restore() {
        if peekw(IMAINSAV) != 0
            pokew(IMAIN, peekw(IMAINSAV))
    }

    ; Remember BASIC's own vector once, and undo a hook we are arriving
    ; through -- coming back this way, $0302 still points into golden RAM.
    sub imain_init() {
        uword v = peekw(IMAIN)
        if v >= $0400 and v < $0500 {
            imain_restore()
        } else {
            pokew(IMAINSAV, v)
        }
    }

    sub open_picker() {
        icons_z(x16c.SPRITE_Z_DISABLED)
        if picker()                   ; chose to run something now
            launch_path(&fullpath)
        cx.dos_chdir(&root, len(root))  ; browsing moved the drive
        make_icons()                  ; a new entry needs its sprite
        icons_z(x16c.SPRITE_Z_FRONT)
        paint_text()
        cx.sprites_on()
        cx.mse_config(1, scrw, scrh)
        mdown = false                 ; the opening click must not drag
    }

    sub press(uword mx, uword my) {
        ubyte i = icon_at(mx, my)
        if i == 255
            return
        uword now = cx.clock_get_timer()
        if i == lasticon {
            uword gap = now - lastclick
            if gap < DBLCLICK {
                lasticon = 255
                launch(i)
                return
            }
        }
        lastclick = now
        lasticon = i
        drag = i
        moved = false
        dragdx = mx - ix[i]
        dragdy = my - iy[i]
        uncaption(i)              ; no label while it moves; back on release
    }

    sub moveto(uword mx, uword my) {
        uword nx = 0
        uword ny = 0
        if mx > dragdx
            nx = mx - dragdx
        if my > dragdy
            ny = my - dragdy
        uword wide = 640
        uword high = 480
        if not hires {
            wide = 320
            high = 240
        }
        if nx > wide - iw
            nx = wide - iw
        if ny > high - iw
            ny = high - iw
        if ny < 8
            ny = 8                            ; keep clear of the title bar
        if nx == ix[drag] and ny == iy[drag]
            return                    ; nothing moved, leave the screen alone
        moved = true
        ix[drag] = nx
        iy[drag] = ny
        cx.sprite_pos(drag + 1, nx, ny)
    }


; =====================================================================
; the program picker
;
; A directory browser that can do two things with what it finds: run it
; now, or keep it. Running is the cheap path -- no icon, no label, no
; entry written -- and is what you want most of the time.
;
; Where we are comes from the drive rather than being tracked here: the
; header line of every listing is the current directory's own path, so
; descending is dos_chdir(name) and the panel just re-reads. That also
; means the path stored for a program is absolute, so a launch can put
; the drive exactly where the program expects to find itself.
; =====================================================================
    const uword ENTRIES = $A400       ; the listing cache, same bank as CFG
    const ubyte E_SIZE  = 40
    const ubyte E_TYPE  = 0
    const ubyte E_NAME  = 1
    const ubyte MAXENT  = 64

    ; The panel, sized to whichever screen we are on. On 40x30 it is
    ; almost the whole display; on 80x60 it is a window with the desktop
    ; showing around it.
    ubyte pk_rows
    ubyte pk_left
    ubyte pk_w
    const ubyte PK_TOP  = 3

    sub pick_layout() {
        if hires {
            pk_rows = 40
            pk_left = 6
            pk_w = 68
        } else {
            pk_rows = 22
            pk_left = 1
            pk_w = 38
        }
    }

    ; The explorer is dressed like the title bar -- the same light grey
    ; plate, the same blue lettering -- so the two read as parts of one
    ; desktop rather than two programs. Blue on light grey rather than
    ; white: index 0 is transparent in the FOREGROUND as well, and white
    ; on this plate is barely there. The selected row inverts, which is
    ; the only place the eye needs to be drawn.
    const ubyte A_PANEL = 6 | (15 << 4)   ; blue on light grey
    const ubyte A_BAR   = 6 | (15 << 4)   ; ...header and footer to match
    const ubyte A_SEL   = 15 | (6 << 4)   ; inverted: the cursor line
    const ubyte A_EDIT  = 6 | (15 << 4)   ; blue on light grey: a typing field

    ubyte[64] curdir
    ubyte[64] fullpath
    ; The file an "open with" launch hands to the program it starts.
    ; Kept apart from fullpath because both are needed at once: one says
    ; what to run, the other what to open.
    ubyte[64] argfile
    bool hasarg = false
    ubyte[24] editbuf
    ubyte[40] nm
    ubyte nent
    ubyte psel
    ubyte ptop
    bool  pdown                       ; the panel's own button tracking
    uword plastck
    ubyte plastidx

    sub ent(ubyte i) -> uword {
        uword a = i
        a *= E_SIZE
        return ENTRIES + a
    }

    ; Read the current directory into the cache: directories first, then
    ; programs, then everything else -- three passes over the listing
    ; rather than a sort.
    ;
    ; The third pass is what makes "open with" possible: a .bmx or a .csv
    ; is not something the desktop can run, but it is something a program
    ; already on the desktop can open, and the browser has to show it
    ; before anyone can choose it. Data files are cached as DIR_TYPE_SEQ,
    ; which the drive itself never reports for them (the host filesystem
    ; calls everything PRG), so the marker is ours and unambiguous.
    sub pick_read() {
        nent = 0
        ubyte pass = 0
        while pass < 3 {
            if cx.dir_open(0, 0, 8)
                return
            while cx.dir_next(&nm, len(nm)) {
                ubyte t = cx.dir_type()
                if t == x16c.DIR_TYPE_HOST {
                    ; Nothing: the header line gives the path on an
                    ; emulator's host filesystem but the VOLUME LABEL on a
                    ; real card, so where we are is ours to remember. Read
                    ; it from here and every program added from a
                    ; subdirectory gets stored as if it were in the root.
                } else if t == x16c.DIR_TYPE_NONE {
                    ; Not a file. Two lines come back this way: the
                    ; header, when the drive gives a volume label rather
                    ; than a path (a real card does, an emulator's host
                    ; filesystem does not -- which is why listing only
                    ; programs never noticed), and the "BLOCKS FREE."
                    ; trailer. Listing either put a row of raw directory
                    ; bytes in the panel.
                } else if nent < MAXENT {
                    bool want = false
                    ubyte kind = t
                    if pass == 0 and t == x16c.DIR_TYPE_DIR {
                        want = true
                        if nm[0] == '.' and nm[1] == 0
                            want = false        ; "." leads nowhere
                    } else if pass == 1 and t == x16c.DIR_TYPE_PRG {
                        want = is_prg(&nm)
                    } else if pass == 2 and t != x16c.DIR_TYPE_DIR {
                        want = not is_prg(&nm)  ; everything that is not one
                        kind = x16c.DIR_TYPE_SEQ
                    }
                    if want {
                        uword e = ent(nent)
                        @(e + E_TYPE) = kind
                        put_str(e + E_NAME, &nm, E_SIZE - 2)
                        nent++
                    }
                }
            }
            cx.dir_close()
            pass++
        }
    }

    ; The X16's host filesystem reports every file as PRG -- source, text,
    ; images, all of it -- so the type is no filter at all and the name has
    ; to be. A program that does not end in .prg will not be offered, which
    ; is the price of not listing the whole card.
    sub is_prg(uword name) -> bool {
        ubyte n = slen(name)
        if n < 5
            return false
        uword t = name + n - 4
        if @(t) != '.'
            return false
        ; The drive hands names back in ASCII ('b' is $62), while Prog8
        ; encodes a lower-case letter in source as PETSCII $41-$5A -- the
        ; same codes as ASCII CAPITALS. So 'p' here is $50, which is ASCII
        ; 'P', and clearing bit 5 folds the drive's byte onto it whichever
        ; case the card was written in. It is the same quirk that makes
        ; filenames in this source lower-case on purpose.
        ubyte c1 = @(t + 1) & $DF
        ubyte c2 = @(t + 2) & $DF
        ubyte c3 = @(t + 3) & $DF
        return c1 == 'p' and c2 == 'r' and c3 == 'g'
    }

    ; curdir + "/" + name: what gets stored, and what gets run
    sub make_path(uword name) {
        ubyte n = 0
        while curdir[n] != 0 and n < 40 {
            fullpath[n] = curdir[n]
            n++
        }
        if n > 0 and fullpath[n - 1] != '/' {
            fullpath[n] = '/'
            n++
        }
        ubyte k = 0
        while @(name + k) != 0 and n < len(fullpath) - 1 {
            fullpath[n] = @(name + k)
            n++
            k++
        }
        fullpath[n] = 0
    }

    sub pk_row(ubyte r, ubyte attr) {
        cx.screen_addr(r, pk_left)
        cx.screen_blitfill(pk_w, attr, ' ')
    }

    sub pick_draw() {
        pk_row(PK_TOP, A_BAR)
        cx.screen_addr(PK_TOP, pk_left + 1)
        cx.screen_blit("programs in ", 12, A_BAR)
        ubyte dn = slen(&curdir)      ; a deep path must not run off the bar
        if dn > pk_w - 14
            dn = pk_w - 14
        cx.screen_blit(&curdir, dn, A_BAR)
        cx.screen_addr(PK_TOP, pk_left + pk_w - 3)
        cx.screen_blit(" x ", 3, 2 | (15 << 4))    ; click to close

        ubyte r = 0
        while r < pk_rows {
            ubyte i = ptop + r
            ubyte attr = A_PANEL
            if i == psel
                attr = A_SEL
            pk_row(PK_TOP + 1 + r, attr)
            if i < nent {
                uword e = ent(i)
                cx.screen_addr(PK_TOP + 1 + r, pk_left + 2)
                if @(e + E_TYPE) == x16c.DIR_TYPE_DIR
                    cx.screen_blit("[dir] ", 6, attr)
                else if @(e + E_TYPE) == x16c.DIR_TYPE_SEQ
                    cx.screen_blit("[dat] ", 6, attr)   ; data: open with
                else
                    cx.screen_blit("      ", 6, attr)
                ; Clamped to the panel: a name is at most 38 bytes and
                ; the panel is wider than that, but a row that ever did
                ; run over wrapped around the screen and drew outside
                ; the browser entirely.
                ubyte nl = slen(e + E_NAME)
                if nl > pk_w - 10
                    nl = pk_w - 10
                cx.screen_blit(e + E_NAME, nl, attr)
            }
            r++
        }
        pk_row(PK_TOP + 1 + pk_rows, A_BAR)
        cx.screen_addr(PK_TOP + 1 + pk_rows, pk_left + 1)
        if hires
            cx.screen_blit("double click opens/runs   right click adds   esc closes",
                           55, A_BAR)
        else
            cx.screen_blit("dbl-click runs  right adds  esc", 31, A_BAR)
    }

    sub pick_move(ubyte k) {
        if k == $91 {                 ; up
            if psel > 0
                psel--
        } else if k == $11 {          ; down
            if psel + 1 < nent
                psel++
        } else if k == $13 {          ; home
            psel = 0
        }
        if psel < ptop
            ptop = psel
        if psel >= ptop + pk_rows
            ptop = psel - pk_rows + 1
    }

    ; -> true when a program was chosen to run, with fullpath set
    ; Where the panel is, kept by hand. ".." trims the last component,
    ; anything else appends one.
    sub descend(uword name) {
        ubyte n = slen(&curdir)
        if @(name) == '.' and @(name + 1) == '.' and @(name + 2) == 0 {
            while n > 1 and curdir[n - 1] != '/'
                n--
            if n > 1
                n--                   ; drop the separator too
            if n == 0
                n = 1
            curdir[n] = 0
            return
        }
        if n > 0 and curdir[n - 1] != '/' {
            curdir[n] = '/'
            n++
        }
        ubyte k = 0
        while @(name + k) != 0 and n < len(curdir) - 1 {
            curdir[n] = @(name + k)
            n++
            k++
        }
        curdir[n] = 0
    }

    sub picker() -> bool {
        psel = 0
        ptop = 0
        pick_layout()
        curdir[0] = '/'               ; the desktop always starts us here
        curdir[1] = 0
        pick_read()
        pdown = true                  ; the click that opened us is still held
        plastidx = 255
        while true {
            pick_draw()
            ubyte k = 0
            ubyte act = 0
            while k == 0 and act == 0 {
                k = cx.key_get()
                if k != 0
                    break
                ubyte pbtn = cx.mse_get()
                uword pmx = peekw(x16c.X16_P0)
                uword pmy = peekw(x16c.X16_P0 + 2)
                ubyte phit = pbtn & 3         ; left (1) and right (2)
                if phit != 0 {
                    if not pdown {
                        pdown = true
                        ubyte pr = lsb(pmy >> 3)
                        ubyte pc = lsb(pmx >> 3)
                        if pr == PK_TOP and pc >= pk_left + pk_w - 3 {
                            k = $1b   ; the x box closes, like ESC
                        } else if pr > PK_TOP and pr <= PK_TOP + pk_rows {
                            ubyte pli = pr - PK_TOP - 1
                            if ptop + pli < nent {
                                ubyte pidx = ptop + pli
                                psel = pidx
                                if phit & 2 != 0 {
                                    ; RIGHT button: keep it. The other half
                                    ; of the pair -- double click runs a
                                    ; program, right click puts it on the
                                    ; desktop -- so both live on the mouse
                                    ; and neither needs the keyboard.
                                    act = 3
                                    plastidx = 255
                                } else {
                                    uword pnow = cx.clock_get_timer()
                                    if pidx == plastidx and pnow - plastck < DBLCLICK {
                                        act = 1       ; double click = enter
                                        plastidx = 255
                                    } else {
                                        plastck = pnow
                                        plastidx = pidx
                                        act = 2       ; single click selects
                                    }
                                }
                            }
                        }
                    }
                } else {
                    pdown = false
                }
            }
            if act == 2
                continue
            if act == 3 {
                uword re = ent(psel)
                if @(re + E_TYPE) == x16c.DIR_TYPE_PRG {
                    make_path(re + E_NAME)
                    void add_dialog(re + E_NAME)
                }
                pdown = true          ; do not re-read the same press
                continue
            }
            if act == 1
                k = $0d
            if k == $1b or k == $03
                return false
            if k == $91 or k == $11 or k == $13 {
                pick_move(k)
            } else if nent != 0 {
                uword e = ent(psel)
                if k == $0d and @(e + E_TYPE) == x16c.DIR_TYPE_DIR {
                    cx.dos_chdir(e + E_NAME, slen(e + E_NAME))
                    descend(e + E_NAME)
                    psel = 0
                    ptop = 0
                    pick_read()
                } else if @(e + E_TYPE) == x16c.DIR_TYPE_PRG {
                    if k == 'r' or k == $0d {
                        make_path(e + E_NAME)
                        return true
                    }
                    if k == 'a' {
                        make_path(e + E_NAME)
                        void add_dialog(e + E_NAME)
                    }
                } else if @(e + E_TYPE) == x16c.DIR_TYPE_SEQ {
                    ; A data file cannot be run, but something already on
                    ; the desktop can open it. Enter asks which, and then
                    ; the program is what gets launched -- with the file
                    ; handed to it through golden RAM.
                    if k == $0d or k == 'o' {
                        ubyte w = openwith_dialog(e + E_NAME)
                        if w != 255 {
                            make_path(e + E_NAME)      ; the data file
                            put_str(&argfile, &fullpath, len(argfile) - 1)
                            hasarg = true
                            ; ...and now fullpath becomes the program
                            put_str(&fullpath, rec_path(w), len(fullpath) - 1)
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    ; Name it and choose its icon. The name defaults to the program's own,
    ; because that is right often enough to just press Enter and wrong
    ; often enough to want changing -- MYGAME.PRG is not a caption.
    sub add_dialog(uword name) -> bool {
        ubyte i = 0
        while @(name + i) != 0 and i < L_MAX {
            ; The drive's name is ASCII, but a caption is drawn in PETSCII,
            ; where a lower-case letter carries the code of an ASCII
            ; capital. Clearing bit 5 lands either case of the file's name
            ; on lower-case PETSCII, so the default caption reads like the
            ; hand-written ones instead of SHOUTING next to them.
            ubyte c = @(name + i)
            if (c >= $41 and c <= $5A) or (c >= $61 and c <= $7A)
                c &= $DF
            editbuf[i] = c
            i++
        }
        if i > 4 {
            if editbuf[i - 4] == '.'            ; drop a ".prg" tail
                i -= 4
        }
        editbuf[i] = 0
        if not ask_label(i)
            return false
        ubyte ic = ask_icon()
        if ic == 255
            return false
        if not add_entry(&fullpath, &editbuf, ic)
            return false
        cfg_save()                    ; ...which goes to the root, so come
        cx.dos_chdir(&curdir, slen(&curdir))   ; back to what we were browsing
        return true
    }

    ; Which program should open this file? Only what is already on the
    ; desktop is offered: those are the programs this machine is set up
    ; for, and a list of every .prg on the card would be a worse question
    ; than the one the user just answered by browsing. -> 255 if
    ; cancelled, or if there is nothing on the desktop to choose from.
    sub openwith_dialog(uword fname) -> ubyte {
        if nicons == 0
            return 255
        ubyte sel = 0
        ubyte rows = nicons
        if rows > 8
            rows = 8                  ; the panel is not a scrolling list
        while true {
            ubyte r = 0
            while r < rows + 2 {
                pk_row(PK_TOP + 2 + r, A_BAR)
                r++
            }
            cx.screen_addr(PK_TOP + 2, pk_left + 2)
            cx.screen_blit("open ", 5, A_BAR)
            ubyte fn = slen(fname)
            if fn > 20
                fn = 20
            cx.screen_blit(fname, fn, A_BAR)
            if hires
                cx.screen_blit("  with (up/down, enter, esc):", 29, A_BAR)
            else
                cx.screen_blit(" with:", 6, A_BAR)
            ubyte i = 0
            while i < rows {
                ubyte attr = A_BAR
                if i == sel
                    attr = A_SEL
                cx.screen_addr(PK_TOP + 3 + i, pk_left + 2)
                cx.screen_blitfill(20, attr, ' ')
                cx.screen_addr(PK_TOP + 3 + i, pk_left + 4)
                cx.screen_blit(rec_label(i), slen(rec_label(i)), attr)
                i++
            }
            ubyte k = cx.key_wait()
            if k == $0d
                return sel
            if k == $1b or k == $03
                return 255
            if k == $91 {                       ; up
                if sel > 0
                    sel--
            } else if k == $11 {                ; down
                if sel + 1 < rows
                    sel++
            }
        }
        return 255
    }

    sub ask_label(ubyte n) -> bool {
        while true {
            pk_row(PK_TOP + 2, A_BAR)
            pk_row(PK_TOP + 3, A_BAR)
            cx.screen_addr(PK_TOP + 2, pk_left + 2)
            if hires
                cx.screen_blit("name on the desktop (enter accepts, esc cancels):",
                               48, A_BAR)
            else
                cx.screen_blit("name it (enter ok, esc cancel)", 29, A_BAR)
            ; An OPAQUE field. Background 0 is transparent, which is the
            ; whole trick behind the wallpaper -- and exactly wrong here:
            ; it cut a hole through the panel and let the photograph
            ; through the middle of the text being typed.
            cx.screen_addr(PK_TOP + 3, pk_left + 2)
            cx.screen_blitfill(L_MAX + 2, A_EDIT, ' ')
            cx.screen_addr(PK_TOP + 3, pk_left + 2)
            if n != 0
                cx.screen_blit(&editbuf, n, A_EDIT)
            cx.screen_addr(PK_TOP + 3, pk_left + 2 + n)
            cx.screen_blit("_", 1, A_EDIT)

            ubyte k = cx.key_wait()
            if k == $0d {
                if n != 0
                    return true
            } else if k == $1b or k == $03 {
                return false
            } else if k == $14 {                ; backspace
                if n > 0
                    n--
            } else if k >= ' ' and k < $80 {
                if n < L_MAX {
                    editbuf[n] = k
                    n++
                }
            }
            editbuf[n] = 0
        }
        return false
    }

    ; The presets drawn as what they actually look like, rather than
    ; listed as numbers. -> 255 if cancelled.
    sub ask_icon() -> ubyte {
        ubyte sel = 0
        while true {
            pk_row(PK_TOP + 2, A_BAR)
            pk_row(PK_TOP + 3, A_BAR)
            pk_row(PK_TOP + 4, A_BAR)
            pk_row(PK_TOP + 5, A_BAR)
            cx.screen_addr(PK_TOP + 2, pk_left + 2)
            if hires
                cx.screen_blit("pick an icon (left/right, enter accepts, esc cancels):",
                               53, A_BAR)
            else
                cx.screen_blit("icon: left/right, enter, esc", 28, A_BAR)
            ubyte i = 0
            while i < NPRESET {
                ubyte pitch = 4
                if not hires
                    pitch = 3
                ubyte c = pk_left + 2 + i * pitch
                cx.screen_addr(PK_TOP + 3, c)
                cx.screen_blitfill(pitch - 1, pbar[i] | (pbar[i] << 4), ' ')
                cx.screen_addr(PK_TOP + 4, c)
                cx.screen_blitfill(pitch - 1, pfill[i] | (pfill[i] << 4), ' ')
                ; A pair of small arrows beside a chip is not enough to see
                ; at a glance -- which of twelve is chosen has to be obvious
                ; without hunting. So the choice gets a solid bar under it,
                ; the full width of the chip.
                cx.screen_addr(PK_TOP + 5, c)
                if i == sel
                    cx.screen_blitfill(pitch - 1, 6 | (6 << 4), ' ')   ; solid blue
                else
                    cx.screen_blitfill(pitch - 1, A_BAR, ' ')
                i++
            }
            ubyte k = cx.key_wait()
            if k == $0d
                return sel
            if k == $1b or k == $03
                return 255
            if k == $9d {
                if sel > 0
                    sel--
            } else if k == $1d {
                if sel + 1 < NPRESET
                    sel++
            }
        }
        return 255
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

    ; Split "games/deep/game.prg" into folder and leaf. A program with
    ; data files alongside it expects to be run from its own directory
    ; -- it opens them by bare name -- so the launcher goes there first
    ; and hands the trampoline only the leaf.
    sub split_path(uword path, ubyte n) {
        ubyte cut = 255
        ubyte i = 0
        while i < n {
            if @(path + i) == '/'
                cut = i
            i++
        }
        ubyte j = 0
        if cut != 255 {
            while j < cut and j < len(folder) - 1 {
                folder[j] = @(path + j)
                j++
            }
        }
        folder[j] = 0
        ubyte k = 0
        i = cut + 1                   ; 0 when there was no slash at all
        while i < n and k < len(leaf) - 1 {
            leaf[k] = @(path + i)
            k++
            i++
        }
        leaf[k] = 0
    }

    ; Run a BASIC program. The desktop cannot JSR into BASIC, but BASIC
    ; will happily execute whatever lines sit on the screen when a RETURN
    ; arrives -- the classic autostart. The KERNAL keyboard queue holds
    ; only TEN characters (typing the commands into it truncates at ten,
    ; which looked like a hang), so the commands are PRINTED instead and
    ; the queue carries just two RETURNs.
    ;
    ; The LOAD line goes on the top row. Executing it prints SEARCHING /
    ; LOADING / READY, so where the cursor lands afterwards is only
    ; roughly known -- rows 4 through 8 all say "run", and whichever one
    ; the second RETURN lands on does the job.
    sub basic_launch() {
        cx.dos_chdir(&folder, slen(&folder))  ; the program's own directory
        cx.mse_hide()
        cx.sprites_off()
        cx.gfx8h_off()
        cx.bank_set(1)
        cx.screen_reset()                     ; a clean, scrolling text screen

        ; Entering BASIC warm prints CR + READY + CR first, so from (0,0)
        ; the cursor lands on row 2 -- the LOAD line goes THERE, not on
        ; row 0. Executing it prints up to four lines of its own, so the
        ; cursor then lands somewhere in rows 3-7: every row from 4 to 10
        ; says "run", and the second RETURN takes whichever one it hits.
        cx.screen_chrout($0d)
        cx.screen_chrout($0d)
        cx.screen_puts("load")
        cx.screen_chrout($22)
        cx.screen_puts(&leaf)
        cx.screen_chrout($22)
        cx.screen_puts(",8")
        cx.screen_chrout($0d)
        cx.screen_chrout($0d)                 ; row 3 left blank for output
        ubyte bl = 4
        while bl <= 10 {
            cx.screen_puts("run")
            cx.screen_chrout($0d)
            bl++
        }
        cx.screen_locate(0, 0)                ; the warm entry starts here
        cx.kbd_put($0d)                       ; execute it...
        cx.kbd_put($0d)                       ; ...and then whatever row says run
        %asm {{
            clc                 ; WARM -- verified on target: clc keeps the
            jmp  $FF47          ; screen (and our printed lines), sec is the
        }}                      ; cold start that wipes them
    }

    sub launch(ubyte i) {
        launch_path(rec_path(i))
    }

    sub launch_path(uword path) {
        ; The launch argument is set per launch or not at all. Clearing
        ; it first means a program can never inherit the file some
        ; earlier launch passed to something else -- golden RAM keeps
        ; whatever was last written there, and a stale path would be
        ; opened without anyone having asked for it.
        launcharg.clear()
        if hasarg {
            launcharg.set(&argfile, slen(&argfile))
            hasarg = false
        }
        split_path(path, slen(path))
        if folder[0] != 0
            cx.dos_chdir(&folder, slen(&folder))
        uword name = &leaf
        ubyte n = slen(&leaf)
        uword centry = cx.fs_prg_entry(name, n, 8)
        if centry == 0 {
            ; No SYS stub. If it is a BASIC program -- it loads at $0801
            ; and simply has no machine-code entry -- it can still be run:
            ; not by us, but by BASIC. Type the commands into the keyboard
            ; buffer and hand the machine to the interpreter; the KERNAL's
            ; enter_basic makes that official. The one-way door is real --
            ; BASIC's RUN never returns -- which is exactly what the
            ; cartridge is for: reset, and the desktop is back.
            bool isbasic = false
            if not cx.fio_open_read(name, n, 5, 8, 2) {
                ubyte lo = cx.fio_chrin()
                ubyte hi = cx.fio_chrin()
                isbasic = lo == $01 and hi == $08
                cx.fio_clrchn()
                cx.fio_close(5)
            } else {
                cx.dos_chdir(&root, len(root))
                cx.screen_addr(scrh - 1, 0)
                cx.screen_blit(&s_fail, len(s_fail), 2 | (6 << 4))
                cx.screen_blitfill(scrw - slen(&s_fail), backdrop, ' ')
                return
            }
            if not isbasic {
                cx.dos_chdir(&root, len(root))
                cx.screen_addr(scrh - 1, 0)
                cx.screen_blit(&s_norun, len(s_norun), 2 | (6 << 4))
                cx.screen_blitfill(scrw - slen(&s_norun), backdrop, ' ')
                return
            }
            if @(CARTMAG) == $CA and @(CARTMAG + 1) == $FE {
                ; No interpreter to hand the program to: the cart jumps
                ; straight into the desktop and BASIC never initialises.
                cx.dos_chdir(&root, len(root))
                cx.screen_addr(scrh - 1, 0)
                cx.screen_blit(&s_nobas, len(s_nobas), 2 | (6 << 4))
                cx.screen_blitfill(scrw - slen(&s_nobas), backdrop, ' ')
                return
            }
            basic_launch()
            return
        }
        cfg_save()
        ; The trampoline loads by the FULL path, never the bare name. The
        ; chdir above is for the program's own data files -- but between
        ; here and the stub's LOAD the working directory has been seen to
        ; revert (the DOS searched the root and answered FILE NOT FOUND
        ; for a file that was right there). An absolute path cannot be
        ; wrong-footed that way, and the stub's reload of /desktop.prg
        ; already relies on exactly that.
        putname(CNAMLEN, CNAME, path, slen(path))
        putname(SNAMLEN, SNAME, &self, len(self))
        ; "cd:<folder>" for the stub to run; the root when there is none
        @(CDCMD) = 'c'
        @(CDCMD + 1) = 'd'
        @(CDCMD + 2) = ':'
        ubyte cdn = 3
        if folder[0] != 0 {
            ubyte cdi = 0
            while folder[cdi] != 0 and cdn < 30 {
                @(CDCMD + cdn) = folder[cdi]
                cdn++
                cdi++
            }
        } else {
            @(CDCMD + cdn) = '/'
            cdn++
        }
        @(CDLEN) = cdn
        pokew(SELFVEC, cx.fs_prg_entry(&self, len(self), 8))

        ; Leave the screen as the child expects to find it -- which means
        ; the wallpaper goes too. Under passthru, background colour 0 is
        ; transparent, and colour 0 is what an ordinary program draws on:
        ; kalk's row headers came up with the photograph showing through
        ; the black behind them. A launched program gets a plain machine.
        cx.mse_hide()
        cx.sprites_off()
        cx.gfx8h_off()
        cx.screen_reset()

        ubyte k = 0
        while k < len(stub) {
            @(STUB + k) = stub[k]
            k++
        }
        @(LOADERR) = 0
        @(LOADMAG) = $C5              ; a launch really happened
        imain_hook()                  ; catch a program that exits to BASIC
        pokew(STUB + JSRAT, centry)
        goto STUB
    }
}
