# new-skill.ps1 - propose, approve or reject a new skill. Run from the repo root.
#   propose: new-skill.ps1 -Plugin <plugin> -Name <kebab-name> -Description "<... USE FOR ... DO NOT USE ...>" [-Role maker]
#   approve: new-skill.ps1 -Plugin <plugin> -Name <kebab-name> -Approve
#   reject : new-skill.ps1 -Name <kebab-name> -Reject -Reason "<why>"
# Proposals live in .pmcro/local/proposals/<name>/ (scratch, never committed). Never edits git, marketplace files or company.json.
param(
  [string]$Plugin,
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$Description,
  [string]$Role = 'maker',
  [switch]$Approve,
  [switch]$Reject,
  [string]$Reason
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$skillDir = Split-Path -Parent $PSScriptRoot
$validator = Join-Path $PSScriptRoot 'validate-skill.ps1'
$propRoot = Join-Path $root '.pmcro/local/proposals'
$prop = Join-Path $propRoot $Name
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Log([string]$file, $obj) {
  New-Item -ItemType Directory -Force $propRoot | Out-Null
  $o = [ordered]@{ ts = (Get-Date).ToString('o') }
  foreach ($p in $obj.GetEnumerator()) { $o[$p.Key] = $p.Value }
  [IO.File]::AppendAllText((Join-Path $propRoot $file), (([pscustomobject]$o | ConvertTo-Json -Compress) + "`n"), $utf8)
}
if ($Name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "name must be kebab-case: $Name" }
if ($Approve -and $Reject) { throw 'choose -Approve or -Reject, not both' }

if ($Reject) {
  if (-not (Test-Path -LiteralPath $prop)) { throw "no proposal named $Name" }
  if (-not $Reason) { throw '-Reject needs -Reason' }
  Remove-Item -LiteralPath $prop -Recurse -Force
  Log 'rejections.jsonl' @{ name = $Name; decision = 'rejected'; reason = $Reason }
  Write-Host "rejected $Name; reason recorded"; exit 0
}

if ($Approve) {
  if (-not $Plugin) { throw '-Approve needs -Plugin' }
  if (-not (Test-Path -LiteralPath $prop)) { throw "no proposal named $Name; propose first" }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $validator -Path $prop
  if ($LASTEXITCODE -ne 0) { throw 'proposal fails validation; not promoted' }
  $target = Join-Path $root "plugins/$Plugin/skills/$Name"
  if (Test-Path -LiteralPath $target) { throw "target already exists: plugins/$Plugin/skills/$Name" }
  New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
  Copy-Item -LiteralPath $prop -Destination $target -Recurse
  $pj = Join-Path $root "plugins/$Plugin/.claude-plugin/plugin.json"
  if (-not (Test-Path -LiteralPath $pj)) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $pj) | Out-Null
    $j = [ordered]@{ name = $Plugin; version = '0.1.0'; description = "$Plugin skills"; skills = @('./skills/') } | ConvertTo-Json
    [IO.File]::WriteAllText($pj, $j + "`n", $utf8)
  }
  Remove-Item -LiteralPath $prop -Recurse -Force
  Log 'approvals.jsonl' @{ name = $Name; plugin = $Plugin; decision = 'approved' }
  Write-Host "approved $Name into plugins/$Plugin/skills/$Name. Register the plugin in both marketplace manifests next."; exit 0
}

# propose
if (-not $Plugin) { throw 'propose needs -Plugin' }
if (-not $Description) { throw 'propose needs -Description' }
if (Test-Path -LiteralPath $prop) { throw "proposal already exists: $Name (approve or reject it first)" }
if (Test-Path -LiteralPath (Join-Path $root "plugins/$Plugin/skills/$Name")) { throw "skill already exists in plugins/$Plugin" }
$safe = "'" + $Description.Replace("'", "''") + "'"
function Render([string]$tmpl) {
  $t = [IO.File]::ReadAllText((Join-Path $skillDir "assets/$tmpl"))
  return $t.Replace('{{Name}}', $Name).Replace('{{Plugin}}', $Plugin).Replace('{{Role}}', $Role).Replace('{{Description}}', $Description)
}
New-Item -ItemType Directory -Force (Join-Path $prop 'scripts'), (Join-Path $prop 'references') | Out-Null
$skillText = (Render 'SKILL.md.tmpl').Replace("description: $Description", "description: $safe")
[IO.File]::WriteAllText((Join-Path $prop 'SKILL.md'), $skillText, $utf8)
[IO.File]::WriteAllText((Join-Path $prop 'README.md'), (Render 'README.md.tmpl'), $utf8)
[IO.File]::WriteAllText((Join-Path $prop "scripts/$Name.ps1"), (Render 'script.ps1.tmpl'), $utf8)
[IO.File]::WriteAllText((Join-Path $prop 'references/README.md'), "# References for $Name`n`nPut long detail here.`n", $utf8)
& powershell -NoProfile -ExecutionPolicy Bypass -File $validator -Path $prop
$code = $LASTEXITCODE
Log 'proposals.jsonl' @{ name = $Name; plugin = $Plugin; decision = 'proposed'; validator_exit = $code }
if ($code -ne 0) { Write-Host "proposal written but FAILS validation: .pmcro/local/proposals/$Name (fix it or -Reject)"; exit 1 }
Write-Host "proposed $Name at .pmcro/local/proposals/$Name. Waiting for Shawn: -Approve or -Reject."
exit 0
