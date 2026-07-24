# 3. Control flow

Everything here is in [`examples/controlflow.p8`](examples/controlflow.p8), which
compiles and runs with no imports.

## if / else

Braces are optional for a single statement:

```prog8
if n < 5
    emit('L')
else if n < 10
    emit('M')
else
    emit('H')
```

With a block:

```prog8
if ready {
    emit('!')
    count++
}
```

## when — the clean multi-way branch

`when` compares one value against several cases (it compiles to an efficient
jump, not a chain of `if`s):

```prog8
when n {
    0            -> emit('z')
    1, 3, 5, 7, 9 -> emit('o')      ; several values share a branch
    10 to 20     -> emit('r')       ; a range
    else         -> emit('e')
}
```

## for

Over a range, optionally with `step` (or `downto`):

```prog8
ubyte i
for i in 0 to 8 step 2 {
    emit('0' + i)
}
for i in 10 downto 1 {
    ...
}
```

Over an array or string — the loop variable takes each element:

```prog8
ubyte[] primes = [2, 3, 5, 7, 11]
for i in primes {
    emit_hex(i)
}
```

## while and do-until

```prog8
while c != 0 {
    emit('*')
    c--
}

do {
    emit('.')
    c++
} until c == 3
```

## repeat

A fixed count, or an open loop you leave with `break`:

```prog8
repeat 4 {
    emit('=')
}

repeat {
    c++
    if c == 2 continue      ; skip to the next iteration
    emit('0' + c)
    if c == 5 break         ; leave the loop
}
```

## unroll

`unroll` repeats a *short* body inline at compile time — no loop overhead, bigger
code. Handy for tight copy/fill loops:

```prog8
unroll 8 {
    emit('=')               ; body is emitted 8 times, straight-line (no counter)
}
```

## break, continue, goto

`break` and `continue` work in `for`, `while`, `do`, and `repeat`. `goto` exists
(jumps to a label) but is rarely needed:

```prog8
mylabel:
    ...
    goto mylabel
```

Next: [Subroutines →](04-subroutines.md)
