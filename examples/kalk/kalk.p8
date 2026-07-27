; =====================================================================
; kalk.p8 -- a VisiCalc-style spreadsheet for the Commander X16.
; A port of zserge's kalk (https://github.com/zserge/kalk) to Prog8,
; running entirely on the X16_Library: the ROM floating point binding
; (util/float), the screen, the keyboard and KERNAL file I/O.
;
;   .\build.ps1 examples\kalk\kalk.p8 -Run
;
; Arrow keys move, or click a cell with the mouse.  Type a number, a
; formula (+ - ( @) or a label.
; Press / for the command menu, > to jump to a cell, ! to recalculate,
; Run/Stop to quit.  The sheet is A..Z x 1..256, held in RAM banks 1-8;
; CSV files are read and written on device 8.
;
; %zeropage dontuse is not optional here: the library owns ZP $22-$31 and
; basicsafe hands those same bytes to Prog8 variables.
; =====================================================================
%import x16lib
%import x16lib_const
%import launcharg
%import kalkcore
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    const ubyte GW     = 4              ; row-number gutter
    const ubyte USEW   = 79             ; usable screen columns (80th would scroll)
    const ubyte VROWS  = 56             ; grid rows on screen
    const ubyte LBMAX  = 72             ; last status/edit column before the mode field

    ; colours: text, headers, cursor cell, locked title cells
    const ubyte C_FG = 1
    const ubyte C_BG = 6
    const ubyte H_FG = 0
    const ubyte H_BG = 15
    const ubyte K_FG = 0
    const ubyte K_BG = 7
    const ubyte L_FG = 0
    const ubyte L_BG = 3

    const ubyte K_UP    = $91
    const ubyte K_DOWN  = $11
    const ubyte K_LEFT  = $9D
    const ubyte K_RIGHT = $1D
    const ubyte K_HOME  = $13
    const ubyte K_CLR   = $93
    const ubyte K_RET   = $0D
    const ubyte K_DEL   = $14
    const ubyte K_TAB   = $09
    const ubyte K_ESC   = $1B
    const ubyte K_STOP  = $03

    ubyte cc                            ; cursor column / row
    ubyte cr
    ubyte vc                            ; top-left of the scrolling window
    ubyte vr
    ubyte tc                            ; locked title columns / rows
    ubyte tr
    bool  dirty
    bool  needfull
    bool  blanked = true                ; layer 1 is off until the first draw
    uword modez

    ubyte[80] linebuf
    ubyte[80] dbuf
    ubyte[40] sbuf
    ubyte[64] ibuf
    ubyte ilen
    ubyte edit_key
    ubyte[48] fname   ; a typed name is short; a browsed path is not
    ubyte fnlen
    ubyte[20] rngbuf

    bool  mouse_down                    ; the button was already down last poll

    ubyte sel_c1
    ubyte sel_r1
    ubyte sel_c2
    ubyte sel_r2

    str m_ready = "READY"
    str m_entry = "ENTRY"
    str m_goto  = " GOTO"
    str m_cmd   = "  CMD"
    str m_move  = " MOVE"
    str m_repl  = " REPL"
    str m_disk  = " DISK"

    str s_gt    = ">"
    str s_eq    = " = "
    str s_eqerr = " = ERROR"
    str s_eqna  = " = NA"
    str s_help  = " /=cmd  >=goto  !=recalc  \"=label  Del=clear  Tab/Ret=move  Stop=quit"
    str s_cmd   = "Command: B)lank C)lear D)elete I)nsert F)ormat G)lobal M)ove R)epl S)torage Q)uit"
    str s_askrc = "(R)ow or (C)olumn?"
    str s_askfm = "Format: L R I G D $ % *"
    str s_askgl = "Global: (C)olumn width or (F)ormat?"
    str s_askw  = "Column width (4-20)?"
    str s_asklk = "Lock (V)ertical (H)orizontal (B)oth (N)one?"
    str s_askst = "Storage: (L)oad (S)ave save&(Q)uit?"
    str s_askcl = "Clear the entire sheet? (y/N)"
    str s_askq  = "Unsaved changes. Quit anyway? (y/N)"
    str s_load  = "Load file:"
    str s_save  = "Save as:"
    str s_src   = "Source:"
    str s_to    = " to:"
    str s_movep = "Move: cursor keys drag, Ret confirm, Esc cancel"
    str s_ioerr = "I/O error, press a key --"
    str s_busy  = "Working..."
    str s_swr   = ",s,w"
    ; What the browser lists: sheets by their own extension, and .csv
    ; too, because that is what kalk has always written and a card full
    ; of them should not look empty.
    str s_sheets   = "*.klk;*.csv"
    str s_sheetsin = "sheets in "
    str s_saveinto = "save into "
    str s_savefoot = "walk to the folder then press h   click a sheet to replace it   esc cancels"
    ; the browser's answers, from the library's ui/filepick.asm
    const ubyte FPK_NONE = 0
    const ubyte FPK_PICK = 1
    const ubyte FPK_ALT  = 2
    const ubyte FPK_HERE = 3      ; 'h': the folder being shown


; =====================================================================
; low level screen output
;
; The grid is painted with the library's direct text-map calls rather
; than CHROUT: a full repaint is ~4500 characters and CHROUT costs
; several hundred cycles each.  cx.screen_addr points VERA at the first
; cell of a row, then cx.screen_blit / cx.screen_blitfill stream
; characters and colour bytes while the address walks the row itself.
; =====================================================================
    sub setcol(ubyte fg, ubyte bg) {
        cx.screen_color(fg, bg)
    }

    sub attr(ubyte fg, ubyte bg) -> ubyte {
        return fg | (bg << 4)
    }

    sub lb_clear() {
        ubyte i = 0
        while i < USEW {
            linebuf[i] = ' '
            i++
        }
    }

    sub lb_text(ubyte pos, uword s, ubyte n) -> ubyte {
        ubyte i = 0
        while i < n {
            if pos >= LBMAX
                return pos
            linebuf[pos] = @(s + i)
            pos++
            i++
        }
        return pos
    }

    sub lb_z(ubyte pos, uword s) -> ubyte {
        ubyte i = 0
        while @(s + i) != 0 {
            if pos >= LBMAX
                return pos
            linebuf[pos] = @(s + i)
            pos++
            i++
        }
        return pos
    }

    sub lb_show(ubyte row, ubyte fg, ubyte bg) {
        cx.screen_addr(row, 0)
        cx.screen_blit(&linebuf, USEW, attr(fg, bg))
    }


; =====================================================================
; layout
; =====================================================================
    sub vcols() -> ubyte {
        ubyte n = (USEW - GW) / kk.cw
        if n == 0
            n = 1
        return n
    }

    sub freecols() -> ubyte {
        ubyte n = vcols()
        if n > tc
            return n - tc
        return 1
    }

    sub freerows() -> ubyte {
        if VROWS > tr
            return VROWS - tr
        return 1
    }

    sub col_at(ubyte ci) -> ubyte {
        if ci < tc
            return ci
        return vc + ci - tc
    }

    ; a row index is 0..255, so anything that adds to it needs a word
    sub row_at(ubyte ri) -> uword {
        if ri < tr
            return ri
        uword r = ri
        r -= tr
        r += vr
        return r
    }

    ; screen slot of a column, 255 when it is not on screen
    sub slot_of_col(ubyte c) -> ubyte {
        if c < tc
            return c
        if c < vc
            return 255
        ubyte s = tc + c - vc
        if s >= tc + freecols()
            return 255
        return s
    }

    sub slot_of_row(ubyte r) -> ubyte {
        if r < tr
            return r
        if r < vr
            return 255
        ubyte s = r - vr + tr
        if s >= tr + freerows()
            return 255
        return s
    }

; =====================================================================
; mouse
;
; The KERNAL tracks the pointer in its own interrupt once MOUSE_CONFIG
; has enabled it, so reading it is just cx.mouse_get: the position lands
; in X16_P0..P3 and the buttons come back in A.
; =====================================================================

    ; Which cell is under a pixel position? Characters are 8x8, the grid
    ; starts below the three header lines and to the right of the row
    ; gutter, and col_at/row_at already account for any locked titles.
    ; -> false if the point is not over a cell, leaving the cursor alone.
    sub mouse_hit(uword mx, uword my) -> bool {
        ubyte sr = lsb(my >> 3)
        ubyte sc = lsb(mx >> 3)
        if sr < 3 or sc < GW
            return false                ; status, edit line, headers, gutter
        ubyte ri = sr - 3
        if ri >= tr + freerows()
            return false
        ubyte ci = (sc - GW) / kk.cw
        if ci >= tc + freecols()
            return false
        uword r = row_at(ri)
        if r >= kk.NROW
            return false
        ubyte c = col_at(ci)
        if c >= kk.NCOL
            return false
        cc = c
        cr = lsb(r)
        return true
    }

    ; -> true when a click just moved the cursor. Only the press edge
    ; counts, so holding the button does not re-select every poll.
    sub mouse_pick() -> bool {
        ubyte btn = cx.mse_get()
        if btn & 1 == 0 {
            mouse_down = false
            return false
        }
        if mouse_down
            return false
        mouse_down = true
        return mouse_hit(peekw(x16c.X16_P0), peekw(x16c.X16_P0 + 2))
    }

    ; Block until something happens: a key, or a click that picked a cell.
    ; -> the key, or 0 when the mouse moved the cursor instead.
    sub wait_event() -> ubyte {
        while true {
            ubyte k = cx.key_get()
            if k != 0
                return k
            if mouse_pick()
                return 0
        }
    }

    sub curidx() -> uword {
        return kk.cidx(cc, cr)
    }


; =====================================================================
; drawing
; =====================================================================
    sub draw_status() {
        lb_clear()
        ubyte k = 1
        k += kk.colname(cc, &linebuf + k)
        uword rowno = cr
        rowno++
        k += kk.putdec(rowno, &linebuf + k)
        k += 2
        uword idx = curidx()
        ubyte t = kk.ctype(idx)
        if t == kk.T_LABEL or t >= kk.T_FORM
            k = lb_text(k, kk.txt_data(idx), kk.txt_len(idx))
        if t == kk.T_NUM {
            cx.f_load(kk.valptr(idx))
            k = lb_text(k, &sbuf, kk.num_general(&sbuf))
        } else if t == kk.T_FORM {
            k = lb_z(k, &s_eq)
            cx.f_load(kk.valptr(idx))
            k = lb_text(k, &sbuf, kk.num_general(&sbuf))
        } else if t == kk.T_FERR {
            k = lb_z(k, &s_eqerr)
        } else if t == kk.T_FNA {
            k = lb_z(k, &s_eqna)
        }
        ubyte i = 0
        while i < 5 {
            linebuf[USEW - 5 + i] = @(modez + i)
            i++
        }
        lb_show(0, H_FG, H_BG)
    }

    sub draw_edit() {
        lb_clear()
        uword idx = curidx()
        if kk.ctype(idx) != kk.T_EMPTY
            void lb_text(2, kk.txt_data(idx), kk.txt_len(idx))
        lb_show(1, C_FG, C_BG)
    }

    ; the row-1 prompt used by every menu and text entry
    sub show_msg(uword z) {
        lb_clear()
        void lb_z(0, z)
        lb_show(1, C_FG, C_BG)
    }

    sub show_input(uword promptz, uword buf, ubyte n) {
        lb_clear()
        ubyte k = lb_z(0, promptz)
        k++
        k = lb_text(k, buf, n)
        if k < LBMAX
            linebuf[k] = '_'
        lb_show(1, C_FG, C_BG)
        draw_status()
    }

    sub draw_colhdr() {
        lb_clear()
        ubyte nc = tc + freecols()
        ubyte ci = 0
        while ci < nc {
            ubyte c = col_at(ci)
            if c >= kk.NCOL
                break
            ubyte n = kk.colname(c, &sbuf)
            ubyte base = GW + ci * kk.cw
            ubyte pad = (kk.cw - n) / 2      ; centred over the column
            ubyte i = 0
            while i < n {
                if base + pad + i < USEW
                    linebuf[base + pad + i] = sbuf[i]
                i++
            }
            ci++
        }
        lb_show(2, H_FG, H_BG)
    }

    sub cellattr(ubyte ri, ubyte ci, ubyte c, ubyte r) -> ubyte {
        if c == cc and r == cr
            return attr(K_FG, K_BG)
        if ci < tc or ri < tr
            return attr(L_FG, L_BG)
        return attr(C_FG, C_BG)
    }

    sub draw_cell(ubyte ri, ubyte ci, ubyte c, ubyte r) {
        kk.fmtcell(kk.cidx(c, r), &dbuf, kk.cw)
        cx.screen_addr(3 + ri, GW + ci * kk.cw)
        cx.screen_blit(&dbuf, kk.cw, cellattr(ri, ci, c, r))
    }

    ; repaint one cell in place (used when only the cursor moved)
    ; Repaint the rows the cursor left and arrived on. A move along a row
    ; only dirties one of them.
    sub touch_cursor(ubyte oc, ubyte orow) {
        touch_cell(oc, orow)
        if cr != orow
            touch_cell(cc, cr)
    }

    ; Repaint the row a cell sits on. A label can spill across several
    ; columns, so a single cell is no longer a safe unit to redraw.
    sub touch_cell(ubyte c, ubyte r) {
        if slot_of_col(c) == 255
            return
        ubyte ri = slot_of_row(r)
        if ri == 255
            return
        draw_row(ri)
    }

    ; the row-number gutter for one screen slot
    sub draw_gutter(ubyte ri, uword r) {
        ubyte ahdr = attr(H_FG, H_BG)
        cx.screen_addr(3 + ri, 0)
        ubyte n = kk.putdec(r + 1, &sbuf)         ; r is a word: no wrap
        ubyte pad = 0
        if n < GW - 1
            pad = GW - 1 - n
        if pad != 0
            cx.screen_blitfill(pad, ahdr, ' ')
        cx.screen_blit(&sbuf, n, ahdr)
        cx.screen_blitfill(GW - n - pad, ahdr, ' ')
    }

    ; one whole grid line: gutter, cells, then blank to the right margin
    sub draw_row(ubyte ri) {
        ubyte nc = tc + freecols()
        ubyte anorm = attr(C_FG, C_BG)
        uword r = row_at(ri)
        if r >= kk.NROW {
            cx.screen_addr(3 + ri, 0)
            cx.screen_blitfill(USEW, anorm, ' ')
            return
        }
        draw_gutter(ri, r)                        ; leaves the address at GW
        ubyte used = GW
        ubyte ci = 0
        while ci < nc {
            ubyte c = col_at(ci)
            if c >= kk.NCOL
                break
            uword idx = kk.cidx(c, lsb(r))

            ; A label wider than its column borrows the columns to its
            ; right, but only while they are empty -- the first occupied
            ; neighbour cuts it off. Numbers never spill.
            ubyte span = 1
            if kk.ctype(idx) == kk.T_LABEL {
                ubyte want = kk.label_len(idx)
                if want > kk.cw {
                    while span < nc - ci {
                        if span * kk.cw >= want
                            break
                        ubyte c2 = col_at(ci + span)
                        if c2 >= kk.NCOL
                            break
                        if kk.ctype(kk.cidx(c2, lsb(r))) != kk.T_EMPTY
                            break
                        span++
                    }
                }
            }

            ; one render across the whole span, then blit it a column at a
            ; time so each keeps its own colour (the cursor highlight has
            ; to stay one cell wide)
            ubyte wide = span * kk.cw
            kk.fmtcell(idx, &dbuf, wide)
            ubyte k = 0
            while k < span {
                cx.screen_blit(&dbuf + k * kk.cw, kk.cw,
                               cellattr(ri, ci + k, col_at(ci + k), lsb(r)))
                k++
            }
            used += wide
            ci += span
        }
        cx.screen_blitfill(USEW - used, anorm, ' ')
    }

    sub draw_grid() {
        ubyte nr = tr + freerows()
        ubyte ri = 0
        while ri < nr {
            draw_row(ri)
            ri++
        }
    }

    ; every row number changed, but the cells they label did not
    sub draw_gutters() {
        ubyte nr = tr + freerows()
        ubyte ri = 0
        while ri < nr {
            uword r = row_at(ri)
            if r < kk.NROW
                draw_gutter(ri, r)
            ri++
        }
    }

    ; Slide the grid one text row inside VRAM instead of re-rendering it.
    ; A scroll step then costs one row of formatting plus a block move,
    ; not a whole screen -- which matters because most of a repaint is the
    ; ROM float-to-string conversion, once per visible cell.
    ;
    ; contentup = the picture moves up, i.e. the cursor went down the sheet.
    ; The row uncovered at the trailing edge keeps its old contents and is
    ; redrawn by the caller.
    sub scroll_one(bool contentup) {
        ubyte dir = 1                         ; 0 = picture moves up
        if contentup
            dir = 0
        cx.screen_scroll(3 + tr, GW, freerows(), (tc + freecols()) * kk.cw, 1, dir)
    }

    sub draw_help() {
        lb_clear()
        void lb_z(0, &s_help)
        lb_show(VROWS + 3, H_FG, H_BG)
    }

    sub draw_all() {
        draw_status()
        draw_edit()
        draw_colhdr()
        draw_grid()
        draw_help()
    }


; =====================================================================
; text entry
; =====================================================================
    sub printable(ubyte ch) -> bool {
        if ch >= $20 and ch <= $5F
            return true
        if ch >= $C1 and ch <= $DA
            return true
        return false
    }

    ; kind 0 = free text, 1 = digits only, 2 = a cell reference / range
    ; -> new length, or 255 when cancelled.  edit_key holds the last key.
    sub edit_input(uword promptz, uword buf, ubyte startlen, ubyte maxn, ubyte kind) -> ubyte {
        ubyte n = startlen
        @(buf + n) = 0
        while true {
            show_input(promptz, buf, n)
            ubyte ch = cx.key_wait()
            edit_key = ch
            if ch == K_ESC or ch == K_STOP
                return 255
            if ch == K_RET or ch == K_TAB
                return n
            if ch == K_DEL {
                if n > 0
                    n--
                @(buf + n) = 0
            } else {
                bool take = false
                if kind == 1 {
                    take = kk.is_digit(ch)
                } else if kind == 2 {
                    if kk.alpha_idx(ch) != 255 {
                        ch = kk.upc(ch)
                        take = true
                    } else if kk.is_digit(ch) or ch == '.' or ch == '$' {
                        take = true
                    }
                } else {
                    take = printable(ch)
                }
                if take {
                    if n < maxn {
                        @(buf + n) = ch
                        n++
                        @(buf + n) = 0
                    }
                }
            }
        }
        return n
    }

    sub do_entry() {
        modez = &m_entry
        ubyte n = edit_input(&s_gt, &ibuf, ilen, kk.MAXIN, 0)
        modez = &m_ready
        if n == 255
            return
        kk.setcell(curidx(), &ibuf, n)
        kk.recalc()
        dirty = true
        needfull = true
        if edit_key == K_TAB {
            if cc < kk.NCOL - 1
                cc++
        } else {
            if cr < kk.MAXROW
                cr++
        }
    }

    sub do_goto() {
        modez = &m_goto
        ubyte n = edit_input(&s_gt, &ibuf, 0, 8, 2)
        modez = &m_ready
        if n == 255 or n == 0
            return
        if kk.refabs(&ibuf) != 0 {
            if kk.ref_c < kk.NCOL and kk.ref_r < kk.NROW {
                cc = lsb(kk.ref_c)
                cr = lsb(kk.ref_r)
            }
        }
        needfull = true
    }


; =====================================================================
; the / command menu
; =====================================================================
    sub askkey(uword z) -> ubyte {
        show_msg(z)
        draw_status()
        return kk.upc(cx.key_wait())
    }

    sub is_fmtchar(ubyte ch) -> bool {
        return ch == 'L' or ch == 'R' or ch == 'I' or ch == 'G' or
               ch == 'D' or ch == '$' or ch == '%' or ch == '*'
    }

    sub command() -> bool {
        modez = &m_cmd
        ubyte ch = askkey(&s_cmd)
        modez = &m_ready
        needfull = true
        if ch == 'B' {
            kk.cell_clear(curidx())
            kk.recalc()
            dirty = true
        } else if ch == 'C' {
            if kk.upc(askkey(&s_askcl)) == 'Y' {
                kk.clear_all()
                dirty = true
            }
        } else if ch == 'D' {
            ch = askkey(&s_askrc)
            if ch == 'R' {
                kk.deleterow(cr)
                kk.recalc()
                dirty = true
            } else if ch == 'C' {
                kk.deletecol(cc)
                kk.recalc()
                dirty = true
            }
        } else if ch == 'I' {
            ch = askkey(&s_askrc)
            if ch == 'R' {
                kk.insertrow(cr)
                kk.recalc()
                dirty = true
            } else if ch == 'C' {
                kk.insertcol(cc)
                kk.recalc()
                dirty = true
            }
        } else if ch == 'F' {
            ch = askkey(&s_askfm)
            if is_fmtchar(ch) {
                if ch == 'G'
                    ch = 0
                kk.set_cfmt(curidx(), ch)
                dirty = true
            }
        } else if ch == 'G' {
            ch = askkey(&s_askgl)
            if ch == 'C' {
                show_msg(&s_askw)
                ubyte n = edit_input(&s_gt, &ibuf, 0, 2, 1)
                if n != 255 and n != 0 {
                    ubyte w = 0
                    ubyte i = 0
                    while i < n {
                        w *= 10
                        w += ibuf[i] - '0'
                        i++
                    }
                    if w >= 4 and w <= 20 {
                        kk.cw = w
                        if tc >= vcols()
                            tc = 0
                    }
                }
            } else if ch == 'F' {
                ch = askkey(&s_askfm)
                if is_fmtchar(ch) {
                    if ch == 'G'
                        ch = 0
                    kk.gfmt = ch
                }
            }
        } else if ch == 'M' {
            movecmd()
        } else if ch == 'R' {
            replcmd()
        } else if ch == 'T' {
            ch = askkey(&s_asklk)
            if ch == 'V' {
                if cc + 1 < vcols() {
                    tc = cc + 1
                    tr = 0
                    cc++
                }
            } else if ch == 'H' {
                if cr < VROWS - 1 {
                    tr = cr + 1
                    tc = 0
                    cr++
                }
            } else if ch == 'B' {
                if cc + 1 < vcols() and cr < VROWS - 1 {
                    tc = cc + 1
                    tr = cr + 1
                    cc++
                    cr++
                }
            } else if ch == 'N' {
                tc = 0
                tr = 0
                vc = 0
                vr = 0
            }
        } else if ch == 'S' {
            return storage()
        } else if ch == 'Q' {
            if not dirty
                return true
            if kk.upc(askkey(&s_askq)) == 'Y'
                return true
        }
        return false
    }


; =====================================================================
; /M -- drag the current row or column with the arrow keys
; =====================================================================
    sub movecmd() {
        ubyte oc = cc
        ubyte orow = cr
        modez = &m_move
        while true {
            needfull = true
            reframe()
            draw_all()
            show_msg(&s_movep)
            ubyte ch = cx.key_wait()
            if ch == K_ESC or ch == K_STOP {
                while cc < oc {
                    kk.swapcol(cc, cc + 1)
                    cc++
                }
                while cc > oc {
                    kk.swapcol(cc, cc - 1)
                    cc--
                }
                while cr < orow {
                    kk.swaprow(cr, cr + 1)
                    cr++
                }
                while cr > orow {
                    kk.swaprow(cr, cr - 1)
                    cr--
                }
                break
            }
            if ch == K_RET {
                if cc != oc or cr != orow
                    dirty = true
                break
            }
            if ch == K_UP and cc == oc {
                if cr > tr and cr > 0 {
                    kk.swaprow(cr, cr - 1)
                    cr--
                }
            } else if ch == K_DOWN and cc == oc {
                if cr < kk.MAXROW {
                    kk.swaprow(cr, cr + 1)
                    cr++
                }
            } else if ch == K_LEFT and cr == orow {
                if cc > tc and cc > 0 {
                    kk.swapcol(cc, cc - 1)
                    cc--
                }
            } else if ch == K_RIGHT and cr == orow {
                if cc < kk.NCOL - 1 {
                    kk.swapcol(cc, cc + 1)
                    cc++
                }
            }
        }
        modez = &m_ready
        kk.recalc()
        needfull = true
    }


; =====================================================================
; /R -- replicate a range, adjusting relative references
; =====================================================================
    sub fmtrange(uword out, ubyte c1, ubyte r1, ubyte c2, ubyte r2) -> ubyte {
        uword n1 = r1
        n1++
        uword n2 = r2
        n2++
        ubyte k = kk.colname(c1, out)
        k += kk.putdec(n1, out + k)
        if c1 != c2 or r1 != r2 {
            @(out + k) = '.'
            @(out + k + 1) = '.'
            @(out + k + 2) = '.'
            k += 3
            k += kk.colname(c2, out + k)
            k += kk.putdec(n2, out + k)
        }
        return k
    }

    ; prompt line: "<label> <range>" (or the reference being typed)
    sub show_range(uword label, bool typed, ubyte c1, ubyte r1, ubyte c2, ubyte r2) {
        lb_clear()
        ubyte k = lb_z(0, label)
        k++
        if typed {
            k = lb_text(k, &ibuf, ilen)
            if k < LBMAX
                linebuf[k] = '_'
        } else {
            k = lb_text(k, &sbuf, fmtrange(&sbuf, c1, r1, c2, r2))
        }
        lb_show(1, C_FG, C_BG)
        draw_status()
    }

    ; anchor at (ac,ar); the cursor picks the other corner. -> false on Esc
    sub selectrange(uword label, ubyte ac, ubyte ar) -> bool {
        cc = ac
        cr = ar
        ilen = 0
        ibuf[0] = 0
        bool typed = false
        while true {
            reframe()
            draw_all()
            sel_c1 = ac
            sel_c2 = cc
            if cc < ac {
                sel_c1 = cc
                sel_c2 = ac
            }
            sel_r1 = ar
            sel_r2 = cr
            if cr < ar {
                sel_r1 = cr
                sel_r2 = ar
            }
            show_range(label, typed, sel_c1, sel_r1, sel_c2, sel_r2)
            ubyte ch = cx.key_wait()
            if ch == K_ESC or ch == K_STOP
                return false
            if ch == K_RET {
                if typed
                    return parse_range()
                return true
            }
            if ch == K_UP or ch == K_DOWN or ch == K_LEFT or ch == K_RIGHT {
                typed = false
                ilen = 0
                ibuf[0] = 0
                movecursor(ch)
            } else if ch == K_DEL {
                typed = true
                if ilen > 0
                    ilen--
                ibuf[ilen] = 0
            } else if printable(ch) {
                typed = true
                if ilen < 16 {
                    ibuf[ilen] = kk.upc(ch)
                    ilen++
                    ibuf[ilen] = 0
                }
            }
        }
        return false
    }

    ; "A1" or "A1...B5" from ibuf into sel_*
    sub parse_range() -> bool {
        ubyte k = kk.refabs(&ibuf)
        if k == 0
            return false
        if kk.ref_c >= kk.NCOL or kk.ref_r >= kk.NROW
            return false
        sel_c1 = lsb(kk.ref_c)
        sel_r1 = lsb(kk.ref_r)
        sel_c2 = sel_c1
        sel_r2 = sel_r1
        if ibuf[k] == '.' {
            while ibuf[k] == '.'
                k++
            if kk.refabs(&ibuf + k) == 0
                return false
            if kk.ref_c >= kk.NCOL or kk.ref_r >= kk.NROW
                return false
            sel_c2 = lsb(kk.ref_c)
            sel_r2 = lsb(kk.ref_r)
        }
        if sel_c1 > sel_c2 {
            k = sel_c1
            sel_c1 = sel_c2
            sel_c2 = k
        }
        if sel_r1 > sel_r2 {
            k = sel_r1
            sel_r1 = sel_r2
            sel_r2 = k
        }
        return true
    }

    sub movecursor(ubyte ch) {
        if ch == K_UP {
            if cr > 0
                cr--
        } else if ch == K_DOWN {
            if cr < kk.MAXROW
                cr++
        } else if ch == K_LEFT {
            if cc > 0
                cc--
        } else if ch == K_RIGHT {
            if cc < kk.NCOL - 1
                cc++
        }
    }

    sub replcmd() {
        ubyte oc = cc
        ubyte orow = cr
        modez = &m_repl
        if not selectrange(&s_src, oc, orow) {
            modez = &m_ready
            cc = oc
            cr = orow
            needfull = true
            return
        }
        ubyte sc1 = sel_c1
        ubyte sr1 = sel_r1
        ubyte sw = sel_c2 - sel_c1 + 1
        ubyte sh = sel_r2 - sel_r1 + 1
        ubyte srclen = fmtrange(&rngbuf, sc1, sr1, sel_c2, sel_r2)

        cc = sc1
        cr = sr1
        ilen = 0
        ibuf[0] = 0
        bool typed = false
        while true {
            reframe()
            draw_all()
            lb_clear()
            ubyte k = lb_text(0, &rngbuf, srclen)
            k = lb_z(k, &s_to)
            k++
            if typed {
                k = lb_text(k, &ibuf, ilen)
                if k < LBMAX
                    linebuf[k] = '_'
            } else {
                uword w2 = cc
                w2 += sw - 1
                uword h2 = cr
                h2 += sh - 1
                if w2 >= kk.NCOL
                    w2 = kk.NCOL - 1
                if h2 >= kk.NROW
                    h2 = kk.MAXROW
                ubyte c2 = lsb(w2)
                ubyte r2 = lsb(h2)
                k = lb_text(k, &sbuf, fmtrange(&sbuf, cc, cr, c2, r2))
            }
            lb_show(1, C_FG, C_BG)
            draw_status()
            ubyte ch = cx.key_wait()
            if ch == K_ESC or ch == K_STOP
                break
            if ch == K_RET {
                ubyte tc1 = cc
                ubyte tr1 = cr
                if typed {
                    if not parse_range()
                        break
                    tc1 = sel_c1
                    tr1 = sel_r1
                }
                show_msg(&s_busy)
                ubyte r = 0
                while r < sh {
                    uword dr = tr1
                    dr += r
                    if dr < kk.NROW {
                        ubyte c = 0
                        while c < sw {
                            uword dc = tc1
                            dc += c
                            if dc < kk.NCOL
                                kk.replicatecell(sc1 + c, sr1 + r, lsb(dc), lsb(dr))
                            c++
                        }
                    }
                    r++
                }
                kk.recalc()
                dirty = true
                break
            }
            if ch == K_UP or ch == K_DOWN or ch == K_LEFT or ch == K_RIGHT {
                typed = false
                ilen = 0
                ibuf[0] = 0
                movecursor(ch)
            } else if ch == K_DEL {
                typed = true
                if ilen > 0
                    ilen--
                ibuf[ilen] = 0
            } else if printable(ch) {
                typed = true
                if ilen < 16 {
                    ibuf[ilen] = kk.upc(ch)
                    ilen++
                    ibuf[ilen] = 0
                }
            }
        }
        modez = &m_ready
        needfull = true
    }


; =====================================================================
; CSV storage, straight through the KERNAL
; =====================================================================
    bool csv_eof
    bool csv_haspend
    ubyte csv_pending

    sub csv_getc() -> ubyte {
        if csv_haspend {
            csv_haspend = false
            return csv_pending
        }
        if csv_eof
            return 0
        ubyte c = cx.fio_chrin()
        if cx.fio_readst() != 0
            csv_eof = true
        return c
    }

    ; PETSCII <-> ASCII so the files are readable off the machine
    sub pet2asc(ubyte c) -> ubyte {
        if c >= $41 and c <= $5A
            return c + $20                  ; unshifted letters -> lower case
        if c >= $C1 and c <= $DA
            return c - $80                  ; shifted letters   -> upper case
        return c
    }

    sub asc2pet(ubyte c) -> ubyte {
        if c >= $61 and c <= $7A
            return c - $20
        if c >= $41 and c <= $5A
            return c + $80
        return c
    }

    ; Browse for a sheet instead of typing its name. -> true when one
    ; was chosen, with fname/fnlen set for csv_load.
    ;
    ; The panel covers most of the grid, so it keeps what is underneath
    ; in a spare bank and puts it back on the way out: kalk cannot
    ; repaint the way a launcher does, because a repaint here means
    ; recalculating every visible cell. Banks 1-10 hold the sheet, so
    ; the browser gets 60 for its listing and 61 for the save-under.
    sub browse_load() -> bool {
        ; Both live in VRAM, which is where a browser that might be
        ; running from a RAM bank has to keep things: the listing at
        ; $12000 and the copy of the screen under the panel at $14000,
        ; clear of the text map at $1B000. kalk's own banks 1-10 are
        ; untouched by either.
        cx.fp_cache($2000, 1)
        cx.fp_saveunder(1, $4000, 1)
        cx.fp_filter(&s_sheets)
        cx.fp_heading(&s_sheetsin)
        ubyte act = cx.fp_open()
        cx.fp_close()
        needfull = true               ; the status line is ours again
        if act != FPK_PICK
            return false
        ; COPY the name out rather than following a pointer to it. The
        ; browser lives in bank 20 here, and a pointer it returns names
        ; its own storage -- which is not mapped any more by the time
        ; the far-call wrapper has switched the bank back. Reading
        ; through one gave an empty string, so the drive was asked to
        ; open a file with no name at all.
        ;
        ; The bare name is enough: fp_close leaves the drive standing in
        ; the directory the panel was showing.
        fnlen = cx.fp_copy_name(&fname, len(fname))
        return fnlen != 0
    }

    ; Choose where to save. The browser is a navigator here rather than
    ; a chooser: walk into the folder you want and press ESC, and the
    ; drive is left standing there, which is where a bare filename will
    ; be written. Landing on an existing sheet fills its name in as the
    ; default, so replacing one is a matter of picking it and pressing
    ; enter twice.
    sub browse_save() -> bool {
        cx.fp_cache($2000, 1)
        cx.fp_saveunder(1, $4000, 1)
        cx.fp_filter(&s_sheets)
        cx.fp_heading(&s_saveinto)
        cx.fp_footing(&s_savefoot)
        ubyte act = cx.fp_open()
        if act == FPK_PICK
            fnlen = cx.fp_copy_name(&fname, len(fname))   ; replace that one
        cx.fp_close()
        needfull = true
        ; ESC now means what it says. 'h' takes the folder on show, and
        ; the drive is left standing there either way, so the filename
        ; asked for next is written where you chose.
        return act == FPK_PICK or act == FPK_HERE
    }

    ; ask for a filename; -> false when cancelled
    sub askname(uword label) -> bool {
        show_msg(label)
        ubyte n = edit_input(label, &fname, fnlen, 16, 0)
        if n == 255 or n == 0
            return false
        fnlen = n
        ; the KERNAL reads PETSCII $41-$5A as the upper-case host name,
        ; so fold shifted letters down into that range
        ubyte i = 0
        while i < fnlen {
            if fname[i] >= $C1 and fname[i] <= $DA
                fname[i] -= $80
            i++
        }
        return true
    }

    ; The file is already closed by whoever failed. "I/O error" on its
    ; own says nothing you can act on, so ask the drive what it thinks:
    ; 62 is FILE NOT FOUND, 74 DRIVE NOT READY, and so on.
    sub io_fail() {
        ; The drive's own code, because "I/O error" on its own sends you
        ; guessing: 62 is FILE NOT FOUND, 74 DRIVE NOT READY. It cost
        ; several rounds of guessing to learn that, so it stays.
        cx.dos_status()
        ubyte code = cx.dos_lasterr()
        cx.screen_addr(0, 0)
        cx.screen_blitfill(USEW, attr(C_FG, C_BG), ' ')
        cx.screen_addr(0, 0)
        cx.screen_blit(&s_ioerr, len(s_ioerr), attr(C_FG, C_BG))
        cx.screen_blit(" drive ", 7, attr(C_FG, C_BG))
        putnum(code)
        void cx.key_wait()
        needfull = true
    }

    ; Format here rather than calling u8_to_dec: that returns a pointer
    ; into the number module, which is in a bank in this build -- the
    ; same trap that emptied the filename.
    ubyte[4] numbuf

    sub putnum(ubyte v) {
        ubyte n = 0
        if v >= 100 {
            numbuf[n] = '0' + v / 100
            n++
            v %= 100
        }
        if n != 0 or v >= 10 {
            numbuf[n] = '0' + v / 10
            n++
        }
        numbuf[n] = '0' + v % 10
        n++
        cx.screen_blit(&numbuf, n, attr(C_FG, C_BG))
    }

    sub csv_needs_quote(uword s, ubyte n) -> bool {
        ubyte i = 0
        while i < n {
            ubyte c = @(s + i)
            if c == ',' or c == '"' or c == $0d or c == $0a
                return true
            i++
        }
        return false
    }

    sub csv_save() -> bool {
        ; last used row / column
        uword idx = 0
        uword maxr = 0
        ubyte maxc = 0
        bool any = false
        uword r = 0
        ubyte c = 0
        while r < kk.NROW {
            c = 0
            while c < kk.NCOL {
                if kk.ctype(kk.cidx(c, lsb(r))) != kk.T_EMPTY {
                    any = true
                    maxr = r
                    if c > maxc
                        maxc = c
                }
                c++
            }
            r++
        }
        show_msg(&s_busy)

        ; name + ",s,w" so the X16 DOS opens a new sequential file
        ubyte i = 0
        while i < 4 {
            fname[fnlen + i] = s_swr[i]
            i++
        }
        if cx.fio_open_write(&fname, fnlen + 4, 1, 8, 2) {
            cx.fio_clrchn()
            cx.fio_close(1)
            return false
        }
        if any {
            r = 0
            while r <= maxr {
                c = 0
                while c <= maxc {
                    if c != 0
                        cx.fio_chrout(',')
                    idx = kk.cidx(c, lsb(r))
                    if kk.ctype(idx) != kk.T_EMPTY {
                        uword s = kk.txt_data(idx)
                        ubyte n = kk.txt_len(idx)
                        if csv_needs_quote(s, n) {
                            cx.fio_chrout('"')
                            i = 0
                            while i < n {
                                if @(s + i) == '"'
                                    cx.fio_chrout('"')
                                cx.fio_chrout(pet2asc(@(s + i)))
                                i++
                            }
                            cx.fio_chrout('"')
                        } else {
                            i = 0
                            while i < n {
                                cx.fio_chrout(pet2asc(@(s + i)))
                                i++
                            }
                        }
                    }
                    c++
                }
                cx.fio_chrout($0a)
                r++
            }
        }
        ubyte st = cx.fio_readst()
        cx.fio_clrchn()
        cx.fio_close(1)
        return st == 0 or st == 64
    }

    ; one CSV field into ibuf; sets ilen, returns 1 = eol, 2 = eof, 0 = comma
    sub csv_field() -> ubyte {
        ilen = 0
        ibuf[0] = 0
        ubyte c = csv_getc()
        if csv_eof and c == 0
            return 2
        if c == '"' {
            while true {
                c = csv_getc()
                if csv_eof and c == 0
                    return 2
                if c == '"' {
                    c = csv_getc()
                    if c != '"' {
                        if c == $0d
                            c = csv_getc()
                        if c == $0a or csv_eof
                            return 1
                        return 0
                    }
                }
                if ilen < kk.MAXIN {
                    ibuf[ilen] = asc2pet(c)
                    ilen++
                    ibuf[ilen] = 0
                }
            }
        }
        while true {
            if c == ',' {
                return 0
            }
            if c == $0a {
                return 1
            }
            if csv_eof and c == 0
                return 2
            if c != $0d {
                if ilen < kk.MAXIN {
                    ibuf[ilen] = asc2pet(c)
                    ilen++
                    ibuf[ilen] = 0
                }
            }
            if csv_eof
                return 1
            c = csv_getc()
        }
        return 2
    }

    sub csv_load() -> bool {
        csv_eof = false
        csv_haspend = false
        if cx.fio_open_read(&fname, fnlen, 1, 8, 2) {
            cx.fio_clrchn()
            cx.fio_close(1)
            return false
        }
        ; OPEN never reports a missing file on a CBM device -- the first
        ; read does, with bit 1 of ST.  Check before touching the sheet.
        csv_pending = cx.fio_chrin()
        ubyte st = cx.fio_readst()
        if st & $02 != 0 {
            cx.fio_clrchn()
            cx.fio_close(1)
            return false
        }
        csv_haspend = true
        if st != 0
            csv_eof = true
        show_msg(&s_busy)
        kk.clear_all()
        uword row = 0
        ubyte col = 0
        while true {
            ubyte k = csv_field()
            if k == 2
                break
            if ilen != 0 and row < kk.NROW and col < kk.NCOL
                kk.setcell(kk.cidx(col, lsb(row)), &ibuf, ilen)
            if k == 1 {
                row++
                col = 0
                if row >= kk.NROW
                    break
            } else {
                col++
            }
        }
        cx.fio_clrchn()
        cx.fio_close(1)
        kk.recalc()
        return true
    }

    sub storage() -> bool {
        modez = &m_disk
        ubyte ch = askkey(&s_askst)
        modez = &m_ready
        needfull = true
        if ch == 'L' {
            if browse_load() {
                if not csv_load() {
                    io_fail()
                } else {
                    dirty = false
                    cc = 0
                    cr = 0
                    vc = 0
                    vr = 0
                }
            } else if askname(&s_load) {
                if not csv_load() {
                    io_fail()
                } else {
                    dirty = false
                    cc = 0
                    cr = 0
                    vc = 0
                    vr = 0
                }
            }
        } else if ch == 'S' or ch == 'Q' {
            ; choose WHERE first; ESC there cancels the save outright
            if browse_save() and askname(&s_save) {
                if not csv_save() {
                    io_fail()
                } else {
                    dirty = false
                    if ch == 'Q'
                        return true
                }
            }
        }
        return false
    }


; =====================================================================
; main loop
; =====================================================================
    sub reframe() {
        ubyte fc = freecols()
        ubyte fr = freerows()
        if tc != 0 {
            if cc < tc
                cc = tc
            if vc < tc
                vc = tc
        }
        if tr != 0 {
            if cr < tr
                cr = tr
            if vr < tr
                vr = tr
        }
        if cc >= tc {
            if cc < vc
                vc = cc
            if cc >= vc + fc
                vc = cc - fc + 1
        }
        if cr >= tr {
            if cr < vr
                vr = cr
            uword lim = vr
            lim += fr
            if cr >= lim
                vr = cr - fr + 1
        }
    }

    sub start() {
        cx.load_banks()
        ; Setting the mode blanks and clears the screen on its way through,
        ; and a launcher has usually left mode 0 behind already: ask first,
        ; and starting from the desktop costs one flash less.
        if cx.screen_get_mode() != 0
            void cx.screen_set_mode(0)      ; 80x60 text
        cx.screen_charset(3)                ; PET upper/lower: both cases visible
        ; Build the first screen in the dark. Clearing, colouring and then
        ; painting 60 rows is several whole-screen changes if it happens in
        ; front of you, and coming from a launcher that is most of the
        ; flicker between one program and the next. The layer comes back on
        ; below, once there is a finished sheet to show.
        @(x16c.VERA_CTRL) = 0
        @(x16c.VERA_DC_VIDEO) &= ~x16c.VERA_VIDEO_LAYER1_EN
        ; MOUSE_CONFIG with a size of 0 keeps whatever bounds are already
        ; set, and on a fresh boot there are none -- so give it the real
        ; screen, 80x60 cells of 8 pixels, or the pointer never appears.
        cx.mse_config(1, 80, 60)            ; KERNAL pointer sprite
        kk.init()
        modez = &m_ready
        fnlen = 0
        dirty = false
        setcol(C_FG, C_BG)
        cx.screen_cls()
        needfull = true

        ; A launcher can name the sheet to open: the desktop's "open
        ; with" leaves the path in golden RAM. Loading it here rather
        ; than making the user retype a name they just picked is the
        ; whole point of the convention -- and with nothing passed this
        ; starts on an empty sheet exactly as it always did.
        uword argp = launcharg.get()
        if argp != 0 {
            ubyte argn = launcharg.length()
            if argn > len(fname)
                argn = len(fname)
            ubyte ai = 0
            while ai < argn {
                fname[ai] = @(argp + ai)
                ai++
            }
            fnlen = argn
            if not csv_load() {
                fnlen = 0             ; unreadable: say so, start empty
                io_fail()
            } else {
                dirty = false
            }
        }

        ubyte oc = 0
        ubyte orow = 0
        while true {
            ubyte pvc = vc
            ubyte pvr = vr
            reframe()
            bool scrolled = false
            if vc != pvc {
                needfull = true
            } else if vr != pvr {
                ; a one-row step is the common case: slide the picture
                if vr == pvr + 1 {
                    scroll_one(true)
                    scrolled = true
                } else if vr + 1 == pvr {
                    scroll_one(false)
                    scrolled = true
                } else {
                    needfull = true
                }
            }
            if needfull {
                draw_all()
                needfull = false
                if blanked {            ; the first sheet is complete: show it
                    blanked = false
                    @(x16c.VERA_CTRL) = 0
                    @(x16c.VERA_DC_VIDEO) |= x16c.VERA_VIDEO_LAYER1_EN
                }
            } else if scrolled {
                draw_gutters()
                if vr > pvr
                    draw_row(tr + freerows() - 1)   ; exposed at the bottom
                else
                    draw_row(tr)                    ; exposed at the top
                touch_cursor(oc, orow)
                draw_status()
                draw_edit()
            } else {
                touch_cursor(oc, orow)
                draw_status()
                draw_edit()
            }
            oc = cc
            orow = cr

            ubyte ch = wait_event()
            if ch == 0
                continue                ; the mouse picked a cell; redraw
            if ch == K_STOP
                break
            if ch == K_UP {
                if cr > tr and cr > 0
                    cr--
            } else if ch == K_DOWN {
                if cr < kk.MAXROW
                    cr++
            } else if ch == K_LEFT {
                if cc > tc and cc > 0
                    cc--
            } else if ch == K_RIGHT {
                if cc < kk.NCOL - 1
                    cc++
            } else if ch == K_HOME or ch == K_CLR {
                cc = tc
                cr = tr
            } else if ch == K_TAB {
                if cc < kk.NCOL - 1
                    cc++
            } else if ch == K_RET {
                if cr < kk.MAXROW
                    cr++
            } else if ch == K_DEL {
                kk.cell_clear(curidx())
                kk.recalc()
                dirty = true
                needfull = true
            } else if ch == '!' {
                kk.recalc()
                needfull = true
            } else if ch == '/' {
                if command()
                    break
            } else if ch == '>' {
                do_goto()
            } else if ch == '"' {
                ibuf[0] = '"'
                ilen = 1
                do_entry()
            } else if ch == '+' or ch == '-' or ch == '(' or ch == '@' or
                      ch == '.' or kk.is_digit(ch) {
                ibuf[0] = ch
                ilen = 1
                do_entry()
            } else if printable(ch) {
                ibuf[0] = ch
                ilen = 1
                do_entry()
            }
        }

        cx.mse_hide()
        cx.screen_reset()                   ; CINT: default mode, charset, colours
    }
}
