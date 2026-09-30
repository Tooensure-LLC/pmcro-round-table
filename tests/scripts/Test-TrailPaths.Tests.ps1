# Test-TrailPaths.Tests.ps1 - cases for the shared trail path scan. Run: pwsh -File tests/scripts/Test-TrailPaths.Tests.ps1
# Exit 0 = PASS. Includes the Checker's loop 1 cases (02-check c2, c4) and the prose false positive that blocked a commit.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root 'plugins/pmcro/skills/frame/scripts/Test-TrailPaths.ps1')
$bs = [string][char]92
$cases = @(
  @{ name = 'drive backslash';   value = "C:${bs}Users${bs}x";                         hit = $true  },
  @{ name = 'drive slash';       value = 'see C:/DevDrives/pmcro-dev.vhdx';           hit = $true  },
  @{ name = 'unc in prose';      value = "copied from $bs${bs}fileserver${bs}share${bs}a"; hit = $true },
  @{ name = 'posix value';       value = '/home/runner/work';                         hit = $true  },
  @{ name = 'posix in prose';    value = 'flags /Users/, /home/ style paths';         hit = $false },
  @{ name = 'url';               value = 'https://github.com/dotnet/skills';          hit = $false },
  @{ name = 'drive letter alone'; value = 'the U: Dev Drive';                          hit = $false },
  @{ name = 'relative trail';    value = 'trails/0001-foundation/02-check.jsonl';     hit = $false },
  @{ name = 'property name';     key = "C:${bs}x"; value = 'v';                       hit = $true  }
)
$fail = 0
Assert-TrailPathScanWorks
foreach ($c in $cases) {
  $k = if ($c.key) { $c.key } else { 'v' }
  $json = [ordered]@{ $k = $c.value } | ConvertTo-Json -Compress
  $got = @(Get-TrailPathHits -Text $json).Count -gt 0
  if ($got -ne $c.hit) { Write-Output "FAIL $($c.name): expected hit=$($c.hit) got $got for $json"; $fail++ } else { Write-Output "OK $($c.name)" }
}
if ($fail) { Write-Output "RESULT FAIL ($fail)"; exit 1 }
Write-Output 'RESULT PASS'
exit 0
