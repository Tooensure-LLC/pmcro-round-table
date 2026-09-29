# queue-status.ps1 - move one queue item to a new status (trails/0012-queue-lifecycle). Run from the repo root.
# Usage: powershell -File <plugin>/skills/loop/scripts/queue-status.ps1 -Id 0020 -Status taken -Trail trails/0012-queue-lifecycle
#        ... -Status partly_done -Trail trails/NNNN-name -Remaining "what is left"   |   ... -Status dropped -Reason "why"
# Refuses: an unknown status; taken/partly_done/done without a trail; partly_done/done for a trail that is not sealed ACCEPT;
# moving a done item anywhere; moving an item that lists trails back to queued. Runs tools/check-queue.ps1 after, when present.
param(
  [Parameter(Mandatory = $true)][string]$Id,
  [Parameter(Mandatory = $true)][ValidateSet('queued', 'taken', 'partly_done', 'done', 'dropped')][string]$Status,
  [string]$Trail = '',
  [string]$Remaining = '',
  [string]$Reason = '',
  [string]$Note = ''
)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root '.git'))) { throw 'queue-status: run from the repo root (no .git in the current folder)' }
$files = @(Get-ChildItem (Join-Path $root 'queue') -Filter "$Id*.json")
if ($files.Count -ne 1) { throw "queue-status: expected one queue item matching '$Id', found $($files.Count)" }
$f = $files[0]
$before = [IO.File]::ReadAllText($f.FullName)
$q = $before | ConvertFrom-Json
$old = [string]$q.status
$trails = @($q.trails | Where-Object { $_ })
$Trail = $Trail -replace '\\', '/'
if ($old -eq 'done') { throw "queue-status: $($f.BaseName) is done; a done item does not move" }
if ($Status -eq 'queued' -and $trails.Count) { throw "queue-status: $($f.BaseName) lists trails ($($trails -join ', ')); it cannot go back to queued" }
if ($Status -in 'taken', 'partly_done', 'done') {
  if (-not $Trail) { throw "queue-status: -Trail is required for $Status" }
  if ([IO.Path]::IsPathRooted($Trail) -or $Trail -notmatch '^trails/[^/]+$') { throw "queue-status: -Trail must be relative, like trails/NNNN-name; got: $Trail" }
  if (-not (Test-Path (Join-Path $root $Trail))) { throw "queue-status: $Trail does not exist" }
}
if ($Status -in 'partly_done', 'done') {
  $d = Join-Path $root "$Trail/disposition.json"
  if (-not ((Test-Path $d) -and ((Get-Content -Raw $d | ConvertFrom-Json).disposition -eq 'ACCEPT'))) { throw "queue-status: $Trail is not sealed ACCEPT, so $($f.BaseName) cannot be $Status" }
}
if ($Status -eq 'partly_done' -and -not $Remaining.Trim()) { throw 'queue-status: partly_done needs -Remaining' }
if ($Status -eq 'dropped' -and -not $Reason.Trim()) { throw 'queue-status: dropped needs -Reason' }
$q.status = $Status
if ($Trail -and ($trails -notcontains $Trail)) { $trails += $Trail }
function SetProp($name, $value) { if ($q.PSObject.Properties[$name]) { $q.$name = $value } else { $q | Add-Member -NotePropertyName $name -NotePropertyValue $value } }
if ($trails.Count) { SetProp 'trails' @($trails) }
if ($Remaining) { SetProp 'remaining' $Remaining }
if ($Reason) { SetProp 'dropped_reason' $Reason }
if ($Note) { SetProp 'status_note' $Note }
SetProp 'status_updated' (Get-Date).ToString('o')
[IO.File]::WriteAllText($f.FullName, ($q | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($true)))
$check = Join-Path $root 'tools/check-queue.ps1'
if (Test-Path $check) {
  $o = & powershell -NoProfile -ExecutionPolicy Bypass -File $check -Root $root
  if ($LASTEXITCODE -ne 0) {
    [IO.File]::WriteAllText($f.FullName, $before, (New-Object System.Text.UTF8Encoding($true)))
    $o | Where-Object { $_ -like 'FAIL*' } | Select-Object -First 5 | ForEach-Object { [Console]::Error.WriteLine($_) }
    throw "queue-status: check-queue failed after the move; $($f.BaseName) restored"
  }
}
"$($f.BaseName): $old -> $Status$(if ($Trail) { " ($Trail)" })"
