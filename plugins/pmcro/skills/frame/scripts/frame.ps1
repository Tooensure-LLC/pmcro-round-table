# frame.ps1 - the /frame skill: write one trail frame after the EC-0001 scan.
# Usage (from the repo root): powershell -File <plugin>/skills/frame/scripts/frame.ps1 (in the company repo: plugins/pmcro/skills/frame/scripts/frame.ps1) -JsonFile <draft.json> -Out trails/NNNN-name/00-frame.jsonl
# The draft is plain JSON; a ts field is added first. Refuses to overwrite (append-only) and refuses any absolute path.
param([Parameter(Mandatory = $true)][string]$JsonFile, [Parameter(Mandatory = $true)][string]$Out)
$ErrorActionPreference = 'Stop'
# Root = the folder you run from (the repo root), not where this file sits, so an installed plugin copy
# writes into your repo (trails/0010-pmcro-plugin-self-contained).
$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root '.git'))) { throw 'frame: run from the repo root (no .git in the current folder)' }
if ([IO.Path]::IsPathRooted($Out) -or ($Out -notmatch '^trails[\\/][^\\/]+[\\/][^\\/]+\.jsonl$')) { throw "frame: -Out must be a relative path like trails/NNNN-name/NN-role.jsonl, got: $Out" }
# EC-0001: prove the scan can fail on a sample built by the same serializer, then scan the frame
$pat = '[A-Za-z]:(\\\\|\\|/)[A-Za-z]'
$control = ((@{ x = 'E:\PMCRO' } | ConvertTo-Json -Compress) -match $pat)
if (-not $control) { throw 'EC-0001: control failed to detect a path; scan not trusted' }
$src = Get-Content -Raw $JsonFile | ConvertFrom-Json
$obj = [ordered]@{ ts = (Get-Date).ToString('o') }
foreach ($p in $src.PSObject.Properties) { $obj[$p.Name] = $p.Value }
$line = [pscustomobject]$obj | ConvertTo-Json -Compress -Depth 8
if ($line -match $pat) { throw "EC-0001: absolute path found in frame: $($Matches[0])" }
$full = Join-Path $root $Out
if (Test-Path $full) { throw "append-only: $Out already exists" }
New-Item -ItemType Directory -Force (Split-Path -Parent $full) | Out-Null
[IO.File]::WriteAllText($full, $line + "`n", (New-Object System.Text.UTF8Encoding($true)))
"EC-0001 scan: control detects=$control; hits in frame=0; wrote $Out"
