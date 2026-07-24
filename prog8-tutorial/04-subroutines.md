# 4. Subroutines

See [`examples/subroutines.p8`](examples/subroutines.p8).

## Plain subroutines

```prog8
sub add(ubyte a, ubyte b) -> ubyte {
    return a + b
}

ubyte s = add(30, 12)      ; 42
```

- Parameters are typed; they behave like local variables.
- `-> type` declares a return value; omit it for a sub that returns nothing.
- Call a sub by name with parentheses.

A sub with no return value is just called as a statement:

```prog8
sub newline() {
    emit($0d)
}
newline()
```

## Local variables

Variables declared inside a sub are local to it:

```prog8
sub gcd(ubyte a, ubyte b) -> ubyte {
    while b != 0 {
        ubyte t = b        ; local
        b = a % b
        a = t
    }
    return a
}
```

## Discarding a return value

If a sub returns something you don't want, prefix the call with `void`:

```prog8
void add(1, 2)             ; call for its side effects, ignore the result
```

## Multiple return values

A sub can return several values. Declare the receiving variables first, then
assign to them as a comma list:

```prog8
sub split(ubyte a, ubyte b) -> ubyte, ubyte {
    return a / b, a % b
}

ubyte q
ubyte r
q, r = split(17, 5)                ; q=3, r=2
```

(There is also a built-in `divmod` that does exactly this — remember built-in
names like `divmod`, `len`, `abs` are reserved.)

## asmsub — a sub written in assembly

When you want registers and hand-written code, `asmsub` lets you specify exactly
which register each parameter and return uses. The body is `%asm`:

```prog8
asmsub double(ubyte v @A) -> ubyte @A {
    %asm {{
        asl  a
        rts
    }}
}
```

`@A`, `@X`, `@Y`, `@AX`, `@AY`, `@XY`, and `@Pc` (carry) are the register/flag
slots. This is how you wrap tight machine code with a typed Prog8 signature.

## extsub — a routine at a fixed address

`extsub` declares a subroutine that already exists at a known address (a KERNAL
call, a routine in ROM, or code you placed yourself). Nothing is generated — it's
just a typed name for `jsr <address>`:

```prog8
extsub $FFD2 = CHROUT(ubyte character @A) clobbers(A)
extsub $FFE4 = GETIN() -> ubyte @A clobbers(X, Y)

CHROUT('A')
ubyte key = GETIN()
```

`clobbers(...)` tells the compiler which registers the routine trashes so it can
protect anything it needs across the call.

## inline

A tiny `inline sub` is pasted at each call site instead of being `jsr`'d, trading
size for speed:

```prog8
inline sub hi(uword w) -> ubyte {
    return msb(w)
}
```

Next: [Memory and pointers →](05-memory-and-pointers.md)
