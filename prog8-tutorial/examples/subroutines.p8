; subroutines.p8 -- sub / params / returns / asmsub / extsub, no imports.
%zeropage basicsafe

main {
    ; extsub: a routine at a fixed address (here the KERNAL's CHROUT).
    extsub $FFD2 = CHROUT(ubyte character @A) clobbers(A)

    sub start() {
        CHROUT(add(30, 12) + '0' - 42 + 'A' - 'A')   ; contrived; prints 'A'? keep simple
        CHROUT($0d)

        ; normal sub with a return value
        ubyte g = gcd(48, 36)
        CHROUT('0' + g / 10)
        CHROUT('0' + g % 10)
        CHROUT($0d)

        ; asmsub: parameters arrive in registers, body is pure asm
        CHROUT(double(5) + '0')     ; prints ':' ($3a = '0'+10)
        CHROUT($0d)
    }

    sub add(ubyte a, ubyte b) -> ubyte {
        return a + b
    }

    ; classic recursion / loop in the core language
    sub gcd(ubyte a, ubyte b) -> ubyte {
        while b != 0 {
            ubyte t = b
            b = a % b
            a = t
        }
        return a
    }

    asmsub double(ubyte v @A) -> ubyte @A {
        %asm {{
            asl  a
            rts
        }}
    }
}
