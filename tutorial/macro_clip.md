# Clip Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_CLIP` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.clip_set(xmin, ymin, xmax, ymax)`

| Field | Details |
|---|---|
| Macro | `cx.clip_set(xmin, ymin, xmax, ymax)` |
| Purpose | set the clip rectangle |
| Input parameters | `xmin, ymin, xmax, ymax` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLIP` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; set the clip rectangle
        cx.clip_set(0, 1, 319, 1)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of clip

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.clip_line()`

| Field | Details |
|---|---|
| Macro | `cx.clip_line()` |
| Purpose | clip clipl_* against the rectangle |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_CLIP` is enabled. |
