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
        ; Store a calculated value in memory, then load it again later.
        cx.f_from_s16(250)
        cx.f_store(saved_float)
        cx.f_load(saved_float)
    }
}

%asm {{
    saved_float !fill 5, 0
}}

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
        ; The unary routines operate directly on FAC after a loader macro.
        cx.f_from_s16(144)
        %asm {{
            jsr f_sqrt
            jsr f_to_str_trim
        }}
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
        ; build FAC from an integer
        cx.f_from_u8('A')
        cx.f_from_s16($1234)
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
        ; parse a string into FAC
        cx.f_from_str(source_text, 16)
    }
}

%asm {{
    source_text  !text "LEVEL/01", 0
}}

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
        ; FAC <-> memory
        cx.f_load(work_buffer)
        cx.f_store(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; FAC op mem
        cx.f_add(work_buffer)
        cx.f_sub(work_buffer)
        cx.f_mul(work_buffer)
        cx.f_div(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; mem - FAC / mem / FAC
        cx.f_rsub(work_buffer)
        cx.f_rdiv(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; FAC = FAC ^ mem
        cx.f_pow(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

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
        ; -> A = -1 / 0 / 1
        cx.f_cmp(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of float

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.f_zero()`

| Field | Details |
|---|---|
| Macro | `cx.f_zero()` |
| Purpose | FAC = 0 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_neg()`

| Field | Details |
|---|---|
| Macro | `cx.f_neg()` |
| Purpose | FAC = -FAC |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_abs()`

| Field | Details |
|---|---|
| Macro | `cx.f_abs()` |
| Purpose | FAC = |FAC| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_int()`

| Field | Details |
|---|---|
| Macro | `cx.f_int()` |
| Purpose | FAC = int(FAC), truncating toward negative infinity |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_sgn()`

| Field | Details |
|---|---|
| Macro | `cx.f_sgn()` |
| Purpose | A = $FF if FAC < 0, 0 if zero, 1 if positive |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_to_s16()`

| Field | Details |
|---|---|
| Macro | `cx.f_to_s16()` |
| Purpose | -- out: A = low, X = high.    Rounds toward zero |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_sqrt()`

| Field | Details |
|---|---|
| Macro | `cx.f_sqrt()` |
| Purpose | FAC = the square root of FAC |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_ln()`

| Field | Details |
|---|---|
| Macro | `cx.f_ln()` |
| Purpose | FAC = the natural logarithm of FAC |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_exp()`

| Field | Details |
|---|---|
| Macro | `cx.f_exp()` |
| Purpose | FAC = e raised to FAC |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_sin()`

| Field | Details |
|---|---|
| Macro | `cx.f_sin()` |
| Purpose | FAC = the sine of FAC, in radians |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_cos()`

| Field | Details |
|---|---|
| Macro | `cx.f_cos()` |
| Purpose | FAC = the cosine of FAC, in radians |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_tan()`

| Field | Details |
|---|---|
| Macro | `cx.f_tan()` |
| Purpose | FAC = the tangent of FAC, in radians |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_atan()`

| Field | Details |
|---|---|
| Macro | `cx.f_atan()` |
| Purpose | FAC = the arctangent of FAC, in radians |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_to_str()`

| Field | Details |
|---|---|
| Macro | `cx.f_to_str()` |
| Purpose | A = low, X = high of a NUL-terminated string |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_to_str_trim()`

| Field | Details |
|---|---|
| Macro | `cx.f_to_str_trim()` |
| Purpose | A = low, X = high, the string without that space |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_FLOAT` is enabled. |

## `cx.f_rpow(addr)`

| Field | Details |
|---|---|
| Macro | `cx.f_rpow(addr)` |
| Purpose | the ROM's order |
| Input parameters | `addr` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_FLOAT` is enabled. |
