# ZiModem Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_SERIAL_ZIMODEM` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Scope`

| Field | Details |
|---|---|
| Macro | Scope |
| Purpose | ESP32 WiFi modem helpers on top of Serial; most block on real hardware replies |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        ; see macro listing above
    }
}
```

## `cx.zi_init(base, divisor)`

| Field | Details |
|---|---|
| Macro | `cx.zi_init(base, divisor)` |
| Purpose | reset the modem to a known state |
| Input parameters | `base, divisor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_init(base, divisor)
    }
}
```

## `cx.zi_cmd(addr)`

| Field | Details |
|---|---|
| Macro | `cx.zi_cmd(addr)` |
| Purpose | send an `AT...` command line (+ CR/LF) |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_cmd(addr)
    }
}
```

## `cx.zi_wait_ok()`

| Field | Details |
|---|---|
| Macro | `cx.zi_wait_ok()` |
| Purpose | read/discard the reply up to `OK\r\n` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_wait_ok()
    }
}
```

## `cx.zi_reset()`

| Field | Details |
|---|---|
| Macro | `cx.zi_reset()` |
| Purpose | `ATZ` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_reset()
    }
}
```

## `cx.zi_get_ip(buffer)`

| Field | Details |
|---|---|
| Macro | `cx.zi_get_ip(buffer)` |
| Purpose | IPv4 address into buffer (via `ATI2`) |
| Input parameters | `buffer` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_get_ip(buffer)
    }
}
```

## `cx.zi_hex_open(filename)`

| Field | Details |
|---|---|
| Macro | `cx.zi_hex_open(filename)` |
| Purpose | begin a hex-mode download |
| Input parameters | `filename` |
| Output parameters | carry set = not found) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_hex_open(filename)
    }
}
```

## `cx.zi_hex_chunk(buffer)`

| Field | Details |
|---|---|
| Macro | `cx.zi_hex_chunk(buffer)` |
| Purpose | next payload chunk |
| Input parameters | `buffer` |
| Output parameters | A = bytes, 0 = done) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_hex_chunk(buffer)
    }
}
```

## `cx.zi_hex_close()`

| Field | Details |
|---|---|
| Macro | `cx.zi_hex_close()` |
| Purpose | swallow the trailing `OK` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_hex_close()
    }
}
```

## `cx.zi_hexdecode(src, digits, dest)`

| Field | Details |
|---|---|
| Macro | `cx.zi_hexdecode(src, digits, dest)` |
| Purpose | pack ASCII hex -> bytes |
| Input parameters | `src, digits, dest` |
| Output parameters | bytes (-> A = `digits`/2) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib

main {
    sub start() {
        cx.zi_hexdecode(src, digits, dest)
    }
}
```
