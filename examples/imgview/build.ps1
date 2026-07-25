# =====================================================================
# examples\imgview\build.ps1 -- build this example.
#
#   .\build.ps1                      # -> build\imgview.prg
#   .\build.ps1 -Image photo.jpg     # ...converting the picture first
#   .\build.ps1 -Image photo.jpg -Run
#
# imgview loads build\IMAGE.BMX, a 640x480 8bpp BMX file. -Image runs
# tools\img2bmx.py (needs Python + Pillow) to produce it; use -Stretch to
# fill the screen instead of fitting and letterboxing. Without -Image the
# program builds against whatever build\IMAGE.BMX is already there.
# =====================================================================
param(
    [string]$Image = "",
    [switch]$Stretch,
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$out  = Join-Path $root "build"

if ($Image) {
    if (-not (Test-Path $Image)) { throw "image not found: $Image" }
    if (-not (Test-Path $out)) { New-Item -ItemType Directory $out | Out-Null }
    $conv = @((Join-Path $root "tools\img2bmx.py"), (Resolve-Path $Image).Path,
              (Join-Path $out "IMAGE.BMX"))
    if ($Stretch) { $conv += "--stretch" }
    Write-Host "Converting $Image -> build\IMAGE.BMX ..." -ForegroundColor Cyan
    & python @conv
    if ($LASTEXITCODE -ne 0) { throw "img2bmx.py failed (exit $LASTEXITCODE)" }
} elseif ($Run -and -not (Test-Path (Join-Path $out "IMAGE.BMX"))) {
    Write-Warning "build\IMAGE.BMX does not exist -- pass -Image <file> to create it."
}

& (Join-Path $root "build.ps1") `
    -Program (Join-Path $PSScriptRoot "imgview.p8") `
    -Run:$Run
