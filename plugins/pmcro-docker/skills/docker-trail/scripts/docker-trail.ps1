# docker-trail.ps1 - run ONE docker command and log it into an open trail. Every docker command goes through here.
# Usage (repo root): powershell -File plugins/pmcro-docker/skills/docker-trail/scripts/docker-trail.ps1 -Trail trails/NNNN-name -Step 01 -DockerArgs build,-t,demo,templates/mcp
# Refuses: no open trail, sealed trail, absolute paths (EC-PORTABLE-005), commands outside the allow list, --privileged, docker.sock,
# and anything when the engine is unreachable. Appends one record to <trail>/<Step>-docker.jsonl. Never pushes, logs in, or prunes.
param(
  [Parameter(Mandatory = $true)][string]$Trail,
  [Parameter(Mandatory = $true)][string]$Step,
  [Parameter(Mandatory = $true)][string[]]$DockerArgs,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$absPat = '[A-Za-z]:(\\\\|\\|/)[A-Za-z]'
$allowed = @('version', 'info', 'build', 'run', 'ps', 'images', 'logs', 'stop', 'inspect')
if ($Trail -notmatch '^trails/[^/\\]+$') { throw "Trail must look like trails/NNNN-name (relative): $Trail" }
if ($Step -notmatch '^\d{2}$') { throw "Step must be two digits like 01: $Step" }
$trailDir = Join-Path $root $Trail
if (-not (Test-Path -LiteralPath (Join-Path $trailDir '00-frame.jsonl'))) { throw "no open trail: $Trail has no 00-frame.jsonl (Log Before Act)" }
if (Test-Path -LiteralPath (Join-Path $trailDir 'disposition.json')) { throw "trail is sealed: $Trail (append-only; open a new trail)" }
# powershell -File passes -DockerArgs build,-t,demo as ONE string; split it back into arguments
if ($DockerArgs.Count -eq 1 -and $DockerArgs[0] -match ',') { $DockerArgs = @($DockerArgs[0] -split ',') }
$sub = $DockerArgs[0]
$joined = ($DockerArgs -join ' ')
if ($allowed -notcontains $sub) { throw "docker '$sub' is not on the allow list ($($allowed -join ', ')). Ask Shawn." }
if ($joined -match '--privileged') { throw 'refused: --privileged (CISO isolation rule). Ask Shawn.' }
if ($joined -match 'docker\.sock') { throw 'refused: docker.sock mount (CISO isolation rule). Ask Shawn.' }
if ($joined -match $absPat) { throw 'refused: absolute path in docker args; use relative paths (EC-PORTABLE-005)' }
function Scrub([string]$s) { [regex]::Replace($s, '[A-Za-z]:(\\\\|\\|/)[A-Za-z][^\s"'']*', '<abs-path>') }
function Write-Record($rec) {
  $rec['ts'] = (Get-Date).ToString('o')
  $line = ([pscustomobject]$rec | ConvertTo-Json -Compress -Depth 5)
  if ($line -match $absPat) { throw 'EC-0001: absolute path found in docker record' }
  if ($DryRun) { Write-Host "DRYRUN record: $line"; return }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::AppendAllText((Join-Path $trailDir "$Step-docker.jsonl"), $line + "`n", $utf8)
}
$base = [ordered]@{ role = 'maker'; phase = 'docker'; trail = $Trail; step = $Step; cmd = "docker $joined" }
if ($sub -ne 'version' -and $sub -ne 'info') {
  $bl = Join-Path $root 'plugins/pmcro-docker/skills/docker-baseline/scripts/docker-baseline.ps1'
  $blOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $bl 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) {
    $base['exit'] = -1; $base['blocked'] = 'baseline failed: engine, cli or dotnet not ready'; $base['baseline'] = (Scrub $blOut)
    Write-Record $base
    throw 'STOP: docker baseline failed (engine not reachable?). Recorded as blocked. Ask Shawn.'
  }
}
if ($DryRun) { $base['exit'] = 0; $base['dry_run'] = $true; Write-Record $base; exit 0 }
$ErrorActionPreference = 'Continue'
$out = & docker @DockerArgs 2>&1 | ForEach-Object { $_.ToString() }
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$text = ($out -join "`n")
$sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-', '')
$tail = @($out | Select-Object -Last 15 | ForEach-Object { Scrub $_ })
$base['exit'] = $code; $base['stdout_sha256'] = $sha; $base['output_tail'] = $tail
Write-Record $base
$out
exit $code
