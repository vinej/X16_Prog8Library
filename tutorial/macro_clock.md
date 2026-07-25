# Clock Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_CLOCK` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.clock_update()`

| Field | Details |
|---|---|
| Macro | `cx.clock_update()` |
| Purpose | update clock state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Set and read the KERNAL clock.
        cx.clock_update()
    }
}

```

## `cx.clock_get_timer() / cx.clock_set_timer(ticks)`

| Field | Details |
|---|---|
| Macro | `cx.clock_get_timer()` / `cx.clock_set_timer(ticks)` |
| Purpose | jiffy timer helpers |
| Input parameters | `ticks` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Set and read the KERNAL clock.
        cx.clock_get_timer()
        cx.clock_set_timer(1)
    }
}

```

## `cx.clock_get_date_time()`

| Field | Details |
|---|---|
| Macro | `cx.clock_get_date_time()` |
| Purpose | read date/time |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Set and read the KERNAL clock.
        cx.clock_get_date_time()
    }
}

```

## `cx.clock_set_date_time_raw(year1900, month, day, hours, minutes, seconds, jiffies, weekday)`

| Field | Details |
|---|---|
| Macro | `cx.clock_set_date_time_raw(year1900, month, day, hours, minutes, seconds, jiffies, weekday)` |
| Purpose | set raw date/time |
| Input parameters | `year1900, month, day, hours, minutes, seconds, jiffies, weekday` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Set and read the KERNAL clock.
        cx.clock_set_date_time_raw(126, 7, 24, 14, 30, 0, 0, 5)
    }
}

```

## `cx.clock_set_date_time(year, month, day, hours, minutes, seconds, weekday)`

| Field | Details |
|---|---|
| Macro | `cx.clock_set_date_time(year, month, day, hours, minutes, seconds, weekday)` |
| Purpose | set date/time |
| Input parameters | `year, month, day, hours, minutes, seconds, weekday` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Set and read the KERNAL clock.
        cx.clock_set_date_time(2026, 7, 24, 14, 30, 0, 5)
    }
}

```
