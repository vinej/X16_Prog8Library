# Float Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_FLOAT` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `FAC / addr`

| Field | Details |
|---|---|
| Macro | `FAC` / `addr` |
| Purpose | accumulator / pointer to a 5-byte float in memory |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `f_sqrt, f_sin, f_ln, f_int, ...`

| Field | Details |
|---|---|
| Macro | `f_sqrt`, `f_sin`, `f_ln`, `f_int`, ... |
| Purpose | argument-free unary routines; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `cx.f_from_u8(byte) / cx.f_from_s16(value)`

| Field | Details |
|---|---|
| Macro | `cx.f_from_u8(byte)` / `cx.f_from_s16(value)` |
| Purpose | build FAC from an integer |
| Input parameters | `byte`; `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_from_u8(byte)
    }
}
```

## `cx.f_from_str(str, len)`

| Field | Details |
|---|---|
| Macro | `cx.f_from_str(str, len)` |
| Purpose | parse a string into FAC |
| Input parameters | `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_from_str(str, len)
    }
}
```

## `cx.f_load(addr) / cx.f_store(addr)`

| Field | Details |
|---|---|
| Macro | `cx.f_load(addr)` / `cx.f_store(addr)` |
| Purpose | FAC <-> memory |
| Input parameters | `addr` |
| Output parameters | memory |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_load(addr)
    }
}
```

## `cx.f_add / _sub / _mul / _div addr`

| Field | Details |
|---|---|
| Macro | `cx.f_add / _sub / _mul / _div addr` |
| Purpose | FAC op mem |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_add()
    }
}
```

## `cx.f_rsub(addr) / cx.f_rdiv(addr)`

| Field | Details |
|---|---|
| Macro | `cx.f_rsub(addr)` / `cx.f_rdiv(addr)` |
| Purpose | mem - FAC / mem / FAC |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_rsub(addr)
    }
}
```

## `cx.f_pow(addr)`

| Field | Details |
|---|---|
| Macro | `cx.f_pow(addr)` |
| Purpose | FAC = FAC ^ mem |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_pow(addr)
    }
}
```

## `cx.f_cmp(addr)`

| Field | Details |
|---|---|
| Macro | `cx.f_cmp(addr)` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `addr` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.f_cmp(addr)
    }
}
```
