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
        ; map a RAM bank at `$A000`
        cx.bank_set(1)
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
        ; one byte
        cx.bank_peek(1, 0)
        cx.bank_poke(1, 0, 'A')
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
        ; copy low RAM into a bank
        cx.mem_to_bank(pixel_run, 1, 0, 32)
    }
}

%asm {{
    pixel_run   !byte 1, 2, 3, 4, 4, 3, 2, 1
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of bank

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.bank_get()`

| Field | Details |
|---|---|
| Macro | `cx.bank_get()` |
| Purpose | the RAM bank mapped at $A000 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BANK` is enabled. |

## `cx.bank_to_mem(bank, offset, dst, count)`

| Field | Details |
|---|---|
| Macro | `cx.bank_to_mem(bank, offset, dst, count)` |
| Purpose | the inverse |
| Input parameters | `bank`, `offset`, `dst`, `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BANK` is enabled. |

## `cx.bank_copy_far(srcbank, srcoff, dstbank, dstoff, count)`

| Field | Details |
|---|---|
| Macro | `cx.bank_copy_far(srcbank, srcoff, dstbank, dstoff, count)` |
| Purpose | copy banked RAM to banked RAM |
| Input parameters | `srcbank`, `srcoff`, `dstbank`, `dstoff`, `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BANK` is enabled. |
