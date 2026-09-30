# seal.ps1 - the /seal skill (Reflector only, after a Checker PASS and Shawn's go).
# Usage (from the repo root): powershell -File <plugin>/skills/seal/scripts/seal.ps1 (in the company repo: plugins/pmcro/skills/seal/scripts/seal.ps1) -Trail trails/NNNN-name -ApprovedBy "Shawn (live chat)"
# Writes disposition.json with file_hashes_at_seal for every *.jsonl frame. Refuses without a latest PASS, refuses to overwrite.
# ACCEPT requires cos_handoff stub (no commit_ref at seal time; Reflector writes cos-handoff.jsonl after commit).
param(
  [Parameter(Mandatory = $true)][string]$Trail,
  [Parameter(Mandatory = $true)][string]$ApprovedBy,
  [string]$Checker = 'cto-checker',
  [int]$Loops = 1,
  [string]$Root = '',
  [string]$HandTo = 'chief-of-staff'
)
$ErrorActionPreference = 'Stop'
# Root = the folder you run from (the repo root), not where this file sits (old-repo trails/0010-pmcro-plugin-self-contained).
if (-not $Root) { $Root = (Get-Location).Path }
if (-not (Test-Path (Join-Path $Root '.git'))) { throw 'seal: run from the repo root (no .git in the current folder)' }
if ([IO.Path]::IsPathRooted($Trail) -or ($Trail -notmatch '^trails[\\/][^\\/]+$')) { throw "seal: -Trail must be relative, like trails/NNNN-name; got: $Trail" }
$td = Join-Path $Root $Trail
$out = Join-Path $td 'disposition.json'
if (Test-Path $out) { throw "append-only: $Trail is already sealed" }
$checks = @(Get-ChildItem $td -Filter '*-check.jsonl' | Sort-Object Name)
if ($checks.Count -eq 0) { throw "seal refused: $Trail has no Checker verdict" }
$last = (Get-Content $checks[-1].FullName | Where-Object { $_.Trim() } | Select-Object -Last 1) | ConvertFrom-Json
if ($last.verdict -ne 'PASS') { throw "seal refused: latest check $($checks[-1].Name) says $($last.verdict), not PASS" }
$pat = '[A-Za-z]:(\\\\|\\|/)[A-Za-z]'
$control = ((@{ x = 'E:\PMCRO' } | ConvertTo-Json -Compress) -match $pat)
if (-not $control) { throw 'EC-0001 control failed' }
$hashes = [ordered]@{}
Get-ChildItem $td -File -Filter '*.jsonl' | Sort-Object Name | ForEach-Object { $hashes[$_.Name] = (Get-FileHash $_.FullName).Hash }
$trailRel = ($Trail -replace '\\', '/')
$dispositionRel = "$trailRel/disposition.json"
if ($dispositionRel -notmatch '^trails/[^/]+/disposition\.json$') { throw "seal refused: disposition_rel must be relative trails/NNNN-name/disposition.json; got: $dispositionRel" }
$cosHandoff = [ordered]@{
  to = $HandTo
  purpose = 'route Auditor before listing'
  status = 'pending_commit_then_route'
  disposition_rel = $dispositionRel
}
function Assert-CosHandoffStub {
  param($Handoff)
  if (-not $Handoff) { throw 'seal refused: ACCEPT disposition lacks cos_handoff stub' }
  foreach ($k in @('to','purpose','status','disposition_rel')) {
    $v = $Handoff.$k
    if ([string]::IsNullOrWhiteSpace([string]$v)) { throw "seal refused: cos_handoff.$k required" }
  }
  if ($Handoff.disposition_rel -notmatch '^trails/[^/]+/disposition\.json$') {
    throw "seal refused: cos_handoff.disposition_rel must be relative trails/NNNN-name/disposition.json"
  }
  if ($Handoff.disposition_rel -match $pat) { throw 'EC-0001: absolute path in cos_handoff.disposition_rel' }
  $names = @($Handoff.PSObject.Properties.Name)
  if ($Handoff -is [System.Collections.IDictionary]) { $names = @($Handoff.Keys) }
  if ($names -contains 'commit_ref') { throw 'seal refused: commit_ref must not be in seal-time cos_handoff (post-commit cos-handoff.jsonl only)' }
}
Assert-CosHandoffStub $cosHandoff
$d = [ordered]@{
  trail = $trailRel
  disposition = 'ACCEPT'
  sealed_ts = (Get-Date).ToString('o')
  sealed_by = 'reflector'
  verdict = 'PASS'
  checker = $Checker
  loops = $Loops
  recorded_defects = @()
  earned_constraints = @()
  auditor_review = 'pending'
  approved_by = $ApprovedBy
  file_hashes_at_seal = $hashes
  cos_handoff = $cosHandoff
}
if ($d.disposition -eq 'ACCEPT') { Assert-CosHandoffStub $d.cos_handoff }
$line = [pscustomobject]$d | ConvertTo-Json -Compress -Depth 6
if ($line -match $pat) { throw 'EC-0001: absolute path in disposition' }
[IO.File]::WriteAllText($out, $line + "`n", (New-Object System.Text.UTF8Encoding($true)))
"EC-0001 scan: control=$control hits=0; sealed $Trail with $($hashes.Count) file hashes; cos_handoff stub status=$($cosHandoff.status)"
