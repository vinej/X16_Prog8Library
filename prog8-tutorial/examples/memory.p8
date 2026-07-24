; memory.p8 -- memory-mapped vars, pointers, peek/poke, builtins. No imports.
%zeropage basicsafe

main {
    ; a variable mapped onto a fixed hardware address (VERA data port 0)
    &ubyte VERA_ADDR_L = $9F20
    &ubyte R0 = $02                 ; a KERNAL zero-page register

    sub start() {
        ; direct memory access with @ and peek/poke
        uword screen = $0400
        poke(screen, 5)
        R0 = peek(screen) + 1       ; -> 6
        pokew($0402, $1234)         ; write a word
        uword w = peekw($0402)      ; read it back

        ; builtin functions (all core, not library):
        ubyte a = 200
        ubyte b = 50
        ubyte mx = max(a, b)
        ubyte mn = min(a, b)
        uword combined = mkword($12, $34)   ; $1234
        ubyte hi = msb(combined)
        ubyte lo = lsb(combined)
        ubyte n = abs(-7 as byte) as ubyte

        emit(lo)                    ; $34
        emit(hi + '0' - hi)         ; keep the compiler honest about hi
        emit($0d)
    }

    sub emit(ubyte ch) {
        %asm {{
            lda  p8v_ch
            jsr  $ffd2
        }}
    }
}
