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
        cx.irq_install()
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
        cx.irq_line_install(handler)
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
        cx.irq_sprcol_install(handler)
    }
}
```
