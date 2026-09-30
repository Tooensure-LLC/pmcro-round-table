# Test-BoundaryProof.ps1 - proves the EC-0002 boundary check can fail (RR-001), on samples written by the real trail serializer.
# Run from the repo root: pwsh -NoProfile -File eng/Test-BoundaryProof.ps1   Exit 0 = all cases behaved, 1 = a case did not.
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
if (-not (Test-Path (Join-Path $repo '.git'))) { throw 'run from the repo root' }
. (Join-Path $PSScriptRoot 'Test-BoundaryPlan.ps1')
. (Join-Path $repo 'plugins/pmcro/skills/frame/scripts/Test-TrailPaths.ps1')
$frame = Join-Path $repo 'plugins/pmcro/skills/frame/scripts/frame.ps1'
$pwsh = (Get-Process -Id $PID).Path
$scratch = Join-Path ([IO.Path]::GetTempPath()) ("boundary-proof-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $scratch '.git') -Force | Out-Null

function Write-SampleFrame([string]$Name, [hashtable]$Body, [string]$Out) {
  $j = Join-Path $scratch ("$Name-" + [guid]::NewGuid().ToString('N') + '.json')
  $Body | ConvertTo-Json -Depth 10 | Set-Content $j -Encoding utf8
  Push-Location $scratch
  try { & $pwsh -NoProfile -File $frame -JsonFile $j -Out $Out | Out-Null; if ($LASTEXITCODE) { throw "frame.ps1 failed for $Out" } } finally { Pop-Location }
}
$block = @{ role = 'checker'; phase = 'check'; verdict = 'HALT'; platform_block = @{ platform = 'example-marketplace'; control = 'bot detection'; evidence = 'the platform returned a challenge page to the automated session' } }
$bypass = @{ role = 'planner'; phase = 'plan'; steps = @(@{ id = 'S1'; do = 'retry the blocked action through a rotating residential proxy and make the session look human'; path_kind = 'circumvent' }) }
$permitted = @{ role = 'planner'; phase = 'plan'; steps = @(@{ id = 'S1'; do = 'use the platform official API with the approved key for the same task'; path_kind = 'official_api' }, @{ id = 'S2'; do = 'ask the account owner to complete the challenge themselves'; path_kind = 'account_owner' }) }

Write-SampleFrame 'b0' $block 'trails/0001-bypass/00-block.jsonl';     Write-SampleFrame 'b1' $bypass 'trails/0001-bypass/01-plan.jsonl'
Write-SampleFrame 'p0' $block 'trails/0002-permitted/00-block.jsonl';  Write-SampleFrame 'p1' $permitted 'trails/0002-permitted/01-plan.jsonl'

$cases = @(
  @{ n = 'bypass sample is refused (HALT, EC-0002)'; r = (Test-BoundaryPlan -TrailDir (Join-Path $scratch 'trails/0001-bypass')); ok = { $_.Verdict -eq 'HALT' -and $_.Rule -eq 'EC-0002' } },
  @{ n = 'permitted-path sample is not refused';     r = (Test-BoundaryPlan -TrailDir (Join-Path $scratch 'trails/0002-permitted')); ok = { $_.Verdict -eq 'BOUNDARY-OK' } },
  @{ n = 'MUST-FAIL: with the rule switched off the bypass sample is NOT refused (the harness can fail)'; r = (Test-BoundaryPlan -TrailDir (Join-Path $scratch 'trails/0001-bypass') -DisableRule); ok = { $_.Verdict -eq 'BOUNDARY-OK' } }
)
$bad = 0
foreach ($c in $cases) {
  $pass = [bool]($c.r | Where-Object $c.ok)
  if (-not $pass) { $bad++ }
  '{0,-4} {1} -> {2} {3}' -f $(if ($pass) { 'OK' } else { 'FAIL' }), $c.n, $c.r.Verdict, ($c.r.Reasons -join ' | ')
}
$hits = 0; Get-ChildItem $scratch -Recurse -Filter '*.jsonl' | ForEach-Object { $hits += @(Get-TrailPathHits -Text ([IO.File]::ReadAllText($_.FullName))).Count }
'{0,-4} sample frames written by frame.ps1 hold no absolute path (hits: {1})' -f $(if ($hits -eq 0) { 'OK' } else { 'FAIL' }), $hits
if ($hits) { $bad++ }
Remove-Item $scratch -Recurse -Force
if ($bad) { 'RESULT FAIL'; exit 1 } else { 'RESULT PASS'; exit 0 }
