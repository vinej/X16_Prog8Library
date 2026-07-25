; =====================================================================
; child.p8 -- something for the launcher to launch.
;
; The contract a launched program has to honour is simply: return. This
; one prints, pauses so the round trip is visible, and lets
; start() fall off the end, which is an RTS back into the trampoline.
; =====================================================================
%import x16lib
%zeropage dontuse

main {
    str s_hello = "child: running, and about to return"
    str s_key   = "child: waiting a moment, then returning"

    sub start() {
        cx.load_banks()
        cx.screen_color(7, 0)
        cx.screen_cls()
        cx.screen_puts(&s_hello)
        cx.screen_chrout($0d)
        cx.screen_puts(&s_key)
        cx.screen_chrout($0d)
        ; a visible pause, but no key: the round trip has to run unattended
        ubyte n = 0
        while n < 12 {
            uword i = 0
            while i < 6000 {
                i++
            }
            n++
        }
    }
}
