# new-mcp-server.ps1 - expand the .NET MCP server template into a new folder. Run from the repo root.
# Usage: new-mcp-server.ps1 -Name HelloMcp -Out templates/hello-mcp -DotnetVersion <x.y> -McpSdkVersion <v> -HostingVersion <v>
# Versions have no defaults on purpose: look them up first (see references/verify.md). Refuses absolute paths and non-empty folders.
param(
  [Parameter(Mandatory = $true)][string]$Name,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$DotnetVersion,
  [Parameter(Mandatory = $true)][string]$McpSdkVersion,
  [Parameter(Mandatory = $true)][string]$HostingVersion
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$skill = Split-Path -Parent $PSScriptRoot
if ($Name -notmatch '^[A-Za-z][A-Za-z0-9]*$') { throw "Name must be letters and digits: $Name" }
if ([IO.Path]::IsPathRooted($Out) -or $Out -match '\.\.') { throw "Out must be a relative path inside the repo: $Out" }
if ($DotnetVersion -notmatch '^\d+\.\d+$') { throw "DotnetVersion must look like 10.0: $DotnetVersion" }
foreach ($v in @($McpSdkVersion, $HostingVersion)) { if ($v -notmatch '^\d+(\.\d+){1,3}(-[A-Za-z0-9.]+)?$') { throw "bad package version: $v" } }
$dest = Join-Path $root $Out
if ((Test-Path -LiteralPath $dest) -and @(Get-ChildItem -LiteralPath $dest -Force).Count -gt 0) { throw "Out exists and is not empty: $Out" }
New-Item -ItemType Directory -Force $dest | Out-Null
$map = @{ 'McpServer.csproj.tmpl' = "$Name.csproj"; 'Program.cs.tmpl' = 'Program.cs'; 'Dockerfile.tmpl' = 'Dockerfile'; 'dockerignore.tmpl' = '.dockerignore' }
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($k in $map.Keys) {
  $t = [IO.File]::ReadAllText((Join-Path $skill "assets/template/$k"))
  $t = $t.Replace('{{ProjectName}}', $Name).Replace('{{DotnetVersion}}', $DotnetVersion).Replace('{{McpSdkVersion}}', $McpSdkVersion).Replace('{{HostingVersion}}', $HostingVersion)
  if ($t -match '\{\{[A-Za-z]+\}\}') { throw "unresolved token in $k" }
  [IO.File]::WriteAllText((Join-Path $dest $map[$k]), $t, $utf8)
}
Write-Host "expanded $Name into $Out (not built; versions unverified until the runtime trail)"
