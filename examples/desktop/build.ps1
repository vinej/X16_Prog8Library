# =====================================================================
# examples\desktop\build.ps1 -- build the launcher and its test child.
#
#   .\build.ps1          # -> build\relaunch.prg + build\child.prg
#   .\build.ps1 -Run     # ...and launch it in the emulator
#
# Both PRGs have to be on the emulated filesystem, because the launcher
# loads the child by name and then reloads itself by name. -Run points
# the emulator's -fsroot at build\, which is where they land.
# =====================================================================
param(
    [switch]$Proof,
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# The wallpaper: 640x480 at 8bpp for the VERA_2 layer, whose palette is
# its own and so cannot disturb the colours the text layer draws with.
$wall = Join-Path $root "build\WALL.BMX"
if (-not (Test-Path $wall)) {
    python (Join-Path $root "tools\img2bmx.py") `
        (Join-Path $root "1694790733.jpg") $wall --stretch
}

# ...and the same picture at 320x240 for a machine without that board.
# --lores puts its palette at index 16 so the text colours survive.
$wallo = Join-Path $root "build\WALLO.BMX"
if (-not (Test-Path $wallo)) {
    python (Join-Path $root "tools\img2bmx.py") `
        (Join-Path $root "1694790733.jpg") $wallo --lores --stretch
}

# A program in a subdirectory, with a data file it opens by bare name:
# the proof that a launch sets the working directory. It is staged into
# build\SUB so the emulated drive sees the same shape as an SD card.
$sub = Join-Path $root "build\SUB"
if (-not (Test-Path $sub)) { New-Item -ItemType Directory -Path $sub | Out-Null }
& (Join-Path $root "build.ps1") -Program (Join-Path $PSScriptRoot "sub\subchild.p8")
Move-Item -Force (Join-Path $root "build\subchild.prg") (Join-Path $sub "SUBCHILD.PRG")
Copy-Item -Force (Join-Path $PSScriptRoot "sub\SUBDATA.SEQ") $sub

# the desktop launches these by name, so they all have to be built too
& (Join-Path $root "build.ps1") -Program (Join-Path $PSScriptRoot "child.p8")
& (Join-Path $root "build.ps1") -Program (Join-Path $root "examples\hello\hello.p8")
& (Join-Path $root "build.ps1") -Program (Join-Path $root "examples\imgview\imgview.p8")
& (Join-Path $root "build.ps1") -Program (Join-Path $root "examples\kalk\kalk.p8")

if ($Proof) {
    & (Join-Path $root "build.ps1") -Program (Join-Path $PSScriptRoot "relaunch.p8") -Run:$Run
} else {
    & (Join-Path $root "build.ps1") -Program (Join-Path $PSScriptRoot "relaunch.p8")
    & (Join-Path $root "build.ps1") -Program (Join-Path $PSScriptRoot "desktop.p8") -Run:$Run
}

# The cartridge edition, built from the PRG above. Same binary: it boots
# straight to the desktop, and RESET returns to it from a program that
# crashed or never came back.
python (Join-Path $root "tools\makecart_desktop.py") `
    (Join-Path $root "build\desktop.prg") (Join-Path $root "build\desktop.crt")
