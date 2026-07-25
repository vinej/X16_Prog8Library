# =====================================================================
# examples\shapes\build.ps1 -- build this example.
#
#   .\build.ps1          # -> build\shapes.prg  (~6 KB, all in low RAM)
#   .\build.ps1 -Bank    # ...with the shape + bitmap engines relocated
#                        #    into RAM bank 22, per shapes.banks (~0.6 KB)
#   .\build.ps1 -Run     # ...and launch it in the emulator
#
# -Bank produces build\BANK22.BIN alongside the PRG; both must ship
# together, and -Run points the emulator's -fsroot at build\ so the
# program's LOAD finds the image.
# =====================================================================
param(
    [switch]$Bank,
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$args = @{
    Program = (Join-Path $PSScriptRoot "shapes.p8")
    Run     = $Run
}
if ($Bank) { $args.BankFile = (Join-Path $PSScriptRoot "shapes.banks") }

& (Join-Path $root "build.ps1") @args
