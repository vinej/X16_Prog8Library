# Buffers Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_BUFFERS` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.rb_init() / cx.rb_count()`

| Field | Details |
|---|---|
| Macro | `cx.rb_init()` / `cx.rb_count()` |
| Purpose | ring buffer init / count |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.rb_init()
    }
}
```

## `cx.rb_put(byte)`

| Field | Details |
|---|---|
| Macro | `cx.rb_put(byte)` |
| Purpose | ring buffer put; -> carry set = full |
| Input parameters | `byte` |
| Output parameters | carry set = full |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.rb_put(byte)
    }
}
```

## `cx.rb_get()`

| Field | Details |
|---|---|
| Macro | `cx.rb_get()` |
| Purpose | ring buffer get; -> A = byte, carry set = empty |
| Input parameters | No macro arguments. |
| Output parameters | A = byte, carry set = empty |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.rb_get()
    }
}
```

## `cx.stk_init() / cx.stk_push(byte) / cx.stk_pop() / cx.stk_depth()`

| Field | Details |
|---|---|
| Macro | `cx.stk_init()` / `cx.stk_push(byte)` / `cx.stk_pop()` / `cx.stk_depth()` |
| Purpose | byte stack helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.stk_init()
    }
}
```
