# Serial Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SERIAL` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `base / divisor`

| Field | Details |
|---|---|
| Macro | `base` / `divisor` |
| Purpose | `base` is from `ser_detect` or `$9F60`; `divisor` is a `SER_BAUD_*` constant |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Detect the UART card, then initialize the first standard base at 9600 bps.
        cx.ser_detect()
        cx.ser_init($9f60, SER_BAUD_9600)
        cx.ser_puts(hello_modem)
    }
}

%asm {{
    hello_modem !text "AT", $0d, 0
}}

```

## `cx.ser_detect()`

| Field | Details |
|---|---|
| Macro | `cx.ser_detect()` |
| Purpose | scan for UARTs |
| Input parameters | No macro arguments. |
| Output parameters | A = count, `ser_u0`/`ser_u1` = bases) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_detect()
    }
}

```

## `cx.ser_init(base, divisor)`

| Field | Details |
|---|---|
| Macro | `cx.ser_init(base, divisor)` |
| Purpose | 8N1, FIFOs, auto-flow; selects that UART |
| Input parameters | `base, divisor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_init($9f60, 12)
    }
}

```

## `cx.ser_avail()`

| Field | Details |
|---|---|
| Macro | `cx.ser_avail()` |
| Purpose | -> carry set if a byte is waiting |
| Input parameters | No macro arguments. |
| Output parameters | carry set if a byte is waiting |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_avail()
    }
}

```

## `cx.ser_get()`

| Field | Details |
|---|---|
| Macro | `cx.ser_get()` |
| Purpose | non-blocking read |
| Input parameters | No macro arguments. |
| Output parameters | carry set = empty, else A = byte) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_get()
    }
}

```

## `cx.ser_get_wait()`

| Field | Details |
|---|---|
| Macro | `cx.ser_get_wait()` |
| Purpose | blocking read |
| Input parameters | No macro arguments. |
| Output parameters | A = byte) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_get_wait()
    }
}

```

## `cx.ser_put(byte)`

| Field | Details |
|---|---|
| Macro | `cx.ser_put(byte)` |
| Purpose | send one byte |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_put('A')
    }
}

```

## `cx.ser_puts(addr)`

| Field | Details |
|---|---|
| Macro | `cx.ser_puts(addr)` |
| Purpose | send a NUL-terminated string |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_puts(work_buffer)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

## `cx.ser_write(addr, len)`

| Field | Details |
|---|---|
| Macro | `cx.ser_write(addr, len)` |
| Purpose | send `len` bytes (binary-safe) |
| Input parameters | `addr, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_write(work_buffer, 16)
    }
}

%asm {{
    work_buffer !fill 64, 0
}}

```

## `cx.ser_read_until(match, buffer, max)`

| Field | Details |
|---|---|
| Macro | `cx.ser_read_until(match, buffer, max)` |
| Purpose | read into buffer until `match` |
| Input parameters | `match, buffer, max` |
| Output parameters | P4/5 = count) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_read_until(1, 1, 32)
    }
}

```

## `cx.ser_discard_until(match)`

| Field | Details |
|---|---|
| Macro | `cx.ser_discard_until(match)` |
| Purpose | read and discard until `match` |
| Input parameters | `match` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Configure the first serial card UART and send a command.
        cx.ser_discard_until(1)
    }
}

```
