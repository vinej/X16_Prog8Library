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
        cx.pcm_ctrl(byte)
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
        cx.pcm_put(sample)
    }
}
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
        cx.pcm_stream_start(src, count, loop)
    }
}
```
