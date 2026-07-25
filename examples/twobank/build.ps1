# =====================================================================
# examples\twobank\build.ps1 -- build this example.
#
#   .\build.ps1          # -> build\twobank.prg + BANK22.BIN + BANK23.BIN
#   .\build.ps1 -Run     # ...and launch it in the emulator
#   .\build.ps1 -Flat    # ...without banking, for comparison
#
# The point of this example is twobank.banks: the graphics modules go to
# RAM bank 22 and the string module to bank 23, leaving a ~500-byte main
# PRG. The two .BIN images must ship alongside the .PRG; -Run points the
# emulator's -fsroot at build\ so cx.load_banks() finds them.
# =====================================================================
param(
    [switch]$Flat,
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$args = @{
    Program = (Join-Path $PSScriptRoot "twobank.p8")
    Run     = $Run
}
if (-not $Flat) { $args.BankFile = (Join-Path $PSScriptRoot "twobank.banks") }

& (Join-Path $root "build.ps1") @args
