<#
.SYNOPSIS
  CC-0001-DETERMINISM: tools/build.ps1 must reproduce the committed generated files exactly, every run.
.DESCRIPTION
  -Mode Clone (default, CI): clone HEAD into a temp folder, run build.ps1 twice in fresh pwsh processes, require an
  empty `git status` after each run. -Mode InPlace (/pmcro:commit): run build.ps1 twice here and require both runs to
  leave identical hashes for every file the build writes. Exit 0 = PASS, 1 = FAIL.
#>
[CmdletBinding()]
param([ValidateSet('Clone', 'InPlace')][string]$Mode = 'Clone', [int]$Runs = 2)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ps = (Get-Process -Id $PID).Path

if ($Mode -eq 'Clone') {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("pmcro-det-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
  git clone -q --no-hardlinks $root $tmp 2>&1 | Out-Null
  if ($LASTEXITCODE) { Write-Output "FAIL could not clone"; exit 1 }
  try {
    for ($i = 1; $i -le $Runs; $i++) {
      & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tmp 'tools/build.ps1') | Out-Null
      if ($LASTEXITCODE) { Write-Output "FAIL build.ps1 exit $LASTEXITCODE on run $i"; exit 1 }
      $dirty = @(git -C $tmp status --porcelain)
      if ($dirty.Count) { Write-Output "FAIL run ${i}: build changed committed files: $(($dirty | ForEach-Object { $_.Trim() }) -join '; ')"; exit 1 }
    }
    Write-Output "PASS $Runs fresh runs of tools/build.ps1 on a clean clone left git status empty"
    exit 0
  } finally { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}

$snap = {
  $changed = @(git -C $root status --porcelain --untracked-files=all | ForEach-Object { $_.Substring(3).Trim('"') } | Where-Object { $_ -notlike 'trails/*' -and $_ -notlike 'queue/*' } | Sort-Object)
  $changed | ForEach-Object { $p = Join-Path $root $_; if (Test-Path -LiteralPath $p -PathType Leaf) { "$_ $((Get-FileHash -LiteralPath $p).Hash)" } else { "$_ gone" } }
}
$first = $null
for ($i = 1; $i -le $Runs; $i++) {
  & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools/build.ps1') | Out-Null
  if ($LASTEXITCODE) { Write-Output "FAIL build.ps1 exit $LASTEXITCODE on run $i"; exit 1 }
  $now = @(& $snap)
  if ($null -eq $first) { $first = $now; continue }
  $diff = @(Compare-Object $first $now)
  if ($diff.Count) { Write-Output "FAIL run $i differs from run 1: $(($diff | ForEach-Object { $_.InputObject.Split(' ')[0] } | Sort-Object -Unique) -join '; ')"; exit 1 }
}
Write-Output "PASS $Runs in-place runs of tools/build.ps1 produced identical output"
exit 0
