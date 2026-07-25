# PCM Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_PCM, X16_USE_PCM_STREAM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.pcm_ctrl(byte) / cx.pcm_rate(rate) / cx.pcm_reset()`

| Field | Details |
|---|---|
| Macro | `cx.pcm_ctrl(byte)` / `cx.pcm_rate(rate)` / `cx.pcm_reset()` |
| Purpose | `PCM` gate |
| Input parameters | `byte`; `rate` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `PCM` gate
        cx.pcm_ctrl('A')
        cx.pcm_rate(1)
        cx.pcm_reset()
    }
}

```

## `cx.pcm_put(sample) / cx.pcm_write(src, count)`

| Field | Details |
|---|---|
| Macro | `cx.pcm_put(sample)` / `cx.pcm_write(src, count)` |
| Purpose | `PCM` gate |
| Input parameters | `sample`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `PCM` gate
        cx.pcm_put(1)
        cx.pcm_write(sample_data, 32)
    }
}

%asm {{
    sample_data !byte $80, $88, $90, $88, $80, $78, $70, $78
}}

```

## `cx.pcm_stream_start(src, count, loop) / cx.pcm_stream_stop()`

| Field | Details |
|---|---|
| Macro | `cx.pcm_stream_start(src, count, loop)` / `cx.pcm_stream_stop()` |
| Purpose | `PCM_STREAM` gate |
| Input parameters | `src, count, loop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; `PCM_STREAM` gate
        cx.pcm_stream_start(sample_data, 32, 1)
        cx.pcm_stream_stop()
    }
}

%asm {{
    sample_data !byte $80, $88, $90, $88, $80, $78, $70, $78
}}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of pcm

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.pcm_full()`

| Field | Details |
|---|---|
| Macro | `cx.pcm_full()` |
| Purpose | carry set if the FIFO cannot take another byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_PCM` is enabled. |

## `cx.pcm_empty()`

| Field | Details |
|---|---|
| Macro | `cx.pcm_empty()` |
| Purpose | carry set if the FIFO has run dry |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_PCM` is enabled. |

## `cx.pcm_stream_active()`

| Field | Details |
|---|---|
| Macro | `cx.pcm_stream_active()` |
| Purpose | A = 1 while data remains, 0 when the whole |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_PCM_STREAM` is enabled. |

## `cx.pcm_stream_start_bank(offset, count, counthi, bank, rate)`

| Field | Details |
|---|---|
| Macro | `cx.pcm_stream_start_bank(offset, count, counthi, bank, rate)` |
| Purpose | play a sample living in banked RAM |
| Input parameters | `offset`, `count`, `counthi`, `bank`, `rate` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_PCM_STREAM` is enabled. |
