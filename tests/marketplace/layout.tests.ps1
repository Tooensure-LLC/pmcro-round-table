# layout.tests.ps1 - skills marketplace layout checks. Run from repo root.
param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$failed = 0
function Assert-Path([string]$Rel) {
  $p = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $p)) {
    Write-Host "FAIL missing: $Rel"
    $script:failed++
    return $false
  }
  Write-Host "OK $Rel"
  return $true
}
$null = Assert-Path '.claude-plugin/marketplace.json'
$null = Assert-Path '.agents/plugins/marketplace.json'
$null = Assert-Path '.cursor-plugin/marketplace.json'
$null = Assert-Path 'plugins/pmcro-docs/skills/simulate/SKILL.md'
$null = Assert-Path 'plugins/pmcro-docs/skills/docfx/SKILL.md'
$null = Assert-Path 'eng/skill-validator/Test-PluginLayout.ps1'
$null = Assert-Path 'docs/marketplace/README.md'
$null = Assert-Path 'marketplace/catalog.json'
$null = Assert-Path 'tests/marketplace/layout.tests.ps1'
if ((Test-Path -LiteralPath (Join-Path $Root '.claude-plugin/marketplace.json'))) {
  $c = Get-Content (Join-Path $Root '.claude-plugin/marketplace.json') -Raw | ConvertFrom-Json
  if (-not $c.name -or -not $c.owner.name -or @($c.plugins).Count -lt 2) { Write-Host 'FAIL claude marketplace shape'; $failed++ } else { Write-Host 'OK claude marketplace shape' }
} else {
  Write-Host 'SKIP claude marketplace shape (file missing)'
}
if ((Test-Path -LiteralPath (Join-Path $Root '.agents/plugins/marketplace.json'))) {
  $a = Get-Content (Join-Path $Root '.agents/plugins/marketplace.json') -Raw | ConvertFrom-Json
  if (-not $a.name -or -not $a.owner.name -or -not $a.interface.displayName -or @($a.plugins).Count -lt 2) { Write-Host 'FAIL agents marketplace shape'; $failed++ } else { Write-Host 'OK agents marketplace shape' }
} else {
  Write-Host 'SKIP agents marketplace shape (file missing)'
}
# Full dotnet/skills layout check (trails/0008): every plugin, manifest, skill and agent
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'eng/skill-validator/Test-PluginLayout.ps1') -Root $Root
if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL eng/skill-validator/Test-PluginLayout.ps1'; $failed++ } else { Write-Host 'OK eng/skill-validator/Test-PluginLayout.ps1' }
if ($failed -gt 0) { Write-Host "RESULT FAIL ($failed)"; exit 1 }
Write-Host 'RESULT PASS'
exit 0
