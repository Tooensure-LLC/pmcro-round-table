# Test-PluginLayout.ps1 - check the plugin marketplace against the dotnet/skills layout (old-repo trails/0008-skill-author-docker-github-plugins).
# Usage (repo root): powershell -NoProfile -ExecutionPolicy Bypass -File eng/skill-validator/Test-PluginLayout.ps1 [-Root <copy>]
# Exit 0 = PASS, 1 = FAIL (one FAIL line per fault). Read-only.
param([string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$ErrorActionPreference = 'Stop'
$fails = 0
function Fail([string]$m) { Write-Host "FAIL $m"; $script:fails++ }
function Ok([string]$m) { Write-Host "OK $m" }
function J([string]$rel) {
  $p = Join-Path $Root $rel
  if (-not (Test-Path -LiteralPath $p)) { Fail "missing: $rel"; return $null }
  try { return (Get-Content -Raw -LiteralPath $p | ConvertFrom-Json) } catch { Fail "does not parse as JSON: $rel"; return $null }
}
function Front([string]$path) {
  $t = [IO.File]::ReadAllText($path)
  $m = [regex]::Match($t, '(?s)^\uFEFF?---\r?\n(.*?)\r?\n---\r?\n')
  if (-not $m.Success) { return $null }
  $n = [regex]::Match($m.Groups[1].Value, '(?m)^name\s*:\s*(.*?)\s*$')
  if (-not $n.Success) { return '' }
  return $n.Groups[1].Value.Trim("'", '"')
}

$pluginRoot = Join-Path $Root 'plugins'
# A plugin folder is any plugins/<name> that holds at least one file (empty leftover folders from moves are ignored).
$folders = @(Get-ChildItem -LiteralPath $pluginRoot -Directory | Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force).Count -gt 0 } | Sort-Object Name | ForEach-Object Name)
$expected = @($folders | Where-Object { $_ -eq 'pmcro' -or $_ -like 'pmcro-*' })
$stray = @($folders | Where-Object { $expected -notcontains $_ })
if ($stray.Count) { Fail "plugin folders not named pmcro or pmcro-*: $($stray -join ', ')" }
if ($expected.Count -ne 5) { Fail "expected exactly 5 pmcro plugins, found $($expected.Count): $($expected -join ', ')" } else { Ok "5 plugins: $($expected -join ', ')" }

# 1. Every host marketplace parses, has the reference fields, and lists exactly the plugin folders
$hosts = [ordered]@{ '.claude-plugin/marketplace.json' = $null; '.agents/plugins/marketplace.json' = 'interface.displayName'; '.cursor-plugin/marketplace.json' = 'metadata.description'; '.github/plugin/marketplace.json' = 'metadata.description' }
foreach ($h in $hosts.Keys) {
  $hb = $fails
  $mj = J $h
  if (-not $mj) { continue }
  if (-not $mj.name -or -not $mj.owner.name) { Fail "$h lacks name or owner.name" }
  if ($hosts[$h]) { $a, $b = $hosts[$h] -split '\.'; if (-not $mj.$a.$b) { Fail "$h lacks $($hosts[$h])" } }
  $listed = @($mj.plugins | ForEach-Object { $_.name } | Sort-Object)
  if (($listed -join ',') -ne ($expected -join ',')) { Fail "$h lists [$($listed -join ', ')], plugin folders are [$($expected -join ', ')]" }
  if ($listed -notcontains 'pmcro') { Fail "$h does not list plugin pmcro" }
  foreach ($e in @($mj.plugins)) {
    if ($e.source -ne "./plugins/$($e.name)") { Fail "$h entry $($e.name) source is '$($e.source)'" }
    if (-not $e.description) { Fail "$h entry $($e.name) has no description" }
  }
  if ($fails -eq $hb) { Ok "$h" }
}

