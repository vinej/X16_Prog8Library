; =====================================================================
; kalkcore.p8 -- the model and formula engine of `kalk`, a VisiCalc-style
; spreadsheet for the Commander X16.  Port of zserge's kalk.c
; (https://github.com/zserge/kalk).
;
; Everything the program needs at run time comes from the X16_Library
; (block `cx`): floating point (the ROM FP library, via util/float),
; screen output, the keyboard and file I/O.  No Prog8 stdlib modules.
;
; The grid is 26 columns (A..Z) x 256 rows.  Per cell we keep a type, a
; format byte, a pointer to its raw input text and a 5-byte MFLPT value
; -- nine bytes, so the whole grid is 58.5 KB and cannot live in low RAM.
; It is held in eight 8K RAM banks instead, 32 rows to a bank:
;
;   bank   = BANK0 + (row >> 5)
;   offset = $A000 + (row & 31) * ROWSZ + col * CELLSZ
;
; A cell is addressed by a packed index, idx = (row << 5) | col, so that
; both of those come out of shifts and masks rather than a division.
; `cellp` selects the bank and returns the window address; every accessor
; goes through it.  Only the cell text arena stays in low RAM, so string
; handling and the formula parser are untouched by the banking.
;
; Cell text is stored, and parsed, in PETSCII exactly as it was typed.
; =====================================================================
%import x16lib

kk {
    %option ignore_unused

    const ubyte NCOL     = 26
    const uword NROW     = 256
    const ubyte MAXROW   = 255       ; NROW-1, as a byte
    const ubyte MAXIN    = 60        ; max cell input length
    const uword ARENASZ  = 11264     ; cell text pool (low RAM)
    const uword MAXF     = 400       ; max formula cells tracked per recalc
    const ubyte FDEPTH   = 10        ; float operand stack slots
    const ubyte MAXDEPTH = 12        ; parser recursion limit

    ; ---- banked grid geometry ----------------------------------------
    const ubyte CELLSZ      = 9      ; type, fmt, text lo/hi, value[5]
    const uword ROWSZ       = 234    ; NCOL * CELLSZ
    const ubyte ROWSPERBANK = 32     ; 32 * 234 = 7488, fits an 8K bank
    const ubyte NBANKS      = 8      ; 8 * 32 = 256 rows
    const ubyte BANK0       = 1      ; first RAM bank used (0 is the KERNAL's)
    const uword WINDOW      = $A000

    const ubyte T_EMPTY  = 0
    const ubyte T_NUM    = 1
    const ubyte T_LABEL  = 2
    const ubyte T_FORM   = 3
    const ubyte T_FERR   = 4         ; formula whose last evaluation failed

    const ubyte F_SUM    = 1
    const ubyte F_ABS    = 2
    const ubyte F_INT    = 3
    const ubyte F_SQRT   = 4

    ; ---- storage -----------------------------------------------------
    uword arena_p = memory("kk_arena", 11264, 0)
    uword flist_p = memory("kk_flist",   800, 0)

    uword arena_top
    uword fcount

    ; offset tables, so a cell address costs two lookups instead of two
    ; multiplications -- this is the hottest path in the program
    uword[32] rowoff                 ; (row & 31) * ROWSZ
    ubyte[32] coloff                 ; col * CELLSZ

    ubyte[9]   cellbuf               ; one cell, moved between banks
    ubyte[234] rowbuf                ; one row, likewise
    ubyte[234] rowbuf2

    ; ---- sheet-wide settings (read by the formatter) -----------------
    ubyte gfmt                       ; global default format, 0 = general
    ubyte cw     = 8                 ; column display width

    ; ---- float scratch ----------------------------------------------
    ubyte[5]  res5
    ubyte[5]  acc5
    ubyte[5]  tmp5
    ubyte[5]  k100
    ubyte[5]  k05
    str       s_hundred = "100"
    str       s_half    = "0.5"
    str       s_error   = "ERROR"

    ; ---- parser state ------------------------------------------------
    uword pp                         ; parse cursor into ebuf
    ubyte perr                       ; non-zero once evaluation has failed
    ubyte pdepth
    ubyte fsp
    ubyte bsp
    ubyte[60] fstk                   ; FDEPTH * 6: 5 float bytes + 1 spare
    ubyte[16] bstk
    ubyte[64] ebuf                   ; the formula being evaluated
    ubyte[8]  fnbuf

    ; ---- reference parsing results -----------------------------------
    uword ref_c
    uword ref_r
    ubyte ref_ac
    ubyte ref_ar

    ; ---- formatting scratch ------------------------------------------
    ubyte[26] tb1
    ubyte[26] tb2

    ; ---- text rewriting ----------------------------------------------
    ubyte rwmode                     ; 0 swap, 1 shift, 2 offset
    ubyte rwaxis                     ; 'R' or 'C'
    uword rwa
    uword rwb
    bool  rwchanged
    ubyte[64] wbuf
    ubyte wlen


; =====================================================================
; character helpers -- input is PETSCII, so letters live in two ranges
; =====================================================================
    sub alpha_idx(ubyte ch) -> ubyte {
        if ch >= $41 and ch <= $5A
            return ch - $41          ; unshifted a..z
        if ch >= $C1 and ch <= $DA
            return ch - $C1          ; shifted A..Z
        return 255
    }

    sub is_digit(ubyte ch) -> bool {
        return ch >= '0' and ch <= '9'
    }

    ; fold an unshifted letter to its shifted (upper-case) PETSCII code,
    ; so it can be compared against 'A'..'Z' literals
    sub upc(ubyte ch) -> ubyte {
        if ch >= $41 and ch <= $5A
            return ch + $80
        return ch
    }

    sub is_space(ubyte ch) -> bool {
        return ch == ' ' or ch == 9
    }


; =====================================================================
; float helpers
; =====================================================================
    ; truncate toward zero, the way C's (long) cast does
    sub ftrunc() {
        if cx.f_sgn() == $FF {
            cx.f_abs()
            cx.f_int()
            cx.f_neg()
        } else {
            cx.f_int()
        }
    }

    sub fac_is_zero() -> bool {
        cx.f_store(&tmp5)
        return tmp5[0] == 0          ; MFLPT: exponent 0 means the value 0
    }


; =====================================================================
; cell storage -- the grid lives in eight 8K RAM banks
; =====================================================================
    ; a cell index packs the row above the column: (row << 5) | col
    sub cidx(ubyte c, ubyte r) -> uword {
        uword i = r
        i <<= 5
        return i | c
    }

    sub idx_row(uword idx) -> ubyte {
        return lsb(idx >> 5)
    }

    sub idx_col(uword idx) -> ubyte {
        return lsb(idx) & 31
    }

    sub idx_valid(uword idx) -> bool {
        return (lsb(idx) & 31) < NCOL
    }

    ; select the cell's bank and return its address in the $A000 window.
    ; The result stays valid only until the next cellp/rowp call.
    sub cellp(uword idx) -> uword {
        cx.bank_set(BANK0 + lsb(idx >> 10))
        uword a = WINDOW
        a += rowoff[lsb(idx >> 5) & 31]
        return a + coloff[lsb(idx) & 31]
    }

    ; same, for a whole row: bank selected once, base of column A returned
    sub rowp(ubyte r) -> uword {
        cx.bank_set(BANK0 + (r >> 5))
        return WINDOW + rowoff[r & 31]
    }

    sub ctype(uword idx) -> ubyte {
        return @(cellp(idx))
    }

    sub set_ctype(uword idx, ubyte t) {
        @(cellp(idx)) = t
    }

    sub cfmt(uword idx) -> ubyte {
        return @(cellp(idx) + 1)
    }

    sub set_cfmt(uword idx, ubyte f) {
        @(cellp(idx) + 1) = f
    }

    sub txt_rec(uword idx) -> uword {
        return peekw(cellp(idx) + 2)
    }

    sub set_txt_rec(uword idx, uword rec) {
        pokew(cellp(idx) + 2, rec)
    }

    ; use the result before anything else selects a bank
    sub valptr(uword idx) -> uword {
        return cellp(idx) + 4
    }

    sub txt_len(uword idx) -> ubyte {
        uword rec = txt_rec(idx)
        if rec == 0
            return 0
        return @(rec + 2)
    }

    sub txt_data(uword idx) -> uword {
        uword rec = txt_rec(idx)
        if rec == 0
            return arena_p           ; harmless, length is 0
        return rec + 3
    }

    sub txt_drop(uword idx) {
        set_txt_rec(idx, 0)
    }

    ; arena record = [owner lo, owner hi, len, len bytes]   (low RAM)
    sub txt_set(uword idx, uword src, ubyte n) -> bool {
        txt_drop(idx)
        if n == 0
            return true
        uword need = n
        need += 3
        if arena_top + need > arena_p + ARENASZ
            arena_compact()
        if arena_top + need > arena_p + ARENASZ
            return false
        uword rec = arena_top
        pokew(rec, idx)
        @(rec + 2) = n
        ubyte i = 0
        while i < n {
            @(rec + 3 + i) = @(src + i)
            i++
        }
        arena_top += need
        set_txt_rec(idx, rec)
        return true
    }

    ; slide every record still owned by a cell down over the dead ones
    sub arena_compact() {
        uword src = arena_p
        uword dst = arena_p
        while src < arena_top {
            uword owner = peekw(src)
            uword sz = @(src + 2)
            sz += 3
            bool live = false
            if idx_valid(owner) {
                if txt_rec(owner) == src
                    live = true
            }
            if live {
                if dst != src {
                    uword i = 0
                    while i < sz {
                        @(dst + i) = @(src + i)
                        i++
                    }
                    set_txt_rec(owner, dst)
                }
                dst += sz
            }
            src += sz
        }
        arena_top = dst
    }

    sub cell_clear(uword idx) {
        uword p = cellp(idx)
        ubyte i = 0
        while i < CELLSZ {
            @(p + i) = 0
            i++
        }
    }

    ; move a cell, including ownership of its text record.  Source and
    ; destination may be in different banks, so the nine bytes travel
    ; through cellbuf rather than window-to-window.
    sub cell_move(uword dst, uword src) {
        if dst == src
            return
        uword p = cellp(src)
        ubyte i = 0
        while i < CELLSZ {
            cellbuf[i] = @(p + i)
            @(p + i) = 0
            i++
        }
        p = cellp(dst)
        i = 0
        while i < CELLSZ {
            @(p + i) = cellbuf[i]
            i++
        }
        uword rec = peekw(&cellbuf + 2)
        if rec != 0
            pokew(rec, dst)          ; the arena is in low RAM
    }

    sub cell_swap(uword a, uword b) {
        if a == b
            return
        uword p = cellp(a)
        ubyte i = 0
        while i < CELLSZ {
            cellbuf[i] = @(p + i)
            i++
        }
        p = cellp(b)
        i = 0
        while i < CELLSZ {
            rowbuf[i] = @(p + i)
            @(p + i) = cellbuf[i]
            i++
        }
        p = cellp(a)
        i = 0
        while i < CELLSZ {
            @(p + i) = rowbuf[i]
            i++
        }
        uword rec = peekw(&cellbuf + 2)
        if rec != 0
            pokew(rec, b)
        rec = peekw(&rowbuf + 2)
        if rec != 0
            pokew(rec, a)
    }

; ---- whole-row moves, used by insert / delete / move row -------------
    sub row_read(ubyte r, uword buf) {
        cx.mem_copy(rowp(r), buf, ROWSZ)
    }

    ; after a row lands somewhere new its text records must be told
    sub fix_row_owners(ubyte r) {
        uword p = rowp(r)
        ubyte c = 0
        while c < NCOL {
            uword rec = peekw(p + coloff[c] + 2)
            if rec != 0
                pokew(rec, cidx(c, r))
            c++
        }
    }

    sub row_write(ubyte r, uword buf) {
        cx.mem_copy(buf, rowp(r), ROWSZ)
        fix_row_owners(r)
    }

    sub row_clear(ubyte r) {
        cx.mem_fill(rowp(r), ROWSZ, 0)
    }

    ; copy a row without blanking the source -- insert/delete overwrite it
    ; on the next step anyway, and the vacated row is cleared at the end
    sub row_copy(ubyte dst, ubyte src) {
        if dst == src
            return
        row_read(src, &rowbuf)
        row_write(dst, &rowbuf)
    }

    sub row_swap(ubyte a, ubyte b) {
        if a == b
            return
        row_read(a, &rowbuf)
        row_read(b, &rowbuf2)
        row_write(a, &rowbuf2)
        row_write(b, &rowbuf)
    }

    sub clear_all() {
        ubyte b = 0
        while b < NBANKS {
            cx.bank_set(BANK0 + b)
            cx.mem_fill(WINDOW, ROWSPERBANK * ROWSZ, 0)
            b++
        }
        arena_top = arena_p
        fcount = 0
    }

    sub init() {
        ubyte i = 0
        uword off = 0
        while i < ROWSPERBANK {
            rowoff[i] = off
            off += ROWSZ
            i++
        }
        i = 0
        ubyte co = 0
        while i < 32 {
            coloff[i] = co
            if i < NCOL - 1
                co += CELLSZ
            i++
        }
        clear_all()
        gfmt = 0
        cw = 8
        cx.f_from_str(&s_hundred, 3)
        cx.f_store(&k100)
        cx.f_from_str(&s_half, 3)
        cx.f_store(&k05)
    }


; =====================================================================
; entering a value  (kalk.c: setcell)
; =====================================================================
    sub setcell(uword idx, uword buf, ubyte n) {
        if not idx_valid(idx)
            return
        if n == 0 {
            cell_clear(idx)
            return
        }
        void txt_set(idx, buf, n)
        ubyte ch = @(buf)
        if ch == '+' or ch == '-' or ch == '(' or ch == '@' {
            set_ctype(idx, T_FORM)
            return
        }
        if is_digit(ch) or ch == '.' {
            ; a bare number if the whole input is one numeric token
            pp = buf
            ubyte used = scan_number_token()
            if used == n {
                cx.f_from_str(buf, n)
                cx.f_store(valptr(idx))
                set_ctype(idx, T_NUM)
            } else {
                set_ctype(idx, T_FORM)
            }
            return
        }
        set_ctype(idx, T_LABEL)
        uword v = valptr(idx)
        ubyte i = 0
        while i < 5 {
            @(v + i) = 0
            i++
        }
    }


; =====================================================================
; the recursive-descent evaluator
;
; Prog8 subroutine locals are statically allocated, so nothing may be
; held in a local across a call that can re-enter the same routine.
; Operands live on an explicit float stack (fstk) and operators on a
; byte stack (bstk) instead.
; =====================================================================
    sub fpush() {
        if fsp >= FDEPTH {
            perr = 1
            return
        }
        cx.f_store(&fstk + fsp * 6)
        fsp++
    }

    sub fpop() -> uword {
        if fsp == 0 {
            perr = 1
            return &fstk
        }
        fsp--
        return &fstk + fsp * 6
    }

    sub bpush(ubyte v) {
        if bsp >= 16 {
            perr = 1
            return
        }
        bstk[bsp] = v
        bsp++
    }

    sub bpop() -> ubyte {
        if bsp == 0 {
            perr = 1
            return 0
        }
        bsp--
        return bstk[bsp]
    }

    sub p_skipws() {
        while is_space(@(pp))
            pp++
    }

    ; consume one numeric literal starting at pp, -> characters consumed
    sub scan_number_token() -> ubyte {
        uword s = pp
        while is_digit(@(pp))
            pp++
        if @(pp) == '.' {
            pp++
            while is_digit(@(pp))
                pp++
        }
        ubyte e = @(pp)
        if e == $45 or e == $C5 {                ; 'e' / shifted 'E'
            uword save = pp
            @(pp) = $45                          ; the ROM's VAL wants $45
            pp++
            if @(pp) == '+' or @(pp) == '-'
                pp++
            if is_digit(@(pp)) {
                while is_digit(@(pp))
                    pp++
            } else {
                pp = save
            }
        }
        return lsb(pp - s)
    }

    sub p_number() {
        uword s = pp
        ubyte n = scan_number_token()
        if n == 0 {
            perr = 1
            cx.f_zero()
            return
        }
        cx.f_from_str(s, n)
    }

    ; parse a (possibly $-anchored) cell reference at `s`
    ; -> characters consumed, 0 if there is no reference there
    sub refabs(uword s) -> ubyte {
        uword p = s
        ref_ac = 0
        ref_ar = 0
        if @(p) == '$' {
            ref_ac = 1
            p++
        }
        ubyte a = alpha_idx(@(p))
        if a == 255
            return 0
        uword c = a
        c++
        p++
        a = alpha_idx(@(p))
        if a != 255 {
            c *= 26
            c += a
            c++
            p++
        }
        if @(p) == '$' {
            ref_ar = 1
            p++
        }
        if not is_digit(@(p))
            return 0
        uword n = 0
        while is_digit(@(p)) {
            if n < 6000 {
                n *= 10
                n += @(p) - '0'
            }
            p++
        }
        if n == 0
            return 0
        ref_c = c - 1
        ref_r = n - 1
        return lsb(p - s)
    }

    sub p_cellval() {
        ubyte n = refabs(pp)
        if n == 0 {
            perr = 1
            cx.f_zero()
            return
        }
        pp += n
        if ref_c >= NCOL or ref_r >= NROW {
            perr = 1
            cx.f_zero()
            return
        }
        uword idx = cidx(lsb(ref_c), lsb(ref_r))
        ubyte t = ctype(idx)
        if t == T_FERR {
            perr = 1
            cx.f_zero()
            return
        }
        if t == T_EMPTY or t == T_LABEL {
            cx.f_zero()
            return
        }
        cx.f_load(valptr(idx))
    }

    sub func_id(ubyte n) -> ubyte {
        if n == 3 {
            if fnbuf[0] == 'S' and fnbuf[1] == 'U' and fnbuf[2] == 'M'
                return F_SUM
            if fnbuf[0] == 'A' and fnbuf[1] == 'B' and fnbuf[2] == 'S'
                return F_ABS
            if fnbuf[0] == 'I' and fnbuf[1] == 'N' and fnbuf[2] == 'T'
                return F_INT
        }
        if n == 4 {
            if fnbuf[0] == 'S' and fnbuf[1] == 'Q' and fnbuf[2] == 'R' and fnbuf[3] == 'T'
                return F_SQRT
        }
        return 0
    }

    sub p_func() {
        ubyte n = 0
        while n < 6 {
            ubyte a = alpha_idx(@(pp))
            if a == 255
                break
            fnbuf[n] = a + 'A'
            n++
            pp++
        }
        ubyte fid = func_id(n)
        if @(pp) != '(' {
            perr = 1
            cx.f_zero()
            return
        }
        pp++
        p_skipws()

        ; a range argument -- A1...B5 -- is checked for first
        uword save = pp
        bool is_range = false
        uword c1 = 0
        uword r1 = 0
        uword c2 = 0
        uword r2 = 0
        ubyte k = refabs(pp)
        if k != 0 {
            c1 = ref_c
            r1 = ref_r
            uword q = pp + k
            if @(q) == '.' and @(q + 1) == '.' and @(q + 2) == '.' {
                q += 3
                k = refabs(q)
                if k != 0 {
                    c2 = ref_c
                    r2 = ref_r
                    pp = q + k
                    is_range = true
                }
            }
        }
        if not is_range
            pp = save

        if is_range {
            if fid != F_SUM {
                perr = 1
                cx.f_zero()
                return
            }
            sum_range(c1, r1, c2, r2)
        } else {
            if fid == 0 {
                perr = 1
                cx.f_zero()
                return
            }
            bpush(fid)
            p_expr()
            fid = bpop()
            if fid == F_ABS
                cx.f_abs()
            else if fid == F_INT
                ftrunc()
            else if fid == F_SQRT {
                if cx.f_sgn() == $FF {
                    perr = 1
                    cx.f_zero()
                } else {
                    cx.f_sqrt()
                }
            }
        }
        p_skipws()
        if @(pp) != ')' {
            perr = 1
            return
        }
        pp++
    }

    sub sum_range(uword c1, uword r1, uword c2, uword r2) {
        uword sw
        if c1 > c2 {
            sw = c1
            c1 = c2
            c2 = sw
        }
        if r1 > r2 {
            sw = r1
            r1 = r2
            r2 = sw
        }
        cx.f_zero()
        cx.f_store(&acc5)
        uword c = c1
        while c <= c2 {
            if c < NCOL {
                uword r = r1
                while r <= r2 {
                    if r < NROW {
                        uword idx = cidx(lsb(c), lsb(r))
                        ubyte t = ctype(idx)
                        if t == T_FERR {
                            perr = 1
                        } else if t == T_NUM or t == T_FORM {
                            cx.f_load(valptr(idx))
                            cx.f_add(&acc5)
                            cx.f_store(&acc5)
                        }
                    }
                    r++
                }
            }
            c++
        }
        cx.f_load(&acc5)
    }

    sub p_prim() {
        pdepth++
        if pdepth > MAXDEPTH {
            perr = 1
            cx.f_zero()
            pdepth--
            return
        }
        p_skipws()
        ubyte ch = @(pp)
        if ch == 0 {
            perr = 1
            cx.f_zero()
            pdepth--
            return
        }
        if ch == '+' {
            pp++
            ch = @(pp)
        }
        if ch == '-' {
            pp++
            p_prim()
            cx.f_neg()
            pdepth--
            return
        }
        if ch == '@' {
            pp++
            p_func()
            pdepth--
            return
        }
        if ch == '(' {
            pp++
            p_expr()
            p_skipws()
            if @(pp) == ')' {
                pp++
            } else {
                perr = 1
            }
            pdepth--
            return
        }
        if is_digit(ch) or ch == '.' {
            p_number()
            pdepth--
            return
        }
        p_cellval()
        pdepth--
    }

    sub p_term() {
        p_prim()
        while true {
            if perr != 0
                return
            p_skipws()
            ubyte op = @(pp)
            if op != '*' and op != '/'
                return
            pp++
            fpush()
            bpush(op)
            p_prim()
            op = bpop()
            if perr != 0 {
                void fpop()
                return
            }
            uword a
            if op == '*' {
                a = fpop()
                cx.f_mul(a)
            } else {
                if fac_is_zero() {
                    perr = 1
                    void fpop()
                    cx.f_zero()
                    return
                }
                a = fpop()
                cx.f_rdiv(a)             ; FAC = mem / FAC = left / right
            }
        }
    }

    sub p_expr() {
        pdepth++
        if pdepth > MAXDEPTH {
            perr = 1
            cx.f_zero()
            pdepth--
            return
        }
        p_term()
        while true {
            if perr != 0 {
                pdepth--
                return
            }
            p_skipws()
            ubyte op = @(pp)
            if op != '+' and op != '-' {
                pdepth--
                return
            }
            pp++
            fpush()
            bpush(op)
            p_term()
            op = bpop()
            if perr != 0 {
                void fpop()
                pdepth--
                return
            }
            uword a = fpop()
            if op == '+' {
                cx.f_add(a)
            } else {
                cx.f_rsub(a)             ; FAC = mem - FAC = left - right
            }
        }
    }

    ; evaluate the NUL-terminated formula in ebuf; result in FAC
    sub eval_ebuf() {
        perr = 0
        pdepth = 0
        fsp = 0
        bsp = 0
        pp = &ebuf
        p_expr()
    }

    sub load_ebuf(uword idx) {
        ubyte n = txt_len(idx)
        if n > MAXIN
            n = MAXIN
        uword s = txt_data(idx)
        ubyte i = 0
        while i < n {
            ebuf[i] = @(s + i)
            i++
        }
        ebuf[n] = 0
    }


; =====================================================================
; recalculation
; =====================================================================
    sub rebuild_flist() {
        fcount = 0
        uword r = 0
        while r < NROW {
            uword p = rowp(lsb(r))
            ubyte c = 0
            while c < NCOL {
                if @(p + coloff[c]) >= T_FORM {
                    if fcount < MAXF {
                        pokew(flist_p + fcount * 2, cidx(c, lsb(r)))
                        fcount++
                    }
                }
                c++
            }
            r++
        }
    }

    sub recalc() {
        rebuild_flist()
        ubyte pass = 0
        while pass < 10 {
            bool changed = false
            uword i = 0
            while i < fcount {
                uword idx = peekw(flist_p + i * 2)
                load_ebuf(idx)
                eval_ebuf()
                ubyte nt = T_FORM
                if perr != 0 {
                    nt = T_FERR
                    cx.f_zero()
                }
                cx.f_store(&res5)
                uword p = cellp(idx)     ; one bank select for the whole cell
                if @(p) != nt
                    changed = true
                @(p) = nt
                ubyte j = 0
                while j < 5 {
                    if @(p + 4 + j) != res5[j]
                        changed = true
                    @(p + 4 + j) = res5[j]
                    j++
                }
                i++
            }
            if not changed
                break
            pass++
        }
    }


; =====================================================================
; number -> text
; =====================================================================
    sub putdec(uword v, uword out) -> ubyte {
        if v == 0 {
            @(out) = '0'
            return 1
        }
        ubyte n = 0
        while v != 0 {
            tb1[n] = lsb(v % 10) + '0'
            v /= 10
            n++
        }
        ubyte i = n
        ubyte k = 0
        while i != 0 {
            i--
            @(out + k) = tb1[i]
            k++
        }
        return n
    }

    ; BASIC-style "general" rendering of FAC, PETSCII-cased
    sub num_general(uword out) -> ubyte {
        uword s = cx.f_to_str_trim()
        ubyte n = 0
        while n < 22 {
            ubyte c = @(s + n)
            if c == 0
                break
            if c >= $41 and c <= $5A
                c += $80                 ; show the E of 1.2E+15 upper case
            @(out + n) = c
            n++
        }
        return n
    }

    ; fixed two decimals; falls back to general form for huge magnitudes
    sub num_fixed2(uword out) -> ubyte {
        ubyte sign_ = cx.f_sgn()
        if sign_ == $FF
            cx.f_abs()
        cx.f_mul(&k100)
        cx.f_add(&k05)
        cx.f_int()
        ubyte n = num_general(&tb2)
        bool alldigits = true
        ubyte i = 0
        while i < n {
            if not is_digit(tb2[i])
                alldigits = false
            i++
        }
        ubyte k = 0
        if sign_ == $FF {
            @(out) = '-'
            k = 1
        }
        if not alldigits {
            i = 0
            while i < n {
                @(out + k) = tb2[i]
                k++
                i++
            }
            return k
        }
        if n < 3 {
            ubyte pad = 3 - n
            i = n
            while i != 0 {
                i--
                tb2[i + pad] = tb2[i]
            }
            i = 0
            while i < pad {
                tb2[i] = '0'
                i++
            }
            n += pad
        }
        i = 0
        while i < n - 2 {
            @(out + k) = tb2[i]
            k++
            i++
        }
        @(out + k) = '.'
        k++
        @(out + k) = tb2[n - 2]
        k++
        @(out + k) = tb2[n - 1]
        k++
        return k
    }

    ; length of the bar for the '*' format: int(FAC), clamped to 0..w
    sub num_bar(ubyte w) -> ubyte {
        if cx.f_sgn() != 1
            return 0
        cx.f_store(&tmp5)
        cx.f_from_u8(w)
        if cx.f_cmp(&tmp5) == $FF
            return w                     ; w < value
        cx.f_load(&tmp5)
        return lsb(cx.f_to_s16())
    }

    ; how many columns of screen a label would like -- the stored text
    ; without the quote that forced it to be a label
    sub label_len(uword idx) -> ubyte {
        ubyte n = txt_len(idx)
        if n == 0
            return 0
        if @(txt_data(idx)) == '"'
            n--
        return n
    }

    ; render cell `idx` into exactly `w` bytes at `out`
    sub fmtcell(uword idx, uword out, ubyte w) {
        ubyte i = 0
        ubyte n = 0
        ubyte t = ctype(idx)
        if t == T_EMPTY {
            while i < w {
                @(out + i) = ' '
                i++
            }
            return
        }
        if t == T_LABEL {
            uword s = txt_data(idx)
            n = txt_len(idx)
            if n != 0 {
                if @(s) == '"' {
                    s++
                    n--
                }
            }
            while i < w {
                if i < n
                    @(out + i) = @(s + i)
                else
                    @(out + i) = ' '
                i++
            }
            return
        }
        if t == T_FERR {
            pad_right(&s_error, 5, out, w)
            return
        }

        ubyte f = cfmt(idx)
        if f == 0 or f == 'D'
            f = gfmt
        if f == 0
            f = 'G'
        cx.f_load(valptr(idx))
        if f == '$' {
            n = num_fixed2(&tb1)
        } else if f == '%' {
            cx.f_mul(&k100)
            n = num_fixed2(&tb1)
            tb1[n] = '%'
            n++
        } else if f == '*' {
            n = num_bar(w)
            i = 0
            while i < n {
                tb1[i] = '*'
                i++
            }
            f = 'L'
        } else if f == 'I' {
            ftrunc()
            n = num_general(&tb1)
        } else {
            n = num_general(&tb1)
        }
        if f == 'L'
            pad_left(&tb1, n, out, w)
        else
            pad_right(&tb1, n, out, w)
    }

    ; text left-aligned in a field of w (truncated)
    sub pad_left(uword s, ubyte n, uword out, ubyte w) {
        ubyte i = 0
        while i < w {
            if i < n
                @(out + i) = @(s + i)
            else
                @(out + i) = ' '
            i++
        }
    }

    ; text right-aligned in a field of w (truncated from the left)
    sub pad_right(uword s, ubyte n, uword out, ubyte w) {
        if n >= w {
            ubyte j = 0
            while j < w {
                @(out + j) = @(s + j)
                j++
            }
            return
        }
        ubyte pad = w - n
        ubyte i = 0
        while i < pad {
            @(out + i) = ' '
            i++
        }
        i = 0
        while i < n {
            @(out + pad + i) = @(s + i)
            i++
        }
    }


; =====================================================================
; reference names
; =====================================================================
    ; A..Z, then AA.. -- always emitted upper case
    sub colname(uword c, uword out) -> ubyte {
        if c < 26 {
            @(out) = 'A' + lsb(c)
            return 1
        }
        uword hi = c / 26
        @(out) = 'A' + lsb(hi) - 1
        @(out + 1) = 'A' + lsb(c % 26)
        return 2
    }

    sub emitref(uword out, uword c, uword r, ubyte ac, ubyte ar) -> ubyte {
        ubyte k = 0
        if ac != 0 {
            @(out) = '$'
            k = 1
        }
        k += colname(c, out + k)
        if ar != 0 {
            @(out + k) = '$'
            k++
        }
        k += putdec(r + 1, out + k)
        return k
    }


; =====================================================================
; rewriting the references inside a formula
;   rwmode 0: swap rwa <-> rwb on rwaxis
;   rwmode 1: insert/delete at rwa, direction rwb (1 = insert, 255 = delete)
;   rwmode 2: offset by rwa columns / rwb rows (two's complement), but
;             only where the reference is not $-anchored
; The rewritten text ends up in wbuf/wlen.
; =====================================================================
    sub rw_walk(uword s, ubyte n) {
        rwchanged = false
        wlen = 0
        ubyte i = 0
        while i < n {
            if wlen > MAXIN - 10
                break
            ubyte k = refabs(s + i)
            if k == 0 {
                wbuf[wlen] = @(s + i)
                wlen++
                i++
            } else {
                uword c = ref_c
                uword r = ref_r
                ubyte ac = ref_ac
                ubyte ar = ref_ar
                if rwmode == 0 {
                    if rwaxis == 'R' {
                        if r == rwa {
                            r = rwb
                            rwchanged = true
                        } else if r == rwb {
                            r = rwa
                            rwchanged = true
                        }
                    } else {
                        if c == rwa {
                            c = rwb
                            rwchanged = true
                        } else if c == rwb {
                            c = rwa
                            rwchanged = true
                        }
                    }
                } else if rwmode == 1 {
                    if rwaxis == 'R' {
                        if rwb == 1 {
                            if r >= rwa {
                                r++
                                rwchanged = true
                            }
                        } else {
                            if r > rwa {
                                r--
                                rwchanged = true
                            }
                        }
                    } else {
                        if rwb == 1 {
                            if c >= rwa {
                                c++
                                rwchanged = true
                            }
                        } else {
                            if c > rwa {
                                c--
                                rwchanged = true
                            }
                        }
                    }
                } else {
                    if ac == 0 {
                        c += rwa
                        rwchanged = true
                        if c >= $8000
                            c = 0
                    }
                    if ar == 0 {
                        r += rwb
                        rwchanged = true
                        if r >= $8000
                            r = 0
                    }
                }
                wlen += emitref(&wbuf + wlen, c, r, ac, ar)
                i += k
            }
        }
        wbuf[wlen] = 0
    }

    sub rewrite_formulas() {
        uword r = 0
        while r < NROW {
            ubyte c = 0
            while c < NCOL {
                uword idx = cidx(c, lsb(r))
                if ctype(idx) >= T_FORM {
                    ubyte n = txt_len(idx)
                    if n != 0 {
                        load_ebuf(idx)
                        rw_walk(&ebuf, n)
                        if rwchanged
                            void txt_set(idx, &wbuf, wlen)
                    }
                }
                c++
            }
            r++
        }
    }

    sub shiftrefs(ubyte axis, uword pos, ubyte dir) {
        rwmode = 1
        rwaxis = axis
        rwa = pos
        rwb = dir
        rewrite_formulas()
    }

    sub fixrefs(ubyte axis, uword a, uword b) {
        rwmode = 0
        rwaxis = axis
        rwa = a
        rwb = b
        rewrite_formulas()
    }


; =====================================================================
; row / column operations
; =====================================================================
    sub insertrow(ubyte at) {
        ubyte r = MAXROW
        while r > at {
            row_copy(r, r - 1)
            r--
        }
        row_clear(at)
        shiftrefs('R', at, 1)
    }

    sub deleterow(ubyte at) {
        shiftrefs('R', at, 255)
        ubyte r = at
        while r < MAXROW {
            row_copy(r, r + 1)
            r++
        }
        row_clear(MAXROW)
    }

    ; column work stays inside one row, so one bank select per row is enough
    sub insertcol(ubyte at) {
        uword r = 0
        while r < NROW {
            uword p = rowp(lsb(r))
            ubyte c = NCOL - 1
            while c > at {
                ubyte i = 0
                while i < CELLSZ {
                    @(p + coloff[c] + i) = @(p + coloff[c - 1] + i)
                    i++
                }
                c--
            }
            ubyte j = 0
            while j < CELLSZ {
                @(p + coloff[at] + j) = 0
                j++
            }
            fix_row_owners(lsb(r))
            r++
        }
        shiftrefs('C', at, 1)
    }

    sub deletecol(ubyte at) {
        shiftrefs('C', at, 255)
        uword r = 0
        while r < NROW {
            uword p = rowp(lsb(r))
            ubyte c = at
            while c < NCOL - 1 {
                ubyte i = 0
                while i < CELLSZ {
                    @(p + coloff[c] + i) = @(p + coloff[c + 1] + i)
                    i++
                }
                c++
            }
            ubyte j = 0
            while j < CELLSZ {
                @(p + coloff[NCOL - 1] + j) = 0
                j++
            }
            fix_row_owners(lsb(r))
            r++
        }
    }

    sub swaprow(ubyte a, ubyte b) {
        row_swap(a, b)
        fixrefs('R', a, b)
    }

    sub swapcol(ubyte a, ubyte b) {
        uword r = 0
        while r < NROW {
            uword p = rowp(lsb(r))
            ubyte i = 0
            while i < CELLSZ {
                ubyte t = @(p + coloff[a] + i)
                @(p + coloff[a] + i) = @(p + coloff[b] + i)
                @(p + coloff[b] + i) = t
                i++
            }
            fix_row_owners(lsb(r))
            r++
        }
        fixrefs('C', a, b)
    }

    ; copy one cell, adjusting the relative references in a formula
    sub replicatecell(ubyte sc, ubyte sr, ubyte dc, ubyte dr) {
        if dc >= NCOL or dr >= NROW
            return
        uword src = cidx(sc, sr)
        uword dst = cidx(dc, dr)
        if src == dst
            return
        ubyte t = ctype(src)
        if t == T_EMPTY {
            cell_clear(dst)
            return
        }
        ubyte n = txt_len(src)
        if t < T_FORM {
            load_ebuf(src)
            uword p = cellp(src)
            ubyte i = 0
            while i < CELLSZ {
                cellbuf[i] = @(p + i)
                i++
            }
            cell_clear(dst)
            p = cellp(dst)
            i = 0
            while i < CELLSZ {
                @(p + i) = cellbuf[i]
                i++
            }
            set_txt_rec(dst, 0)      ; a fresh record, never a shared one
            void txt_set(dst, &ebuf, n)
            return
        }
        load_ebuf(src)
        rwmode = 2
        rwa = dc
        rwa -= sc
        rwb = dr
        rwb -= sr
        rw_walk(&ebuf, n)
        cell_clear(dst)
        set_cfmt(dst, cfmt(src))
        void txt_set(dst, &wbuf, wlen)
        set_ctype(dst, T_FORM)
    }
}
