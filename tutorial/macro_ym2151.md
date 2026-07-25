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
        ; reset the chip, load the default patches
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
        ; raw register write / shadowed write
        cx.ym_write($20, $20)
        cx.ym_poke($20, $20)
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
        ; load a built-in ROM patch (0-162)
        cx.ym_patch_rom(0, 1)
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
        ; play a raw key code
        cx.ym_note(0, $4c, 0)
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
        ; play a packed note (0 releases)
        cx.ym_note_bas(0, 60)
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
        ; release
        cx.ym_release_note(0)
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
        ; volume / pan
        cx.ym_vol(0, 1)
        cx.ym_pan(0, $c0)
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
        ; a drum voice
        cx.ym_drum(0, 60)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of ym

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.ym_busy()`

| Field | Details |
|---|---|
| Macro | `cx.ym_busy()` |
| Purpose | carry set while the chip is busy |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_YM` is enabled. |

## `cx.ym_get_pan(channel)`

| Field | Details |
|---|---|
| Macro | `cx.ym_get_pan(channel)` |
| Purpose | X = pan setting |
| Input parameters | `channel` |
| Output parameters | Returns `X`. |
| More info | Available when `X16_USE_YM` is enabled. |

## `cx.ym_get_vol(channel)`

| Field | Details |
|---|---|
| Macro | `cx.ym_get_vol(channel)` |
| Purpose | X = attenuation |
| Input parameters | `channel` |
| Output parameters | Returns `X`. |
| More info | Available when `X16_USE_YM` is enabled. |

## `cx.ym_patch_ram(channel, addr)`

| Field | Details |
|---|---|
| Macro | `cx.ym_patch_ram(channel, addr)` |
| Purpose | load an instrument |
| Input parameters | `channel`, `addr` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_YM` is enabled. |
