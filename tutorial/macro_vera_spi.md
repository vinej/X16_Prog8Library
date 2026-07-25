# VERA SPI Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_VERA_SPI` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.spi_get_ctrl() / cx.spi_set_ctrl(ctrl)`

| Field | Details |
|---|---|
| Macro | `cx.spi_get_ctrl()` / `cx.spi_set_ctrl(ctrl)` |
| Purpose | read/write SPI control |
| Input parameters | `ctrl` |
| Output parameters | read/write SPI control |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_get_ctrl()
        cx.spi_set_ctrl($01)
    }
}

```

## `cx.spi_select() / cx.spi_deselect()`

| Field | Details |
|---|---|
| Macro | `cx.spi_select()` / `cx.spi_deselect()` |
| Purpose | chip select helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_select()
        cx.spi_deselect()
    }
}

```

## `cx.spi_slow() / cx.spi_fast()`

| Field | Details |
|---|---|
| Macro | `cx.spi_slow()` / `cx.spi_fast()` |
| Purpose | clock speed helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_slow()
        cx.spi_fast()
    }
}

```

## `cx.spi_autotx_on() / cx.spi_autotx_off()`

| Field | Details |
|---|---|
| Macro | `cx.spi_autotx_on()` / `cx.spi_autotx_off()` |
| Purpose | auto-transmit controls |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_autotx_on()
        cx.spi_autotx_off()
    }
}

```

## `cx.spi_wait()`

| Field | Details |
|---|---|
| Macro | `cx.spi_wait()` |
| Purpose | wait for SPI ready |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_wait()
    }
}

```

## `cx.spi_transfer(byte)`

| Field | Details |
|---|---|
| Macro | `cx.spi_transfer(byte)` |
| Purpose | transfer one byte |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_transfer('A')
    }
}

```

## `cx.spi_read() / cx.spi_write(byte) / cx.spi_autotx_read()`

| Field | Details |
|---|---|
| Macro | `cx.spi_read()` / `cx.spi_write(byte)` / `cx.spi_autotx_read()` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_read()
        cx.spi_write('A')
        cx.spi_autotx_read()
    }
}

```

## `cx.spi_read_bytes(buffer, count) / cx.spi_write_bytes(buffer, count)`

| Field | Details |
|---|---|
| Macro | `cx.spi_read_bytes(buffer, count)` / `cx.spi_write_bytes(buffer, count)` |
| Purpose | block I/O helpers |
| Input parameters | `buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Select an SPI device and exchange command bytes.
        cx.spi_read_bytes(1, 32)
        cx.spi_write_bytes(1, 32)
    }
}

```
