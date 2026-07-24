# YM2151 Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_YM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.ym_init()`

| Field | Details |
|---|---|
| Macro | `cx.ym_init()` |
| Purpose | reset the chip, load the default patches |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_init()
    }
}
```

## `cx.ym_write(reg, val) / cx.ym_poke(reg, val)`

| Field | Details |
|---|---|
| Macro | `cx.ym_write(reg, val)` / `cx.ym_poke(reg, val)` |
| Purpose | raw register write / shadowed write |
| Input parameters | `reg, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_write(reg, val)
    }
}
```

## `cx.ym_patch_rom(channel, index)`

| Field | Details |
|---|---|
| Macro | `cx.ym_patch_rom(channel, index)` |
| Purpose | load a built-in ROM patch (0-162) |
| Input parameters | `channel, index` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_patch_rom(channel, index)
    }
}
```

## `cx.ym_note(channel, kc, kf)`

| Field | Details |
|---|---|
| Macro | `cx.ym_note(channel, kc, kf)` |
| Purpose | play a raw key code |
| Input parameters | `channel, kc, kf` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_note(channel, kc, kf)
    }
}
```

## `cx.ym_note_bas(channel, note)`

| Field | Details |
|---|---|
| Macro | `cx.ym_note_bas(channel, note)` |
| Purpose | play a packed note (0 releases) |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_note_bas(channel, note)
    }
}
```

## `cx.ym_release_note(channel)`

| Field | Details |
|---|---|
| Macro | `cx.ym_release_note(channel)` |
| Purpose | release |
| Input parameters | `channel` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_release_note(channel)
    }
}
```

## `cx.ym_vol(channel, atten) / cx.ym_pan(channel, pan)`

| Field | Details |
|---|---|
| Macro | `cx.ym_vol(channel, atten)` / `cx.ym_pan(channel, pan)` |
| Purpose | volume / pan |
| Input parameters | `channel, atten`; `channel, pan` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_vol(channel, atten)
    }
}
```

## `cx.ym_drum(channel, note)`

| Field | Details |
|---|---|
| Macro | `cx.ym_drum(channel, note)` |
| Purpose | a drum voice |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ym_drum(channel, note)
    }
}
```
