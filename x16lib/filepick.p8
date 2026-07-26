; =====================================================================
; filepick.p8 -- a file browser any program can put on screen.
;
; Lifted out of examples/desktop, which had the only copy: a directory
; panel with a mouse, keyboard, scrolling and descent into folders. The
; desktop still uses it -- that is the point, one copy -- and imgview
; and kalk use the same one.
;
;       %import filepick
;
;       filepick.filter("*.bmx")           ; what to list
;       if filepick.open() == filepick.PICK
;           load_it(filepick.path())       ; absolute, ready to open
;       filepick.close()
;
; WHAT IT IS NOT: it does not save, it does not rename, and it does not
; decide what a file means. It answers one question -- which file? --
; and the caller does the rest.
;
; THE FILTER is a list of patterns separated by ';':
;
;       "*.prg"             programs
;       "*.bmx;*.png"       either kind of picture
;       "*.*"               every file, whatever it is called
;
; Directories are always listed whatever the filter says, or there would
; be no way to reach the file you wanted. Matching folds case, because
; the drive answers in ASCII and Prog8 source is PETSCII (see .match).
;
; SET primary() when some of the listed files are special: the desktop
; lists everything with "*.*" but marks anything that is not a "*.prg"
; with [dat], because those it cannot run, only hand to a program that
; can. Left unset, primary is the filter and nothing is marked.
;
; MEMORY: the entry cache is 64 x 40 bytes and lives wherever cache()
; puts it -- by default $A400 in RAM bank 63, clear of the banks kalk
; and the library's bank_alloc use. Nothing else is held between calls.
;
; SAVE-UNDER: a desktop repaints itself when the panel closes, so it
; does not care what was underneath. kalk does: it has a spreadsheet on
; screen. saveunder(<bank>) keeps the covered characters and colours in
; that bank and puts them back on close -- about 5.7 KB of an 8 KB bank
; at 80 columns.
; =====================================================================
%import x16lib
%import x16lib_const

