<#
.SYNOPSIS
  Vendors repo-maintainer skills from dotnet/skills (MIT) at a pinned commit into .agents/skills/.
.DESCRIPTION
  Build off others: dotnet/skills keeps skills for working ON the repo in .agents/skills/ and shipped skills in
  plugins/<plugin>/skills/. We copy their maintainer skills unchanged, pinned to one commit, and record the
  provenance in .agents/skills/UPSTREAM.json and THIRD-PARTY-NOTICES.md. Re-run with -Ref <sha> to update.
  Refuses to overwrite a local change: a vendored folder whose files differ from UPSTREAM.json hashes is skipped.
#>
[CmdletBinding()]
param(
  [string]$Repo = 'dotnet/skills',
  [string]$Ref = '',
  [string[]]$Skills = @('create-skill', 'create-skill-test', 'improve-skill-quality', 'create-custom-agent', 'authoring-github-workflows')
)
$ErrorActionPreference = 'Stop'
# gh writes UTF-8; Windows PowerShell 5.1 decodes native output with the OEM code page unless told otherwise.
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$root = Split-Path $PSScriptRoot -Parent
if (-not $Ref) { $Ref = gh api "repos/$Repo/commits/main" --jq '.sha' }
if ($LASTEXITCODE -or $Ref -notmatch '^[0-9a-f]{40}$') { throw "could not resolve a commit sha for $Repo (got '$Ref')" }
$dest = Join-Path $root '.agents/skills'
New-Item -ItemType Directory -Force $dest | Out-Null
$manifestPath = Join-Path $dest 'UPSTREAM.json'
$old = if (Test-Path $manifestPath) { Get-Content -Raw $manifestPath | ConvertFrom-Json } else { $null }

# Parse JSON in PowerShell: Windows PowerShell 5.1 drops the double quotes a --jq filter would need.
$tree = @((gh api "repos/$Repo/git/trees/${Ref}?recursive=1" | ConvertFrom-Json).tree | Where-Object type -eq 'blob' | ForEach-Object path)
$files = [ordered]@{}
foreach ($s in $Skills) {
  $paths = @($tree | Where-Object { $_ -like ".agents/skills/$s/*" } | Sort-Object)
  if (-not $paths) { throw "$Repo@$Ref has no .agents/skills/$s" }
  $local = Join-Path $dest $s
  if ($old -and (Test-Path $local)) {
    $changed = @($old.files.PSObject.Properties | Where-Object { $_.Name -like "$s/*" } | Where-Object {
      $p = Join-Path $dest $_.Name; -not (Test-Path $p) -or (Get-FileHash $p -Algorithm SHA256).Hash -ne $_.Value })
    if ($changed) { Write-Warning "skip $s : local edits in $($changed.Name -join ', ')"; continue }
    Remove-Item -Recurse -Force $local
  }
  foreach ($p in $paths) {
    $rel = $p.Substring('.agents/skills/'.Length)
    $out = Join-Path $dest $rel
    New-Item -ItemType Directory -Force (Split-Path $out -Parent) | Out-Null
    $raw = gh api "repos/$Repo/contents/${p}?ref=$Ref" -H 'Accept: application/vnd.github.raw'
    if ($LASTEXITCODE) { throw "download failed: $p" }
    [IO.File]::WriteAllText($out, (($raw -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
    $files[$rel] = (Get-FileHash $out -Algorithm SHA256).Hash
  }
  Write-Host "vendored $s ($($paths.Count) files)"
}
$manifest = [ordered]@{ source = "https://github.com/$Repo"; ref = $Ref; license = 'MIT'; path = '.agents/skills'; skills = $Skills; files = $files }
[IO.File]::WriteAllText($manifestPath, (($manifest | ConvertTo-Json -Depth 5) + "`n"), (New-Object Text.UTF8Encoding($false)))
$notice = @"
# Third-party notices

## dotnet/skills

Files under ``.agents/skills/`` listed in ``.agents/skills/UPSTREAM.json`` are copied unchanged from
https://github.com/$Repo at commit ``$Ref``, licensed under the MIT License (Copyright (c) .NET Foundation and Contributors).
Update them only with ``eng/sync-upstream.ps1``.
"@
[IO.File]::WriteAllText((Join-Path $root 'THIRD-PARTY-NOTICES.md'), ($notice -replace "`r`n", "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
"sync-upstream: $Repo@$($Ref.Substring(0,12)) -> .agents/skills ($(@($files.Keys).Count) files)"
