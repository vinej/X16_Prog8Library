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
        cx.u16_to_dec(value)
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
        cx.dec_to_u16(str, len)
    }
}
```
