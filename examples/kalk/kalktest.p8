; =====================================================================
; kalktest.p8 -- the assertions from kalk.c's own test suite, run on the
; X16 against kalkcore.  Prints one line per group; any failure names the
; expression that produced the wrong answer.
;
;   .\build.ps1 examples\kalk\kalktest.p8 -Run
; =====================================================================
%import x16lib
%import kalkcore
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    ubyte fails
    ubyte checks
    ubyte[16] nbuf
    str s_pass  = "  all ok"
    str s_fail  = "  FAILED: "
    str s_hdr1  = "kalk engine self-test"
    ubyte[32] want

    sub start() {
        cx.load_banks()
        void cx.screen_set_mode(0)
        cx.screen_color(1, 6)
        cx.screen_cls()
        cx.screen_puts(&s_hdr1)
        nl()
        kk.init()

        test_ref()
        test_colname()
        test_expr()
        test_recalc()
        test_replicate()
        test_shift()
        test_banks()

        nl()
        if fails == 0
            cx.screen_puts(&s_pass)
        else {
            cx.screen_puts(&s_fail)
            puts_dec(fails)
        }
        nl()
        void cx.key_wait()
    }

    sub nl() {
        cx.screen_chrout($0d)
    }

    sub puts_dec(uword v) {
        ubyte n = kk.putdec(v, &nbuf)
        nbuf[n] = 0
        cx.screen_puts(&nbuf)
    }

    ; ---- helpers -----------------------------------------------------
    sub note(uword title) {
        nl()
        cx.screen_puts(title)
        cx.screen_chrout(' ')
    }

    sub ok(bool cond, uword what) {
        checks++
        if cond {
            cx.screen_chrout('.')
        } else {
            fails++
            nl()
            cx.screen_puts(&s_fail)
            cx.screen_puts(what)
            nl()
        }
    }

    ; evaluate a NUL-terminated formula string and compare with `expect`
    ; (also a string, in the general number format)
    sub evals(uword src, uword expect) {
        ubyte n = 0
        while @(src + n) != 0 {
            kk.ebuf[n] = @(src + n)
            n++
        }
        kk.ebuf[n] = 0
        kk.eval_ebuf()
        ubyte m = 0
        if kk.perr != 0 {
            want[0] = 'E'
            want[1] = 'R'
            want[2] = 'R'
            m = 3
        } else {
            m = kk.num_general(&want)
        }
        want[m] = 0
        bool same = true
        ubyte i = 0
        while true {
            if want[i] != @(expect + i)
                same = false
            if want[i] == 0
                break
            i++
        }
        checks++
        if same {
            cx.screen_chrout('.')
        } else {
            fails++
            nl()
            cx.screen_puts(src)
            cx.screen_chrout('=')
            cx.screen_puts(&want)
            cx.screen_chrout('/')
            cx.screen_puts(expect)
            nl()
        }
    }

    sub put(ubyte c, ubyte r, uword text) {
        ubyte n = 0
        while @(text + n) != 0
            n++
        kk.setcell(kk.cidx(c, r), text, n)
    }

    ; ---- tests -------------------------------------------------------
    str t_ref = "ref"
    str r_a1 = "A1"
    str r_z50 = "Z50"
    str r_aa10 = "AA10"
    str r_az99 = "AZ99"
    str r_ba1 = "BA1"
    str r_abs = "$B$2"

    sub test_ref() {
        note(&t_ref)
        ok(kk.refabs(&r_a1) == 2 and kk.ref_c == 0 and kk.ref_r == 0, &r_a1)
        ok(kk.refabs(&r_z50) == 3 and kk.ref_c == 25 and kk.ref_r == 49, &r_z50)
        ok(kk.refabs(&r_aa10) == 4 and kk.ref_c == 26 and kk.ref_r == 9, &r_aa10)
        ok(kk.refabs(&r_az99) == 4 and kk.ref_c == 51 and kk.ref_r == 98, &r_az99)
        ok(kk.refabs(&r_ba1) == 3 and kk.ref_c == 52 and kk.ref_r == 0, &r_ba1)
        ok(kk.refabs(&r_abs) == 4 and kk.ref_c == 1 and kk.ref_r == 1 and
           kk.ref_ac == 1 and kk.ref_ar == 1, &r_abs)
    }

    str t_col = "colname"
    ubyte[4] cnb

    sub test_colname() {
        note(&t_col)
        ok(kk.colname(0, &cnb) == 1 and cnb[0] == 'A', &t_col)
        ok(kk.colname(25, &cnb) == 1 and cnb[0] == 'Z', &t_col)
        ok(kk.colname(26, &cnb) == 2 and cnb[0] == 'A' and cnb[1] == 'A', &t_col)
        ok(kk.colname(51, &cnb) == 2 and cnb[0] == 'A' and cnb[1] == 'Z', &t_col)
        ok(kk.colname(52, &cnb) == 2 and cnb[0] == 'B' and cnb[1] == 'A', &t_col)
    }

    str t_expr = "expr"
    str v3 = "3"
    str v5 = "5"
    str v11 = "11"
    str vm135 = "-13.5"

    str e1 = "42"
    str e2 = "1.5"
    str e3 = ".5"
    str e4 = "-123"
    str e5 = "+123"
    str e6 = "(123)"
    str e7 = "A1"
    str e8 = "A2"
    str e9 = "A3"
    str e10 = "B1"
    str e11 = "A12"
    str e12 = "A1*A2"
    str e13 = "A1*10/A2"
    str e14 = "A1/0"
    str e15 = "A1+A2"
    str e16 = "A1+A2-A3"
    str e17 = "A1+A2*A3"
    str e18 = "(A1+A2)*A3"
    str e19 = "@ABS(A1)"
    str e20 = "@ABS(A4)"
    str e21 = "@INT(A4)"
    str e22 = "@INT(@ABS(A4))"
    str e23 = "@SQRT(A3+A2)"
    str e24 = "@SUM(A3)"
    str e25 = "@SUM(A1...A3)"
    str e26 = "@SUM(A3...A1)"
    str e27 = "@SUM(A1...A1)"
    str e28 = "@SUM(A1...B3)"
    str e29 = "@SQRT(-A1)"
    str e30 = ""

    str x42 = "42"
    str x15 = "1.5"
    str x05 = ".5"
    str xm123 = "-123"
    str x123 = "123"
    str x3 = "3"
    str x5 = "5"
    str x11 = "11"
    str x0 = "0"
    str x15b = "15"
    str x6 = "6"
    str xerr = "ERR"
    str x8 = "8"
    str xm3 = "-3"
    str x58 = "58"
    str x88 = "88"
    str x135 = "13.5"
    str xm13 = "-13"
    str x13 = "13"
    str x4 = "4"
    str x19 = "19"

    sub test_expr() {
        note(&t_expr)
        kk.clear_all()
        put(0, 0, &v3)
        put(0, 1, &v5)
        put(0, 2, &v11)
        put(0, 3, &vm135)               ; leading '-' makes this a formula
        kk.recalc()
        evals(&e30, &xerr)
        evals(&e1, &x42)
        evals(&e2, &x15)
        evals(&e3, &x05)
        evals(&e4, &xm123)
        evals(&e5, &x123)
        evals(&e6, &x123)
        evals(&e7, &x3)
        evals(&e8, &x5)
        evals(&e9, &x11)
        evals(&e10, &x0)
        evals(&e11, &x0)
        evals(&e12, &x15b)
        evals(&e13, &x6)
        evals(&e14, &xerr)
        evals(&e15, &x8)
        evals(&e16, &xm3)
        evals(&e17, &x58)
        evals(&e18, &x88)
        evals(&e19, &x3)
        evals(&e20, &x135)
        evals(&e21, &xm13)
        evals(&e22, &x13)
        evals(&e23, &x4)
        evals(&e24, &x11)
        evals(&e25, &x19)
        evals(&e26, &x19)
        evals(&e27, &x3)
        evals(&e28, &x19)
        evals(&e29, &xerr)
    }

    str t_rec = "recalc"
    str c1 = "5"
    str c2 = "7"
    str c3 = "11"
    str c4 = "+@SUM(A1...A3)"
    str d2 = "+A1+5"
    str d3 = "+A2+A1"
    str d4 = "+A1+A2+A3"
    str x23 = "23"
    str x30 = "30"
    str x38 = "38"
    str seven = "7"

    sub test_recalc() {
        note(&t_rec)
        kk.clear_all()
        put(0, 0, &c1)
        put(0, 1, &c2)
        put(0, 2, &c3)
        put(0, 3, &c4)
        kk.recalc()
        ok(cellis(0, 3, &x23), &c4)

        kk.clear_all()
        put(0, 0, &c1)
        put(0, 1, &d2)
        put(0, 2, &d3)
        put(0, 3, &d4)
        kk.recalc()
        ok(cellis(0, 3, &x30), &d4)     ; 5 + 10 + 15

        put(0, 0, &seven)
        kk.recalc()
        ok(cellis(0, 3, &x38), &d4)     ; 7 + 12 + 19
    }

    sub cellis(ubyte c, ubyte r, uword expect) -> bool {
        uword idx = kk.cidx(c, r)
        if kk.ctype(idx) == kk.T_FERR
            return false
        cx.f_load(kk.valptr(idx))
        ubyte m = kk.num_general(&want)
        want[m] = 0
        ubyte i = 0
        while true {
            if want[i] != @(expect + i)
                return false
            if want[i] == 0
                return true
            i++
        }
        return false
    }

    str t_repl = "replicate"
    str p1 = "+A1+$B$1"
    str p2 = "10"
    str p3 = "100"
    str p4 = "1000"
    str x110 = "110"
    str x1100 = "1100"

    sub test_replicate() {
        note(&t_repl)
        kk.clear_all()
        put(0, 0, &p2)                  ; A1 = 10
        put(1, 0, &p3)                  ; B1 = 100
        put(0, 1, &p4)                  ; A2 = 1000
        put(2, 0, &p1)                  ; C1 = +A1+$B$1 = 110
        kk.recalc()
        ok(cellis(2, 0, &x110), &p1)
        kk.replicatecell(2, 0, 2, 1)    ; C2 = +A2+$B$1 = 1100
        kk.recalc()
        ok(cellis(2, 1, &x1100), &p1)
    }

    str t_shift = "insert/delete"
    str q1 = "1"
    str q2 = "2"
    str q3 = "+A1+A2"
    str x3b = "3"

    sub test_shift() {
        note(&t_shift)
        kk.clear_all()
        put(0, 0, &q1)                  ; A1 = 1
        put(0, 1, &q2)                  ; A2 = 2
        put(0, 2, &q3)                  ; A3 = +A1+A2 = 3
        kk.recalc()
        ok(cellis(0, 2, &x3b), &q3)
        kk.insertrow(0)                 ; everything moves down one row
        kk.recalc()
        ok(cellis(0, 3, &x3b), &q3)
        kk.deleterow(0)
        kk.recalc()
        ok(cellis(0, 2, &x3b), &q3)
    }

    ; ---- the grid spans eight RAM banks: check across the boundaries ---
    str t_bank = "banked rows"
    str b1 = "1"
    str b2 = "2"
    str bsum = "+A6+A32+A33+A200"
    str bhi  = "+Z256"
    str x4b  = "4"
    str x1b  = "1"
    str x256 = "256"
    str r_z256 = "Z256"

    sub test_banks() {
        note(&t_bank)
        kk.clear_all()
        ; rows 5, 31, 32 and 199 sit in banks 1, 1, 2 and 7
        put(0, 5,   &b1)
        put(0, 31,  &b1)
        put(0, 32,  &b1)
        put(0, 199, &b1)
        put(0, 250, &bsum)          ; a formula in bank 8 reading four banks
        kk.recalc()
        ok(cellis(0, 250, &x4b), &bsum)

        ; the far corner, Z256, and a reference that reaches it
        put(25, 255, &b1)
        put(1, 255, &bhi)
        kk.recalc()
        ok(cellis(1, 255, &x1b), &bhi)

        ; a row number that needs all three digits
        ok(kk.refabs(&r_z256) == 4 and kk.ref_c == 25 and kk.ref_r == 255, &r_z256)
        ubyte n = kk.putdec(256, &want)
        want[n] = 0
        ok(streq(&want, &x256), &x256)

        ; text survives a row move across a bank boundary
        kk.clear_all()
        put(0, 31, &t_bank)         ; label in bank 1, last row of it
        kk.insertrow(0)             ; pushes it into bank 2
        ok(labelis(0, 32, &t_bank), &t_bank)
    }

    sub streq(uword a, uword b) -> bool {
        ubyte i = 0
        while true {
            if @(a + i) != @(b + i)
                return false
            if @(a + i) == 0
                return true
            i++
        }
        return false
    }

    sub labelis(ubyte c, ubyte r, uword expect) -> bool {
        uword idx = kk.cidx(c, r)
        if kk.ctype(idx) != kk.T_LABEL
            return false
        ubyte n = kk.txt_len(idx)
        uword s = kk.txt_data(idx)
        ubyte i = 0
        while i < n {
            if @(s + i) != @(expect + i)
                return false
            i++
        }
        return @(expect + n) == 0
    }
}
