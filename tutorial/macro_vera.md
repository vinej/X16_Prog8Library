# VERA Macros

> Prog8 edition, generated from the X16_Library `src_acme/tutorial` by `tools/acme_doc2prog8.py`. Do not edit this copy by hand. Macros become calls in the `cx` block; constants live in `x16c`.

Detailed reference for the `X16_USE_VERA` macro gate.

Set the gate before sourcing the library:

```prog8
%import x16lib
```

The macros in this file are thin Prog8 wrappers around the routines in
`src_acme/video/vera.asm`. They load immediate arguments into registers and then
call the runtime routine. Register contract for the routines: `A`, `X`, `Y`,
processor flags, and scratch bytes `X16_T0..X16_T2` may be clobbered unless a
macro notes otherwise.

For VERA addresses, `ADDR_H` is not just the high address byte. It contains:

| Bits | Meaning |
|---|---|
| bit 0 | VRAM address bit 16, usually `0` or `VERA_ADDR_H_BANK` |
| bit 3 | decrement flag, `VERA_ADDR_H_DECR` |
| bits 7:4 | auto-increment index, usually `VERA_INC_* << 4` |

Common increment constants are `VERA_INC_0`, `VERA_INC_1`, `VERA_INC_2`,
`VERA_INC_4`, `VERA_INC_8`, `VERA_INC_16`, `VERA_INC_32`, `VERA_INC_64`,
`VERA_INC_128`, `VERA_INC_256`, `VERA_INC_512`, `VERA_INC_40`,
`VERA_INC_80`, `VERA_INC_160`, `VERA_INC_320`, and `VERA_INC_640`.

## `cx.vera_set_addr0(l, m, h)`

| Field | Details |
|---|---|
| Macro | `cx.vera_set_addr0(l, m, h)` |
| Purpose | Point VERA data port 0 at a runtime or macro-supplied VRAM address. Use this before reading or writing through `VERA_DATA0`, or before calling `cx.vera_fill()`. |
| Input parameters | `l`: low byte for `VERA_ADDR_L`; `m`: middle byte for `VERA_ADDR_M`; `h`: full `VERA_ADDR_H` value, including address bit 16 and the auto-increment/decrement bits. |
| Output parameters | None returned. VERA port 0 address registers are updated. |
| More info | The macro selects ADDRSEL 0 without disturbing DCSEL, then writes `VERA_ADDR_L/M/H`. Compose `h` yourself from the address bank bit and the increment index. For assembly-time constant addresses, the lower-level `cx.vera_addr(0, addr, inc)` macro is often shorter. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Point VERA data port 0 at a runtime or macro-supplied VRAM address. Use this before reading or writing through `VERA_DATA0`, or before calling `+xm_vera_fill`
        cx.vera_set_addr0(1, 1, 64)
    }
}

```

## `cx.vera_set_addr1(l, m, h)`

| Field | Details |
|---|---|
| Macro | `cx.vera_set_addr1(l, m, h)` |
| Purpose | Point VERA data port 1 at a runtime or macro-supplied VRAM address. This is most useful when copying from port 0 to port 1 with `cx.vera_copy()`, or when a routine needs a second independent VERA stream. |
| Input parameters | `l`: low byte for `VERA_ADDR_L`; `m`: middle byte for `VERA_ADDR_M`; `h`: full `VERA_ADDR_H` value, including address bit 16 and the auto-increment/decrement bits. |
| Output parameters | None returned. VERA port 1 address registers are updated. |
| More info | The macro selects ADDRSEL 1 without disturbing DCSEL, then writes `VERA_ADDR_L/M/H`. `VERA_DATA1` always accesses port 1, regardless of the current ADDRSEL bit. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Point VERA data port 1 at a runtime or macro-supplied VRAM address. This is most useful when copying from port 0 to port 1 with `+xm_vera_copy`, or when a routine needs a second independent VERA stream
        cx.vera_set_addr1(1, 1, 64)
    }
}

```

## `cx.vera_fill(val, count)`

| Field | Details |
|---|---|
| Macro | `cx.vera_fill(val, count)` |
| Purpose | Write the same byte repeatedly through `VERA_DATA0`, starting at the current port 0 address. Use it for fast clears, solid spans, repeated tile bytes, palette bytes, and any other linear or strided fill. |
| Input parameters | `val`: byte value to write; `count`: 16-bit byte count. |
| Output parameters | None returned. VERA port 0 advances according to the increment already configured in `VERA_ADDR_H`. |
| More info | You must point port 0 first with `cx.vera_set_addr0()` or `cx.vera_addr()`. `count = 0` writes nothing. The routine stores `val`, count low, and count high in `X16_T0..X16_T2`, so do not expect those scratch bytes to survive. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Write the same byte repeatedly through `VERA_DATA0`, starting at the current port 0 address. Use it for fast clears, solid spans, repeated tile bytes, palette bytes, and any other linear or strided fill
        cx.vera_fill($20, 32)
    }
}

```

## `cx.vera_copy(count)`

| Field | Details |
|---|---|
| Macro | `cx.vera_copy(count)` |
| Purpose | Copy bytes from VERA data port 0 to VERA data port 1. Use it for VRAM-to-VRAM blits when both source and destination can be streamed with VERA auto-increment. |
| Input parameters | `count`: 16-bit byte count. Before calling, port 0 must point at the source and port 1 must point at the destination. Each port keeps its own auto-increment/decrement setting. |
| Output parameters | None returned. Port 0 and port 1 both advance according to their configured increments. |
| More info | `count = 0` copies nothing. `VERA_DATA0` always reads port 0 and `VERA_DATA1` always writes port 1, so the copy loop does not need to switch ADDRSEL. The routine uses `X16_T1..X16_T2` for the count. Avoid overlapping source/destination regions unless the port increments and direction are chosen deliberately. |
| Example | See below. |

```prog8
%import x16lib



main {
    sub start() {
        ; Copy bytes from VERA data port 0 to VERA data port 1. Use it for VRAM-to-VRAM blits when both source and destination can be streamed with VERA auto-increment
        cx.vera_copy(32)
    }
}

```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of vera

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `cx.vera_has_fx()`

| Field | Details |
|---|---|
| Macro | `cx.vera_has_fx()` |
| Purpose | A = major version (only meaningful when carry is set) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERA_FXPROBE` is enabled. |
