# 2. Operators and expressions

## Arithmetic

```prog8
ubyte a = 10
ubyte b = 3
ubyte s = a + b        ; 13
ubyte d = a - b        ; 7
ubyte m = a * b        ; 30
ubyte q = a / b        ; 3   (integer division)
ubyte r = a % b        ; 1   (remainder)
```

There is no `**` power operator; multiply, or use a built-in like `sqrt`.

## Bitwise vs. logical

Keep these two families separate — bitwise work on the bits of an integer,
logical work on truth values.

| Bitwise | | Logical | |
|---|---|---|---|
| `&` | and | `and` | logical and |
| `\|` | or | `or` | logical or |
| `^` | xor | `xor` | logical xor |
| `~` | not (complement) | `not` | logical not |
| `<<` `>>` | shift left / right | | |

```prog8
ubyte flags = %10110000
ubyte hi    = flags >> 4          ; %00001011
ubyte set   = flags | %00000001   ; set bit 0
ubyte clr   = flags & %11111110   ; clear bit 0
bool  ok    = (a > 0) and (b > 0) ; logical
```

Shifts by a constant are cheap; the compiler turns `x >> 4` into repeated shifts,
or a nibble swap where it can.

## Comparisons

`==  !=  <  >  <=  >=` — they yield a `bool`:

```prog8
if count >= WIDTH { ... }
bool equal = (x == y)
```

## Containment: `in`

Test membership in an array or range without a loop:

```prog8
ubyte key = 7
if key in [1, 3, 5, 7, 9]
    emit('o')
if key in 0 to 9
    emit('d')
```

## Address-of and low/high bytes

- `&thing` — the address of a variable, array, string, or sub.
- `lsb(w)` / `msb(w)` — the low / high byte of a word (see [built-ins](06-builtin-functions.md)).

```prog8
uword p = &title           ; pointer to the string
ubyte lo = lsb(p)
ubyte hi = msb(p)
```

## Casts in expressions

Mixed-type or narrowing arithmetic needs `as`:

```prog8
ubyte count = 5
uword total = 1000
total += count as uword        ; widen the ubyte to add it to a uword
ubyte low = (total & $00ff) as ubyte
```

## Assignment shortcuts

```prog8
x += 2        x -= 2
x *= 3        x /= 3
x <<= 1       x >>= 1
x &= mask     x |= bit
x++           x--
```

Prog8 has no chained assignment (`a = b = 0`) and no comma expressions — one
statement does one thing, which keeps the generated 6502 predictable.

Next: [Control flow →](03-control-flow.md)
