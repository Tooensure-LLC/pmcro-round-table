# replay.ps1 - re-verify a trail on this machine. Prints MATCH or MISMATCH; exit 0 or 1.
# Usage: powershell -ExecutionPolicy Bypass -File tools/replay.ps1 trails/0001-company-founding
# Read-only except for re-running tools/build.ps1, which rewrites generated files from company.json.
# v2 (trails/0004-replay-v2): also fails when a sealed trail file changed, or when trails/ or queue/ differ from the commit.
param([Parameter(Mandatory = $true)][string]$Trail)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$td = Join-Path $root $Trail
$safe = ($root -replace '\\', '/')
$g = @('-c', "safe.directory=$safe", '-C', $root)
$results = New-Object System.Collections.ArrayList
function Add-Check($name, $ok, $detail) { [void]$results.Add([pscustomobject]@{ Check = $name; Result = $(if ($ok) { 'ok' } else { 'FAIL' }); Detail = $detail }) }
function Last-Line($path) { (Get-Content $path | Where-Object { $_.Trim() } | Select-Object -Last 1) | ConvertFrom-Json }

# 1. The trail exists
$exists = Test-Path $td
Add-Check 'trail exists' $exists $Trail
if ($exists) {
  # 2. Relative paths only, with a positive control (EC-0001)
  $pat = '[A-Za-z]:(\\\\|\\|/)[A-Za-z]'
  $control = ((@{ x = 'E:\PMCRO' } | ConvertTo-Json -Compress) -match $pat)
  $files = @(Get-ChildItem $td -File | Where-Object { $_.Extension -in '.jsonl', '.json' })
  $disp = Join-Path $td 'disposition.json'
  $defects = @()
  if (Test-Path $disp) { $d = Get-Content -Raw $disp | ConvertFrom-Json; if ($d.recorded_defects) { $defects = @($d.recorded_defects) } }
  $hits = @($files | Where-Object { $defects -notcontains $_.Name } | Select-String -Pattern $pat)
  Add-Check 'no absolute paths' ($control -and $hits.Count -eq 0) "scan can fail: $control; hits outside recorded defects: $($hits.Count); recorded defects: $($defects -join ', ')"

  # 3. Sealed ACCEPT
  $sealed = (Test-Path $disp) -and ((Get-Content -Raw $disp | ConvertFrom-Json).disposition -eq 'ACCEPT')
  Add-Check 'sealed ACCEPT' $sealed $(if (Test-Path $disp) { 'disposition.json present' } else { 'no disposition.json' })

  # 4. Latest independent check is PASS
  $checks = @(Get-ChildItem $td -Filter '*-check.jsonl' | Sort-Object Name)
  $verdict = if ($checks.Count) { (Last-Line $checks[-1].FullName).verdict } else { 'none' }
  Add-Check 'checker PASS' ($verdict -eq 'PASS') "latest check: $(if ($checks.Count) { $checks[-1].Name } else { 'none' }) = $verdict"

  # 5. Auditor AUDIT-PASS
  $ap = Join-Path $td 'audit.jsonl'
  $finding = if (Test-Path $ap) { (Last-Line $ap).finding } else { 'none' }
  Add-Check 'auditor AUDIT-PASS' ($finding -eq 'AUDIT-PASS') "audit: $finding"

  # 6. Template replay: company.json + tools/build.ps1 reproduce the committed files, byte for byte
  $build = Join-Path $root 'tools\build.ps1'
  $out = @('chiefs', 'docs', 'marketplace', 'AGENTS.md', 'CLAUDE.md', '.agents', '.pmcro', 'plugins/pmcro', '.claude-plugin', '.cursor-plugin')
  # .pmcro/local is gitignored scratch: never part of the guarantee (trails/0005: scratch writes during a replay made it non-deterministic)
  # trails/0008 loop 2: match .pmcro/local only at this root, so replay also works from a checkout that itself sits under some .pmcro/local
  $scratch = (Join-Path $root '.pmcro\local') + '\'
  $hash = { Get-ChildItem ($out | ForEach-Object { Join-Path $root $_ }) -Recurse -File | Where-Object { -not $_.FullName.StartsWith($scratch, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object FullName | Get-FileHash | ForEach-Object Hash }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $build | Out-Null; $h1 = & $hash
  & powershell -NoProfile -ExecutionPolicy Bypass -File $build | Out-Null; $h2 = & $hash
  $deterministic = ((Compare-Object $h1 $h2) -eq $null)
  # v2: trails and queue are part of the committed state a buyer replays
  # trails/0008: hand-authored plugins and eng/ tooling are part of the committed state too
  $dirty = @(git @g status --porcelain -- company.json tools $out trails queue plugins eng 2>$null)
  Add-Check 'committed state replays exactly' ($deterministic -and $dirty.Count -eq 0) "deterministic: $deterministic; files differing from the commit (company.json, tools, generated, trails, queue, plugins, eng): $($dirty.Count) $(($dirty | ForEach-Object { $_.Trim() }) -join '; ')"

  # 7. v2: every file hashed at sealing still matches (disposition.file_hashes_at_seal, where present).
  # Line-ending neutral: git stores LF and Windows working copies may be CRLF, so a file passes if its bytes,
  # or the same bytes with line endings normalized to LF or to CRLF, hash to the sealed SHA256. Any other change fails.
  $sealHashes = if (Test-Path $disp) { (Get-Content -Raw $disp | ConvertFrom-Json).file_hashes_at_seal } else { $null }
  if ($sealHashes) {
    $latin = [Text.Encoding]::GetEncoding(28591)
    $sha = [Security.Cryptography.SHA256]::Create()
    $hex = { param([byte[]]$b) ([BitConverter]::ToString($sha.ComputeHash($b)) -replace '-', '') }
    $bad = @(); $n = 0
    foreach ($p in $sealHashes.PSObject.Properties) {
      $n++
      $fp = Join-Path $td $p.Name
      if (-not (Test-Path $fp)) { $bad += "$($p.Name) (missing)"; continue }
      $raw = [IO.File]::ReadAllBytes($fp)
      $lf = $latin.GetString($raw) -replace "`r`n", "`n"
      $variants = @((& $hex $raw), (& $hex $latin.GetBytes($lf)), (& $hex $latin.GetBytes(($lf -replace "`n", "`r`n"))))
      if ($variants -notcontains $p.Value.ToUpper()) { $bad += $p.Name }
    }
    Add-Check 'trail matches seal' ($bad.Count -eq 0) "$($n - $bad.Count) of $n sealed files match; changed since sealing: $(if ($bad.Count) { $bad -join ', ' } else { 'none' })"
  } else {
    Add-Check 'trail matches seal' $true 'skipped: no file_hashes_at_seal in disposition.json (sealed before replay v2, or not sealed)'
  }

  # 8. trails/0012: every queue item's status agrees with the trails (tools/check-queue.ps1)
  $cq = Join-Path $root 'tools\check-queue.ps1'
  if (Test-Path $cq) {
    $qo = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $cq -Root $root)
    $qok = ($LASTEXITCODE -eq 0)
    Add-Check 'queue consistent' $qok ("$($qo | Select-Object -Last 1) $((@($qo | Where-Object { $_ -like 'FAIL*' }) | Select-Object -First 2) -join '; ')").Trim()
  }
}

$results | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
$ok = (@($results | Where-Object Result -eq 'FAIL').Count -eq 0)
$head = (git @g rev-parse --short HEAD 2>$null)
Write-Output ("{0}: {1} at commit {2}" -f $(if ($ok) { 'MATCH' } else { 'MISMATCH' }), $Trail, $head)
exit $(if ($ok) { 0 } else { 1 })
