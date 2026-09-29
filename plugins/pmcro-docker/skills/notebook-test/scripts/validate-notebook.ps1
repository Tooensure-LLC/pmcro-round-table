# validate-notebook.ps1 - check a test notebook without running it. Usage (repo root):
#   powershell -File plugins/pmcro-docker/skills/notebook-test/scripts/validate-notebook.ps1 -Path <file.ipynb>
# Exit 0 = PASS, 1 = FAIL. Hardware gate: a code cell with docker build or docker run is a failure.
param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$fails = 0
function Fail([string]$m) { Write-Host "FAIL $m"; $script:fails++ }
if (-not (Test-Path -LiteralPath $Path)) { Write-Host "FAIL file not found: $Path"; Write-Host 'RESULT FAIL'; exit 1 }
try { $nb = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json } catch { Write-Host 'FAIL not valid JSON'; Write-Host 'RESULT FAIL'; exit 1 }
if ($nb.nbformat -ne 4) { Fail "nbformat is '$($nb.nbformat)', expected 4" }
$cells = @($nb.cells)
if ($cells.Count -eq 0) { Fail 'no cells' }
$i = 0
foreach ($c in $cells) {
  $i++
  if ($c.cell_type -eq 'code') {
    $src = (@($c.source) -join '')
    if ($src -match 'docker\s+(build|run)\b') { Fail "cell $i has '$($Matches[0])' (hardware gate closed)" }
  }
}
if ($fails -gt 0) { Write-Host "RESULT FAIL ($fails)"; exit 1 }
Write-Host "OK $Path ($($cells.Count) cells)"
Write-Host 'RESULT PASS'
exit 0
