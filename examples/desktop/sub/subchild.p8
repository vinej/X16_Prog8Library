; =====================================================================
; subchild.p8 -- a launched program that has files of its own.
;
; It lives in a subdirectory with SUBDATA.SEQ beside it and opens that
; file by BARE NAME. That only works if whoever launched it made the
; program's own directory current first, which is the whole point of
; the exercise: a program with data files cannot be run from elsewhere.
;
; Like every launchable program it must return, so it prints, pauses,
; and lets start() fall off the end.
; =====================================================================
%import x16lib
%zeropage dontuse

main {
    str fname = "subdata.seq"
    str s_ok   = "subchild: read my data file from my own directory"
    str s_bad  = "subchild: CANNOT SEE MY DATA FILE"
    ubyte[40] buf

    sub start() {
        cx.load_banks()
        cx.screen_color(7, 0)
        cx.screen_cls()

        ubyte n = 0
        if cx.fio_open_read(&fname, len(fname), 4, 8, 2) {
            cx.screen_puts(&s_bad)
        } else {
            while n < 38 {
                ubyte c = cx.fio_chrin()
                if cx.fio_readst() != 0
                    break
                if c == $0d
                    break
                buf[n] = c
                n++
            }
            buf[n] = 0
            cx.fio_clrchn()
            cx.fio_close(4)
            cx.screen_puts(&s_ok)
            cx.screen_chrout($0d)
            cx.screen_puts("it says: ")
            cx.screen_puts(&buf)
        }
        cx.screen_chrout($0d)

        ubyte d = 0
        while d < 12 {
            uword w = 0
            while w < 6000 {
                w++
            }
            d++
        }
    }
}
