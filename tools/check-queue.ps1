# check-queue.ps1 - prove every queue item's status agrees with the trails (old-repo trails/0012-queue-lifecycle).
# Usage (repo root): powershell -File tools/check-queue.ps1 [-Root <copy>]. Exit 0 = PASS, 1 = FAIL (one line per fault). Read-only.
# Statuses: queued (no trails) | taken (by an existing trail) | partly_done (sealed trails + remaining) | done (sealed trails) | dropped (reason).
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$allowed = @('queued', 'taken', 'partly_done', 'done', 'dropped')
. (Join-Path $Root 'plugins/pmcro/skills/frame/scripts/Test-TrailPaths.ps1')  # the shared path scan
$fails = 0
function Fail([string]$m) { Write-Output "FAIL $m"; $script:fails++ }
function Sealed([string]$t) {
  $d = Join-Path $Root (Join-Path $t 'disposition.json')
  (Test-Path $d) -and ((Get-Content -Raw $d | ConvertFrom-Json).disposition -eq 'ACCEPT')
}
$qdir = Join-Path $Root 'queue'
if (-not (Test-Path $qdir)) { Write-Output 'FAIL queue/ does not exist'; Write-Output 'RESULT FAIL (1) over 0 items'; exit 1 }
$items = @(Get-ChildItem $qdir -Filter '*.json' | Sort-Object Name)
foreach ($f in $items) {
  $n = $f.BaseName
  try { $q = Get-Content -Raw $f.FullName | ConvertFrom-Json } catch { Fail "$n does not parse"; continue }
  $s = [string]$q.status
  $trails = @($q.trails | Where-Object { $_ })
  if ($allowed -notcontains $s) { Fail "$n status '$s' is not one of: $($allowed -join ', ')"; continue }
  foreach ($t in $trails) {
    if (@(Get-PathHitsInString $t).Count -or $t -notmatch '^trails/[^/]+$') { Fail "$n trail '$t' is not a relative trails/NNNN-name path"; continue }
    if (-not (Test-Path (Join-Path $Root $t))) { Fail "$n trail '$t' does not exist" }
  }
  switch ($s) {
    'queued'      { if ($trails.Count) { Fail "$n is queued but lists trails: $($trails -join ', ')" } }
    'taken'       { if (-not $trails.Count) { Fail "$n is taken but lists no trail" } }
    'partly_done' {
      if (-not $trails.Count) { Fail "$n is partly_done but lists no trail" }
      foreach ($t in $trails) { if (-not (Sealed $t)) { Fail "$n is partly_done but $t is not sealed ACCEPT" } }
      if (-not ([string]$q.remaining).Trim()) { Fail "$n is partly_done but says nothing in remaining" }
    }
    'done' {
      if (-not $trails.Count) { Fail "$n is done but lists no trail" }
      foreach ($t in $trails) { if (-not (Sealed $t)) { Fail "$n is done but $t is not sealed ACCEPT" } }
    }
    'dropped'     { if (-not ([string]$q.dropped_reason).Trim()) { Fail "$n is dropped with no dropped_reason" } }
  }
}
if ($fails) { Write-Output "RESULT FAIL ($fails) over $($items.Count) items"; exit 1 }
Write-Output "RESULT PASS over $($items.Count) items"
exit 0
