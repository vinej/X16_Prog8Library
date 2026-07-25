# Interrupts Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_IRQ` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.irq_install() / cx.irq_remove()`

| Field | Details |
|---|---|
| Macro | `cx.irq_install()` / `cx.irq_remove()` |
| Purpose | hook / unhook the frame counter |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; hook / unhook the frame counter
        cx.irq_install()
        cx.irq_remove()
    }
}

```

## `cx.vsync_wait()`

| Field | Details |
|---|---|
| Macro | `cx.vsync_wait()` |
| Purpose | block until the next frame boundary |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; block until the next frame boundary
        cx.vsync_wait()
    }
}

```

## `cx.irq_line_install(handler)`

| Field | Details |
|---|---|
| Macro | `cx.irq_line_install(handler)` |
| Purpose | call a handler at a scanline |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; call a handler at a scanline
        cx.irq_line_install(1)
    }
}

```

## `cx.irq_sprcol_install(handler (handler = 0 polls)) / cx.irq_sprcol_remove()`

| Field | Details |
|---|---|
| Macro | `cx.irq_sprcol_install(handler)` (`handler` = 0 polls) / `cx.irq_sprcol_remove()` |
| Purpose | sprite-collision interrupt |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; sprite-collision interrupt
        cx.irq_sprcol_install(1)
        cx.irq_sprcol_remove()
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of irq

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.irq_line_remove()`

| Field | Details |
|---|---|
| Macro | `cx.irq_line_remove()` |
| Purpose | stop the raster-line interrupt and acknowledge any pending one |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `cx.irq_save_regs()`

| Field | Details |
|---|---|
| Macro | `cx.irq_save_regs()` |
| Purpose | bracket a callback that calls |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `cx.irq_restore_regs()`

| Field | Details |
|---|---|
| Macro | `cx.irq_restore_regs()` |
| Purpose | bracket a callback that calls |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `cx.irq_frames()`

| Field | Details |
|---|---|
| Macro | `cx.irq_frames()` |
| Purpose | Byte subtraction wraps correctly, so deltas are valid across the wrap: |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `cx.sprite_collisions()`

| Field | Details |
|---|---|
| Macro | `cx.sprite_collisions()` |
| Purpose | read and clear the accumulated collision groups |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_IRQ_SPRCOL_API` is enabled. |
