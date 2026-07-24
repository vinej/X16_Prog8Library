; controlflow.p8 -- if / when / for / while / repeat / do-until, no imports.
%zeropage basicsafe

main {
    sub start() {
        ubyte n = 7

        ; if / else if / else
        if n < 5
            emit('L')
        else if n < 10
            emit('M')
        else
            emit('H')
        newline()

        ; when (like switch)
        when n {
            0 -> emit('z')
            1, 3, 5, 7, 9 -> emit('o')      ; multiple values
            else -> emit('e')
        }
        newline()

        ; for over a range, step
        ubyte i
        for i in 0 to 8 step 2 {
            emit('0' + i)
        }
        newline()

        ; for over an array
        ubyte[] primes = [2, 3, 5, 7, 11]
        for i in primes {
            emit_hex(i)
            emit(' ')
        }
        newline()

        ; while and do-until
        ubyte c = 3
        while c != 0 {
            emit('*')
            c--
        }
        c = 0
        do {
            emit('.')
            c++
        } until c == 3
        newline()

        ; repeat (fixed count) and unconditional repeat with break
        repeat 4 {
            emit('=')
        }
        c = 0
        repeat {
            c++
            if c == 2 continue
            emit('0' + c)
            if c == 5 break
        }
        newline()
    }

    sub emit(ubyte ch) {
        %asm {{
            lda  p8v_ch
            jsr  $ffd2
        }}
    }
    sub newline() { emit($0d) }
    sub emit_nibble(ubyte n) {
        if n < 10
            emit(n + $30)
        else
            emit(n - 10 + $41)
    }
    sub emit_hex(ubyte v) {
        emit_nibble(v >> 4)
        emit_nibble(v & 15)
    }
}
