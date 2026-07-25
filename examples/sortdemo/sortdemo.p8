; sortdemo.p8 -- numeric and string sorting via the X16_Library (v0.11.8).
%import x16lib
%import x16lib_const
%zeropage basicsafe

main {
    uword[8] nums = [500, 30, 8000, 1, 900, 42, 65000, 7]
    str[]    names = ["delta", "alpha", "charlie", "bravo"]

    sub start() {
        cx.load_banks()
        cx.sort_u16(&nums, len(nums))       ; sort the words in place
        cx.str_sort(&names, len(names))     ; sort the string pointers by content
        repeat { }
    }
}
