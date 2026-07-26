@echo off
rem =====================================================================
rem launch_cart.bat -- run the desktop as a CARTRIDGE.
rem
rem The difference that matters is RESET. A cartridge gets control when
rem the machine resets, so a program that crashes into the monitor, hangs,
rem or simply never returns is no longer the end of the session: press
rem reset and the desktop is back. From RAM there is no way back at all.
rem
rem Bank 32 is ROM (signature "CX16" at $C000, then the desktop image);
rem bank 33 is NVRAM, which survives power-off.
rem
rem   launch_cart.bat          build the cart from build\desktop.prg and run
rem   launch_cart.bat -sync    also copy the programs onto the SD image
rem =====================================================================
setlocal
set HERE=%~dp0
set IMG=%HERE%x16_rc3.img

if not exist "%HERE%build\desktop.prg" (
    echo launch_cart: build\desktop.prg not found -- run examples\desktop\build.ps1
    exit /b 1
)

python "%HERE%tools\makecart_desktop.py" "%HERE%build\desktop.prg" "%HERE%build\desktop.crt"
if errorlevel 1 exit /b 1

if /i "%~1"=="-sync" (
    python "%HERE%tools\img_put.py" "%IMG%" ^
        --as KALK.PRG    "%HERE%build\kalk.prg" ^
        --as IMGVIEW.PRG "%HERE%build\imgview.prg" ^
        --as WALL.BMX    "%HERE%build\WALL.BMX" ^
        --as WALLO.BMX   "%HERE%build\WALLO.BMX"
)

rem -bitmap2 gives the 640x480 wallpaper; drop it and the desktop runs the
rem 320x240 screen instead, which any stock X16 can do.
"%HERE%emulator\x16emu.exe" -rom "%HERE%emulator\rom.bin" -bitmap2 ^
        -cart "%HERE%build\desktop.crt" -sdcard "%IMG%"
endlocal
