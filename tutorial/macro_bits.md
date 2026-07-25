# Bits Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BITS` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.catnib(hi, lo)`

| Field | Details |
|---|---|
| Macro | `cx.catnib(hi, lo)` |
| Purpose | combine two nibbles |
| Input parameters | `hi, lo` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; combine two nibbles
        cx.catnib($0f, $00)
    }
}

```

## `cx.hinib(byte) / cx.lonib(byte)`

| Field | Details |
|---|---|
| Macro | `cx.hinib(byte)` / `cx.lonib(byte)` |
| Purpose | extract high/low nibble |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; extract high/low nibble
        cx.hinib('A')
        cx.lonib('A')
    }
}

```

## `cx.bit_set(addr, mask) / cx.bit_clr(addr, mask) / cx.bit_test(addr, mask)`

| Field | Details |
|---|---|
| Macro | `cx.bit_set(addr, mask)` / `cx.bit_clr(addr, mask)` / `cx.bit_test(addr, mask)` |
| Purpose | bit operations |
| Input parameters | `addr, mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; bit operations
        cx.bit_set(work_buffer, $01)
        cx.bit_clr(work_buffer, $01)
        cx.bit_test(work_buffer, $01)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of bits

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.bit_put(addr, mask, set)`

| Field | Details |
|---|---|
| Macro | `cx.bit_put(addr, mask, set)` |
| Purpose | -- in: X16_PTR0 = address, A = mask, |
| Input parameters | `addr`, `mask`, `set` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BITS` is enabled. |
