# frame.ps1 - the /frame skill: write one trail frame after the EC-0001 scan.
# Usage (from the repo root): pwsh -File plugins/pmcro/skills/frame/scripts/frame.ps1 -JsonFile <draft.json> -Out trails/NNNN-name/NN-role.jsonl
# The draft is plain JSON; a ts field is added first. Refuses to overwrite (append-only) and refuses any absolute path.
# Writes UTF-8 without a byte-order mark (trails/0001 02-check D7) and keeps nesting up to 64 levels.
param([Parameter(Mandatory = $true)][string]$JsonFile, [Parameter(Mandatory = $true)][string]$Out)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Test-TrailPaths.ps1')
# Root = the folder you run from (the repo root), not where this file sits, so an installed plugin copy writes into your repo.
$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root '.git'))) { throw 'frame: run from the repo root (no .git in the current folder)' }
if ([IO.Path]::IsPathRooted($Out) -or ($Out -notmatch '^trails[\\/][^\\/]+[\\/][^\\/]+\.jsonl$')) { throw "frame: -Out must be a relative path like trails/NNNN-name/NN-role.jsonl, got: $Out" }
Assert-TrailPathScanWorks
$src = Get-Content -Raw $JsonFile | ConvertFrom-Json -Depth 64
$obj = [ordered]@{ ts = (Get-Date).ToString('o') }
foreach ($p in $src.PSObject.Properties) { $obj[$p.Name] = $p.Value }
$line = [pscustomobject]$obj | ConvertTo-Json -Compress -Depth 64
$hits = @(Get-TrailPathHits -Text $line)
if ($hits.Count) { throw "EC-0001: absolute path found in frame: $($hits -join '; ')" }
$full = Join-Path $root $Out
if (Test-Path $full) { throw "append-only: $Out already exists" }
New-Item -ItemType Directory -Force (Split-Path -Parent $full) | Out-Null
[IO.File]::WriteAllText($full, $line + "`n", (New-Object System.Text.UTF8Encoding($false)))
"EC-0001 scan: controls pass; hits in frame=0; wrote $Out"
