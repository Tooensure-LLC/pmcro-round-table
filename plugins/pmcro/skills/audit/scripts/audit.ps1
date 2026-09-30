# audit.ps1 - the /audit skill (Auditor only, outside the chain, reports to Shawn).
# The Auditor agent supplies a draft with the four pillars and a finding; this script enforces the invariants and writes audit.jsonl.
# Usage (from the repo root): pwsh -File plugins/pmcro/skills/audit/scripts/audit.ps1 -Trail trails/NNNN-name -JsonFile <draft.json> [-Root .]
# Preconditions: the trail is sealed ACCEPT and its latest Checker verdict is PASS. finding must be AUDIT-PASS or AUDIT-HOLD.
# Refuses an unsealed trail, a non-PASS check, a finding not in the set, an absolute path (EC-0001), and refuses to overwrite (LAW-010, Append-Only).
param(
  [Parameter(Mandatory = $true)][string]$Trail,
  [Parameter(Mandatory = $true)][string]$JsonFile,
  [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\..\frame\scripts\Test-TrailPaths.ps1')
if (-not $Root) { $Root = (Get-Location).Path }
if (-not (Test-Path (Join-Path $Root '.git'))) { throw 'audit: run from the repo root (no .git in the current folder)' }
if ([IO.Path]::IsPathRooted($Trail) -or ($Trail -notmatch '^trails[\\/][^\\/]+$')) { throw "audit: -Trail must be relative, like trails/NNNN-name; got: $Trail" }
Assert-TrailPathScanWorks
$td = Join-Path $Root $Trail
if (-not (Test-Path $td)) { throw "audit: $Trail does not exist" }
# Precondition 1: the Auditor samples sealed trails that passed (disposition ACCEPT).
$disp = Join-Path $td 'disposition.json'
if (-not (Test-Path $disp)) { throw "audit refused: $Trail is not sealed (no disposition.json)" }
if (((Get-Content -Raw $disp | ConvertFrom-Json).disposition) -ne 'ACCEPT') { throw "audit refused: $Trail disposition is not ACCEPT" }
# Precondition 2: the latest independent Checker verdict is PASS.
$checks = @(Get-ChildItem $td -Filter '*-check.jsonl' | Sort-Object Name)
if ($checks.Count -eq 0) { throw "audit refused: $Trail has no Checker verdict" }
$lastCheck = (Get-Content $checks[-1].FullName | Where-Object { $_.Trim() } | Select-Object -Last 1) | ConvertFrom-Json
if ($lastCheck.verdict -ne 'PASS') { throw "audit refused: latest check $($checks[-1].Name) says $($lastCheck.verdict), not PASS" }
# Append-only: one Auditor finding per trail (LAW-010).
$out = Join-Path $td 'audit.jsonl'
if (Test-Path $out) { throw "append-only: $Trail already has audit.jsonl (LAW-010)" }
# The Auditor's draft: the four pillars (booleans) and a finding.
$src = Get-Content -Raw $JsonFile | ConvertFrom-Json -Depth 64
$finding = [string]$src.finding
if ($finding -notin @('AUDIT-PASS', 'AUDIT-HOLD')) { throw "audit refused: finding must be AUDIT-PASS or AUDIT-HOLD; got: $finding" }
$pillarNames = @('falsifiable', 'grounded', 'challenged', 'cost')
$pillars = $src.pillars
if (-not $pillars) { throw 'audit refused: pillars required (falsifiable, grounded, challenged, cost)' }
foreach ($p in $pillarNames) {
  $v = $pillars.$p
  if ($null -eq $v) { throw "audit refused: pillar '$p' required" }
  if ($v -isnot [bool]) { throw "audit refused: pillar '$p' must be true or false" }
}
# AUDIT-PASS iff all four pillars hold; AUDIT-HOLD iff at least one fails. The finding cannot disagree with the pillars.
$allTrue = @($pillarNames | Where-Object { -not $pillars.$_ }).Count -eq 0
if ($finding -eq 'AUDIT-PASS' -and -not $allTrue) { throw 'audit refused: AUDIT-PASS requires all four pillars true' }
if ($finding -eq 'AUDIT-HOLD' -and $allTrue) { throw 'audit refused: AUDIT-HOLD requires at least one pillar false' }
# Build the record: ts, role, phase, trail first, then the Auditor's own fields (finding, pillars, notes, ...).
$obj = [ordered]@{ ts = (Get-Date).ToString('o'); role = 'auditor'; phase = 'audit'; trail = ($Trail -replace '\\', '/') }
foreach ($prop in $src.PSObject.Properties) { if ($prop.Name -notin @('ts', 'role', 'phase', 'trail')) { $obj[$prop.Name] = $prop.Value } }
$line = [pscustomobject]$obj | ConvertTo-Json -Compress -Depth 64
$hits = @(Get-TrailPathHits -Text $line)
if ($hits.Count) { throw "EC-0001: absolute path in audit record: $($hits -join '; ')" }
[IO.File]::WriteAllText($out, $line + "`n", (New-Object System.Text.UTF8Encoding($false)))
"audit: $Trail finding=$finding pillars(falsifiable=$($pillars.falsifiable) grounded=$($pillars.grounded) challenged=$($pillars.challenged) cost=$($pillars.cost)); wrote $Trail/audit.jsonl"
