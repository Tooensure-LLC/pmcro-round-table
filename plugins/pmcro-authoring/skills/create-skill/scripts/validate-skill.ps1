# validate-skill.ps1 - check one skill folder. Usage (repo root): powershell -File plugins/pmcro-authoring/skills/create-skill/scripts/validate-skill.ps1 -Path plugins/<plugin>/skills/<name>
# Exit 0 = PASS, 1 = FAIL. Manual-first: no model needed.
param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$fails = New-Object System.Collections.Generic.List[string]
function Fail([string]$m) { $script:fails.Add($m) | Out-Null; Write-Host "FAIL $m" }
$dir = (Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue)
if (-not $dir) { Write-Host "FAIL folder not found: $Path"; Write-Host 'RESULT FAIL'; exit 1 }
$dir = $dir.Path
$folder = Split-Path -Leaf $dir
$skill = Join-Path $dir 'SKILL.md'
if (-not (Test-Path -LiteralPath $skill)) { Write-Host 'FAIL SKILL.md missing'; Write-Host 'RESULT FAIL'; exit 1 }
$text = [IO.File]::ReadAllText($skill)
$m = [regex]::Match($text, '(?s)^\uFEFF?---\r?\n(.*?)\r?\n---\r?\n(.*)$')
if (-not $m.Success) { Write-Host 'FAIL no frontmatter block'; Write-Host 'RESULT FAIL'; exit 1 }
$front = $m.Groups[1].Value
$body = $m.Groups[2].Value
function Get-Field([string]$k) {
  $x = [regex]::Match($front, "(?m)^$k\s*:\s*(.*)$")
  if (-not $x.Success) { return $null }
  $v = $x.Groups[1].Value.Trim()
  if ($v.Length -ge 2 -and $v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2).Replace("''", "'") }
  elseif ($v.Length -ge 2 -and $v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
  return $v
}
$name = Get-Field 'name'
$desc = Get-Field 'description'
if (-not $name) { Fail 'name missing' }
elseif ($name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { Fail "name not kebab-case: $name" }
elseif ($name -ne $folder) { Fail "name '$name' does not match folder '$folder'" }
if (-not $desc) { Fail 'description missing or empty' }
else {
  if ($desc.Length -gt 1024) { Fail "description longer than 1024 ($($desc.Length))" }
  if ($desc -cnotmatch 'USE FOR' -or $desc -cnotmatch 'DO NOT USE') { Fail 'description must contain USE FOR and DO NOT USE' }
}
foreach ($r in [regex]::Matches($body, '(references|scripts|assets)/[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*')) {
  $rel = $r.Value
  if (-not (Test-Path -LiteralPath (Join-Path $dir $rel))) { Fail "referenced path missing: $rel" }
}
if ($fails.Count -gt 0) { Write-Host "RESULT FAIL ($($fails.Count))"; exit 1 }
Write-Host "OK $folder"
Write-Host 'RESULT PASS'
exit 0
