# Sort Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SORT` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

The sort routines order a contiguous block of fixed-size elements **in place**,
ascending. There is no array "type": you pass a base address and an element
count, which is exactly what a high-level array is underneath. Insertion sort:
small, stable, and dependency-free.

## `cx.sort_u8(ptr, count)` / `cx.sort_s8(ptr, count)`

| Field | Details |
|---|---|
| Macro | `cx.sort_u8(ptr, count)` / `cx.sort_s8(ptr, count)` |
| Purpose | Sort `count` bytes at `ptr` in place, unsigned (`u8`) or signed (`s8`). |
| Input parameters | `ptr`: base address; `count`: element count. |
| Output parameters | The block is sorted in place. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Sort enemy initiative values before the turn scheduler reads them.
        cx.sort_u8(initiative, 6)
    }
}

%asm {{
    initiative !byte 9, 3, 7, 1, 4, 6
}}

```

## `cx.sort_u16(ptr, count)` / `cx.sort_s16(ptr, count)`

| Field | Details |
|---|---|
| Macro | `cx.sort_u16(ptr, count)` / `cx.sort_s16(ptr, count)` |
| Purpose | Sort `count` words at `ptr` in place, unsigned (`u16`) or signed (`s16`). |
| Input parameters | `ptr`: base address; `count`: element count. Each element is two bytes, low byte first. |
| Output parameters | The block is sorted in place. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Sort a high-score table from lowest to highest before insertion.
        cx.sort_u16(score_words, 5)
    }
}

%asm {{
    score_words !word 1200, 300, 950, 1600, 700
}}

```

## `cx.sort_ptr(ptr, count, cmp)`

| Field | Details |
|---|---|
| Macro | `cx.sort_ptr(ptr, count, cmp)` |
| Purpose | Sort `count` 2-byte elements using a caller-supplied comparator. |
| Input parameters | `ptr`: base address; `count`: element count; `cmp`: comparator routine address. |
| Output parameters | The pointer array is permuted in place. |
| More info | The comparator receives element A's address in `X16_PTR2` (`P4/P5`) and element B's in `X16_PTR3` (`P6/P7`), and returns carry **set** if A must sort after B (`A > B`). This is the general engine behind the typed sorts; use it for records, reverse order, or custom keys. To sort an array of *string* pointers, the STRING module's `str_sort` binds this to `str_compare`. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Sort record pointers with your own comparison routine.
        cx.sort_ptr(record_ptrs, 3, compare_records)
    }
}

%asm {{
    compare_records
}}
; Return carry set when record A should come after record B.
%asm {{
    clc
    rts
}}

%asm {{
    record_ptrs !word record_a, record_b, record_c
    record_a    !byte 3
    record_b    !byte 1
    record_c    !byte 2
}}

```
