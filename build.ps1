# =====================================================================
# build.ps1 -- compile a Prog8 program against the X16_Library wrapper,
# linking only the library modules the program actually calls.
#
#   .\build.ps1                       # build examples\hello\hello.p8
#   .\build.ps1 examples\hello\hello.p8     # a specific program
#   .\build.ps1 examples\hello\hello.p8 -Run    # ...and run it in the emulator
#
# How "pay-per-use" works: the wrapper embeds the whole X16_Library 64tass
# source (x16lib\x16lib_src.asm), gated module-by-module. This script scans
# your program for cx.<routine>() calls, maps each to its X16_USE_* gate via
# x16lib\routine_gates.json, and writes x16lib\x16lib_gates.inc so 64tass
# assembles only those modules (their dependencies are pulled in automatically
# by the library). Everything else is left out of the PRG.
# =====================================================================
param(
    [string]$Program = "examples\hello\hello.p8",
    [string]$BankFile = "",    # a file describing multiple banks; lines: bank <N>, "mod,mod"
    [string]$Bank = "",        # OR a single bank inline: comma list of modules, e.g. "shapes,bitmap2h"
    [int]$BankNum = 1,         # bank number for the inline -Bank form
    [switch]$Run
)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$sdk  = Join-Path $root "prog8-sdk"
$out  = Join-Path $root "build"
$lib  = Join-Path $root "x16lib"
$emu  = Join-Path $root "emulator"

function Find-Java {
    $save = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    try {
        $cands = @()
        $cmd = Get-Command java -ErrorAction SilentlyContinue
        if ($cmd) { $cands += $cmd.Source }
        $cands += Get-ChildItem "C:\Program Files\Eclipse Adoptium\*\bin\java.exe" |
                  ForEach-Object { $_.FullName }
        $cands += Get-ChildItem "C:\Program Files\Java\*\bin\java.exe" |
                  ForEach-Object { $_.FullName }
        foreach ($j in $cands) {
            $txt = (& $j -version 2>&1 | Out-String)
            if ($txt -match 'version "(\d+)' -and [int]$matches[1] -ge 17) { return $j }
        }
    } finally { $ErrorActionPreference = $save }
    throw "No Java 17+ found. Install a JDK 17+ (e.g. Eclipse Adoptium 21)."
}
$java = Find-Java
if (-not (Test-Path $out)) { New-Item -ItemType Directory $out | Out-Null }
$env:PATH = "$sdk;$env:PATH"

# --- 1. scan the program + the local modules it %imports for cx.<routine>() calls ---
$progDir = Split-Path -Parent (Resolve-Path $Program)
$called  = New-Object System.Collections.Generic.HashSet[string]
$visited = New-Object System.Collections.Generic.HashSet[string]
$queue   = New-Object System.Collections.Generic.Queue[string]
$queue.Enqueue((Resolve-Path $Program).Path)
while ($queue.Count -gt 0) {
    $f = $queue.Dequeue()
    if (-not $visited.Add($f) -or -not (Test-Path $f)) { continue }
    # strip line comments so cx.* examples in comments are ignored
    $text = ((Get-Content $f) | ForEach-Object { ($_ -replace ';.*$', '') }) -join "`n"
    foreach ($m in [regex]::Matches($text, 'cx\.([a-z_][a-z0-9_]*)\s*\(')) {
        [void]$called.Add($m.Groups[1].Value)
    }
    # Follow the user's own local modules (in the program's directory),
    # and the hand-written shared ones that live beside the wrapper in
    # x16lib\ -- filepick calls cx.dir_* and cx.mse_* on the program's
    # behalf, and gates it needs would otherwise be left off.
    #
    # The GENERATED files are skipped on purpose: x16lib.p8 is where
    # every cx.* routine is defined rather than called, so scanning it
    # would turn on the whole library for every program and the
    # pay-per-use build would stop paying.
    $generated = @('x16lib', 'x16lib_const')
    foreach ($m in [regex]::Matches($text, '(?m)^\s*%import\s+([A-Za-z_][A-Za-z0-9_]*)')) {
        $nm = $m.Groups[1].Value
        $cand = Join-Path $progDir ($nm + ".p8")
        if (Test-Path $cand) { $queue.Enqueue((Resolve-Path $cand).Path); continue }
        if ($generated -notcontains $nm) {
            $cand = Join-Path $lib ($nm + ".p8")
            if (Test-Path $cand) { $queue.Enqueue((Resolve-Path $cand).Path) }
        }
    }
}

# --- 2. map calls -> X16_USE_* gates ---
$map = Get-Content (Join-Path $lib "routine_gates.json") -Raw | ConvertFrom-Json
$gates = New-Object System.Collections.Generic.HashSet[string]
foreach ($name in $called) {
    if ($map.PSObject.Properties.Name -contains $name) { [void]$gates.Add($map.$name) }
}
# A module with no cx.* entry points of its own cannot be found by the
# call scan: filepick's editing half (n/e/d/c/v inside fp_open) is asked
# for by a directive in the program rather than by calling something.
#
#     ; X16_GATE X16_USE_FILEPICK_EDIT
#
# It has to join the set BEFORE the bank layout is resolved, or -Bank
# would leave it in low RAM while the rest of the module moved out.
foreach ($line in (Get-Content $Program)) {
    if ($line -match '^\s*;\s*X16_GATE\s+(X16_USE_[A-Z0-9_]+)') { [void]$gates.Add($matches[1]) }
}
$enabled = @($gates)
Write-Host ("Modules used ({0}): {1}" -f $enabled.Count, (($enabled | Sort-Object) -join ", ")) -ForegroundColor Cyan

# --- 3. resolve the bank layout -> which gates go into which RAM bank ---
# Sources (first that applies):
#   -BankFile <path> : lines  `bank <N>, "mod,mod"`  (1..many banks)
#   -Bank "mod,mod"  : a single bank, number -BankNum
$bankSpec = @()   # list of @{ Num=<int>; Gates=@(...) }
function Resolve-Tokens($csv) {
    $out = @()
    foreach ($tok in ($csv.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $re = '^X16_USE_' + [regex]::Escape($tok.ToUpper()) + '(_.*)?$'
        $hit = @($enabled | Where-Object { $_ -match $re })
        if (-not $hit) { Write-Warning "bank spec '$tok' matches no module used by this program" }
        $out += $hit
    }
    return @($out | Sort-Object -Unique)
}
if ($BankFile) {
    if (-not (Test-Path $BankFile)) { throw "bank file not found: $BankFile" }
    foreach ($line in Get-Content $BankFile) {
        $l = ($line -replace '(#|;).*$', '').Trim()
        if (-not $l) { continue }
        if ($l -match '^bank\s+(\d+)\s*,\s*"([^"]*)"\s*$') {
            $bankSpec += @{ Num = [int]$matches[1]; Gates = (Resolve-Tokens $matches[2]) }
        } else {
            throw "bad bank-file line (expected: bank <N>, `"mod,mod`"):`n  $line"
        }
    }
} elseif ($Bank) {
    $bankSpec += @{ Num = $BankNum; Gates = (Resolve-Tokens $Bank) }
}

# gate -> bank number, and validate a gate isn't assigned to two banks
$bankOf = @{}
foreach ($b in $bankSpec) {
    foreach ($g in $b.Gates) {
        if ($bankOf.ContainsKey($g) -and $bankOf[$g] -ne $b.Num) {
            throw "module $g assigned to both bank $($bankOf[$g]) and bank $($b.Num)"
        }
        $bankOf[$g] = $b.Num
    }
}
$bankedGates = @($bankOf.Keys)
$lowGates    = @($enabled | Where-Object { $bankedGates -notcontains $_ } | Sort-Object)

# --- 4. build one companion image per bank ---
$bankInc = Join-Path $lib "x16lib_bankaddr.inc"
$cfgInc  = Join-Path $lib "x16lib_bankcfg.inc"
$loadInc = Join-Path $lib "x16lib_bankload.inc"
$addrLines = @("; GENERATED by build.ps1 -- addresses of routines relocated into RAM banks.")
$loadLines = @("; GENERATED by build.ps1 -- loads each bank image at startup.")
$symGate = Get-Content (Join-Path $lib "symbol_gates.json") -Raw | ConvertFrom-Json
$tass = Join-Path $sdk "64tass.exe"

foreach ($b in ($bankSpec | Where-Object { $_.Gates.Count -gt 0 })) {
    $n = $b.Num
    Write-Host ("Bank {0}: {1}" -f $n, ($b.Gates -join ", ")) -ForegroundColor Magenta
    $blobAsm = Join-Path $out "bank$n.asm"
    $blobBin = Join-Path $out ("BANK{0}.BIN" -f $n)
    $blobLbl = Join-Path $out "bank$n.lbl"
    $bl = @()
    foreach ($g in $b.Gates) { $bl += "$g = 1" }
    $bl += '* = $A000'
    $bl += '.include "x16lib_src.asm"'
    Set-Content -Path $blobAsm -Value $bl -Encoding ascii
    & $tass -C --cbm-prg -I $lib -o $blobBin --labels="$blobLbl" $blobAsm 2>&1 |
        Where-Object { $_ -match 'error' } | ForEach-Object { Write-Host $_ }
    if (-not (Test-Path $blobBin)) { throw "bank $n assembly failed" }
    $binSize = (Get-Item $blobBin).Length - 2
    Write-Host ("  BANK{0}.BIN = {1} bytes at `$A000" -f $n, $binSize)
    if ($binSize -gt 8192) { throw "bank $n is $binSize bytes -- exceeds the 8K window. Put fewer modules in it." }

    # export addresses of THIS bank's explicitly-listed modules (its own symbols)
    foreach ($line in Get-Content $blobLbl) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$([0-9A-Fa-f]+)\s*$') {
            $sym = $matches[1]; $addr = [Convert]::ToInt32($matches[2],16)
            if ($addr -ge 0xA000 -and $addr -le 0xBFFF -and
                ($symGate.PSObject.Properties.Name -contains $sym) -and
                ($b.Gates -contains $symGate.$sym)) {
                $addrLines += ('{0} = ${1:X4}' -f $sym, $addr)
            }
        }
    }
    # loader entry: select bank n, LOAD "BANKn.BIN" (secondary 1 -> file address)
    $fname = "BANK{0}.BIN" -f $n
    $fn = ([byte[]][char[]]$fname) -join ','
    $loadLines += @(
        "        lda #$n",
        "        sta `$00",
        "        lda #$($fname.Length)",
        "        ldx #<_bl_name$n",
        "        ldy #>_bl_name$n",
        "        jsr `$FFBD",
        "        lda #1",
        "        ldx #8",
        "        ldy #1",
        "        jsr `$FFBA",
        "        lda #0",
        "        jsr `$FFD5",
        "        bra _bl_after$n",
        "_bl_name$n .byte $fn",
        "_bl_after$n"
    )
}

# bank config: BANK_<gate> = its bank number (weak-0 default means low RAM)
$cfg = @("; GENERATED by build.ps1 -- module -> bank number.")
foreach ($g in ($bankedGates | Sort-Object)) { $cfg += "BANK_$g = $($bankOf[$g])" }
Set-Content -Path $cfgInc  -Value $cfg -Encoding ascii
Set-Content -Path $bankInc -Value $addrLines -Encoding ascii
Set-Content -Path $loadInc -Value $loadLines -Encoding ascii

# --- 5. write the low-RAM gates include ---
$incLines = @("; GENERATED by build.ps1 -- X16_USE_* gates assembled into low RAM.")
foreach ($g in $lowGates) { $incLines += "$g = 1" }
Set-Content -Path (Join-Path $lib "x16lib_gates.inc") -Value $incLines -Encoding ascii

# --- 6. compile ---
Write-Host "Compiling $Program ..." -ForegroundColor Cyan
& $java -jar (Join-Path $sdk "prog8c.jar") -target cx16 -srcdirs $lib -out $out $Program
if ($LASTEXITCODE -ne 0) { throw "prog8c failed (exit $LASTEXITCODE)" }

$prg = Join-Path $out ([IO.Path]::GetFileNameWithoutExtension($Program) + ".prg")
if (-not (Test-Path $prg)) { throw "expected output $prg not found" }
Write-Host "Built $prg" -ForegroundColor Green

if ($Run) {
    $x16 = Join-Path $emu "x16emu.exe"
    if (-not (Test-Path $x16)) { throw "emulator not found at $x16" }
    Write-Host "Launching emulator (-bitmap2 for VERA_2)..." -ForegroundColor Cyan
    # -fsroot points the emulated filesystem at build\ so a banked program's
    # LOAD "BANK.BIN" resolves to the companion image built alongside the PRG.
    & $x16 -rom (Join-Path $emu "rom.bin") -bitmap2 -fsroot $out -prg $prg -run
}
