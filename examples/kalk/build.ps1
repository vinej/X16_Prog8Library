# =====================================================================
# examples\kalk\build.ps1 -- build the spreadsheet, or its self-test.
#
#   .\build.ps1          # -> build\kalk.prg
#   .\build.ps1 -Run     # ...and launch it in the emulator
#   .\build.ps1 -Test    # build the engine self-test instead
#   .\build.ps1 -Test -Run
#
# The sample sheet is copied to build\ (the emulator's -fsroot under -Run)
# so that /SL and typing "order.csv" finds it -- lower case on purpose:
# Prog8's PETSCII maps a-z to $41-$5A, which the KERNAL reads as the
# upper-case host name ORDER.CSV.
# =====================================================================
param(
    [switch]$Test,
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$out  = Join-Path $root "build"

if (-not (Test-Path $out)) { New-Item -ItemType Directory $out | Out-Null }
Copy-Item (Join-Path $PSScriptRoot "ORDER.CSV") (Join-Path $out "ORDER.CSV") -Force

$prog = if ($Test) { "kalktest.p8" } else { "kalk.p8" }

& (Join-Path $root "build.ps1") `
    -Program (Join-Path $PSScriptRoot $prog) `
    -Run:$Run