# 2. Every plugin has the per-plugin files, and its three manifests agree
foreach ($p in $expected) {
  $d = "plugins/$p"
  $before = $fails
  foreach ($f in 'README.md') { if (-not (Test-Path -LiteralPath (Join-Path $Root "$d/$f"))) { Fail "missing: $d/$f" } }
  $vj = J "$d/version.json"; if ($vj -and -not $vj.version) { Fail "$d/version.json has no version" }
  $main = J "$d/plugin.json"; $cl = J "$d/.claude-plugin/plugin.json"; $cx = J "$d/.codex-plugin/plugin.json"
  foreach ($pair in @(@('plugin.json', $main), @('.claude-plugin/plugin.json', $cl), @('.codex-plugin/plugin.json', $cx))) {
    $x = $pair[1]; if (-not $x) { continue }
    if ($x.name -ne $p) { Fail "$d/$($pair[0]) name '$($x.name)' does not match folder '$p'" }
    if (-not $x.version -or -not $x.description) { Fail "$d/$($pair[0]) lacks version or description" }
    if (@($x.skills) -notcontains './skills/') { Fail "$d/$($pair[0]) skills is not ['./skills/']" }
  }
  if ($main -and $cl -and $cx) {
    if ($main.version -ne $cl.version -or $main.version -ne $cx.version) { Fail "$d manifests disagree on version" }
    if ($main.description -ne $cl.description -or $main.description -ne $cx.description) { Fail "$d manifests disagree on description" }
  }
  # agents: each listed agent file exists and has a frontmatter name; there is at least one
  $agents = @(); if ($main) { $agents = @($main.agents) }
  if ($agents.Count -eq 0) { Fail "$d/plugin.json lists no agents" }
  foreach ($a in $agents) {
    $ap = Join-Path $Root (Join-Path $d ($a -replace '^\./', ''))
    if (-not (Test-Path -LiteralPath $ap)) { Fail "$d agent missing: $a"; continue }
    $n = Front $ap
    if (-not $n) { Fail "$d agent $a has no frontmatter name" }
    elseif ("$n.agent.md" -ne (Split-Path -Leaf $ap)) { Fail "$d agent $a frontmatter name '$n' does not match its file name" }
  }
  # skills: every skills/<s>/ has SKILL.md whose frontmatter name equals the folder
  $sd = Join-Path $Root "$d/skills"
  $skills = @(); if (Test-Path -LiteralPath $sd) { $skills = @(Get-ChildItem -LiteralPath $sd -Directory | Sort-Object Name) }
  if ($skills.Count -eq 0) { Fail "$d has no skills" }
  foreach ($s in $skills) {
    $sm = Join-Path $s.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $sm)) { Fail "$d/skills/$($s.Name) has no SKILL.md"; continue }
    $n = Front $sm
    if ($null -eq $n) { Fail "$d/skills/$($s.Name)/SKILL.md has no frontmatter" }
    elseif ($n -ne $s.Name) { Fail "$d/skills/$($s.Name)/SKILL.md name '$n' does not match its folder '$($s.Name)'" }
  }
  if ($fails -eq $before) { Ok "$d ($($skills.Count) skills, $($agents.Count) agents)" }
}

# 3. Claude Code hooks (trails/0001 02-check D5): PreToolUse is an array of { matcher, hooks[] }, each hook exec form
#    (command + args) whose script argument is anchored on a root placeholder, so it cannot fail open from a subfolder.
foreach ($pair in @(@('.claude/settings.json', '${CLAUDE_PROJECT_DIR}/'), @('plugins/pmcro/hooks/hooks.json', '${CLAUDE_PLUGIN_ROOT}/'))) {
  $hb = $fails
  $hj = J $pair[0]; if (-not $hj) { continue }
  $raw = Get-Content -Raw -LiteralPath (Join-Path $Root $pair[0])
  if ($raw -notmatch '"PreToolUse"\s*:\s*\[') { Fail "$($pair[0]) hooks.PreToolUse is not an array" }
  foreach ($e in @($hj.hooks.PreToolUse)) {
    if (-not $e.matcher) { Fail "$($pair[0]) PreToolUse entry has no matcher" }
    foreach ($h in @($e.hooks)) {
      if ($h.type -ne 'command' -or -not $h.command) { Fail "$($pair[0]) hook is not a command hook" }
      if (-not @($h.args).Count) { Fail "$($pair[0]) hook '$($h.command)' is not exec form (no args)" }
      elseif (-not (@($h.args) | Where-Object { $_ -like "$($pair[1])*" })) { Fail "$($pair[0]) hook args are not anchored on $($pair[1])" }
    }
  }
  if ($fails -eq $hb) { Ok "$($pair[0]) hooks" }
}

if ($fails -gt 0) { Write-Host "RESULT FAIL ($fails)"; exit 1 }
Write-Host 'RESULT PASS'
exit 0
