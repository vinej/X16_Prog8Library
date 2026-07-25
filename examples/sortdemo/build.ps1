# =====================================================================
# examples\sortdemo\build.ps1 -- build this example.
#
#   .\build.ps1          # -> build\sortdemo.prg
#   .\build.ps1 -Run     # ...and launch it in the emulator
#
# A thin wrapper around the repo-root build.ps1, which does the gate scan
# and drives prog8c. Run it from anywhere; paths are resolved from the
# script's own location.
# =====================================================================
param(
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

& (Join-Path $root "build.ps1") `
    -Program (Join-Path $PSScriptRoot "sortdemo.p8") `
    -Run:$Run
