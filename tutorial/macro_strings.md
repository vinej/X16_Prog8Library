# Strings Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_STRING and friends` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Gates / arguments`

| Field | Details |
|---|---|
| Macro | Gates / arguments |
| Purpose | each string gate is separate; `str`/`src`/`dst` are addresses, `ch` and lengths are immediates |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `cx.str_length(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_length(str)` |
| Purpose | -> Y = length |
| Input parameters | `str` |
| Output parameters | Y = length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_length(str)
    }
}
```

## `cx.str_copy(src, dst)`

| Field | Details |
|---|---|
| Macro | `cx.str_copy(src, dst)` |
| Purpose | copy |
| Input parameters | `src, dst` |
| Output parameters | Y = length) |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_copy(src, dst)
    }
}
```

## `cx.str_ncopy(src, dst, max)`

| Field | Details |
|---|---|
| Macro | `cx.str_ncopy(src, dst, max)` |
| Purpose | copy, capped |
| Input parameters | `src, dst, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_ncopy(src, dst, max)
    }
}
```

## `cx.str_append(tgt, suffix)`

| Field | Details |
|---|---|
| Macro | `cx.str_append(tgt, suffix)` |
| Purpose | -> A = new length |
| Input parameters | `tgt, suffix` |
| Output parameters | A = new length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_append(tgt, suffix)
    }
}
```

## `cx.str_nappend(tgt, suffix, max)`

| Field | Details |
|---|---|
| Macro | `cx.str_nappend(tgt, suffix, max)` |
| Purpose | append, capped |
| Input parameters | `tgt, suffix, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_nappend(tgt, suffix, max)
    }
}
```

## `cx.str_compare(s1, s2)`

| Field | Details |
|---|---|
| Macro | `cx.str_compare(s1, s2)` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `s1, s2` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_compare(s1, s2)
    }
}
```

## `cx.str_hash(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_hash(str)` |
| Purpose | -> A = hash |
| Input parameters | `str` |
| Output parameters | A = hash |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_hash(str)
    }
}
```

## `cx.str_lower(str) / cx.str_lower_iso(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_lower(str)` / `cx.str_lower_iso(str)` |
| Purpose | lower-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_lower(str)
    }
}
```

## `cx.str_upper(str) / cx.str_upper_iso(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_upper(str)` / `cx.str_upper_iso(str)` |
| Purpose | upper-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_upper(str)
    }
}
```

## `cx.str_compare_nocase(s1, s2 (+ _iso))`

| Field | Details |
|---|---|
| Macro | `cx.str_compare_nocase(s1, s2)` (+ `_iso`) |
| Purpose | case-insensitive compare |
| Input parameters | `s1, s2` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_compare_nocase(s1, s2)
    }
}
```

## `cx.str_find(str, ch) / cx.str_rfind(str, ch)`

| Field | Details |
|---|---|
| Macro | `cx.str_find(str, ch)` / `cx.str_rfind(str, ch)` |
| Purpose | -> carry + A = index |
| Input parameters | `str, ch` |
| Output parameters | carry + A = index |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_find(str, ch)
    }
}
```

## `cx.str_find_eol(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_find_eol(str)` |
| Purpose | first CR/LF |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_find_eol(str)
    }
}
```

## `cx.str_contains(str, ch)`

| Field | Details |
|---|---|
| Macro | `cx.str_contains(str, ch)` |
| Purpose | -> carry set if present |
| Input parameters | `str, ch` |
| Output parameters | carry set if present |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_contains(str, ch)
    }
}
```

## `cx.str_pattern_match(str, pattern)`

| Field | Details |
|---|---|
| Macro | `cx.str_pattern_match(str, pattern)` |
| Purpose | `?`/`*` match -> carry |
| Input parameters | `str, pattern` |
| Output parameters | carry |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_pattern_match(str, pattern)
    }
}
```

## `cx.str_left(src, dst, len) / cx.str_right(...)`

| Field | Details |
|---|---|
| Macro | `cx.str_left(src, dst, len)` / `cx.str_right(...)` |
| Purpose | copy an end |
| Input parameters | `src, dst, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_left(src, dst, len)
    }
}
```

## `cx.str_slice(src, dst, start, len)`

| Field | Details |
|---|---|
| Macro | `cx.str_slice(src, dst, start, len)` |
| Purpose | copy a middle run |
| Input parameters | `src, dst, start, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_slice(src, dst, start, len)
    }
}
```

## `cx.str_ltrim(str) / cx.str_rtrim(str) / cx.str_trim(str)`

| Field | Details |
|---|---|
| Macro | `cx.str_ltrim(str)` / `cx.str_rtrim(str)` / `cx.str_trim(str)` |
| Purpose | trim whitespace in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.str_ltrim(str)
    }
}
```

## `str_isdigit, str_lowerchar, ...`

| Field | Details |
|---|---|
| Macro | `str_isdigit`, `str_lowerchar`, ... |
| Purpose | character already in `A`; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```
