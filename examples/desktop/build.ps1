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
