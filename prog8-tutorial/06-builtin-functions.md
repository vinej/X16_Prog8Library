# 6. Built-in functions

These are part of the **language**, not a library — no `%import` needed. The
compiler often turns them into a few inline instructions rather than a call.

## Sizes and lengths

```prog8
ubyte n = len(scores)          ; element count of an array, or string length
ubyte b = sizeof(uword)        ; bytes a type occupies (2)
```

## Bytes and words

```prog8
ubyte lo = lsb($1234)          ; $34  -- low byte of a word
ubyte hi = msb($1234)          ; $12  -- high byte
uword w  = mkword($12, $34)    ; $1234 -- build a word from (msb, lsb)
```

## Arithmetic helpers

```prog8
ubyte m  = max(a, b)
ubyte n  = min(a, b)
ubyte c  = clamp(x, 10, 200)   ; force x into 10..200
byte  s  = sgn(value)          ; -1 / 0 / 1
uword r  = sqrt(65000)         ; integer square root
ubyte a2 = abs(-7 as byte) as ubyte
ubyte q, ubyte r2
q, r2 = divmod(17, 5)          ; quotient and remainder in one call
```

> Note: random numbers (`rnd`, `rndw`) are **not** built-in — they live in the
> `math` library (`%import math`). They're the kind of thing that looks core but
> isn't; when in doubt, the compiler tells you `undefined symbol` and you know an
> import is missing.

## Rotate and bit twiddling

```prog8
rol(x)      ror(x)             ; rotate through carry (in place)
rol2(x)     ror2(x)            ; rotate without carry
setlsb(w, b)   setmsb(w, b)    ; set the low / high byte of a word
```

## Memory (recap from the previous page)

`peek`, `poke`, `peekw`, `pokew`, `memory()` — all built-in.

## Full list

The complete set (there are more — `swap`, `reverse`, `sort`, string helpers via
the stdlib, etc.) is in the Prog8 docs under *Syntax Reference → Built-in
functions*. Anything listed there works without an import; anything else (like
`txt.print`) is a library.

Next: [Inline assembly →](07-inline-assembly.md)
