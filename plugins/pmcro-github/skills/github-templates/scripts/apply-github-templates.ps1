# apply-github-templates.ps1 - copy the .github templates into a repo folder. DRY RUN by default. Run from the repo root.
# Usage: apply-github-templates.ps1 [-Target .] [-Apply]
# Never overwrites an existing file, never runs git, refuses absolute paths and '..'.
param([string]$Target = '.', [switch]$Apply)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$src = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets/.github'
if ([IO.Path]::IsPathRooted($Target) -or $Target -match '\.\.') { throw "Target must be a relative folder inside the repo: $Target" }
$destRoot = Join-Path (Join-Path $root $Target) '.github'
$srcFull = (Resolve-Path -LiteralPath $src).Path
$new = 0; $skip = 0
foreach ($f in Get-ChildItem -LiteralPath $srcFull -Recurse -File -Force) {
  $rel = $f.FullName.Substring($srcFull.Length).TrimStart('\', '/')
  $to = Join-Path $destRoot $rel
  $relShow = '.github/' + ($rel -replace '\\', '/')
  if (Test-Path -LiteralPath $to) { Write-Host "EXISTS  $relShow (kept)"; $skip++; continue }
  Write-Host "NEW     $relShow"
  $new++
  if ($Apply) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $to) | Out-Null
    Copy-Item -LiteralPath $f.FullName -Destination $to
  }
}
if ($Apply) { Write-Host "applied $new new file(s), kept $skip existing. Nothing committed or pushed." }
else { Write-Host "DRY RUN: $new new, $skip existing. Nothing changed. Re-run with -Apply after Shawn says go." }
