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
        ; see macro listing above
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
        cx.i16_from_u8(byte)
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
        cx.i32_from_u16(value)
    }
}
```
