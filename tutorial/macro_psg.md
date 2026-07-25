# PSG Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_PSG` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.psg_init()`

| Field | Details |
|---|---|
| Macro | `cx.psg_init()` |
| Purpose | silence all 16 voices |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_init()
    }
}

```

## `cx.psg_set_freq(voice, freq)`

| Field | Details |
|---|---|
| Macro | `cx.psg_set_freq(voice, freq)` |
| Purpose | frequency word |
| Input parameters | `voice, freq` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_set_freq(0, $1f40)
    }
}

```

## `cx.psg_set_vol(voice, vol, pan)`

| Field | Details |
|---|---|
| Macro | `cx.psg_set_vol(voice, vol, pan)` |
| Purpose | volume (0-63) + pan |
| Input parameters | `voice, vol, pan` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_set_vol(0, 48, $c0)
    }
}

```

## `cx.psg_set_wave(voice, wave, width)`

| Field | Details |
|---|---|
| Macro | `cx.psg_set_wave(voice, wave, width)` |
| Purpose | waveform + pulse width |
| Input parameters | `voice, wave, width` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_set_wave(0, $40, 32)
    }
}

```

## `cx.psg_note_off(voice)`

| Field | Details |
|---|---|
| Macro | `cx.psg_note_off(voice)` |
| Purpose | volume to zero, keep the rest |
| Input parameters | `voice` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_note_off(0)
    }
}

```

## `cx.psg_env_start / _release / _stop voice`

| Field | Details |
|---|---|
| Macro | `cx.psg_env_start / _release / _stop voice` |
| Purpose | ASR envelope control |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_env_start(0)
        cx.psg_env_release(0)
        cx.psg_env_stop(0)
    }
}

```

## `cx.psg_env_tick()`

| Field | Details |
|---|---|
| Macro | `cx.psg_env_tick()` |
| Purpose | advance every armed envelope (once a frame) |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Prepare voice 0 for a short confirmation beep.
        cx.psg_env_tick()
    }
}

```
