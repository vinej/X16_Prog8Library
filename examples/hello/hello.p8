; hello.p8 -- the X16_Library "hello" ported to Prog8.
;
; Mirrors dist/examples/hello-64tass.asm from the X16_Library: print a
; message and the number 1234 through the library's own screen routines,
; then poke a '*' into the text screen via VERA.
;
; Build:  build.ps1 examples\hello\hello.p8      (see README.md)

%import x16lib             ; typed wrappers + the embedded library source
%import x16lib_const       ; VRAM_TEXT, VERA_INC_*, ... constants
%zeropage basicsafe

main {
    str msg = "hello from prog8! "

    sub start() {
        cx.screen_puts(&msg)              ; A/X = string pointer

        ; print the number 1234 with the library's u16 -> decimal routine,
        ; which returns a pointer (A/X) to the ASCIIZ text that screen_puts prints
        cx.screen_puts(cx.u16_to_dec(1234))

        cx.screen_chrout($0d)             ; newline

        ; drop a '*' on text row 4 straight through VERA.
        ; VRAM text base is $1B000; row 4 = $1B000 + 4*128*2 = $1B400.
        cx.vera_set_addr0($00, $b4, $01)   ; low, mid, high (bit16 = bank), +0 increment
        cx.vera_fill($2a, 1)
    }
}
