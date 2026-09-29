# docker-baseline.ps1 - record what Docker and .NET this machine really has, before any docker command.
# Usage (repo root): powershell -File plugins/pmcro-docker/skills/docker-baseline/scripts/docker-baseline.ps1
# Prints one JSON object for the trail frame. Exit 0 = engine reachable, 2 = engine unreachable or CLI missing (stop and ask Shawn).
$ErrorActionPreference = 'Continue'
function Try-Run([scriptblock]$sb) { try { $o = & $sb 2>$null; if ($LASTEXITCODE -eq 0) { return (($o | Out-String).Trim()) } } catch { }; return $null }
$cli = Try-Run { docker --version }
$engine = $null
if ($cli) { $engine = Try-Run { docker info --format '{{.ServerVersion}}' } }
$dn = Try-Run { dotnet --version }
$result = [ordered]@{
  docker_cli = $cli
  docker_engine_version = $engine
  docker_engine_reachable = [bool]$engine
  dotnet_version = $dn
}
$result | ConvertTo-Json -Compress
if (-not $cli) { Write-Host 'STOP: docker CLI not found. Ask Shawn.'; exit 2 }
if (-not $engine) { Write-Host 'STOP: docker engine not reachable (start Docker Desktop). Ask Shawn.'; exit 2 }
if (-not $dn) { Write-Host 'STOP: dotnet not found. Ask Shawn.'; exit 2 }
exit 0
