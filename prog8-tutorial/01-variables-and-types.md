# 1. Variables and types

Prog8 is statically typed. Types map directly onto how the 6502 stores data, so
choosing the right one is choosing the machine representation.

## The numeric types

| Type | Size | Range |
|---|---|---|
| `ubyte` | 1 byte | 0 … 255 |
| `byte` | 1 byte | −128 … 127 |
| `uword` | 2 bytes | 0 … 65535 |
| `word` | 2 bytes | −32768 … 32767 |
| `long` | 4 bytes | signed 32-bit (compile-time / limited runtime) |
| `float` | 5 bytes | 6502 ROM float (needs the floats lib to do much) |
| `bool` | 1 byte | `true` / `false` |

```prog8
ubyte count = 5
byte  delta = -3
uword total = 1000
bool  ready = true
```

A variable with no initializer starts at zero:

```prog8
ubyte x            ; == 0
uword addr         ; == 0
```

## Constants

`const` values are folded at compile time and take no memory:

```prog8
const ubyte WIDTH  = 40
const uword SCREEN = $0400
const ubyte AREA   = WIDTH * 5      ; computed at compile time
```

## Number literals

```prog8
ubyte a = 255           ; decimal
ubyte b = $FF           ; hex
ubyte c = %11111111     ; binary
ubyte d = 'A'           ; character -> its byte value ($41)
uword e = $C000
```

## Strings

`str` is a NUL-terminated array of bytes:

```prog8
str title = "prog8 core"
str greet = "hi\n"          ; \n, \r, \" etc. are understood
```

`&title` is the address of the string; `len(title)` is its length (excluding the
terminator). Encoding matters: by default a string is PETSCII. Prefixes pick
another encoding — `sc:"..."` (screencodes), `iso:"..."` (ISO/Latin-1). See the
[memory page](05-memory-and-pointers.md) for reading a string byte by byte.

## Arrays

Fixed-size, typed, zero-based:

```prog8
ubyte[5] scores = [10, 20, 30, 40, 50]
uword[3] addrs  = [$1000, $2000, $3000]
ubyte[] primes  = [2, 3, 5, 7, 11]      ; size inferred from the initializer
ubyte[16] buffer                        ; all zero

ubyte first = scores[0]
scores[2] = 99
ubyte n = len(scores)                   ; 5
```

## Type conversions

Prog8 will *not* silently narrow. Widening (ubyte → uword) is automatic; going
the other way, or mixing signedness, needs an explicit `as`:

```prog8
ubyte small = 200
uword big   = small            ; ok, widening is implicit
ubyte back  = big as ubyte     ; explicit narrowing (keeps the low byte)
byte  s     = -3
ubyte u     = s as ubyte       ; reinterpret the bits (-> 253)
```

Try it: [`examples/basics.p8`](examples/basics.p8) declares each of these and
prints an array in hex.

Next: [Operators and expressions →](02-operators-and-expressions.md)
