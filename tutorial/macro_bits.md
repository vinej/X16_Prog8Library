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
        cx.catnib(hi, lo)
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
        cx.hinib(byte)
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
        cx.bit_set(addr, mask)
    }
}
```
