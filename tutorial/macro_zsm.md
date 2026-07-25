# ZSM Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_ZSM, X16_USE_ZSM_PCM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.zsm_init(header) / cx.zsm_init_stream(stream, loop)`

| Field | Details |
|---|---|
| Macro | `cx.zsm_init(header)` / `cx.zsm_init_stream(stream, loop)` |
| Purpose | `ZSM` gate |
| Input parameters | `header`; `stream, loop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `ZSM` gate
        cx.zsm_init(zsm_header)
        cx.zsm_init_stream(zsm_stream, 1)
    }
}

%asm {{
    zsm_header  !word zsm_stream
    zsm_stream  !byte 0
}}

```

## `cx.zsm_play() / cx.zsm_stop() / cx.zsm_rewind()`

| Field | Details |
|---|---|
| Macro | `cx.zsm_play()` / `cx.zsm_stop()` / `cx.zsm_rewind()` |
| Purpose | `ZSM` gate |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `ZSM` gate
        cx.zsm_play()
        cx.zsm_stop()
        cx.zsm_rewind()
    }
}

```

## `cx.zsm_get_tickrate() / cx.zsm_status() / cx.zsm_tick()`

| Field | Details |
|---|---|
| Macro | `cx.zsm_get_tickrate()` / `cx.zsm_status()` / `cx.zsm_tick()` |
| Purpose | `ZSM` gate |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `ZSM` gate
        cx.zsm_get_tickrate()
        cx.zsm_status()
        cx.zsm_tick()
    }
}

```

## `cx.zsm_pcm_present() / cx.zsm_pcm_trigger(instrument)`

| Field | Details |
|---|---|
| Macro | `cx.zsm_pcm_present()` / `cx.zsm_pcm_trigger(instrument)` |
| Purpose | `ZSM_PCM` gate |
| Input parameters | `instrument` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `ZSM_PCM` gate
        cx.zsm_pcm_present()
        cx.zsm_pcm_trigger(0)
    }
}

```
