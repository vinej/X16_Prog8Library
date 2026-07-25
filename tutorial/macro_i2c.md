# I2C Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_I2C` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `cx.i2c_read_byte(device, offset)`

| Field | Details |
|---|---|
| Macro | `cx.i2c_read_byte(device, offset)` |
| Purpose | read one byte |
| Input parameters | `device, offset` |
| Output parameters | read one byte |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Read or write a byte from a small I2C register device.
        cx.i2c_read_byte($6f, 0)
    }
}

```

## `cx.i2c_write_byte(value, device, offset)`

| Field | Details |
|---|---|
| Macro | `cx.i2c_write_byte(value, device, offset)` |
| Purpose | write one byte |
| Input parameters | `value, device, offset` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Read or write a byte from a small I2C register device.
        cx.i2c_write_byte($1234, $6f, 0)
    }
}

```

## `cx.i2c_batch_read(device, buffer, count)`

| Field | Details |
|---|---|
| Macro | `cx.i2c_batch_read(device, buffer, count)` |
| Purpose | read a sequence |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Read or write a byte from a small I2C register device.
        cx.i2c_batch_read($6f, 1, 32)
    }
}

```

## `cx.i2c_batch_read_fixed(device, buffer, count)`

| Field | Details |
|---|---|
| Macro | `cx.i2c_batch_read_fixed(device, buffer, count)` |
| Purpose | read from a fixed register |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Read or write a byte from a small I2C register device.
        cx.i2c_batch_read_fixed($6f, 1, 32)
    }
}

```

## `cx.i2c_batch_write(device, buffer, count)`

| Field | Details |
|---|---|
| Macro | `cx.i2c_batch_write(device, buffer, count)` |
| Purpose | write a sequence |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Read or write a byte from a small I2C register device.
        cx.i2c_batch_write($6f, 1, 32)
    }
}

```
