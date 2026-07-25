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
        ; ring buffer init / count
        cx.rb_init()
        cx.rb_count()
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
        ; ring buffer put; -> carry set = full
        cx.rb_put('A')
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
        ; ring buffer get; -> A = byte, carry set = empty
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
        ; byte stack helpers
        cx.stk_init()
        cx.stk_push('A')
        cx.stk_pop()
        cx.stk_depth()
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## The 8 KB banked stack and ring buffer

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.stack_pop()`

| Field | Details |
|---|---|
| Macro | `cx.stack_pop()` |
| Purpose | pop one byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.stack_popw()`

| Field | Details |
|---|---|
| Macro | `cx.stack_popw()` |
| Purpose | pop one word |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.stack_size()`

| Field | Details |
|---|---|
| Macro | `cx.stack_size()` |
| Purpose | bytes stored = STACK_TOP - sp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.stack_free()`

| Field | Details |
|---|---|
| Macro | `cx.stack_free()` |
| Purpose | bytes free = sp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.stack_isempty()`

| Field | Details |
|---|---|
| Macro | `cx.stack_isempty()` |
| Purpose | sp == STACK_TOP |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.stack_isfull()`

| Field | Details |
|---|---|
| Macro | `cx.stack_isfull()` |
| Purpose | carry set if less than 2 bytes remain |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.ring_get()`

| Field | Details |
|---|---|
| Macro | `cx.ring_get()` |
| Purpose | dequeue one byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.ring_getw()`

| Field | Details |
|---|---|
| Macro | `cx.ring_getw()` |
| Purpose | dequeue one word |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.ring_size()`

| Field | Details |
|---|---|
| Macro | `cx.ring_size()` |
| Purpose | bytes queued = fill |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.ring_free()`

| Field | Details |
|---|---|
| Macro | `cx.ring_free()` |
| Purpose | usable bytes free |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.ring_isempty()`

| Field | Details |
|---|---|
| Macro | `cx.ring_isempty()` |
| Purpose | fill == 0 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.ring_isfull()`

| Field | Details |
|---|---|
| Macro | `cx.ring_isfull()` |
| Purpose | fill >= 8191 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.stack_init(bank)`

| Field | Details |
|---|---|
| Macro | `cx.stack_init(bank)` |
| Purpose | claim a bank and empty the stack |
| Input parameters | `bank` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.ring_init(bank)`

| Field | Details |
|---|---|
| Macro | `cx.ring_init(bank)` |
| Purpose | claim a bank and empty the queue |
| Input parameters | `bank` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.stack_push(byte)`

| Field | Details |
|---|---|
| Macro | `cx.stack_push(byte)` |
| Purpose | push one byte |
| Input parameters | `byte` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.ring_put(byte)`

| Field | Details |
|---|---|
| Macro | `cx.ring_put(byte)` |
| Purpose | enqueue one byte |
| Input parameters | `byte` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `cx.stack_pushw(value)`

| Field | Details |
|---|---|
| Macro | `cx.stack_pushw(value)` |
| Purpose | push one word (low byte first, then high) |
| Input parameters | `value` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `cx.ring_putw(value)`

| Field | Details |
|---|---|
| Macro | `cx.ring_putw(value)` |
| Purpose | enqueue one word (low byte first) |
| Input parameters | `value` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |
