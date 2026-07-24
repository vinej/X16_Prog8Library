; basics.p8 -- Prog8 core language, no library imports.
; Output uses only the KERNAL CHROUT ($FFD2) through inline asm, so this
; program imports nothing.

%zeropage basicsafe

main {
    ; --- constants and variables ---------------------------------------
    const ubyte WIDTH = 40
    ubyte  count = 5
    uword  total = 1000
    byte   delta = -3
    bool   ready = true

    ubyte[5] scores = [10, 20, 30, 40, 50]
    str      title  = "prog8 core"

    sub start() {
        print_str(&title)
        newline()

        total += count as uword
        emit_hex(lsb(total))        ; low byte of total in hex
        newline()

        ; array + loop
        ubyte i
        for i in 0 to len(scores)-1 {
            emit_hex(scores[i])
            emit(' ')
        }
        newline()
    }

    ; --- library-free output helpers -----------------------------------
    sub emit(ubyte ch) {
        %asm {{
            lda  p8v_ch
            jsr  $ffd2           ; CHROUT
        }}
    }

    sub newline() {
        emit($0d)
    }

    sub print_str(uword ptr) {
        ubyte i = 0
        while @(ptr + i) != 0 {
            emit(@(ptr + i))
            i++
        }
    }

    sub emit_nibble(ubyte n) {
        if n < 10
            emit(n + $30)        ; '0'..'9'
        else
            emit(n - 10 + $41)   ; 'A'..'F'
    }

    sub emit_hex(ubyte v) {
        emit_nibble(v >> 4)
        emit_nibble(v & 15)
    }
}
