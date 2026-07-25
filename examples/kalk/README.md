# kalk — a spreadsheet for the Commander X16

A port of [zserge's **kalk**](https://github.com/zserge/kalk), a VisiCalc-style
terminal spreadsheet, to [Prog8](https://prog8.readthedocs.io/) on the X16.

It is a worked example of building a whole application on the
[X16_Library wrapper](../../README.md): every run-time service — floating
point, the screen, the keyboard, files, banked memory — is a `cx.*` call, with
nothing from Prog8's own stdlib — and, since the wrapper learned to type the
library's return values, not a line of inline assembly either.

```powershell
.\build.ps1 -Run            # build and launch the spreadsheet
.\build.ps1 -Test -Run      # build and run the engine self-test
```

That is this folder's own `build.ps1`. It works from here or from the repo root
(`.\examples\kalk\build.ps1 -Run`), and copies `ORDER.CSV` into `build\` so the
sample sheet is loadable. It wraps the root `build.ps1`, which you can also
call directly:

```powershell
.\build.ps1 examples\kalk\kalk.p8 -Run
```

```
 A1  Item                                                              READY
   Item
              A          B          C          D
   1 Item      Qty        Price      Total
   2 Widget A         10       4.99       49.9
   3 Widget B         25        2.5       62.5
   ...
   7 Subtotal                          286.37
```

| File | What |
|---|---|
| `build.ps1` | build this example (`-Test` for the self-test, `-Run` to launch) |
| `kalk.p8` | the application: renderer, key loop, command menus, CSV |
| `kalkcore.p8` | the model: cells, text arena, formula parser, recalculation, formatting |
| `kalktest.p8` | kalk.c's own assertions, run on the machine |
| `ORDER.CSV` | a sample sheet |

## Using it

A **26 x 256** sheet (A..Z, rows 1-256) in 80x60 text. Type a number, a formula
(`+ - ( @`) or a label; `"` forces a label. Arrow keys move, `Tab`/`Return`
advance, `>` jumps to a cell, `!` recalculates, `Del` clears a cell,
`Run/Stop` quits.

**Click a cell to select it.** The KERNAL tracks the pointer in its own
interrupt, so the main loop just polls `cx.mse_get` alongside a non-blocking
`cx.key_get`; only the press edge counts, so holding the button does not
re-select. Clicks land on cells only — the status lines, column headers and row
gutter ignore them — and the hit test goes through the same `col_at`/`row_at`
mapping as drawing, so it stays right when the sheet is scrolled or has locked
titles. The menus and cell entry are keyboard-driven.

A label wider than its column **spills into the columns to its right**, for as
far as they are empty; the first occupied neighbour cuts it off, exactly where
the text would have collided. Numbers never spill — they are truncated to the
column. Column letters are centred over their column.

`/` opens the command menu — the same set as kalk:

| | |
|---|---|
| `/B` `/C` | blank the cell / clear the sheet |
| `/IR` `/IC` `/DR` `/DC` | insert / delete a row or column (references shift) |
| `/F` *fmt* | cell format: `L R I G D $ % *` (left, right, integer, general, default, currency, percent, bar) |
| `/GC` `/GF` | global column width (4-20) / global format |
| `/M` | drag the current row or column with the arrow keys |
| `/R` | replicate a range; relative references adjust, `$A$1` ones don't |
| `/TV` `/TH` `/TB` `/TN` | lock title rows/columns |
| `/SL` `/SS` `/SQ` | load / save / save & quit a **CSV** file on device 8 |
| `/Q` | quit |

Formulas: `+A1*B2-3`, `(A1+A2)/2`, with `$` for absolute references (`$A$1`,
`$A1`, `A$1`). The function set is VisiCalc's:

| | |
|---|---|
| over a range | `@SUM` `@MIN` `@MAX` `@COUNT` `@AVERAGE` (or `@AVG`) |
| | `@NPV(rate, range)` — each flow discounted one more period than the last |
| | `@LOOKUP(value, range)` — the last key at or below `value`, answered from the next column (or row, for a horizontal range) |
| over a value | `@ABS` `@INT` `@SQRT` `@EXP` `@LN` `@LOG10` |
| | `@SIN` `@COS` `@TAN` `@ASIN` `@ACOS` `@ATAN` |
| on their own | `@PI` `@ERROR` `@NA` — written bare, as VisiCalc does, though empty parentheses are accepted |

`@NA` and `@ERROR` propagate: a formula that reads an `@NA` cell is itself
`@NA`, one that reads an `@ERROR` cell is `@ERROR`, and `@ERROR` wins when a
formula meets both. Domains that would otherwise drop into the ROM's own error
handler and abandon the program are caught first — `@LN` and `@LOG10` of zero
or less, `@SQRT` of a negative, `@ASIN`/`@ACOS` outside -1..1, and division by
zero — and show as `ERROR`.

The angle functions work in radians and come free: the whole ROM floating-point
module is already linked for the arithmetic, so `f_sin`, `f_cos`, `f_tan`,
`f_atan`, `f_ln` and `f_exp` were sitting in the binary unused. `@LOG10` is
`@LN` scaled by 1/ln 10, and `@ASIN` is `@ATAN(x / @SQRT(1 - x*x))` with the
two endpoints done by hand.

`ORDER.CSV` is a sample sheet. `build.ps1` copies it into `build\`, which is
where `-Run` points the emulator's `-fsroot`, so `/SL` and typing `order.csv`
finds it (lower case on purpose: Prog8's PETSCII maps `a-z` to `$41-$5A`, which
the KERNAL reads as the upper-case host name).

## How it maps onto the library

* **Arithmetic** is `cx.f_load` / `f_add` / `f_mul` / `f_rsub` / `f_rdiv` /
  `f_cmp` / `f_from_str` — the ROM's floating point through `util/float`.
  `f_rsub` and `f_rdiv` compute `mem - FAC` and `mem / FAC`, which is exactly
  what a left-to-right expression parser wants.
* **Screen** is `cx.screen_set_mode` / `screen_charset` / `screen_color`, and
  for the grid itself `cx.screen_addr` / `screen_blit` / `screen_blitfill` —
  direct text-map writes rather than `CHROUT`, which costs several hundred
  cycles a character. **Keys** are `cx.key_wait`; **files** are
  `cx.fio_open_read` / `fio_open_write` / `fio_chrout` and `x16src.fio_chrin`.
* **Scrolling does not repaint.** A one-row step calls `cx.screen_scroll` to
  slide the grid inside VRAM and then renders only the row that was just
  exposed, so it costs one row of work instead of fifty-six.
* **The grid lives in banked RAM.** A cell is 9 bytes (type, format, text
  pointer, 5-byte MFLPT value), so 26 x 256 cells is 58.5 KB — far more than
  low RAM holds. It goes into eight 8K banks instead, 32 rows per bank, with
  `cx.bank_set` selecting and `cx.mem_copy` / `cx.mem_fill` moving rows:

  ```
  bank   = 1 + (row >> 5)
  offset = $A000 + (row & 31) * 234 + col * 9
  ```

  A cell index packs the row above the column (`idx = row<<5 | col`) so both
  fall out of shifts, and two small offset tables replace the multiplications.
  Only the cell-text arena stays in low RAM, which leaves the string handling
  and the parser untouched by the banking.
* The program is **~20 KB of code plus 12 KB of low-RAM data**, and pulls in 7
  library modules (`FLOAT`, `SCREEN`, `SCREEN_EXTRA`, `INPUT_KEYWAIT`,
  `FILEIO`, `BANK`, `MEM`). It reserves **RAM banks 1-8**, so it needs a
  standard 512 KB machine and nothing else may use those banks.

Measured on the emulator, with every visible cell holding a number:

| | |
|---|---|
| cursor move along a row | 0.015 s |
| cursor move up or down | 0.026 s |
| **scroll one row** | **0.071 s** |
| full repaint — after an edit, a jump, a width change | 0.62 s |
| insert a row at the top: 255 rows moved across all eight banks, every formula's references rewritten, full recalculation | 0.83 s |

The whole program leaves about **1.7 KB of low RAM free**; the full VisiCalc
function set cost 2.3 KB of that.

The full repaint is dominated by number formatting, not by drawing: of that
0.62 s, **0.54 s is the ROM's float-to-string conversion**, called once per
visible cell, and only 0.03 s is putting characters on the screen. That is why
scrolling block-moves the picture instead of re-rendering it — it sidesteps the
formatting entirely, and made a scroll step 9× cheaper.

Moving the cursor repaints whole rows rather than single cells, because a
spilling label crosses cell boundaries and is no longer safe to redraw a cell
at a time. That costs about 0.02 s a keypress, still well ahead of the
keyboard's repeat rate.

## Two things the port had to get right

* **`%zeropage dontuse` is required.** With `basicsafe`, Prog8 allocated
  variables at `$24`-`$31`, which is inside the library's `X16_P0..P7` /
  `X16_T0..` block, and every `cx.*` call quietly corrupted them. See the
  [zero-page note](../../README.md#zero-page-note).
* Prog8 subroutine locals are **static**, so the recursive expression parser
  keeps its operands on an explicit float stack and its operators on a byte
  stack instead of in locals.

## Caveats

Division by zero, `@SQRT` of a negative and out-of-range references are caught
and shown as `ERROR`, but a floating-point *overflow* still lands in the ROM's
BASIC error handler.

`kalktest.p8` runs kalk.c's own test suite (expressions, references,
recalculation, replicate, insert/delete) on the machine, plus checks that cross
the RAM-bank boundaries, and prints `all ok`.

## License

kalk is MIT-licensed by Serge Zaitsev; this port keeps that.
