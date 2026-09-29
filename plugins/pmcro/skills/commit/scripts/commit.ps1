# commit.ps1 - the Maker's only way to commit (skill /pmcro:commit). Local commit only; never pushes.
# Usage (repo root): powershell -NoProfile -ExecutionPolicy Bypass -File plugins/pmcro/skills/commit/scripts/commit.ps1 trails/NNNN-name "message"
# Exit 0 = committed, 1 = refused (reason on stderr), 2 = nothing to commit.
param(
  [Parameter(Mandatory, Position = 0)][string]$Trail,
  [Parameter(Mandatory, Position = 1)][string]$Message
)
$ErrorActionPreference = 'Stop'
function Refuse([string]$why) { [Console]::Error.WriteLine("commit refused: $why"); exit 1 }

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root '.git'))) { Refuse 'run from the repo root (no .git here).' }
if ([IO.Path]::IsPathRooted($Trail) -or $Trail -notmatch '^trails/\d{4}-[a-z0-9-]+/?$') { Refuse "trail must be a relative path trails/NNNN-name, got '$Trail'." }
$Trail = $Trail.TrimEnd('/')
$tdir = Join-Path $root $Trail
if (-not (Test-Path (Join-Path $tdir '00-frame.jsonl'))) { Refuse "$Trail has no 00-frame.jsonl (Log Before Act, EC-SYS-003)." }
if (Test-Path (Join-Path $tdir 'disposition.json')) { Refuse "$Trail is sealed; open a new trail (Append-Only, LAW-010)." }
if ($Message -match "[`r`n]") { Refuse 'message must be one line.' }

# 1. Regenerate: generated files must match company.json in every commit.
$ps = (Get-Process -Id $PID).Path  # same PowerShell that runs this script (pwsh 7 preferred)
& $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools/build.ps1') | Write-Host
if ($LASTEXITCODE) { Refuse 'tools/build.ps1 failed.' }

# 2. Validate the plugin marketplace.
& $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'eng/skill-validator/Test-PluginLayout.ps1') -Root $root | Where-Object { $_ -like 'FAIL*' } | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE) { Refuse 'eng/skill-validator/Test-PluginLayout.ps1 failed.' }

# 3. Absolute-path scan (EC-PORTABLE-005), first proven able to fail on a sample built by the same serializer (EC-0001).
$abs = '(?i)(?<![A-Za-z0-9])[A-Z]:[\\/]|(?<![A-Za-z0-9.])/(Users|home|root|mnt)/'
$sample = [ordered]@{ path = 'C:' + [char]92 + 'probe' } | ConvertTo-Json -Compress
if ($sample -notmatch $abs) { Refuse 'absolute-path scan could not detect its own sample; scan is broken.' }
git -C $root add -A
$staged = @(git -C $root diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -like 'trails/*' })
$hits = @($staged | Where-Object { (Get-Content -Raw (Join-Path $root $_)) -match $abs })
if ($hits.Count) { git -C $root reset -q; Refuse "absolute path in staged trail file(s): $($hits -join ', ')" }

# 4. One local commit, named for the trail.
if (-not (git -C $root diff --cached --name-only)) { Write-Host 'nothing to commit'; exit 2 }
$id = ($Trail -split '/')[1].Substring(0, 4)
git -C $root commit -q -m "trail ${id}: $Message" -m "Trail: $Trail"
if ($LASTEXITCODE) { Refuse 'git commit failed.' }
git -C $root log -1 --format='%h %s'
exit 0
