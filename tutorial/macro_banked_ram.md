# Banked RAM Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BANK` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.bank_set(bank)`

| Field | Details |
|---|---|
| Macro | `cx.bank_set(bank)` |
| Purpose | map a RAM bank at `$A000` |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_set(bank)
    }
}
```

## `cx.bank_peek(bank, offset (-msb(A) = byte)) / cx.bank_poke(bank, offset, byte)`

| Field | Details |
|---|---|
| Macro | `cx.bank_peek(bank, offset)` (-> A = byte) / `cx.bank_poke(bank, offset, byte)` |
| Purpose | one byte |
| Input parameters | `bank, offset`; `bank, offset, byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_peek(bank, offset)
    }
}
```

## `cx.mem_to_bank(src, bank, offset, count)`

| Field | Details |
|---|---|
| Macro | `cx.mem_to_bank(src, bank, offset, count)` |
| Purpose | copy low RAM into a bank |
| Input parameters | `src, bank, offset, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.mem_to_bank(src, bank, offset, count)
    }
}
```
