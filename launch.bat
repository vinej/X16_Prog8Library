@echo off
rem =====================================================================
rem launch.bat -- run the desktop against the x16_rc3 SD card image.
rem
rem The card is mounted as device 8, so the desktop, the programs it
rem launches and everything already on the card share one filesystem --
rem which is the point: the picker browses APPS, DEMOS, GAMES and the
rem rest, and a program launched from GAMES runs with GAMES current.
rem
rem The build is copied onto the card first. The trampoline reloads the
rem desktop from the CARD after a program returns, so a stale copy there
rem would quietly undo whatever you just rebuilt.
rem
rem   launch.bat              build\desktop.prg, synced and run
rem   launch.bat -sync        sync only, do not start the emulator
rem =====================================================================
setlocal
set HERE=%~dp0
set IMG=%HERE%x16_rc3.img
rem x16emuw.exe is the same emulator with no console window -- the one to
rem run once things work. Swap in x16emu.exe when you want the console
rem back: that is where -log output and start-up errors go.
set EMU=%HERE%emulator\x16emuw.exe

if not exist "%IMG%" (
    echo launch: %IMG% not found
    exit /b 1
)
if not exist "%HERE%build\desktop.prg" (
    echo launch: build\desktop.prg not found -- run examples\desktop\build.ps1 first
    exit /b 1
)

rem echo Syncing the build onto %IMG% ...
rem BANK20.BIN belongs with KALK.PRG and is not optional: kalk calls
rem load_banks() at startup and jumps into whatever that file holds, so
rem a copy left over from an older build sends it into the middle of a
rem routine. It was missing from this list, and went stale the first
rem time the library changed size.
python "%HERE%tools\img_put.py" "%IMG%" ^
    --as DESKTOP.PRG "%HERE%build\desktop.prg" ^
    --as KALK.PRG    "%HERE%build\kalk.prg" ^
    --as BANK20.BIN  "%HERE%build\BANK20.BIN" ^
    --as IMGVIEW.PRG "%HERE%build\imgview.prg" ^
    --as CHILD.PRG   "%HERE%build\child.prg" ^
    --as /DESKTOP/WALL.BMX  "%HERE%build\WALL.BMX" ^
    --as /DESKTOP/WALLO.BMX "%HERE%build\WALLO.BMX" ^
    --as IMAGE.BMX   "%HERE%build\IMAGE.BMX"
if errorlevel 1 (
    echo launch: copying to the card failed
    exit /b 1
)

if /i "%~1"=="-sync" goto :done

rem -bitmap2 is what puts the wallpaper behind the text; without it the
rem desktop still runs, it just falls back to a plain blue backdrop.
rem echo Starting the emulator ...
rem The SD trace is off unless asked for: add -log D (and switch EMU to
rem x16emu.exe, which has a console to print it in) to see every command
rem and sector the card handles. It slows loading badly, so leave it off
rem unless a load is misbehaving.
rem
rem start, so this window closes instead of sitting there for as long as
rem the emulator runs.
start "" "%EMU%" -rom "%HERE%emulator\rom.bin" -bitmap2 -sdcard "%IMG%" ^
        -prg "%HERE%build\desktop.prg" -run

:done
endlocal
