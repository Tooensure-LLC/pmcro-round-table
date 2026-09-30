# commit.ps1 - the Maker's only way to commit (skill /pmcro:commit). Local commit only; never pushes.
# Usage (repo root): pwsh -NoProfile -File plugins/pmcro/skills/commit/scripts/commit.ps1 trails/NNNN-name "message"
# Exit 0 = committed, 1 = refused (reason on stderr), 2 = nothing to commit.
# Gates, in order: open trail; generator is deterministic (CC-0001-DETERMINISM); plugin validator; dotnet test (when a
# solution exists); shared absolute-path scan over every added, copied, modified or renamed trail file (EC-PORTABLE-005).
param(
  [Parameter(Mandatory, Position = 0)][string]$Trail,
  [Parameter(Mandatory, Position = 1)][string]$Message
)
$ErrorActionPreference = 'Stop'
function Refuse([string]$why) { [Console]::Error.WriteLine("commit refused: $why"); exit 1 }
. (Join-Path $PSScriptRoot '../../frame/scripts/Test-TrailPaths.ps1')

$root = (Get-Location).Path
$ps = (Get-Process -Id $PID).Path  # the same PowerShell that runs this script (pwsh 7)
if (-not (Test-Path (Join-Path $root '.git'))) { Refuse 'run from the repo root (no .git here).' }
if ([IO.Path]::IsPathRooted($Trail) -or $Trail -notmatch '^trails/\d{4}-[a-z0-9-]+/?$') { Refuse "trail must be a relative path trails/NNNN-name, got '$Trail'." }
$Trail = $Trail.TrimEnd('/')
$tdir = Join-Path $root $Trail
if (-not (Test-Path (Join-Path $tdir '00-frame.jsonl'))) { Refuse "$Trail has no 00-frame.jsonl (Log Before Act, EC-SYS-003)." }
if (Test-Path (Join-Path $tdir 'disposition.json')) { Refuse "$Trail is sealed; open a new trail (Append-Only, LAW-010)." }
if ($Message -match "[`r`n]") { Refuse 'message must be one line.' }

# 1. Regenerate twice; both runs must agree (CC-0001-DETERMINISM, in-place variant; CI runs the clean-clone variant).
& $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'eng/Test-Determinism.ps1') -Mode InPlace | Write-Host
if ($LASTEXITCODE) { Refuse 'tools/build.ps1 is not deterministic (eng/Test-Determinism.ps1).' }

# 2. Plugin marketplace layout, hook shape and host marketplaces.
$v = @(& $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'eng/skill-validator/Test-PluginLayout.ps1') -Root $root)
if ($LASTEXITCODE) { $v | Where-Object { $_ -like 'FAIL*' } | ForEach-Object { Write-Host $_ }; Refuse 'eng/skill-validator/Test-PluginLayout.ps1 failed.' }

# 3. Tests, when the repo has a solution (trails/0001 02-check b2: a broken hook shape was committed because tests never ran).
$sln = @(Get-ChildItem $root -Filter '*.slnx' -File) + @(Get-ChildItem $root -Filter '*.sln' -File) | Select-Object -First 1
if ($sln) {
  $t = @(dotnet test $sln.FullName -c Release --nologo 2>&1)
  if ($LASTEXITCODE) { $t | Select-Object -Last 15 | ForEach-Object { Write-Host $_ }; Refuse "dotnet test failed on $($sln.Name)." }
  Write-Host ($t | Where-Object { $_ -match 'Passed!|Failed!' } | Select-Object -Last 1)
}

# 4. Shared absolute-path scan, first proven able to fail (EC-0001), over every staged trail file including renames.
Assert-TrailPathScanWorks
git -C $root add -A
$staged = @(git -C $root diff --cached --name-only --diff-filter=ACMR -- trails queue)
$hits = @(foreach ($f in $staged) { $h = @(Get-TrailPathHits -Text (Get-Content -Raw -LiteralPath (Join-Path $root $f))); if ($h.Count) { "$f ($($h -join '; '))" } })
if ($hits.Count) { git -C $root reset -q; Refuse "absolute path in staged trail or queue file(s): $($hits -join ', ')" }

# 5. One local commit, named for the trail.
if (-not (git -C $root diff --cached --name-only)) { Write-Host 'nothing to commit'; exit 2 }
$id = ($Trail -split '/')[1].Substring(0, 4)
git -C $root commit -q -m "trail ${id}: $Message" -m "Trail: $Trail"
if ($LASTEXITCODE) { Refuse 'git commit failed.' }
git -C $root log -1 --format='%h %s'
exit 0
