; twobank.p8 -- demonstrates splitting library modules across two RAM banks.
%import x16lib
%import x16lib_const
%zeropage basicsafe

main {
    str s = "hello"
    sub start() {
        cx.load_banks()                       ; loads BANK22.BIN + BANK23.BIN
        cx.gfx2h_init()                       ; bitmap2h  -> bank 22
        cx.shape_circle(320, 240, 100, 1)     ; shapes    -> bank 22
        cx.str_length(&s)                     ; strings   -> bank 23
        repeat { }
    }
}