filepick {
    ; what open()/resume() came back with
    const ubyte NONE = 0          ; cancelled: ESC, Run/Stop, or the x box
    const ubyte PICK = 1          ; a file was chosen: path() has it
    const ubyte ALT  = 2          ; the second gesture: right click, or 'a'

    const ubyte E_SIZE = 40       ; one cache entry: type, then the name
    const ubyte E_TYPE = 0
    const ubyte E_NAME = 1
    const ubyte MAXENT = 64
    const ubyte NOBANK = 255

    ; ---- configuration, all optional -------------------------------
    uword cacheat  = $A400
    ubyte cachebk  = 63
    uword filt     = 0            ; 0 means "*.*"
    uword prim     = 0            ; 0 means "the same as filt"
    uword head     = 0            ; 0 means "files in "
    uword foot     = 0
    ubyte a_panel  = 6 | (15 << 4)
    ubyte a_bar    = 6 | (15 << 4)
    ubyte a_sel    = 15 | (6 << 4)
    ubyte underbk  = NOBANK
    uword startat  = 0            ; 0 means "/"
    ; The panel is drawn in PET upper/lower (charset 3) so a name reads
    ; the way it was written. 255 leaves whatever the caller had -- there
    ; is no way to ask the KERNAL which charset is loaded, so the module
    ; cannot put back what it does not know.
    ubyte chset    = 3

    sub cache(uword addr, ubyte bank) {
        cacheat = addr
        cachebk = bank
    }

    sub filter(uword pattern) {
        filt = pattern
    }

    sub primary(uword pattern) {
        prim = pattern
    }

    sub style(ubyte panel, ubyte bar, ubyte sel) {
        a_panel = panel
        a_bar = bar
        a_sel = sel
    }

    sub heading(uword text) {
        head = text
    }

    sub footing(uword text) {
        foot = text
    }

    sub saveunder(ubyte bank) {
        underbk = bank
    }

    sub start_dir(uword path) {
        startat = path
    }

    sub charset(ubyte n) {
        chset = n
    }

    ; ---- state ------------------------------------------------------
    ubyte[64] curdir
    ubyte[64] full
    ubyte[40] nm
    ubyte nent
    ubyte sel
    ubyte top
    bool  down                    ; the button was already held last poll
    uword lastck
    ubyte lastidx
    ubyte rows                    ; the panel, in cells
    ubyte left
    ubyte wide
    ubyte scrw
    ubyte scrh
    ubyte callerbank
    bool  saved                   ; there is a screen in the bank to restore
    const ubyte TOP = 3
    const uword DBLCLICK = 30     ; jiffies: half a second

    str s_root = "/"
    str s_head = "files in "
    str s_all  = "*.*"
    str s_foot = "double click opens   esc closes"

    ; -> the absolute path of the chosen entry
    sub path() -> uword {
        return &full
    }

    ; -> just the name, without the directory
    sub name() -> uword {
        ubyte i = 0
        uword last = &full
        while full[i] != 0 {
            if full[i] == '/'
                last = &full + i + 1
            i++
        }
        return last
    }

    ; -> the directory being browsed, which is where the drive is left
    sub dir() -> uword {
        return &curdir
    }

    ; Where the panel is, for a caller that wants to draw its own rows
    ; inside it -- the desktop asks a name and an icon on the rows just
    ; below the header. Valid once open() has run.
    sub panel_top() -> ubyte {
        return TOP
    }

    sub panel_left() -> ubyte {
        return left
    }

    sub panel_width() -> ubyte {
        return wide
    }

    sub panel_rows() -> ubyte {
        return rows
    }

    ; Repaint the panel: after a caller has drawn over it.
    sub redraw() {
        draw()
    }

    ; =================================================================
    ; matching
    ;
    ; The drive hands names back in ASCII ('b' is $62) while Prog8
    ; encodes a lower-case letter in source as PETSCII $41-$5A -- the
    ; same codes as ASCII CAPITALS. Clearing bit 5 folds either onto the
    ; other, which is why patterns in source are written lower-case and
    ; still match a card written in upper.
    ; =================================================================
    sub fold(ubyte c) -> ubyte {
        if (c >= $41 and c <= $5A) or (c >= $61 and c <= $7A)
            return c & $DF
        return c
    }

    ; Does this name match one of the patterns in this ';' list?
    sub match(uword who, uword pattern) -> bool {
        if pattern == 0
            return true
        uword p = pattern
        while @(p) != 0 {
            ; one pattern: up to the next ';' or the end
            if match_one(who, p)
                return true
            while @(p) != 0 and @(p) != ';'
                p++
            if @(p) == ';'
                p++
        }
        return false
    }

    sub match_one(uword who, uword p) -> bool {
        ; "*" or "*.*" -- everything
        if @(p) == '*' {
            if @(p + 1) == 0 or @(p + 1) == ';'
                return true
            if @(p + 1) == '.' and @(p + 2) == '*'
                return true
        }
        ; "*.ext" -- compare the tail
        if @(p) != '*' or @(p + 1) != '.'
            return false
        uword ext = p + 2
        ubyte en = 0
        while @(ext + en) != 0 and @(ext + en) != ';'
            en++
        if en == 0
            return false
        ubyte wn = 0
        while @(who + wn) != 0
            wn++
        if wn < en + 1
            return false
        uword tail = who + wn - en
        if @(tail - 1) != '.'
            return false
        ubyte i = 0
        while i < en {
            if fold(@(tail + i)) != fold(@(ext + i))
                return false
            i++
        }
        return true
    }

    ; =================================================================
    ; the listing
    ; =================================================================
    sub ent(ubyte i) -> uword {
        uword a = i
        a *= E_SIZE
        return cacheat + a
    }

    ; Directories first, then whatever counts as primary, then the rest:
    ; three passes over the listing rather than a sort. Data files are
    ; cached as DIR_TYPE_SEQ and primary ones as DIR_TYPE_PRG, whatever
    ; the drive called them -- an emulator's host filesystem reports
    ; every file as PRG, so the drive's own answer is no help.
    sub read() {
        uword pat = filt
        if pat == 0
            pat = &s_all
        uword pri = prim
        if pri == 0
            pri = pat
        cx.bank_set(cachebk)
        nent = 0
        ubyte pass = 0
        while pass < 3 {
            if cx.dir_open(0, 0, 8)
                return
            while cx.dir_next(&nm, len(nm)) {
                ubyte t = cx.dir_type()
                if t == x16c.DIR_TYPE_HOST or t == x16c.DIR_TYPE_NONE {
                    ; Not files. The header line is a path on an
                    ; emulator's host filesystem (HOST) and the volume
                    ; label on a real card (NONE, with raw directory
                    ; bytes in the name), and the "BLOCKS FREE." trailer
                    ; is NONE as well. Listing either put a row of
                    ; rubbish on screen.
                } else if nent < MAXENT {
                    bool want = false
                    ubyte kind = t
                    if pass == 0 and t == x16c.DIR_TYPE_DIR {
                        want = nm[0] != '.' or nm[1] != 0   ; "." leads nowhere
                    } else if t != x16c.DIR_TYPE_DIR {
                        if not match(&nm, pat) {
                            ; not ours to show at all
                        } else if pass == 1 {
                            want = match(&nm, pri)
                            kind = x16c.DIR_TYPE_PRG
                        } else if pass == 2 {
                            want = not match(&nm, pri)
                            kind = x16c.DIR_TYPE_SEQ
                        }
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

    sub put_str(uword dst, uword src, ubyte maxn) {
        ubyte i = 0
        while i < maxn and @(src + i) != 0 {
            @(dst + i) = @(src + i)
            i++
        }
        @(dst + i) = 0
    }

    sub zlen(uword s) -> ubyte {
        ubyte i = 0
        while @(s + i) != 0
            i++
        return i
    }

    ; curdir + "/" + name, which is what the caller gets back
    sub make_path(uword who) {
        ubyte n = 0
        while curdir[n] != 0 and n < 40 {
            full[n] = curdir[n]
            n++
        }
        if n > 0 and full[n - 1] != '/' {
            full[n] = '/'
            n++
        }
        ubyte k = 0
        while @(who + k) != 0 and n < len(full) - 1 {
            full[n] = @(who + k)
            n++
            k++
        }
        full[n] = 0
    }

    ; Where we are, kept by hand: ".." trims the last component and
    ; anything else appends one. The drive is not asked, because it
    ; answers with a volume label on a card and a path on an emulator.
    sub descend(uword who) {
        ubyte n = zlen(&curdir)
        if @(who) == '.' and @(who + 1) == '.' and @(who + 2) == 0 {
            while n > 1 and curdir[n - 1] != '/'
                n--
            if n > 1
                n--
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
        while @(who + k) != 0 and n < len(curdir) - 1 {
            curdir[n] = @(who + k)
            n++
            k++
        }
        curdir[n] = 0
    }

    ; =================================================================
    ; the panel
    ; =================================================================
    sub layout() {
        if cx.screen_get_mode() == 0 {
            scrw = 80
            scrh = 60
            rows = 40
            left = 6
            wide = 68
        } else {
            scrw = 40
            scrh = 30
            rows = 22
            left = 1
            wide = 38
        }
    }

    sub prow(ubyte r, ubyte attr) {
        cx.screen_addr(r, left)
        cx.screen_blitfill(wide, attr, ' ')
    }

    sub draw() {
        uword h = head
        if h == 0
            h = &s_head
        prow(TOP, a_bar)
        cx.screen_addr(TOP, left + 1)
        cx.screen_blit(h, zlen(h), a_bar)
        ubyte dn = zlen(&curdir)
        if dn > wide - 14
            dn = wide - 14
        cx.screen_blit(&curdir, dn, a_bar)
        cx.screen_addr(TOP, left + wide - 3)
        cx.screen_blit(" x ", 3, 2 | (15 << 4))    ; click to close

        ubyte r = 0
        while r < rows {
            ubyte i = top + r
            ubyte attr = a_panel
            if i == sel
                attr = a_sel
            prow(TOP + 1 + r, attr)
            if i < nent {
                uword e = ent(i)
                cx.screen_addr(TOP + 1 + r, left + 2)
                if @(e + E_TYPE) == x16c.DIR_TYPE_DIR
                    cx.screen_blit("[dir] ", 6, attr)
                else if @(e + E_TYPE) == x16c.DIR_TYPE_SEQ
                    cx.screen_blit("[dat] ", 6, attr)
                else
                    cx.screen_blit("      ", 6, attr)
                ; Clamped: a row that runs over wraps around the screen
                ; and draws outside the panel entirely.
                ubyte nl = zlen(e + E_NAME)
                if nl > wide - 10
                    nl = wide - 10
                cx.screen_blit(e + E_NAME, nl, attr)
            }
            r++
        }
        uword f = foot
        if f == 0
            f = &s_foot
        prow(TOP + 1 + rows, a_bar)
        cx.screen_addr(TOP + 1 + rows, left + 1)
        ubyte fn = zlen(f)
        if fn > wide - 2
            fn = wide - 2
        cx.screen_blit(f, fn, a_bar)
    }

    sub move(ubyte k) {
        if k == $91 {                 ; up
            if sel > 0
                sel--
        } else if k == $11 {          ; down
            if sel + 1 < nent
                sel++
        } else if k == $13 {          ; home
            sel = 0
        }
        if sel < top
            top = sel
        if sel >= top + rows
            top = sel - rows + 1
    }

    ; =================================================================
    ; save-under
    ;
    ; The text map is a character and a colour per cell, side by side,
    ; and screen_addr leaves VERA pointing at the first of a row with
    ; the address stepping by one -- so a row is 2 x wide sequential
    ; bytes, read or written the same way.
    ; =================================================================
    sub under_addr(ubyte r) -> uword {
        uword a = r
        a *= wide
        a *= 2
        return $A000 + a
    }

    sub save_under() {
        if underbk == NOBANK
            return
        cx.bank_set(underbk)
        ubyte r = 0
        while r < rows + 2 {
            cx.screen_addr(TOP + r, left)
            uword d = under_addr(r)
            ubyte i = 0
            while i < wide {
                @(d) = @(x16c.VERA_DATA0)
                @(d + 1) = @(x16c.VERA_DATA0)
                d += 2
                i++
            }
            r++
        }
        saved = true
        cx.bank_set(cachebk)
    }

    sub restore_under() {
        if underbk == NOBANK or not saved
            return
        cx.bank_set(underbk)
        ubyte r = 0
        while r < rows + 2 {
            cx.screen_addr(TOP + r, left)
            uword d = under_addr(r)
            ubyte i = 0
            while i < wide {
                @(x16c.VERA_DATA0) = @(d)
                @(x16c.VERA_DATA0) = @(d + 1)
                d += 2
                i++
            }
            r++
        }
        saved = false
    }

    ; =================================================================
    ; the loop
    ; =================================================================

    ; Open on the starting directory. -> NONE / PICK / ALT
    sub open() -> ubyte {
        layout()
        callerbank = @($00)           ; the RAM bank the caller was using
        saved = false
        uword s = startat
        if s == 0
            s = &s_root
        put_str(&curdir, s, len(curdir) - 1)
        cx.dos_chdir(s, zlen(s))
        sel = 0
        top = 0
        lastidx = 255
        if chset != 255
            cx.screen_charset(chset)
        save_under()
        read()
        cx.mse_config(1, scrw, scrh)
        down = true                   ; the click that opened us may still be held
        return loop()
    }

    ; Come back to the same directory and the same selection: for a
    ; caller that handled an ALT and wants the browser back.
    sub resume() -> ubyte {
        cx.bank_set(cachebk)
        cx.mse_config(1, scrw, scrh)
        down = true
        return loop()
    }

    ; Put back whatever was under the panel, hide the pointer, and give
    ; the caller its RAM bank back. The DRIVE is left in the directory
    ; that was being browsed -- a caller that cares should chdir.
    sub close() {
        restore_under()
        cx.mse_hide()
        cx.bank_set(callerbank)
    }

    sub loop() -> ubyte {
        while true {
            draw()
            ubyte k = 0
            ubyte act = 0
            while k == 0 and act == 0 {
                k = cx.key_get()
                if k != 0
                    break
                ubyte btn = cx.mse_get()
                uword mx = peekw(x16c.X16_P0)
                uword my = peekw(x16c.X16_P0 + 2)
                ubyte hit = btn & 3           ; left (1) and right (2)
                if hit != 0 {
                    if not down {
                        down = true
                        ubyte pr = lsb(my >> 3)
                        ubyte pc = lsb(mx >> 3)
                        if pr == TOP and pc >= left + wide - 3 {
                            k = $1b           ; the x box closes, like ESC
                        } else if pr > TOP and pr <= TOP + rows {
                            ubyte li = pr - TOP - 1
                            if top + li < nent {
                                ubyte idx = top + li
                                sel = idx
                                if hit & 2 != 0 {
                                    act = 3   ; right button: the ALT gesture
                                    lastidx = 255
                                } else {
                                    uword now = cx.clock_get_timer()
                                    if idx == lastidx and now - lastck < DBLCLICK {
                                        act = 1           ; double click
                                        lastidx = 255
                                    } else {
                                        lastck = now
                                        lastidx = idx
                                        act = 2           ; select only
                                    }
                                }
                            }
                        }
                    }
                } else {
                    down = false
                }
            }
            if act == 2
                continue
            if act == 3 {
                uword re = ent(sel)
                if @(re + E_TYPE) != x16c.DIR_TYPE_DIR {
                    make_path(re + E_NAME)
                    return ALT
                }
                down = true
                continue
            }
            if act == 1
                k = $0d
            if k == $1b or k == $03
                return NONE
            if k == $91 or k == $11 or k == $13 {
                move(k)
            } else if nent != 0 {
                uword e = ent(sel)
                if k == $0d and @(e + E_TYPE) == x16c.DIR_TYPE_DIR {
                    cx.dos_chdir(e + E_NAME, zlen(e + E_NAME))
                    descend(e + E_NAME)
                    sel = 0
                    top = 0
                    read()
                } else if @(e + E_TYPE) != x16c.DIR_TYPE_DIR {
                    if k == 'r' or k == $0d {
                        make_path(e + E_NAME)
                        return PICK
                    }
                    if k == 'a' {
                        make_path(e + E_NAME)
                        return ALT
                    }
                }
            }
        }
        return NONE
    }

    ; -> true when the chosen entry is one of the primary kind. A caller
    ; that lists "*.*" uses this to tell what it can act on directly
    ; from what it has to hand to something else.
    sub is_primary() -> bool {
        uword pri = prim
        if pri == 0
            pri = filt
        return match(name(), pri)
    }
}
