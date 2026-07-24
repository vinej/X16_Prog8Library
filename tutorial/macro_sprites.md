# Sprites Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SPRITE` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.sprites_on() / cx.sprites_off()`

| Field | Details |
|---|---|
| Macro | `cx.sprites_on()` / `cx.sprites_off()` |
| Purpose | the sprite renderer as a whole |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprites_on()
    }
}
```

## `cx.sprite_init_all()`

| Field | Details |
|---|---|
| Macro | `cx.sprite_init_all()` |
| Purpose | zero all 128 attribute records |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_init_all()
    }
}
```

## `cx.sprite_pos(sprite, x, y)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_pos(sprite, x, y)` |
| Purpose | set a sprite's 10-bit position |
| Input parameters | `sprite, x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_pos(sprite, x, y)
    }
}
```

## `cx.sprite_get_pos(sprite)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_get_pos(sprite)` |
| Purpose | read it back |
| Input parameters | `sprite` |
| Output parameters | P0/1 = x, P2/3 = y) |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_get_pos(sprite)
    }
}
```

## `cx.sprite_image(sprite, vaddr, mode)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_image(sprite, vaddr, mode)` |
| Purpose | point at pixels; `mode` = `SPRITE_MODE_4BPP`/`8BPP` |
| Input parameters | `sprite, vaddr, mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_image(sprite, vaddr, mode)
    }
}
```

## `cx.sprite_flags(sprite, flags)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_flags(sprite, flags)` |
| Purpose | byte 6: collision mask, Z, flips |
| Input parameters | `sprite, flags` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_flags(sprite, flags)
    }
}
```

## `cx.sprite_z(sprite, z)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_z(sprite, z)` |
| Purpose | change only the Z-depth |
| Input parameters | `sprite, z` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_z(sprite, z)
    }
}
```

## `cx.sprite_size(sprite, wcode, hcode, paloff)`

| Field | Details |
|---|---|
| Macro | `cx.sprite_size(sprite, wcode, hcode, paloff)` |
| Purpose | size codes + palette offset |
| Input parameters | `sprite, wcode, hcode, paloff` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.sprite_size(sprite, wcode, hcode, paloff)
    }
}
```
