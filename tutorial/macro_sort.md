# Sort Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SORT` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

The sort routines order a contiguous block of fixed-size elements **in place**,
ascending. There is no array "type" — you pass a base address and an element
count, which is exactly what a high-level array is underneath. Insertion sort:
small, stable, and dependency-free.

## `cx.sort_u8(ptr, count)` / `cx.sort_s8(ptr, count)`

| Field | Details |
|---|---|
| Macro | `cx.sort_u8(ptr, count)` / `cx.sort_s8(ptr, count)` |
| Purpose | sort `count` bytes at `ptr` in place — unsigned (`u8`) or signed (`s8`) |
| Input parameters | `ptr`: base address; `count`: element count |
| Output parameters | The block is sorted in place. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sort_u8(mydata, 8)
    }
}


%asm {{
    mydata !byte 5, 3, 8, 1, 9, 2, 7, 4
}}
```

## `cx.sort_u16(ptr, count)` / `cx.sort_s16(ptr, count)`

| Field | Details |
|---|---|
| Macro | `cx.sort_u16(ptr, count)` / `cx.sort_s16(ptr, count)` |
| Purpose | sort `count` words (2 bytes each) at `ptr` — unsigned or signed |
| Input parameters | `ptr`: base address; `count`: element count |
| Output parameters | The block is sorted in place. |

## `cx.sort_ptr(ptr, count, cmp)`

| Field | Details |
|---|---|
| Macro | `cx.sort_ptr(ptr, count, cmp)` |
| Purpose | sort `count` 2-byte elements using a caller-supplied comparator |
| Input parameters | `ptr`: base address; `count`: element count; `cmp`: comparator routine address |
| Output parameters | The pointer array is permuted in place. |
| More info | The comparator receives element A's address in `X16_PTR2` (P4/P5) and element B's in `X16_PTR3` (P6/P7), and returns carry **set** if A must sort after B (A > B). This is the general engine behind the typed sorts; use it for records, reverse order, or custom keys. To sort an array of *string* pointers, the STRING module's `str_sort` binds this to `str_compare`. |
