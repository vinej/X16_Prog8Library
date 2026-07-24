# 7. Inline assembly

Prog8 assembles with **64tass**, and you can drop raw 6502 into any subroutine
with an `%asm {{ ... }}` block. This is how the library-free examples in this
tutorial produce output at all.

## The basics

```prog8
sub beep() {
    %asm {{
        lda  #$0d
        jsr  $ffd2          ; CHROUT
    }}
}
```

Everything between `{{` and `}}` is passed to the assembler verbatim, so it is
64tass syntax, not Prog8. Labels, `.byte` data, addressing modes — all available.

## Reaching Prog8 variables from asm

A Prog8 variable or parameter is visible in asm under a prefixed name:

- a **sub parameter** or **local** `foo` → `p8v_foo`
- a **block-level** variable → also `p8v_foo`, reachable through its block scope

```prog8
sub emit(ubyte ch) {
    %asm {{
        lda  p8v_ch          ; read the parameter 'ch'
        jsr  $ffd2
    }}
}
```

A `uword` occupies two bytes; `p8v_ptr` is the low byte and `p8v_ptr+1` the high:

```prog8
sub call_it(uword addr) {
    %asm {{
        lda  p8v_addr
        sta  P8ZP_SCRATCH_W1
        lda  p8v_addr+1
        sta  P8ZP_SCRATCH_W1+1
        jmp  (P8ZP_SCRATCH_W1)
    }}
}
```

`P8ZP_SCRATCH_W1/W2` and `P8ZP_SCRATCH_REG` are scratch zero-page locations Prog8
reserves for exactly this.

## Whole-routine assembly: `asmsub`

When the *entire* routine is assembly and you want register-level control over
the signature, use `asmsub` (from the [subroutines page](04-subroutines.md)):

```prog8
asmsub swap_nibbles(ubyte v @A) -> ubyte @A {
    %asm {{
        pha
        lsr  a
        lsr  a
        lsr  a
        lsr  a
        sta  P8ZP_SCRATCH_REG
        pla
        asl  a
        asl  a
        asl  a
        asl  a
        ora  P8ZP_SCRATCH_REG
        rts
    }}
}
```

## Including external asm or binary

- `%asminclude "file.asm"` — paste an assembly source file at this point.
- `%asmbinary "file.bin"` — embed a raw binary blob.

(These are exactly the mechanisms the X16 library wrapper in this repo uses to
fold the whole library's 64tass source into a program.)

## When to reach for asm

Prefer Prog8 — it's readable and the codegen is good. Drop to asm for: a KERNAL/
hardware call with a specific register contract, a cycle-critical inner loop, or
self-modifying tricks. Keep the asm small and let Prog8 hold the structure.

Next: [Blocks, scope, and directives →](08-blocks-scope-directives.md)
