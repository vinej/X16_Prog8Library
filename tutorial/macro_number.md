# Number Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_NUMBER` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.u16_to_dec(value) / cx.u16_to_hex(value)`

| Field | Details |
|---|---|
| Macro | `cx.u16_to_dec(value)` / `cx.u16_to_hex(value)` |
| Purpose | format unsigned 16-bit; -> A/X = buffer, Y = length |
| Input parameters | `value` |
| Output parameters | A/X = buffer, Y = length |
| More info | Available when `X16_USE_NUMBER` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; format unsigned 16-bit; -> A/X = buffer, Y = length
        cx.u16_to_dec($1234)
        cx.u16_to_hex($1234)
    }
}

```

## `cx.dec_to_u16(str, len)`

| Field | Details |
|---|---|
| Macro | `cx.dec_to_u16(str, len)` |
| Purpose | parse decimal; -> P4/5 = value, carry set on bad digit |
| Input parameters | `str, len` |
| Output parameters | P4/5 = value, carry set on bad digit |
| More info | Available when `X16_USE_NUMBER` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; parse decimal; -> P4/5 = value, carry set on bad digit
        cx.dec_to_u16(source_text, 16)
    }
}

%asm {{
    source_text  !text "LEVEL/01", 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## Packed BCD arithmetic

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.bcd_add8()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_add8()` |
| Purpose | bcd_a += bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_add16()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_add16()` |
| Purpose | bcd_a += bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_add32()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_add32()` |
| Purpose | bcd_a += bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_sub8()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_sub8()` |
| Purpose | bcd_a -= bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_sub16()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_sub16()` |
| Purpose | bcd_a -= bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_sub32()`

| Field | Details |
|---|---|
| Macro | `cx.bcd_sub32()` |
| Purpose | bcd_a -= bcd_b at that width |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_addto(value)`

| Field | Details |
|---|---|
| Macro | `cx.bcd_addto(value)` |
| Purpose | add bcd_b (32-bit) to a 4-byte BCD value in place |
| Input parameters | `value` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |

## `cx.bcd_subfrom(value)`

| Field | Details |
|---|---|
| Macro | `cx.bcd_subfrom(value)` |
| Purpose | subtract bcd_b (32-bit) from a 4-byte BCD value in place |
| Input parameters | `value` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_BCD` is enabled. |
