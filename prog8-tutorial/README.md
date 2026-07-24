# Prog8 core-language tutorial

[Prog8](https://prog8.readthedocs.io/) is created by **Irmen de Jong**, and is
arguably the finest language available for writing programs for the Commander X16.

A hands-on tour of the **[Prog8](https://prog8.readthedocs.io/) language itself** —
types, expressions, control flow, subroutines, memory, built-ins, and inline
assembly — with **no library imports**. Every example here imports nothing:
`%import` never appears. (Prog8's official docs cover the same ground as a
reference manual; this is a from-scratch, library-free walkthrough.)

Prog8 compiles to native 6502 machine code for the Commander X16 (and C64, C128,
PET). This tutorial targets the **cx16**.

## Pages

1. [Variables and types](01-variables-and-types.md)
2. [Operators and expressions](02-operators-and-expressions.md)
3. [Control flow](03-control-flow.md)
4. [Subroutines](04-subroutines.md)
5. [Memory and pointers](05-memory-and-pointers.md)
6. [Built-in functions](06-builtin-functions.md)
7. [Inline assembly](07-inline-assembly.md)
8. [Blocks, scope, and directives](08-blocks-scope-directives.md)

Complete, compile-tested programs are in [`examples/`](examples/):
`basics.p8`, `controlflow.p8`, `subroutines.p8`, `memory.p8`.

## Building and running

You need the Prog8 compiler (`prog8c.jar`, Java 17+) and `64tass` on your PATH
(both live in this repo's `prog8-sdk/`), and the X16 emulator to run.

```
java -jar prog8c.jar -target cx16 prog8-tutorial/examples/basics.p8
x16emu -prg BASICS.PRG -run
```

## The one caveat: the core language has no I/O

Reading the keyboard or printing text is done by *libraries* (`txt`, `conv`, …)
or the KERNAL. To stay strictly library-free, these examples produce output by
calling the KERNAL's `CHROUT` ($FFD2) directly through inline assembly:

```prog8
sub emit(ubyte ch) {
    %asm {{
        lda  p8v_ch          ; a sub parameter is visible in asm as p8v_<name>
        jsr  $ffd2           ; CHROUT: print the character in A
    }}
}
```

That is the *only* piece of machine-specific glue used. Everything else is pure
language. (Printing a *number* also needs conversion, which the core language
can express itself — see the `emit_hex`/`emit_nibble` helpers in the examples,
which turn a byte into hex digits with nothing but `if`/arithmetic.)

Throughout, "core" means: no `%import`. Built-in functions like `len`, `abs`,
`peek`/`poke`, `msb`/`lsb`, `mkword`, `min`/`max` are part of the language, not
libraries, so they are fair game.
