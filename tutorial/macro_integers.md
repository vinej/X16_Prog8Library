# Integers Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_INT16, X16_USE_INT32` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `i16_add, i16_mul, i32_divmod, ...`

| Field | Details |
|---|---|
| Macro | `i16_add`, `i16_mul`, `i32_divmod`, ... |
| Purpose | argument-free routines; load `i16_a`/`i16_b` or `i32_a`/`i32_b`, then `jsr` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Load the integer registers, then call argument-free arithmetic directly.
        cx.i16_const(i16_a, 1000)
        cx.i16_const(i16_b, 7)
        %asm {{
            jsr i16_divmod
        }}

        cx.i32_const(i32_a, 1000000)
        cx.i32_const(i32_b, 7)
        %asm {{
            jsr i32_divmod
        }}
    }
}

```

## `cx.i16_from_u8(byte) / cx.i16_from_s8(byte)`

| Field | Details |
|---|---|
| Macro | `cx.i16_from_u8(byte)` / `cx.i16_from_s8(byte)` |
| Purpose | integer loaders |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; integer loaders
        cx.i16_from_u8('A')
        cx.i16_from_s8('A')
    }
}

```

## `cx.i32_from_u16(value) / cx.i32_from_s16(value)`

| Field | Details |
|---|---|
| Macro | `cx.i32_from_u16(value)` / `cx.i32_from_s16(value)` |
| Purpose | integer loaders |
| Input parameters | `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; integer loaders
        cx.i32_from_u16($1234)
        cx.i32_from_s16($1234)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of int16, int32

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.i16_add()`

| Field | Details |
|---|---|
| Macro | `cx.i16_add()` |
| Purpose | i16_a += i16_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_sub()`

| Field | Details |
|---|---|
| Macro | `cx.i16_sub()` |
| Purpose | i16_a -= i16_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_neg()`

| Field | Details |
|---|---|
| Macro | `cx.i16_neg()` |
| Purpose | i16_a = -i16_a |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_abs()`

| Field | Details |
|---|---|
| Macro | `cx.i16_abs()` |
| Purpose | i16_a = |i16_a| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_shl()`

| Field | Details |
|---|---|
| Macro | `cx.i16_shl()` |
| Purpose | i16_a <<= 1 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_shr()`

| Field | Details |
|---|---|
| Macro | `cx.i16_shr()` |
| Purpose | i16_a >>= 1, logical (zero fill) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_asr()`

| Field | Details |
|---|---|
| Macro | `cx.i16_asr()` |
| Purpose | i16_a >>= 1, arithmetic (sign fill) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_cmpu()`

| Field | Details |
|---|---|
| Macro | `cx.i16_cmpu()` |
| Purpose | unsigned compare i16_a with i16_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_cmps()`

| Field | Details |
|---|---|
| Macro | `cx.i16_cmps()` |
| Purpose | signed compare |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_mul()`

| Field | Details |
|---|---|
| Macro | `cx.i16_mul()` |
| Purpose | i16_a = i16_a * i16_b, modulo 2^16 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_divmod()`

| Field | Details |
|---|---|
| Macro | `cx.i16_divmod()` |
| Purpose | unsigned: i16_a = i16_a / i16_b, i16_r = i16_a % i16_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_divmod_s()`

| Field | Details |
|---|---|
| Macro | `cx.i16_divmod_s()` |
| Purpose | signed divide, truncating toward zero |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_sqrt()`

| Field | Details |
|---|---|
| Macro | `cx.i16_sqrt()` |
| Purpose | floor(sqrt(i16_a)), the ISQRT of FLOAT.TXT |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_to_dec()`

| Field | Details |
|---|---|
| Macro | `cx.i16_to_dec()` |
| Purpose | unsigned i16_a to decimal |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i16_to_dec_s()`

| Field | Details |
|---|---|
| Macro | `cx.i16_to_dec_s()` |
| Purpose | signed i16_a to decimal, with a leading '-' |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_INT16` is enabled. |

## `cx.i32_to_s16()`

| Field | Details |
|---|---|
| Macro | `cx.i32_to_s16()` |
| Purpose | the top two bytes are lost |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_add()`

| Field | Details |
|---|---|
| Macro | `cx.i32_add()` |
| Purpose | i32_a += i32_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_sub()`

| Field | Details |
|---|---|
| Macro | `cx.i32_sub()` |
| Purpose | i32_a -= i32_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_neg()`

| Field | Details |
|---|---|
| Macro | `cx.i32_neg()` |
| Purpose | i32_a = -i32_a |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_abs()`

| Field | Details |
|---|---|
| Macro | `cx.i32_abs()` |
| Purpose | i32_a = |i32_a| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_shl()`

| Field | Details |
|---|---|
| Macro | `cx.i32_shl()` |
| Purpose | i32_a <<= 1 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_shr()`

| Field | Details |
|---|---|
| Macro | `cx.i32_shr()` |
| Purpose | i32_a >>= 1, logical (zero fill) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_asr()`

| Field | Details |
|---|---|
| Macro | `cx.i32_asr()` |
| Purpose | i32_a >>= 1, arithmetic (sign fill) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_cmpu()`

| Field | Details |
|---|---|
| Macro | `cx.i32_cmpu()` |
| Purpose | unsigned compare i32_a with i32_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_cmps()`

| Field | Details |
|---|---|
| Macro | `cx.i32_cmps()` |
| Purpose | signed compare |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_mul()`

| Field | Details |
|---|---|
| Macro | `cx.i32_mul()` |
| Purpose | i32_a = i32_a * i32_b, modulo 2^32 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_divmod()`

| Field | Details |
|---|---|
| Macro | `cx.i32_divmod()` |
| Purpose | unsigned: i32_a = i32_a / i32_b, i32_r = i32_a % i32_b |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_INT32` is enabled. |

## `cx.i32_to_dec()`

| Field | Details |
|---|---|
| Macro | `cx.i32_to_dec()` |
| Purpose | unsigned i32_a to decimal, no leading zeros |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_INT32` is enabled. |
