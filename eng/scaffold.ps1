<#
.SYNOPSIS
  Rebuilds the PMCR-O repo skeleton from official templates only (build off others, never reinvent).
.DESCRIPTION
  Every file this script creates comes from a published template:
    dotnet new globaljson/gitignore/editorconfig/buildprops/sln/tool-manifest   (.NET SDK)
    dotnet new aspire-apphost / aspire-servicedefaults / aspire-xunit            (Aspire.ProjectTemplates 13.5.4)
    dotnet new aiagent-webapi --provider ollama                                   (Microsoft.Agents.AI.ProjectTemplates)
    docfx init                                                                   (DocFX local tool)
  Run from the repo root. Refuses to overwrite a project that already exists.
#>
[CmdletBinding()]
param([string]$Name = 'Pmcro')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Invoke-Step([string]$What, [scriptblock]$Do) {
  Write-Host "==> $What"
  & $Do
  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "$What failed with exit $LASTEXITCODE" }
}
function New-IfMissing([string]$Path, [scriptblock]$Do) { if (Test-Path $Path) { Write-Host "skip $Path (exists)" } else { & $Do } }

New-IfMissing '.gitignore'          { Invoke-Step 'gitignore'      { dotnet new gitignore } }
New-IfMissing '.editorconfig'       { Invoke-Step 'editorconfig'   { dotnet new editorconfig } }
New-IfMissing 'Directory.Build.props' { Invoke-Step 'buildprops'  { dotnet new buildprops } }
New-IfMissing "$Name.slnx"          { Invoke-Step 'solution'       { dotnet new sln -n $Name --format slnx } }

New-IfMissing "src/$Name.ServiceDefaults" { Invoke-Step 'service defaults' { dotnet new aspire-servicedefaults -n "$Name.ServiceDefaults" -o "src/$Name.ServiceDefaults" } }
New-IfMissing "src/$Name.Runtime"   { Invoke-Step 'MAF runtime'    { dotnet new aiagent-webapi -n "$Name.Runtime" -o "src/$Name.Runtime" --provider ollama } }
New-IfMissing "src/$Name.AppHost"   { Invoke-Step 'AppHost'        { dotnet new aspire-apphost -n "$Name.AppHost" -o "src/$Name.AppHost" } }
New-IfMissing "tests/$Name.Tests"   { Invoke-Step 'tests'          { dotnet new aspire-xunit -n "$Name.Tests" -o "tests/$Name.Tests" } }

Invoke-Step 'add projects to solution' {
  Get-ChildItem src, tests -Recurse -Filter *.csproj | ForEach-Object { dotnet sln "$Name.slnx" add $_.FullName }
}
Invoke-Step 'AppHost references runtime' { dotnet add "src/$Name.AppHost" reference "src/$Name.Runtime" }
Invoke-Step 'runtime references service defaults' { dotnet add "src/$Name.Runtime" reference "src/$Name.ServiceDefaults" }
Invoke-Step 'tests reference AppHost' { dotnet add "tests/$Name.Tests" reference "src/$Name.AppHost" }

# .NET 10 SDK writes the tool manifest at the repo root; older SDKs used .config/.
if (-not ((Test-Path 'dotnet-tools.json') -or (Test-Path '.config/dotnet-tools.json'))) { Invoke-Step 'tool manifest' { dotnet new tool-manifest } }
Invoke-Step 'docfx (local tool)' { dotnet tool install docfx }
New-IfMissing 'docs/docfx.json' { Invoke-Step 'docfx init' { dotnet docfx init --yes --output docs } }
Write-Host 'scaffold: OK'
