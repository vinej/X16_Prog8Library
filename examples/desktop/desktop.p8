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
; X16_GATE X16_USE_FILEPICK_EDIT   -- n/e/d/c/v in the browser, and the
; blue-on-yellow prompt that comes with them. kalk asks for the same
; thing; without it the desktop's browser can only CHOOSE a file, which
; is why its panel looked plainer than kalk's for no apparent reason.
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    ; The browser's answers (x16c.FPK_*) come from the library's
    ; ui/filepick.asm, via x16lib_const.

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

    ; The desktop's own files live in /DESKTOP, beside the icon library:
    ; the list, the two wallpapers and the .ICO files a program can be
    ; given. Only DESKTOP.PRG stays in the root, because the trampoline
    ; reloads it by name from there and that path is the fragile one.
    ;
    ; Two spellings of the same file, and they are not interchangeable.
    ; LOAD and OPEN honour a path in the name; SAVE does NOT -- it writes
    ; to the current directory and ignores one -- so writing the list
    ; means changing directory to cfgdir first and saving the bare name.
    str cfgdir  = "/desktop"
    str cfgname = "desktop.cfg"
    str cfgpath = "/desktop/desktop.cfg"
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
    ; Absolute, so the wallpaper is found whatever directory a launched
    ; program left us standing in. bmx_load opens the file, and OPEN
    ; honours a path -- which is what makes the old chdir-to-root dance
    ; unnecessary here.
    str wall   = "/desktop/wall.bmx"   ; the default, on a fresh card
    str wall_lo = "/desktop/wallo.bmx"
    str wpre    = "/desktop/"
    ; The chosen wallpaper's stem lives in the spare bytes of the config
    ; header -- eight characters, which is why mkwalls.py names them
    ; PICnn. A config written before this has zeros there, so an empty
    ; stem means "the default" and the file format did not have to change
    ; at all: no magic bump, no migration, old desktops keep working.
    const ubyte C_WALL = 5             ; CFG+5..CFG+13, NUL-terminated
    const ubyte WSTEM_MAX = 8
    ubyte[24] wallpath

    ; Fill wallpath with the wallpaper to load. -> its length.
    ; The two sizes are different FILES, not the same one scaled:
    ; <STEM>.BMX is 640x480 for the VERA_2 board, <STEM>.BMO is 320x240
    ; with its palette at index 16 so the text colours survive.
    sub wall_name() -> ubyte {
        ubyte j = 0
        if @(CFG + C_WALL) == 0 {
            uword src = &wall
            ubyte n = len(wall)
            if not hires {
                src = &wall_lo
                n = len(wall_lo)
            }
            while j < n {
                wallpath[j] = @(src + j)
                j++
            }
            wallpath[j] = 0
            return j
        }
        while wpre[j] != 0 {
            wallpath[j] = wpre[j]
            j++
        }
        ubyte k = 0
        while k < WSTEM_MAX and @(CFG + C_WALL + k) != 0 {
            wallpath[j] = @(CFG + C_WALL + k)
            j++
            k++
        }
        wallpath[j] = '.'
        j++
        wallpath[j] = 'b'
        j++
        wallpath[j] = 'm'
        j++
        if hires
            wallpath[j] = 'x'
        else
            wallpath[j] = 'o'
        j++
        wallpath[j] = 0
        return j
    }

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

    ; Where an icon file's name is built, big enough for the longest
    ; path a record can hold plus ".ico" and a terminator.
    const ubyte ICOP_MAX = 47
    ubyte[48] icopath

    uword[MAXICON] ix
    uword[MAXICON] iy

    uword[] defx = [48, 176, 304, 432, 560]
    uword[] defy = [80, 80, 80, 80, 80]

    ubyte drag = 255                  ; which icon is being dragged
    bool  moved                       ; ...and whether it actually went anywhere
    uword dragdx
    uword dragdy
    bool  mdown
    bool  rdown                       ; ...and the same latch for the right
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

    str title    = " X16 Desktop -- drag, dbl-click runs, right click = icon, Run/Stop"
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
        if cx.fs_load(&cfgpath, len(cfgpath), 8, x16c.FS_SA_ADDR, CFG)
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
        cx.dos_chdir(&cfgdir, len(cfgdir))
        void cx.dos_delete(&cfgname, len(cfgname))  ; SAVE will not overwrite
        void cx.fs_save(&cfgname, len(cfgname), 8, CFG, CFG + CFG_LEN)
        ; ...and put the drive back at the root before leaving. Saving
        ; the list is the LAST thing that happens before the trampoline
        ; loads the program, and the trampoline loads it by the stored
        ; path -- which for anything in the root is relative ("kalk.prg",
        ; "imgview.prg"). Leave the drive in /DESKTOP and that LOAD looks
        ; for them there and comes straight back to the desktop. The old
        ; code chdir'd here to "/" and every root program depended on it
        ; without saying so.
        cx.dos_chdir(&root, len(root))
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

    ; Build "<program path>.ico" -- or ".i16" on the small screen --
    ; into icopath. -> its length, or 0 when there is nothing to build.
    ;
    ; The extension is REPLACED, not appended: a record holds
    ; "apps/paint/paint.prg" and the icon beside it is PAINT.ICO. Only a
    ; dot after the last slash counts, or a directory with a dot in its
    ; name would cut the path off at the wrong place.
    ;
    ; Lower case on purpose, like every other filename here: Prog8's
    ; PETSCII maps a-z to $41-$5A, which the KERNAL reads back as the
    ; upper-case name the card actually stores.
    sub icon_file(ubyte n) -> ubyte {
        uword p = rec_path(n)
        ubyte i = 0
        ubyte dot = 0                 ; index of the dot, PLUS ONE, so
        while i < P_MAX {             ; that 0 can mean "none seen yet"
            ubyte ch = @(p + i)
            if ch == 0
                break
            if ch == '/'
                dot = 0               ; a dot in a folder name does not count
            if ch == '.'
                dot = i + 1
            i++
        }
        if i == 0
            return 0
        ubyte cut = i
        if dot != 0
            cut = dot - 1
        if cut > ICOP_MAX - 5
            return 0
        ubyte j = 0
        while j < cut {
            icopath[j] = @(p + j)
            j++
        }
        icopath[j] = '.'
        j++
        icopath[j] = 'i'
        j++
        if hires {
            icopath[j] = 'c'
            j++
            icopath[j] = 'o'
        } else {
            icopath[j] = '1'
            j++
            icopath[j] = '6'
        }
        j++
        icopath[j] = 0
        return j
    }

    ; 32x32 at 4bpp: two pixels to a byte, sixteen bytes to a row.
    sub make_icons() {
        ubyte n = 0
        bool tried = false
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
            ; A program's own icon file, if it has one, lands straight on
            ; top of the preset just drawn. Done in that order because
            ; fs_vload reports nothing back -- it is the one loader here
            ; with no return value -- so there is no way to ask whether
            ; the file was there. Drawing first makes the preset the
            ; fallback by construction: no file, nothing overwritten.
            ubyte fn = icon_file(n)
            if fn != 0 {
                cx.fs_vload(&icopath, fn, 8, IVBANK, base)
                tried = true
            }
            ; attach the image and give the sprite its shape
            cx.sprite_image_at(n + 1, IVBANK, base, x16c.SPRITE_MODE_4BPP)
            cx.sprite_size(n + 1, sprsize, sprsize, 0)
            cx.sprite_z(n + 1, x16c.SPRITE_Z_FRONT)
            n++
        }
        ; Most programs have no icon, so most of those loads failed, and
        ; each failure leaves "62,FILE NOT FOUND" sitting on the command
        ; channel. Reading it once clears it -- otherwise the next thing
        ; to ask the drive how it is gets an error that belongs to us.
        if tried
            void cx.dos_status()
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
                ubyte wn = wall_name()
            cx.bmx_load_hires(&wallpath, wn, 8)
            } else {
                ; 320x240 into VERA layer 0 at $00000. Its palette starts
                ; at index 16 (img2bmx --lores puts it there) so the 16
                ; system colours the text draws with survive the load.
                ubyte wn2 = wall_name()
            void cx.bmx_load(&wallpath, wn2, 8, 0, $0000)
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
            ; 'i' re-icons whatever was last clicked. It needs a target,
            ; and the last click is the only selection this desktop has.
            if k == 'i' and lasticon != 255 and lasticon < nicons
                change_icon(lasticon)

            ubyte btn = cx.mse_get()
            uword mx = peekw(x16c.X16_P0)
            uword my = peekw(x16c.X16_P0 + 2)

            ; Right click on an icon opens the icon panel for it. Latched
            ; like the left button: mse_get is polled every frame, so
            ; without this the panel would open, and the button still
            ; being down when we came back would open it straight again.
            if btn & x16c.MSE_BUTTON_RIGHT != 0 {
                if not rdown {
                    rdown = true
                    ubyte hit = icon_at(mx, my)
                    if hit != 255 {
                        change_icon(hit)
                    } else {
                        ; ...and on the desktop itself, the desktop's own
                        ; background. Same gesture, and what it acts on is
                        ; whatever is under the pointer.
                        icons_z(x16c.SPRITE_Z_DISABLED)
                        choose_wall()
                        ; blank() first and reveal() last, exactly as
                        ; start() does. The wallpaper is 307 KB and the
                        ; load is visible if layer 1 is on: you watch the
                        ; old picture flash up, the new one wipe down
                        ; over it, and the text land last. Dark through
                        ; the load, then one register write turns the
                        ; whole desktop on at once.
                        cx.mse_hide()
                        blank()
                        paint()
                        make_icons()
                        icons_z(x16c.SPRITE_Z_FRONT)
                        reveal()
                        cx.sprites_on()
                        cx.mse_config(1, scrw, scrh)
                        cx.mse_show_keep()
                        mdown = false
                    }
                }
            } else {
                rdown = false
            }

            if btn & x16c.MSE_BUTTON_LEFT != 0 {
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

    ; ---- giving a program a different icon -------------------------------
    ; The chosen file is COPIED next to the program as <program>.ICO
    ; rather than remembered in the list. Two reasons: the record is
    ; exactly full at 64 bytes, so remembering a name would mean growing
    ; it and migrating every saved desktop -- and an icon that lives
    ; beside its program is then found by the same code that finds the
    ; generated ones, with nothing new to go wrong.
    str icodir  = "/desktop"
    str icofilt = "*.ico"
    str icohead = "icons in "
    str icofoot = "right click shows it   enter takes it   esc cancels"
    ubyte[24] iconame
    ubyte[48] icosrc
    ubyte[24] icodest
    ; Scratch inside the config's bank window, past the list itself.
    ; CFG_LEN is 1040, the window is 8 KB, and bank CFGBANK is already
    ; mapped -- so this costs no low RAM at all.
    const uword ICOBUF = CFG + $0800

    ; Copy /DESKTOP/<iconame> to <program dir>/<leaf>.<ext>, both sizes.
    ; -> false if the source could not be read.
    sub copy_one(uword ext, uword nbytes) -> bool {
        ubyte i = 0
        while icodir[i] != 0 {
            icosrc[i] = icodir[i]
            i++
        }
        icosrc[i] = '/'
        i++
        ubyte j = 0
        while iconame[j] != 0 and iconame[j] != '.' {
            icosrc[i] = iconame[j]
            i++
            j++
        }
        ubyte k = 0
        while @(ext + k) != 0 {
            icosrc[i] = @(ext + k)
            i++
            k++
        }
        icosrc[i] = 0
        ; SA 0, so LOAD eats the file's 2-byte header and ICOBUF holds
        ; the pixels alone. SAVE then writes a fresh header of its own,
        ; which is why the copy comes out the same size as the original.
        if cx.fs_load(&icosrc, i, 8, x16c.FS_SA_ADDR, ICOBUF)
            return false
        ubyte d = 0
        while leaf[d] != 0 and leaf[d] != '.' {
            icodest[d] = leaf[d]
            d++
        }
        k = 0
        while @(ext + k) != 0 {
            icodest[d] = @(ext + k)
            d++
            k++
        }
        icodest[d] = 0
        void cx.dos_delete(&icodest, d)     ; SAVE will not overwrite
        void cx.fs_save(&icodest, d, 8, ICOBUF, ICOBUF + nbytes)
        return true
    }

    ; ---- the icon grid ---------------------------------------------------
    ; Choosing a picture from a list of filenames is choosing blind, and
    ; filepick cannot say "the highlight moved" -- so this does not use
    ; filepick at all. It reads /DESKTOP itself and shows the ICONS, all
    ; of them at once, which answers the question the panel is asking
    ; instead of describing it. You pick the one you can see.
    const ubyte GRIDCOLS = 6
    const ubyte GRIDROWS = 4
    const ubyte GRIDMAX  = 24         ; GRIDCOLS * GRIDROWS, one page
    ; How many names are collected in all. /DESKTOP holds one per program,
    ; so this is the ceiling on what can be offered -- 120 names at 16
    ; bytes is 1920, which still fits the config bank's window alongside
    ; the list and the copy buffer.
    const ubyte GRIDTOTAL = 120
    ubyte gridpage
    ubyte upcol                       ; where the [up]/[down] buttons sit
    ubyte dncol
    ; The grid serves two callers at two sizes -- icons at the desktop's
    ; own icon size, wallpapers at 64x64 because a photograph needs the
    ; room to be recognisable -- so the cell geometry is set by whoever
    ; opens it rather than baked in.
    uword gridpx                      ; pixels across one image
    uword gridbytes                   ; ...and what that costs in VRAM
    ubyte gridsz                      ; the SPRITE_SIZE_* code for it
    ubyte gridcols
    ubyte gridmax                     ; how many fit on one page
    const ubyte GRIDNLEN = 16
    const ubyte GRIDSPR  = 21         ; the desktop owns 1..MAXICON
    ; The names live in the config's bank window, past the list and past
    ; the copy buffer, so a grid of 24 costs no low RAM.
    const uword GRIDNAMES = CFG + $0C00

    sub grid_name(ubyte i) -> uword {
        uword a = i
        a *= GRIDNLEN
        return GRIDNAMES + a
    }

    ; Read /DESKTOP and keep the .ICO names. -> how many were found.
    ; The .I16 companions are skipped: they are the same icons at the
    ; other size, and offering both would show every icon twice.
    sub grid_scan() -> ubyte {
        ubyte n = 0
        ; Stand in the directory and ask for "$", rather than handing the
        ; path to dir_open. dir_open passes what it is given straight to
        ; SETNAM without prepending the dollar, so a bare "/desktop" is
        ; opened as a FILE and the listing comes back empty -- which made
        ; right-click look like it did nothing at all. A length of 0 is
        ; the documented way to ask for the current directory.
        cx.dos_chdir(&icodir, len(icodir))
        if cx.dir_open(&icodir, 0, 8) {
            cx.dos_chdir(&root, len(root))
            return 0
        }
        while n < GRIDTOTAL {
            if not cx.dir_next(&iconame, len(iconame))
                break
            ubyte l = 0
            while iconame[l] != 0 and l < GRIDNLEN
                l++
            if l > 4 {
                if iconame[l - 4] == '.' and iconame[l - 3] == 'i' and
                   iconame[l - 2] == 'c' and iconame[l - 1] == 'o' {
                    uword d = grid_name(n)
                    ubyte j = 0
                    while j < l and j < GRIDNLEN - 1 {
                        @(d + j) = iconame[j]
                        j++
                    }
                    @(d + j) = 0
                    n++
                }
            }
        }
        cx.dir_close()
        cx.dos_chdir(&root, len(root))
        return n
    }

    ; Where cell i sits, in pixels.
    sub grid_x(ubyte i) -> uword {
        uword c = i % gridcols
        c *= gridpx
        c += (i % gridcols) * 8
        return gridx0 + c
    }
    sub grid_y(ubyte i) -> uword {
        uword r = i / gridcols
        r *= gridpx
        r += (i / gridcols) * 8
        return gridy0 + r
    }
    uword gridx0
    uword gridy0

    ; Load every found icon into its own VRAM slot and hang a sprite on
    ; it. The slots start past the sixteen the desktop's own icons use,
    ; so nothing here can scribble on one of those.
    ; How many icons page `gridpage` holds.
    sub grid_oncount(ubyte total) -> ubyte {
        ubyte first = gridpage * gridmax
        if first >= total
            return 0
        ubyte left = total - first
        if left > gridmax
            return gridmax
        return left
    }

    sub grid_pages(ubyte total) -> ubyte {
        return (total + gridmax - 1) / gridmax
    }

    sub grid_show(ubyte total) {
        ubyte count = grid_oncount(total)
        ubyte base_i = gridpage * gridmax
        ubyte i = 0
        while i < count {
            ubyte k = 0
            while icodir[k] != 0 {
                icosrc[k] = icodir[k]
                k++
            }
            icosrc[k] = '/'
            k++
            uword s = grid_name(base_i + i)
            ubyte j = 0
            while @(s + j) != 0 {
                icosrc[k] = @(s + j)
                k++
                j++
            }
            icosrc[k] = 0
            uword off = MAXICON + 1
            off *= ibytes                 ; clear of the desktop's own icons
            uword slot = i
            slot *= gridbytes
            uword base = IVRAM + off + slot
            cx.fs_vload(&icosrc, k, 8, IVBANK, base)
            cx.sprite_image_at(GRIDSPR + i, IVBANK, base, x16c.SPRITE_MODE_4BPP)
            cx.sprite_size(GRIDSPR + i, gridsz, gridsz, 0)
            cx.sprite_z(GRIDSPR + i, x16c.SPRITE_Z_FRONT)
            cx.sprite_pos(GRIDSPR + i, grid_x(i), grid_y(i))
            i++
        }
        ; Every load that missed left an error on the command channel.
        void cx.dos_status()
    }

    ; Always all GRIDMAX slots, not just the ones in use: a short last
    ; page would otherwise leave the previous page's icons on screen.
    sub grid_hide() {
        ubyte i = 0
        while i < GRIDMAX {
            cx.sprite_z(GRIDSPR + i, x16c.SPRITE_Z_DISABLED)
            i++
        }
    }

    ; -> the chosen index within the WHOLE list, or 255.
    sub grid_pick(ubyte total) -> ubyte {
        ; A box big enough for the grid, in the middle of the screen.
        ubyte cw = lsb(gridpx >> 3) + 1       ; cell width in characters
        ubyte grows = (gridmax + gridcols - 1) / gridcols
        ubyte boxw = cw * gridcols + 2
        ubyte boxh = cw * grows + 3
        ubyte bx = (scrw - boxw) / 2
        ubyte by = (scrh - boxh) / 2
        ubyte r = 0
        while r < boxh {
            cx.screen_addr(by + r, bx)
            cx.screen_blitfill(boxw, A_PANEL, ' ')
            r++
        }
        gridx0 = bx + 1
        gridx0 <<= 3
        gridy0 = by + 1
        gridy0 <<= 3
        gridpage = 0
        ubyte npages = grid_pages(total)
        upcol = bx + boxw - 12
        dncol = bx + boxw - 7
        bool redraw = true
        cx.mse_show_keep()            ; the pointer is already configured
        bool held = false
        while true {
            if redraw {
                redraw = false
                grid_hide()
                grid_show(total)
                cx.screen_addr(by, bx + 1)
                cx.screen_blitfill(boxw - 2, A_BAR, ' ')
                cx.screen_addr(by, bx + 1)
                cx.screen_blit("click an icon", 13, A_BAR)
                if npages > 1 {
                    cx.screen_addr(by, bx + 15)
                    cx.screen_blit(cx.u8_to_dec(gridpage + 1), 1, A_BAR)
                    cx.screen_blit("/", 1, A_BAR)
                    cx.screen_blit(cx.u8_to_dec(npages), 1, A_BAR)
                    ; Buttons rather than named keys: they say what they
                    ; do without being explained, and the same two cells
                    ; answer a click and a cursor key.
                    cx.screen_addr(by, upcol)
                    if gridpage != 0
                        cx.screen_blit("[up]", 4, A_SEL)
                    else
                        cx.screen_blit("[up]", 4, A_BAR)
                    cx.screen_addr(by, dncol)
                    if gridpage + 1 < npages
                        cx.screen_blit("[down]", 6, A_SEL)
                    else
                        cx.screen_blit("[down]", 6, A_BAR)
                }
            }
            ubyte k = cx.key_get()
            if k == $1b or k == $03
                return 255
            ; The cursor keys do what the two buttons do.
            if k == $91 and gridpage != 0 {         ; cursor up
                gridpage--
                redraw = true
            }
            if k == $11 and gridpage + 1 < npages { ; cursor down
                gridpage++
                redraw = true
            }
            ubyte btn = cx.mse_get()
            uword mx = peekw(x16c.X16_P0)
            uword my = peekw(x16c.X16_P0 + 2)
            if btn & x16c.MSE_BUTTON_LEFT != 0 {
                if not held {
                    held = true
                    ; The two buttons first: they sit on the header row,
                    ; above every icon, so a click there is never a click
                    ; on the grid.
                    ubyte cc = lsb(mx >> 3)
                    ubyte cr = lsb(my >> 3)
                    if cr == by and npages > 1 {
                        if cc >= upcol and cc < upcol + 4 and gridpage != 0 {
                            gridpage--
                            redraw = true
                        }
                        if cc >= dncol and cc < dncol + 6 and gridpage + 1 < npages {
                            gridpage++
                            redraw = true
                        }
                    }
                    ubyte count = grid_oncount(total)
                    ubyte i = 0
                    while i < count {
                        uword gx = grid_x(i)
                        uword gy = grid_y(i)
                        if mx >= gx and mx < gx + gridpx and my >= gy and my < gy + gridpx
                            return gridpage * gridmax + i
                        i++
                    }
                }
            } else {
                held = false
            }
        }
        return 255
    }

    const ubyte PREVSPR = 20          ; icons own sprites 1..MAXICON
    sub preview_icon() {
        ubyte n = cx.fp_copy_name(&iconame, len(iconame))
        if n == 0
            return
        ubyte i = 0
        while icodir[i] != 0 {
            icosrc[i] = icodir[i]
            i++
        }
        icosrc[i] = '/'
        i++
        ubyte j = 0
        while j < n {
            icosrc[i] = iconame[j]
            i++
            j++
        }
        icosrc[i] = 0
        ; Its own VRAM slot, straight after the sixteen the desktop's own
        ; icons use, so previewing never scribbles on one of them.
        uword off = MAXICON
        off *= ibytes
        uword base = IVRAM + off
        cx.fs_vload(&icosrc, i, 8, IVBANK, base)
        cx.sprite_image_at(PREVSPR, IVBANK, base, x16c.SPRITE_MODE_4BPP)
        cx.sprite_size(PREVSPR, sprsize, sprsize, 0)
        cx.sprite_z(PREVSPR, x16c.SPRITE_Z_FRONT)
        ; Inside the panel's own top-right corner, a character clear of
        ; both edges. Off at the screen edge it read as an ornament that
        ; had nothing to do with the list; sitting in the panel it is
        ; obviously the answer to the question the panel is asking.
        ;
        ; It covers the right end of the top few rows, which is empty --
        ; filenames are left-aligned -- and SPRITE_Z_FRONT already puts
        ; it in front of layer 1, so no z-order change is needed. One row
        ; down, so the heading stays readable.
        uword px = cx.fp_panel_left()
        px += cx.fp_panel_width()
        px <<= 3                      ; columns -> pixels
        px -= iww                      ; ...the icon's own width
        px -= 8                        ; ...and a character of margin
        uword py = cx.fp_panel_top()
        py++
        py <<= 3
        cx.sprite_pos(PREVSPR, px, py)
    }

    ; ---- the wallpaper chooser -------------------------------------------
    ; Right click on the desktop itself, where there is no icon. The list
    ; is names rather than thumbnails: a wallpaper is 300 KB and there is
    ; nowhere to put ten of them at once, so this shows what is on offer
    ; and applies the choice -- the desktop then IS the preview.
    str wallhead = "wallpaper   click one   esc"
    sub wall_scan() -> ubyte {
        ubyte n = 0
        cx.dos_chdir(&icodir, len(icodir))
        if cx.dir_open(&icodir, 0, 8) {
            cx.dos_chdir(&root, len(root))
            return 0
        }
        while n < GRIDTOTAL {
            if not cx.dir_next(&iconame, len(iconame))
                break
            ubyte l = 0
            while iconame[l] != 0 and l < GRIDNLEN
                l++
            ; The THUMBNAILS, not the wallpapers. Each picture has a
            ; 32x32 .THM beside it in exactly the icon format, so the
            ; same grid that chooses an icon can show the pictures --
            ; the wallpapers themselves are 300 KB and there is nowhere
            ; to hold ten at once. The whole name is kept, because
            ; grid_show loads by it; the stem is taken off at the end.
            if l > 4 {
                if iconame[l - 4] == '.' and iconame[l - 3] == 't' and
                   iconame[l - 2] == 'h' and iconame[l - 1] == 'm' {
                    uword d = grid_name(n)
                    ubyte j = 0
                    while j < l and j < GRIDNLEN - 1 {
                        @(d + j) = iconame[j]
                        j++
                    }
                    @(d + j) = 0
                    n++
                }
            }
        }
        cx.dir_close()
        cx.dos_chdir(&root, len(root))
        return n
    }

    sub choose_wall() {
        ubyte total = wall_scan()
        if total == 0 {
            cx.screen_addr(scrh - 1, 0)
            cx.screen_blitfill(scrw, A_BAR, ' ')
            cx.screen_addr(scrh - 1, 1)
            cx.screen_blit("no wallpapers in /desktop", 25, A_BAR)
            return
        }
        ; The very same grid the icons use, paging buttons and all --
        ; but at 64x64. A photograph shrunk to 32 is a smudge; at 64 you
        ; can tell which of your pictures it is, which is the entire
        ; point of showing them.
        ; EIGHT per page, and the number is not a matter of taste. The
        ; grid's pixels start at $16200 and the text layer's map is at
        ; $1B000, so there are 19 KB to work in. Twelve 64x64 thumbnails
        ; are 24 KB: they ran through the map and painted garbage across
        ; the top of the screen. Eight are 16 KB and stop at $1A200.
        gridpx = 64
        gridbytes = 2048              ; 64x64 at 4bpp
        gridsz = x16c.SPRITE_SIZE_64
        gridcols = 4
        gridmax = 8
        ubyte sel = grid_pick(total)
        grid_hide()
        if sel == 255
            return
        ; grid_name holds "PIC03.THM"; the config wants "PIC03", and
        ; wall_name() puts .BMX or .BMO back on depending on the screen.
        uword chosen = grid_name(sel)
        ubyte j = 0
        while j < WSTEM_MAX and @(chosen + j) != 0 and @(chosen + j) != '.' {
            @(CFG + C_WALL + j) = @(chosen + j)
            j++
        }
        @(CFG + C_WALL + j) = 0
        cfg_save()
        ; Tear up the cache stamp. wall_cached() asks whether the picture
        ; already in SDRAM is the one it fingerprinted -- not whether it
        ; is the one now being ASKED for -- so after choosing, the old
        ; wallpaper still matches its own stamp and paint() would decide
        ; there was nothing to fetch. Clearing the magic makes the next
        ; paint load from disk, which is exactly what was wanted.
        @(WALLMAG) = 0
    }

    sub change_icon(ubyte n) {
        icons_z(x16c.SPRITE_Z_DISABLED)
        gridpx = iww                  ; icons show at the desktop's own size
        gridbytes = ibytes
        gridsz = sprsize
        gridcols = GRIDCOLS
        gridmax = GRIDMAX
        ubyte count = grid_scan()
        ubyte got = 0
        if count == 0 {
            ; Never fail silently here. A right click that does nothing
            ; at all is indistinguishable from a right click that was
            ; not noticed, and that is exactly how the last bug hid.
            cx.screen_addr(scrh - 1, 0)
            cx.screen_blitfill(scrw, A_BAR, ' ')
            cx.screen_addr(scrh - 1, 1)
            cx.screen_blit("no icons found in /desktop", 26, A_BAR)
        }
        if count != 0 {
            ubyte sel = grid_pick(count)
            grid_hide()
            if sel != 255 {
                uword s = grid_name(sel)
                while @(s + got) != 0 and got < len(iconame) - 1 {
                    iconame[got] = @(s + got)
                    got++
                }
                iconame[got] = 0
            }
        }
        if got != 0 {
            ; SAVE writes to the CURRENT directory and ignores a path,
            ; so stand in the program's own folder before copying.
            split_path(rec_path(n), slen(rec_path(n)))
            if folder[0] != 0
                cx.dos_chdir(&folder, slen(&folder))
            else
                cx.dos_chdir(&root, len(root))
            void copy_one(".ico", 512)
            void copy_one(".i16", 128)
        }
        cx.dos_chdir(&root, len(root))
        make_icons()
        icons_z(x16c.SPRITE_Z_FRONT)
        paint_text()
        cx.sprites_on()
        cx.mse_config(1, scrw, scrh)
        mdown = false
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
; The browser itself is x16lib/filepick -- one copy, shared with imgview
; and anything else that needs to ask "which file?". What stays here is
; what only a desktop wants: keeping an entry, choosing its icon, and
; handing a data file to a program that can open it.
;
; The desktop lists EVERYTHING and marks anything that is not a .prg,
; because a .bmx is not something it can run but is something it can
; hand over. cx.fp_is_primary() is that distinction.
; =====================================================================
    ; The browser is dressed like the title bar -- the same light grey
    ; plate, the same blue lettering -- so the two read as parts of one
    ; desktop rather than two programs. Blue, not white: index 0 is
    ; transparent in the FOREGROUND as well, and white on this plate is
    ; barely there.
    const ubyte A_PANEL = 6 | (15 << 4)   ; blue on light grey
    const ubyte A_BAR   = 6 | (15 << 4)   ; ...header and footer to match
    const ubyte A_SEL   = 15 | (6 << 4)   ; inverted: the cursor line
    ; Taken from the library rather than restated, so the desktop's own
    ; typing fields cannot drift away from the browser's. They had:
    ; A_EDIT was blue on light grey while filepick's edit field is blue
    ; on yellow, and the two sat one dialog apart looking unrelated.
    const ubyte A_EDIT   = x16c.FPK_AEDIT     ; $76, blue on yellow
    const ubyte A_CURSOR = x16c.FPK_ACURSOR   ; $67, inverted: a block

    str pk_all   = "*.*"
    str pk_prg   = "*.prg"
    str pk_head  = "programs in "
    ; The edit keys have to be named here or nobody finds them: they are
    ; the browser's, not the desktop's, and nothing else on screen hints
    ; that the panel can rename or delete anything. kalk's footer says
    ; the same thing in the same words.
    str pk_foot  = "dbl-click runs  right adds  n/e/d/c/v edit  esc closes"
    str pk_foot4 = "dbl runs  right adds  nedcv  esc"

    ubyte[64] fullpath
    ; The file an "open with" launch hands to the program it starts.
    ; Kept apart from fullpath because both are needed at once: one says
    ; what to run, the other what to open.
    ubyte[64] argfile
    bool hasarg = false
    ubyte[24] editbuf
    ubyte[40] pickname            ; the chosen name, copied out of the browser
    ubyte[64] pickdir             ; ...and the directory it came from

    sub pk_setup() {
        cx.fp_cache($2000, 1)              ; the listing: VRAM $12000, clear
                                   ; of the icon sprites at $14000
        cx.fp_filter(&pk_all)
        cx.fp_primary(&pk_prg)
        cx.fp_style(A_PANEL, A_BAR, A_SEL)
        cx.fp_heading(&pk_head)
        if hires
            cx.fp_footing(&pk_foot)
        else
            cx.fp_footing(&pk_foot4)
    }

    ; The panel's geometry, asked of the module so the dialogs below
    ; land inside it whatever screen we are on.
    sub pk_row(ubyte r, ubyte attr) {
        cx.screen_addr(r, cx.fp_panel_left())
        cx.screen_blitfill(cx.fp_panel_width(), attr, ' ')
    }

    sub pk_left() -> ubyte {
        return cx.fp_panel_left()
    }

    sub pk_w() -> ubyte {
        return cx.fp_panel_width()
    }

    ; -> true when a program was chosen to run, with fullpath set
    sub picker() -> bool {
        pk_setup()
        ubyte act = cx.fp_open()
        while act == x16c.FPK_ALT {
            ; right click, or 'a': keep it on the desktop. Only a
            ; program can be kept -- an icon that cannot be launched
            ; would be furniture.
            if cx.fp_is_primary() {
                void cx.fp_copy_path(&fullpath, len(fullpath))
                void cx.fp_copy_name(&pickname, len(pickname))
                void add_dialog(&pickname)
            }
            act = cx.fp_resume()
        }
        if act != x16c.FPK_PICK {
            cx.fp_close()
            return false
        }
        if cx.fp_is_primary() {
            void cx.fp_copy_path(&fullpath, len(fullpath))
            void cx.fp_copy_name(&pickname, len(pickname))
            cx.fp_close()
            say_loading(&pickname)
            return true
        }
        ; A data file: which program should open it?
        void cx.fp_copy_name(&pickname, len(pickname))
        ubyte w = openwith_dialog(&pickname)
        if w == 255 {
            cx.fp_close()
            return false
        }
        void cx.fp_copy_path(&argfile, len(argfile))
        hasarg = true
        put_str(&fullpath, rec_path(w), len(fullpath) - 1)
        cx.fp_close()
        return true
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
        ubyte dn = cx.fp_copy_dir(&pickdir, len(pickdir))
        cx.dos_chdir(&pickdir, dn)  ; back to the browsed dir
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
                pk_row(cx.fp_panel_top() + 2 + r, A_BAR)
                r++
            }
            cx.screen_addr(cx.fp_panel_top() + 2, pk_left() + 2)
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
                cx.screen_addr(cx.fp_panel_top() + 3 + i, pk_left() + 2)
                cx.screen_blitfill(20, attr, ' ')
                cx.screen_addr(cx.fp_panel_top() + 3 + i, pk_left() + 4)
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
            pk_row(cx.fp_panel_top() + 2, A_BAR)
            pk_row(cx.fp_panel_top() + 3, A_BAR)
            cx.screen_addr(cx.fp_panel_top() + 2, pk_left() + 2)
            if hires
                cx.screen_blit("name on the desktop (enter accepts, esc cancels):",
                               48, A_BAR)
            else
                cx.screen_blit("name it (enter ok, esc cancel)", 29, A_BAR)
            ; An OPAQUE field. Background 0 is transparent, which is the
            ; whole trick behind the wallpaper -- and exactly wrong here:
            ; it cut a hole through the panel and let the photograph
            ; through the middle of the text being typed.
            cx.screen_addr(cx.fp_panel_top() + 3, pk_left() + 2)
            cx.screen_blitfill(L_MAX + 2, A_EDIT, ' ')
            cx.screen_addr(cx.fp_panel_top() + 3, pk_left() + 2)
            if n != 0
                cx.screen_blit(&editbuf, n, A_EDIT)
            ; A block, not an underscore: a space drawn with the cursor
            ; attribute is inverted, so it fills the cell the way the
            ; browser's edit field does. An underscore on a yellow field
            ; is nearly invisible, which is half of why this dialog did
            ; not look like the one next door.
            cx.screen_addr(cx.fp_panel_top() + 3, pk_left() + 2 + n)
            cx.screen_blit(" ", 1, A_CURSOR)

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
            pk_row(cx.fp_panel_top() + 2, A_BAR)
            pk_row(cx.fp_panel_top() + 3, A_BAR)
            pk_row(cx.fp_panel_top() + 4, A_BAR)
            pk_row(cx.fp_panel_top() + 5, A_BAR)
            cx.screen_addr(cx.fp_panel_top() + 2, pk_left() + 2)
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
                ubyte c = pk_left() + 2 + i * pitch
                cx.screen_addr(cx.fp_panel_top() + 3, c)
                cx.screen_blitfill(pitch - 1, pbar[i] | (pbar[i] << 4), ' ')
                cx.screen_addr(cx.fp_panel_top() + 4, c)
                cx.screen_blitfill(pitch - 1, pfill[i] | (pfill[i] << 4), ' ')
                ; A pair of small arrows beside a chip is not enough to see
                ; at a glance -- which of twelve is chosen has to be obvious
                ; without hunting. So the choice gets a solid bar under it,
                ; the full width of the chip.
                cx.screen_addr(cx.fp_panel_top() + 5, c)
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
        ; Same guard as launch_path: an empty folder means the root, not
        ; "wherever we are". Harmless today because launch_path has just
        ; put us there, but a chdir to "" is not a chdir to "/", and the
        ; next person to call this from somewhere else would find out the
        ; hard way.
        if folder[0] != 0
            cx.dos_chdir(&folder, slen(&folder))  ; the program's own directory
        else
            cx.dos_chdir(&root, len(root))
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
        say_loading(rec_label(i))
        launch_path(rec_path(i))
    }

    ; Between the double click and the program appearing there is a
    ; noticeable wait -- the file is read to find its entry point, the
    ; icon list is saved, then the trampoline loads the program itself.
    ; Without a word on screen that reads as a click that did nothing,
    ; and the second click people give it lands in whatever comes up.
    ;
    ; It goes in the title bar, which is about to be replaced by the
    ; program anyway, so nothing has to put it back.
    sub say_loading(uword label) {
        cx.screen_addr(0, 0)
        cx.screen_blitfill(scrw, 6 | (15 << 4), ' ')
        cx.screen_addr(0, 1)
        cx.screen_blit("loading ", 8, 6 | (15 << 4))
        ubyte n = slen(label)
        if n > 20
            n = 20
        cx.screen_blit(label, n, 6 | (15 << 4))
        cx.screen_blit("...", 3, 6 | (15 << 4))
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
        ; Say where we are, ALWAYS -- a program in the root has no folder
        ; to change to, and leaving the drive wherever it happened to be
        ; is not the same thing as being at the root. This used to work
        ; by luck: cfg_save ran first and chdir'd to "/" on its way past.
        ; The moment the list moved to /DESKTOP that luck ran out and
        ; every root program -- imgview, kalk, shell -- stopped loading,
        ; because fs_prg_entry was looking for them in /DESKTOP.
        if folder[0] != 0
            cx.dos_chdir(&folder, slen(&folder))
        else
            cx.dos_chdir(&root, len(root))
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

