# Architecture

## One definition, three hosts

`company.json` is the only hand-edited source. `tools/build.ps1` generates everything a host reads, and each generated file goes where that host's published convention expects it.

| Host | What it reads | Convention |
| --- | --- | --- |
| Grok Bot | `chiefs/<id>/AGENT.md` (one bot per seat) | Grok Bot templates |
| Claude Code | `CLAUDE.md` (imports `AGENTS.md`), `.claude/settings.json`, `.claude/rules/`, `.claude/output-styles/`, the `pmcro` plugin | [.claude directory](https://code.claude.com/docs/en/claude-directory) |
| Codex, Cursor, Copilot | `AGENTS.md`, `.agents/plugins/marketplace.json`, `.cursor-plugin/marketplace.json` | [agents.md](https://agents.md), [dotnet/skills](https://github.com/dotnet/skills) layout |
| MAF runtime | `chiefs/<id>/AGENT.md` as agent instructions, `plugins/*/skills` through `AgentSkillsProvider`, `roles` for the loop workflow | [Agent Skills](https://agentskills.io), [MAF skills](https://learn.microsoft.com/agent-framework/agents/skills) |

## Two kinds of skills (the dotnet/skills split)

- `plugins/<plugin>/skills/<skill>/`: the skills the company ships. Every host that installs the marketplace gets them, and the MAF runtime loads them.
- `.agents/skills/<skill>/`: skills for working on this repo (create-skill, create-skill-test, improve-skill-quality and others). These are vendored from dotnet/skills at a pinned commit by `eng/sync-upstream.ps1`, plus the repo's own `powershell-execution`.

## The loop in the runtime

`Pmcro.Runtime` registers one agent per seat and one agent per loop role. The `pmcro-cycle` workflow runs Planner > Maker > Checker > Reflector in a fixed order. The Orchestrator opens each cycle and, from the evidence alone, closes it with ACCEPT, EXTEND, LOOP, ESCALATE or INTERRUPT.

## Governance

- The Claude Code `PreToolUse` hook blocks edits when no trail is open (Log Before Act). The MAF equivalent is function-invocation middleware.
- The runtime's skills provider has no script runner. Skills can be advertised, loaded and read, but scripts run only through a governed Maker step.
- `/pmcro:commit` is the only way to commit. It regenerates, validates, scans for absolute paths, and never pushes.
