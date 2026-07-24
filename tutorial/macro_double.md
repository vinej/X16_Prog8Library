# Double Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_DOUBLE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `d_ac / addr`

| Field | Details |
|---|---|
| Macro | `d_ac` / `addr` |
| Purpose | accumulator / pointer to an 8-byte double in memory |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `d_exp, d_sqrt, d_sin, ...`

| Field | Details |
|---|---|
| Macro | `d_exp`, `d_sqrt`, `d_sin`, ... |
| Purpose | argument-free unary routines; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `cx.d_from_s16(value) / cx.d_from_str(str, len)`

| Field | Details |
|---|---|
| Macro | `cx.d_from_s16(value)` / `cx.d_from_str(str, len)` |
| Purpose | build d_ac |
| Input parameters | `value`; `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.d_from_s16(value)
    }
}
```

## `cx.d_load(addr) / cx.d_store(addr)`

| Field | Details |
|---|---|
| Macro | `cx.d_load(addr)` / `cx.d_store(addr)` |
| Purpose | d_ac <-> memory |
| Input parameters | `addr` |
| Output parameters | memory |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.d_load(addr)
    }
}
```

## `cx.d_add / _sub / _mul / _div addr`

| Field | Details |
|---|---|
| Macro | `cx.d_add / _sub / _mul / _div addr` |
| Purpose | d_ac op mem |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.d_add()
    }
}
```

## `cx.d_pow(addr)`

| Field | Details |
|---|---|
| Macro | `cx.d_pow(addr)` |
| Purpose | d_ac = d_ac ^ mem |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.d_pow(addr)
    }
}
```

## `cx.d_cmp(addr)`

| Field | Details |
|---|---|
| Macro | `cx.d_cmp(addr)` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `addr` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.d_cmp(addr)
    }
}
```
