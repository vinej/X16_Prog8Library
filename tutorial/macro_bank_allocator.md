# Bank allocator Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BANKALLOC` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.bank_alloc_init(first, last)`

| Field | Details |
|---|---|
| Macro | `cx.bank_alloc_init(first, last)` |
| Purpose | initialize allocator range |
| Input parameters | `first, last` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_alloc_init(first, last)
    }
}
```

## `cx.bank_alloc()`

| Field | Details |
|---|---|
| Macro | `cx.bank_alloc()` |
| Purpose | allocate one bank; -> carry clear, A = bank |
| Input parameters | No macro arguments. |
| Output parameters | carry clear, A = bank |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_alloc()
    }
}
```

## `cx.bank_free(bank)`

| Field | Details |
|---|---|
| Macro | `cx.bank_free(bank)` |
| Purpose | free one bank |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_free(bank)
    }
}
```

## `cx.bank_reserve(bank)`

| Field | Details |
|---|---|
| Macro | `cx.bank_reserve(bank)` |
| Purpose | reserve one bank |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.bank_reserve(bank)
    }
}
```
