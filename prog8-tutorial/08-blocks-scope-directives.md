# 8. Blocks, scope, and directives

## Blocks

A program is organized into **blocks**. `main` is special — execution starts at
`main.start`. Blocks group related code and data and form a namespace:

```prog8
main {
    sub start() {
        counter.reset()
        counter.bump()
    }
}

counter {
    ubyte value

    sub reset() { value = 0 }
    sub bump()  { value++ }
}
```

Refer to another block's symbol with `block.name` (`counter.value`,
`counter.bump()`). Inside a block you can use the short name.

A block can be given a fixed load address:

```prog8
mydata $C000 {
    ubyte[256] table
}
```

## Scope

- **Block-level** variables live for the whole program (like globals, but
  namespaced by their block).
- **Sub-level** variables are local to the subroutine.
- Names resolve inner-to-outer: a local shadows a block variable of the same name.

## The common directives

Directives start with `%`. The core (library-free) ones:

| Directive | What it does |
|---|---|
| `%zeropage basicsafe` | zero-page policy: `basicsafe` keeps BASIC alive, `kernalsafe`, `floatsafe`, `dontuse`, `full` |
| `%address $0801` | set the program load address (default `$0801` on cx16) |
| `%option no_sysinit` | skip the standard startup init |
| `%option ignore_unused` | don't warn about unused symbols in this block |
| `%asm {{ ... }}` | inline assembly (see [page 7](07-inline-assembly.md)) |
| `%asminclude` / `%asmbinary` | include asm source / a raw binary |
| `%import name` | pull in a library — the one thing this tutorial avoids |

```prog8
%zeropage basicsafe
%option no_sysinit

main {
    sub start() {
        ...
    }
}
```

## `%import` — the boundary of "core"

`%import` is how you leave the core language and bring in a library — `txt` for
text I/O, `math` for `rnd`/trig, `diskio` for files, `floats` for floating point,
and so on. Everything in this tutorial deliberately stops at that boundary: no
`%import` appears in any example.

When you're ready to go further, the same skills carry straight over — a library
call like `txt.print("hi")` is just a subroutine in another block. And the
X16-library wrapper in this repo (`%import x16lib`) gives you the Commander X16's
whole hardware surface with the same `block.routine()` calling style you learned
here.

---

That's the core language. Revisit the compile-tested programs in
[`examples/`](examples/), change them, and watch what the compiler does — reading
the generated `.asm` next to your `.p8` is one of the best ways to learn how Prog8
turns each construct into 6502.
