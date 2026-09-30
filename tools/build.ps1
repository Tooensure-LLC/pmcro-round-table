# build.ps1 - renders chiefs/, docs/company/, marketplace/, the host context files (AGENTS.md, CLAUDE.md, .claude/)
# and the plugin marketplace from company.json. Output paths follow each host's published convention:
#   AGENTS.md (agents.md), CLAUDE.md + .claude/ (code.claude.com/docs/en/claude-directory),
#   plugins/*/skills/*/SKILL.md (agentskills.io; also loaded by MAF AgentSkillsProvider), DocFX content under docs/.
# Deterministic: same company.json + same trails => same output. ASCII only. No timestamps.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$c = Get-Content -Raw (Join-Path $root 'company.json') | ConvertFrom-Json
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Out-File2($rel, $text) {
  $p = Join-Path $root $rel
  New-Item -ItemType Directory -Force (Split-Path -Parent $p) | Out-Null
  [IO.File]::WriteAllText($p, ($text -replace "`r`n", "`n"), $utf8)
}
$nl = "`n"
$roster = ($c.bots | ForEach-Object { $_.title }) -join ', '
$laws = ($c.laws | ForEach-Object -Begin { $i = 0 } -Process { $i++; "$i. $($_.name): $($_.text)" }) -join $nl
$ask = ($c.always_ask_shawn) -join ', '
$gen = '<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->'

# 1. One Grok Bot role prompt per bot (kept in $agentText for plugins/pmcro/agents, section 5)
$agentText = @{}
foreach ($b in $c.bots) {
  $who = switch ($b.kind) {
    'checker' { "You are the independent Checker for the $($b.checks_for.ToUpper()) Chief. You are a separate bot on purpose: the Maker never scores its own work, and you never do the Maker's work." }
    'auditor' { 'You sit OUTSIDE the chain of command and report only to Shawn. No Chief can direct you or edit your findings.' }
    default   { 'Chiefs frame intents; the PMCR-O loop executes them. If a request is outside Owns, name the Chief who owns it and stop.' }
  }
  $txt = @"
$gen
You are the $($b.title) of the $($c.company). Please rename yourself "$($b.title)".

WHO YOU ARE
$who

BOUNDARY
- Owns: $($b.owns)
- Does not own: $($b.does_not_own)
- Reports to: $($b.reports_to)

THE COMPANY
Product: $($c.product)
Loop: $($c.loop -join ' > '). The Checker is always a separate bot.
Roster: $roster.

LAWS
$laws

EARNED CONSTRAINTS (lessons the company paid for)
$(($c.earned_constraints | ForEach-Object { "- $($_.id): $($_.text)" }) -join $nl)

ALWAYS ASK SHAWN FIRST: $ask.

FIRST TASK (change nothing): reply in 2 short lines: $($b.first_task) Then wait.
"@
  Out-File2 "chiefs/$($b.id)/AGENT.md" $txt
  $agentText[$b.id] = $txt
}

