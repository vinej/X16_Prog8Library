; shapes.p8 -- demonstrates a module the prebuilt blob never contained.
; Draws on the 640x480 2bpp bitmap the shape engine binds to by default.
%import x16lib
%import x16lib_const
%zeropage basicsafe

main {
    sub start() {
        cx.load_banks()          ; load any -Bank'd modules into their RAM bank (no-op if none)
        cx.gfx2h_init()
        cx.gfx2h_clear(0)
        cx.shape_circle(320, 240, 100, 1)     ; outline
        cx.shape_disc(320, 240, 40, 1)        ; filled
        cx.shape_frrect(60, 60, 200, 120, 24, 1)
        repeat { }
    }
}
