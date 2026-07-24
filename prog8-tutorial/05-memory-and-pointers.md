# 5. Memory and pointers

The 6502 has 64 KB of address space, and Prog8 lets you touch any of it directly.
See [`examples/memory.p8`](examples/memory.p8).

## Memory-mapped variables (`&`)

A `&`-prefixed declaration doesn't allocate storage — it *names an existing
address*, so reads and writes go straight to that hardware register or location:

```prog8
&ubyte VERA_ADDR_L = $9F20      ; a VERA register
&ubyte R0          = $02        ; KERNAL zero-page register r0 low
&uword cursor      = $0400      ; treat two bytes at $0400 as a word

VERA_ADDR_L = 10                ; writes hardware directly
R0++
```

This is exactly how the syslib and the X16 library expose hardware — but you can
do it yourself for any address, with no import.

## peek / poke — read and write any address

```prog8
poke($0400, 5)                  ; write byte 5 to $0400
ubyte v = peek($0400)           ; read it back

pokew($0402, $1234)             ; write a 16-bit word (little-endian)
uword w = peekw($0402)          ; read a word
```

`poke`/`peek` are byte; `pokew`/`peekw` are word. They're built-ins — no library.

## The `@` dereference

`@(address)` is an lvalue/rvalue for the byte at a runtime address — the same idea
as `peek`/`poke` but usable in expressions:

```prog8
uword ptr = $0400
@(ptr) = 65                     ; store
ubyte c = @(ptr + 3)            ; load, with address arithmetic
```

Walking a NUL-terminated string with nothing but `@` and a loop:

```prog8
sub print_str(uword ptr) {
    ubyte i = 0
    while @(ptr + i) != 0 {
        emit(@(ptr + i))
        i++
    }
}

print_str(&title)               ; &str gives its address
```

## Pointers are just `uword`s

An address is a 16-bit number, so you hold pointers in `uword` and do arithmetic
on them. `&x` gives the address of any variable, array, string, or subroutine:

```prog8
uword code = &start             ; address of a sub
uword data = &scores            ; address of an array's first element
uword mid  = &scores + 2        ; third element's address
```

## `memory()` — reserve a block

`memory("name", size, alignment)` reserves a labelled block and returns its
address — useful for scratch buffers without hard-coding an address:

```prog8
uword buf = memory("scratch", 256, 0)
@(buf) = 0
```

Next: [Built-in functions →](06-builtin-functions.md)
