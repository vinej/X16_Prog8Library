# desktop — a launcher for the Commander X16

Icons are VERA sprites on a text-mode backdrop. Drag one with the mouse to move
it; double click it, or press its number, to run the program it stands for. When
that program finishes, **the desktop comes back, with the icons where you left
them**.

```powershell
.\build.ps1 -Run          # the desktop
.\build.ps1 -Proof -Run   # just the launch/return round trip, no UI
```

| File | What |
|---|---|
| `build.ps1` | builds the desktop and everything it can launch |
| `desktop.p8` | the launcher: sprites, mouse, and the launch path |
| `relaunch.p8` | the round trip on its own — the part worth reading first |
| `child.p8` | a program to launch, which prints and returns |

It also launches `kalk`, `hello` and `imgview`, which live in their own example
folders; `build.ps1` builds those too, since the desktop loads them by name.

## Coming back is the hard part

A PRG loads at `$0801` and overwrites whatever was there, so a launcher cannot
call a program and expect to still exist afterwards. It cannot even *load* one:
the moment `LOAD` runs, the caller's own next instruction has been replaced by
the incoming program. My first attempt did exactly that and fell into the
machine-language monitor.

What survives is **golden RAM, `$0400-$07FF`** — the KERNAL does not use it,
BASIC does not use it, and Prog8 only uses it if asked. A fifty-four byte
trampoline goes there and does the whole job from outside `$0801`:

```
SETNAM / SETLFS / LOAD   the program
JSR  <program entry>         ; it owns $0801.. now
   ...it returns...
SETNAM / SETLFS / LOAD   the desktop, back off disk
JMP  (<desktop entry>)
```

The trampoline refers only to fixed golden-RAM addresses and the KERNAL jump
table, never to itself, so it can be copied to `$0400` and run there. Icon
positions live in golden RAM too, just above it, so they survive the round trip
without touching the disk.

Entry addresses are **read, not assumed**. Prog8 emits `SYS 2071` today, but that
number moves with the stub text, so the SYS argument is parsed out of each PRG's
BASIC stub — read *off disk*, since loading a program to find out where it
starts would defeat the point.

Both programs here did that by hand at first, in forty lines each. It is now
`cx.fs_prg_entry(name, len, 8)`: writing the same fiddly parser twice was the
argument for putting it in the library, and getting it wrong once (the entry is
`$0817`, not the `$080D` I assumed) was the argument for it being worth testing
there rather than here.

## What makes a program launchable

**It has to return.** Prog8's `start()` falling off the end is an `RTS` straight
back into the trampoline. Two things break it:

* a program that ends in an endless loop (`repeat { }`) never comes back — that
  rules out `shapes` and `sortdemo` as they stand
* a program that uses golden RAM for itself overwrites the trampoline

`kalk` is launchable: Run/Stop leaves its loop, it restores the screen, and
`start()` returns. `imgview` was not — it ended in `repeat { }` — so it now
waits for `ESC` (or Run/Stop) and returns. Other keys are ignored, so a stray
press cannot dismiss a picture you are still looking at.

**Restoring the screen means more than `screen_reset`.** `imgview` draws on the
VERA_2 bitmap, and `screen_reset` is `CINT`, which only restores the primary
VERA. The first time the desktop launched it, the round trip worked perfectly
and the screen still showed the photo: the desktop was underneath, hidden by a
bitmap layer nobody had switched off. `imgview` now calls `gfx8h_off` before it
returns — and the desktop calls it on the way *in* as well, because trusting
every program to clean up after itself is how you get an invisible desktop.

## Using it

Drag an icon to move it; the caption follows it live, rubbed out at the old
spot and redrawn at the new one. It sits on the first text row *entirely* below
the icon — rounding down instead would tuck the label under the icon's own
sprite as soon as a drag left the 8-pixel grid. Double
click within half a second to launch, or press `1`-`4`. `Run/Stop` quits.

The pointer needs `mse_config(1, 80, 60)` rather than `mouse_show`: with a size
of zero `MOUSE_CONFIG` keeps whatever bounds are already set, and on a fresh
boot there are none, so the pointer never appears.

## Next

Icons and their programs are a table in the source. Reading them from a file,
more than four of them, a grid-snap, and a way to run programs that do not
return are all still to come.
