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
        ; Store d_ac in memory, then restore it before another operation.
        cx.d_from_s16(250)
        cx.d_store(saved_double)
        cx.d_load(saved_double)
    }
}

%asm {{
    saved_double !fill 8, 0
}}

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
        ; Unary double routines consume and replace d_ac directly.
        cx.d_from_s16(144)
        %asm {{
            jsr d_sqrt
            jsr d_to_str
        }}
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
        ; build d_ac
        cx.d_from_s16($1234)
        cx.d_from_str(source_text, 16)
    }
}

%asm {{
    source_text  !text "LEVEL/01", 0
}}

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
        ; d_ac <-> memory
        cx.d_load(work_buffer)
        cx.d_store(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; d_ac op mem
        cx.d_add(work_buffer)
        cx.d_sub(work_buffer)
        cx.d_mul(work_buffer)
        cx.d_div(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; d_ac = d_ac ^ mem
        cx.d_pow(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; -> A = -1 / 0 / 1
        cx.d_cmp(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of double

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.d_neg()`

| Field | Details |
|---|---|
| Macro | `cx.d_neg()` |
| Purpose | d_ac = -d_ac d_abs -- d_ac = |d_ac| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_abs()`

| Field | Details |
|---|---|
| Macro | `cx.d_abs()` |
| Purpose | d_ac = |d_ac| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_to_s32()`

| Field | Details |
|---|---|
| Macro | `cx.d_to_s32()` |
| Purpose | X16_P0..P3 = (s32) d_ac, truncated toward zero |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_sqrt()`

| Field | Details |
|---|---|
| Macro | `cx.d_sqrt()` |
| Purpose | d_ac = sqrt(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_exp()`

| Field | Details |
|---|---|
| Macro | `cx.d_exp()` |
| Purpose | d_ac = e^d_ac |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_ln()`

| Field | Details |
|---|---|
| Macro | `cx.d_ln()` |
| Purpose | d_ac = ln(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_sin()`

| Field | Details |
|---|---|
| Macro | `cx.d_sin()` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_cos()`

| Field | Details |
|---|---|
| Macro | `cx.d_cos()` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_tan()`

| Field | Details |
|---|---|
| Macro | `cx.d_tan()` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_atan()`

| Field | Details |
|---|---|
| Macro | `cx.d_atan()` |
| Purpose | d_ac = atan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_sinh()`

| Field | Details |
|---|---|
| Macro | `cx.d_sinh()` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_cosh()`

| Field | Details |
|---|---|
| Macro | `cx.d_cosh()` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_tanh()`

| Field | Details |
|---|---|
| Macro | `cx.d_tanh()` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_to_str()`

| Field | Details |
|---|---|
| Macro | `cx.d_to_str()` |
| Purpose | format d_ac as a NUL-terminated decimal string |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `cx.d_from_s32(addr)`

| Field | Details |
|---|---|
| Macro | `cx.d_from_s32(addr)` |
| Purpose | in: X16_P0..P3 = signed 32-bit, little-endian |
| Input parameters | `addr` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |
