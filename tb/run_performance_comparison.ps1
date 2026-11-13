param([string]$Baseline = 'main')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$out = Join-Path $repo 'build/performance_comparison'
New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $repo
try {
    $names = @('ADDER', 'COUNT_ADDER', 'MULTIPLIER', 'MAC_ADDER', 'MAC_MULTIPLIER', 'MAC', 'DUT')
    $legacySources = @()
    foreach ($name in $names) {
        $source = git show "${Baseline}:DUT/rtl/$name.sv"
        if ($LASTEXITCODE -ne 0) { throw "Cannot read $name from $Baseline" }
        $path = Join-Path $out "$name.sv"
        [System.IO.File]::WriteAllText($path, ($source -join "`n"))
        $legacySources += $path
    }
    $legacyExe = Join-Path $out 'legacy.vvp'
    & iverilog -g2012 -DLEGACY -s tb_performance -o $legacyExe @legacySources tb/tb_performance.sv
    if ($LASTEXITCODE -ne 0) { throw 'Baseline compilation failed' }
    & vvp $legacyExe
    if ($LASTEXITCODE -ne 0) { throw 'Baseline performance check failed' }
    $currentExe = Join-Path $out 'current.vvp'
    & iverilog -g2012 -s tb_performance -o $currentExe rtl/ADDER.sv rtl/MULTIPLIER.sv rtl/VEDIC4_PIPELINED.sv rtl/MAC.sv rtl/MAC4x4.sv tb/tb_performance.sv
    if ($LASTEXITCODE -ne 0) { throw 'Current compilation failed' }
    & vvp $currentExe
    if ($LASTEXITCODE -ne 0) { throw 'Current performance check failed' }
} finally { Pop-Location }
