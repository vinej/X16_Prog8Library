# ROM audio Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_AUDIO_ROM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Scope`

| Field | Details |
|---|---|
| Macro | Scope |
| Purpose | thin ROM `BANK_AUDIO` wrappers; separate from local PSG/YM modules |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `cx.ar_audio_init, cx.ar_playstring_voice voice`

| Field | Details |
|---|---|
| Macro | `cx.ar_audio_init()`, `cx.ar_playstring_voice(voice)` |
| Purpose | general ROM audio helpers |
| Input parameters | `voice` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_audio_init()
    }
}
```

## `cx.ar_fmplaystring(str, len, cx.ar_fmchordstring str, len, cx.ar_psgplaystring str, len, cx.ar_psgchordstring str, len)`

| Field | Details |
|---|---|
| Macro | `cx.ar_fmplaystring(str, len)`, `cx.ar_fmchordstring(str, len)`, `cx.ar_psgplaystring(str, len)`, `cx.ar_psgchordstring(str, len)` |
| Purpose | play strings/chords |
| Input parameters | `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_fmplaystring(str, len)
    }
}
```

## `cx.ar_fmfreq(channel, hz, cx.ar_fmfreq_no_retrigger channel, hz, cx.ar_fmnote channel, note, kf, cx.ar_fmnote_no_retrigger channel, note, kf, cx.ar_fmvib speed, depth)`

| Field | Details |
|---|---|
| Macro | `cx.ar_fmfreq(channel, hz)`, `cx.ar_fmfreq_no_retrigger(channel, hz)`, `cx.ar_fmnote(channel, note, kf)`, `cx.ar_fmnote_no_retrigger(channel, note, kf)`, `cx.ar_fmvib(speed, depth)` |
| Purpose | FM helpers |
| Input parameters | `channel, hz`; `channel, note, kf`; `speed, depth` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_fmfreq(channel, hz)
    }
}
```

## `cx.ar_psgfreq(voice, hz, cx.ar_psgnote voice, note, kf, cx.ar_psgwav voice, wave)`

| Field | Details |
|---|---|
| Macro | `cx.ar_psgfreq(voice, hz)`, `cx.ar_psgnote(voice, note, kf)`, `cx.ar_psgwav(voice, wave)` |
| Purpose | PSG helpers |
| Input parameters | `voice, hz`; `voice, note, kf`; `voice, wave` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_psgfreq(voice, hz)
    }
}
```

## `cx.ar_note_bas2fm, bas2midi, bas2psg, fm2bas, fm2midi, fm2psg, freq2bas/fm/midi/psg, midi2bas/fm/psg, psg2bas/fm/midi`

| Field | Details |
|---|---|
| Macro | `cx.ar_note_bas2fm()`, `bas2midi`, `bas2psg`, `fm2bas`, `fm2midi`, `fm2psg`, `freq2bas/fm/midi/psg`, `midi2bas/fm/psg`, `psg2bas/fm/midi` |
| Purpose | note conversion |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_note_bas2fm()
    }
}
```

## `cx.ar_psg_init, cx.ar_psg_playfreq, cx.ar_psg_read_raw/cooked, cx.ar_psg_setatten/freq/pan/vol, cx.ar_psg_write, cx.ar_psg_write_fast, cx.ar_psg_getatten/pan`

| Field | Details |
|---|---|
| Macro | `cx.ar_psg_init()`, `cx.ar_psg_playfreq()`, `cx.ar_psg_read_raw/cooked`, `cx.ar_psg_setatten/freq/pan/vol`, `cx.ar_psg_write()`, `cx.ar_psg_write_fast()`, `cx.ar_psg_getatten/pan` |
| Purpose | ROM PSG shadows |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_psg_init()
    }
}
```

## `cx.ar_ym_init, cx.ar_ym_loaddefpatches, cx.ar_ym_loadpatch_rom, cx.ar_ym_loadpatchlfn, cx.ar_ym_playdrum/playnote, cx.ar_ym_setatten/drum/note/pan, cx.ar_ym_read_raw/cooked, cx.ar_ym_release, cx.ar_ym_trigger, cx.ar_ym_trigger_no_retrigger, cx.ar_ym_write, cx.ar_ym_getatten/pan, cx.ar_ym_get_chip_type`

| Field | Details |
|---|---|
| Macro | `cx.ar_ym_init()`, `cx.ar_ym_loaddefpatches()`, `cx.ar_ym_loadpatch_rom()`, `cx.ar_ym_loadpatchlfn()`, `cx.ar_ym_playdrum/playnote`, `cx.ar_ym_setatten/drum/note/pan`, `cx.ar_ym_read_raw/cooked`, `cx.ar_ym_release()`, `cx.ar_ym_trigger()`, `cx.ar_ym_trigger_no_retrigger()`, `cx.ar_ym_write()`, `cx.ar_ym_getatten/pan`, `cx.ar_ym_get_chip_type()` |
| Purpose | ROM YM shadows |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.ar_ym_init()
    }
}
```
