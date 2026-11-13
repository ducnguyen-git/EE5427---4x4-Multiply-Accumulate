$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$simDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('mac4x4-tests-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $simDirectory | Out-Null
Push-Location $repoRoot
try {
    # Compile the package before sources that reference package parameters.
    $sources = @('rtl/uart/uart_pkg.sv')
    $sources += @(Get-ChildItem rtl -Filter *.sv | ForEach-Object { $_.FullName })
    $sources += @(Get-ChildItem rtl/uart -Filter *.sv |
        Where-Object { $_.Name -ne 'uart_pkg.sv' } | ForEach-Object { $_.FullName })
    foreach ($top in @('tb_ADDER', 'tb_MULTIPLIER', 'tb_VEDIC4_PIPELINED', 'tb_MAC', 'tb_MAC4x4', 'tb_MAC4x4_uart')) {
        $executable = Join-Path $simDirectory "$top.vvp"
        & iverilog -g2012 -s $top -o $executable @sources "tb/$top.sv"
        if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $top" }
        & vvp $executable
        if ($LASTEXITCODE -ne 0) { throw "Simulation failed: $top" }
    }
} finally {
    Pop-Location
}
Write-Host "All six testbenches passed. Simulation files: $simDirectory"