# 2. Docs site (GitHub Pages serves docs/)
$rows = ($c.bots | ForEach-Object { "| [$($_.title)](chiefs/$($_.id).md) | $($_.group) | $($_.reports_to) |" }) -join $nl
$lawRows = ($c.laws | ForEach-Object { "| $($_.id) | $($_.name) | $($_.text) |" }) -join $nl
$rt = ($c.round_tables | ForEach-Object { "- **$($_.name)** (chair: $($_.chair)): $($_.members -join ', '). $($_.note)" }) -join $nl
$trailDir = Join-Path $root 'trails'
$trails = @(Get-ChildItem $trailDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
$trailRows = ($trails | ForEach-Object {
  $files = @(Get-ChildItem $_.FullName -File | Sort-Object Name | ForEach-Object { $_.Name })
  $state = if ($files -contains 'disposition.json') { ((Get-Content -Raw (Join-Path $_.FullName 'disposition.json')) | ConvertFrom-Json).disposition } else { 'OPEN (not sealed)' }
  "| ``trails/$($_.Name)/`` | $state | $($files -join ', ') |"
}) -join $nl
Out-File2 'docs/company/index.md' @"
$gen
# $($c.company)

Version $($c.version). Runtime: $($c.runtime).

**Product:** $($c.product)

$($c.principles -join "$nl$nl")

## The loop

$($c.loop -join ' > '). The Checker is always a separate bot. Failures become a new seed intent; after 3 loops the work halts to Shawn.

## Roster

| Seat | Group | Reports to |
| --- | --- | --- |
$rows

## Round tables

$rt

## Laws

| Id | Law | Meaning |
| --- | --- | --- |
$lawRows

## Earned constraints

$(($c.earned_constraints | ForEach-Object { "- **$($_.id)** ($($_.earned_on)): $($_.text)" }) -join $nl)

Always ask Shawn first: $ask.

## Trails

Every change to this company is a trail. Trails are append-only and use relative paths, so they replay anywhere.

| Trail | State | Files |
| --- | --- | --- |
$trailRows

## The company drive`n`n| Folder | What it is |`n| --- | --- |`n$(($c.drive | ForEach-Object { "| ``$($_.path)`` | $($_.what) |" }) -join $nl)`n`n## Marketplace

See ``marketplace/catalog.json`` in the repo. Each bot is a shareable Grok Bot template built from ``chiefs/<id>/AGENT.md``, and the same seat runs in the MAF runtime.
"@
Out-File2 'docs/company/toc.yml' ("- name: Company${nl}  href: index.md${nl}- name: Seats${nl}  items:${nl}" + (($c.bots | ForEach-Object { "  - name: $($_.title)${nl}    href: chiefs/$($_.id).md" }) -join $nl) + $nl)
foreach ($b in $c.bots) {
  Out-File2 "docs/company/chiefs/$($b.id).md" @"
$gen
# $($b.title)

Group: $($b.group). Reports to: $($b.reports_to).

**Owns:** $($b.owns)

**Does not own:** $($b.does_not_own)

Grok Bot prompt and MAF agent instructions: ``chiefs/$($b.id)/AGENT.md``. Claude Code / Copilot agent: ``plugins/pmcro/agents/$($b.id).agent.md``.

[Back to the company](../index.md)
"@
}

# 3. Marketplace catalog: every bot is a shareable template; every trail is a candidate trail product
$items = @()
foreach ($b in $c.bots) {
  $items += [ordered]@{ id = "bot/$($b.id)"; type = 'grok-bot-template'; title = $b.title; group = $b.group; source = "chiefs/$($b.id)/AGENT.md"; docs = "docs/company/chiefs/$($b.id).md" }
}
foreach ($t in $trails) {
  $dp = Join-Path $t.FullName 'disposition.json'; $sealed = Test-Path $dp; $ap = Join-Path $t.FullName 'audit.jsonl'; $audited = $sealed -and (Test-Path $ap) -and (((Get-Content $ap | Select-Object -Last 1) | ConvertFrom-Json).finding -eq 'AUDIT-PASS')
  $items += [ordered]@{ id = "trail/$($t.Name)"; type = 'trail-product'; title = $t.Name; source = "trails/$($t.Name)/"; listed = $audited; note = $(if ($audited) { 'sealed and Auditor-reviewed' } elseif ($sealed) { 'sealed; waiting for Auditor review' } else { 'open; not listed until sealed by a Checker and reviewed by the Auditor' }) }
}
$cat = [ordered]@{ marketplace = $c.company; version = $c.version; generated_from = 'company.json'; items = $items }
Out-File2 'marketplace/catalog.json' (($cat | ConvertTo-Json -Depth 6) + $nl)

# 4. Agent folder layout (old-repo trails/0005-pmcro-skeleton): AGENTS.md for every host, CLAUDE.md -> @AGENTS.md, and .pmcro/ for PMCR-O's own parts.
#    The skills themselves are plugins/pmcro/skills (section 5; old-repo trails/0010-pmcro-plugin-self-contained).
$skillRows = ($c.skills | ForEach-Object { "- ``/pmcro:$($_.id)`` ($($_.role)): $($_.description)" }) -join $nl
$roleRows = ($c.roles | ForEach-Object { "- **$($_.name)** ($($_.pattern)): $($_.contract)" }) -join $nl
Out-File2 'AGENTS.md' @"
$gen
# $($c.company)

$($c.product)

## The loop

$($c.loop -join ' > '). The Checker is always a separate bot. Nobody scores their own work.

$roleRows

## Laws

$laws

## Earned constraints

$(($c.earned_constraints | ForEach-Object { "- $($_.id): $($_.text)" }) -join $nl)

## Reflector rule

- $($c.reflector_rule.id) $($c.reflector_rule.name): $($c.reflector_rule.text)

## How to reply

$($c.output_style.text) See ``.claude/output-styles/pmcro.md``.

## Skills (plugin ``pmcro``, in ``plugins/pmcro/skills/``; seats are agents, addressed as ``@bot-id``)

$skillRows

## Where things are

- ``company.json``: the single source of truth. Edit it, then run ``tools/build.ps1``. Never hand-edit generated files.
- ``trails/NNNN-name/``: append-only records of every change. ``queue/``: seed intents in Shawn's own words, each with a status ($($c.queue.statuses -join ', ')); move a status only with ``$($c.queue.move)``, and ``$($c.queue.check)`` proves the statuses agree with the trails.
- ``.claude/``: Claude Code's standard folder: ``settings.json`` (permissions and the log-before-act hook), ``rules/`` (one file per law), ``output-styles/pmcro.md``. Generated; other hosts read the same laws from this file.
- ``plugins/``: the plugin marketplace. Skills are Agent Skills (``SKILL.md``); the same folders are loaded by the MAF runtime through ``AgentSkillsProvider``, by Claude Code, Codex and Cursor through the plugin marketplaces, and by Grok Bot as bot templates (``chiefs/``).
- ``src/``: the company's own runtime: ``Pmcro.AppHost`` (Aspire), ``Pmcro.Runtime`` (Microsoft Agent Framework, one agent per seat), ``Pmcro.ServiceDefaults`` (OpenTelemetry). ``tests/``: xUnit and PowerShell checks. ``docs/``: DocFX site. ``eng/``: scaffolding and validators. ``.local/`` is scratch and never committed.
- Build: ``dotnet build``, ``dotnet test``, ``dotnet docfx docs/docfx.json``, ``tools/build.ps1``. Stack pins and their sources: ``eng/STACK.md``.

Always ask Shawn first: $ask.
"@
Out-File2 'CLAUDE.md' "@AGENTS.md$nl$nl$gen$nl"
# .agents/skills is no longer generated (old-repo trails/0010-pmcro-plugin-self-contained): the skills and their scripts live in plugins/pmcro.
Out-File2 '.claude/output-styles/pmcro.md' @"
---
name: '$($c.output_style.name)'
description: 'Every reply runs the PMCR-O loop in order and ends with the next seed.'
---
$gen

$($c.output_style.text)

Roots:
$(($c.output_style.roots | ForEach-Object { "- $_" }) -join $nl)
"@
foreach ($l in $c.laws) { Out-File2 ".claude/rules/$($l.id).md" "$gen$nl# $($l.id) $($l.name)$nl$nl$($l.text)$nl" }
foreach ($e in $c.earned_constraints) { Out-File2 ".claude/rules/$($e.id).md" "$gen$nl# $($e.id) (earned on $($e.earned_on))$nl$nl$($e.text)$nl" }
Out-File2 ".claude/rules/$($c.reflector_rule.id).md" "$gen$nl# $($c.reflector_rule.id) $($c.reflector_rule.name)$nl$nl$($c.reflector_rule.text)$nl"
Out-File2 'plugins/pmcro/skills/loop/references/pmcro-loop.md' @"
$gen
# The PMCR-O loop

Fixed order inside every cycle: $($c.loop -join ' > '). The Orchestrator never skips or reorders a role. Between cycles it decides from evidence only: ACCEPT, EXTEND, LOOP, ESCALATE or INTERRUPT (see the role contracts below).

1. Orchestrator: ``/pmcro:seed`` turns Shawn's words into a true intent; ``/pmcro:frame`` opens the trail with a baseline (Log Before Act).
2. Planner: writes ``NN-plan.jsonl`` with ``/pmcro:frame``: the bare minimum steps, each with a proof that can fail.
3. Maker: does the steps, writes ``NN-make.jsonl`` with real output, commits, stops at HANDOFF: CHECKER REQUIRED.
4. Checker (separate bot): ``/pmcro:check`` writes ``NN-check.jsonl``: PASS, LOOP or HALT.
5. Reflector: writes ``NN-reflect.jsonl`` with one candidate constraint ($($c.reflector_rule.id)) and the next seed; on PASS and Shawn's go, ``/pmcro:seal``.

LOOP starts the next numbered plan. After 3 loops (EC-009) the work stops and goes to Shawn. ``/pmcro:replay`` re-verifies any trail at any time.

## Role contracts

$roleRows
"@
foreach ($r in $c.roles) { Out-File2 "src/Pmcro.Runtime/Roles/$($r.id).md" "$gen$nl# $($r.name)$nl${nl}Pattern: $($r.pattern)$nl$nl$($r.contract)$nl" }
# Hooks, exported to the hosts that read them (company.json hooks[].event before_edit = Claude Code PreToolUse Edit|Write).
$pre = @($c.hooks | Where-Object { $_.event -eq 'before_edit' })
# [ordered]: a plain @{} hashtable has no stable key order, which made these two files differ between runs (trails/0001 02-check D1).
# Exec form (command + args, no shell) per code.claude.com/docs/en/hooks, so the path placeholder works on Windows
# whether Claude Code would pick Git Bash or PowerShell; the script path is anchored on the project or plugin root.
$hookEntry = { param([string]$scriptPrefix) @([ordered]@{ matcher = 'Edit|Write|MultiEdit|NotebookEdit'; hooks = @($pre | ForEach-Object { [ordered]@{ type = 'command'; command = $_.executable; args = @($_.args) + @($_.script.Replace('plugins/pmcro/', $scriptPrefix)); timeout = 30 } }) }) }
$settings = [ordered]@{
  '$schema' = 'https://json.schemastore.org/claude-code-settings.json'
  permissions = [ordered]@{
    deny = @('Read(./.env)', 'Read(./.env.*)', 'Read(./secrets/**)', 'Bash(git push:*)')
    ask  = @('Bash(dotnet tool install:*)', 'Bash(dotnet new install:*)', 'Bash(winget:*)', 'Bash(gh repo create:*)')
  }
  hooks = [ordered]@{ PreToolUse = @(& $hookEntry '${CLAUDE_PROJECT_DIR}/plugins/pmcro/') }
}
Out-File2 '.claude/settings.json' (($settings | ConvertTo-Json -Depth 8) + $nl)
Out-File2 'plugins/pmcro/hooks/hooks.json' (([ordered]@{ hooks = [ordered]@{ PreToolUse = @(& $hookEntry '${CLAUDE_PLUGIN_ROOT}/') } } | ConvertTo-Json -Depth 8) + $nl)

# 5. Plugin marketplace in the dotnet/skills layout (old-repo trails/0008-skill-author-docker-github-plugins).
#    plugins/pmcro is generated here from company.json: skills = company.json skills (/pmcro:<id>), agents = the seats (@<bot-id>).
#    The other plugins/pmcro-* folders are hand-authored; the three host marketplace.json files list every plugins/*/plugin.json.
$m = $c.marketplace
$q = { param($s) "'" + ($s -replace "'", "''") + "'" }
$pj = { param($name, $ver, $desc, [string[]]$agents)
  $o = [ordered]@{ name = $name; version = $ver; description = $desc; skills = @('./skills/') }
  if ($agents) { $o.agents = @($agents) }
  ($o | ConvertTo-Json -Depth 4) + $nl }
$agentRefs = @($c.bots | ForEach-Object { "./agents/$($_.id).agent.md" })
Out-File2 'plugins/pmcro/plugin.json' (& $pj $m.core_plugin $m.core_plugin_version $m.core_plugin_description $agentRefs)
Out-File2 'plugins/pmcro/.claude-plugin/plugin.json' (& $pj $m.core_plugin $m.core_plugin_version $m.core_plugin_description $agentRefs)
Out-File2 'plugins/pmcro/.codex-plugin/plugin.json' (& $pj $m.core_plugin $m.core_plugin_version $m.core_plugin_description $null)
Out-File2 'plugins/pmcro/version.json' @"
{
  "`$schema": "https://raw.githubusercontent.com/dotnet/Nerdbank.GitVersioning/main/src/NerdBank.GitVersioning/version.schema.json",
  "version": "$(($m.core_plugin_version -split '\.')[0..1] -join '.')",
  "pathFilters": [
    ".",
    ":!plugin.json",
    ":!.codex-plugin/plugin.json",
    ":!.claude-plugin/plugin.json",
    ":!version.json"
  ]
}
"@
Out-File2 'plugins/pmcro/README.md' @"
$gen
# pmcro

$($m.core_plugin_description)

## Invoke

- A skill: ``/pmcro:<skill> <arguments>``. Each ``skills/<skill>/SKILL.md`` says how its arguments are read.
- A seat: ``@<bot-id>``, for example ``@cto-checker /pmcro:check trails/<name>``.

| Skill | Role | Arguments |
| --- | --- | --- |
$(($c.skills | ForEach-Object { "| ``/pmcro:$($_.id)`` | $($_.role) | $($_.arguments) |" }) -join $nl)

| Agent | Seat | Group |
| --- | --- | --- |
$(($c.bots | ForEach-Object { "| ``@$($_.id)`` | $($_.title) | $($_.group) |" }) -join $nl)

The files under ``agents/`` are GitHub Copilot custom-agent definitions. Codex plugin installs expose this plugin's skills, but do not install those ``.agent.md`` files as native Codex agents.
"@
foreach ($s in $c.skills) {
  $scriptLine = if ($s.script -like 'scripts/*') {
    "Script: ``$($s.script)`` in this skill folder. Run it from your repo root; it works on the repo you run it in."
  } elseif ($s.script) {
    $full = [IO.Path]::GetFullPath((Join-Path $root "plugins/pmcro/skills/$($s.id)/$($s.script)"))
    $rel = $full.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
    "Script: ``$rel`` in the company repo (run from its root)."
  } else { 'No script: this skill is instructions only.' }
  Out-File2 "plugins/pmcro/skills/$($s.id)/SKILL.md" @"
---
name: $($s.id)
description: $(& $q $s.description)
---
$gen

# /pmcro:$($s.id)

Role: $($s.role).

## Arguments

``/pmcro:$($s.id) <arguments>``: $($s.arguments)

## What it does

$($s.description)

$scriptLine

## References

- ``AGENTS.md`` (laws, earned constraints, reply style)
- ``../loop/references/pmcro-loop.md`` (where this skill sits in the loop)
"@
}
foreach ($b in $c.bots) {
  Out-File2 "plugins/pmcro/agents/$($b.id).agent.md" @"
---
name: $($b.id)
description: $(& $q "$($b.title) seat of $($c.company). Owns: $($b.owns)")
user-invokable: true
disable-model-invocation: false
---
$($agentText[$b.id])
"@
}
$plugs = @(Get-ChildItem (Join-Path $root 'plugins') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'plugin.json') } | Sort-Object @{ Expression = { $_.Name -ne $m.core_plugin } }, Name |
  ForEach-Object { $j = Get-Content -Raw (Join-Path $_.FullName 'plugin.json') | ConvertFrom-Json; [ordered]@{ name = $j.name; source = "./plugins/$($_.Name)"; description = $j.description } })
$mk = { param($extra) $o = [ordered]@{ name = $m.name; owner = [ordered]@{ name = $m.owner } }; foreach ($k in $extra.Keys) { $o[$k] = $extra[$k] }; $o.plugins = $plugs; ($o | ConvertTo-Json -Depth 6) + $nl }
Out-File2 '.claude-plugin/marketplace.json' (& $mk ([ordered]@{}))
Out-File2 '.agents/plugins/marketplace.json' (& $mk ([ordered]@{ interface = [ordered]@{ displayName = $m.display_name } }))
Out-File2 '.cursor-plugin/marketplace.json' (& $mk ([ordered]@{ metadata = [ordered]@{ description = $m.description } }))
Out-File2 '.github/plugin/marketplace.json' (& $mk ([ordered]@{ metadata = [ordered]@{ description = $m.description } }))  # GitHub Copilot, as in dotnet/skills

"built: $(@($c.bots).Count) bots, $(@($trails).Count) trails, $(@($items).Count) marketplace items, $(@($c.skills).Count) skills, $(@($c.laws).Count + @($c.earned_constraints).Count + 1) rules, $(@($plugs).Count) plugins, AGENTS.md, CLAUDE.md, .claude, docs/company"
