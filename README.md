# Tooensure / PMCR-O Agent Company

An AI agent company where every change runs the PMCR-O loop (Orchestrator > Planner > Maker > Checker > Reflector) and leaves a replayable trail. The trail is the product.

One definition, `company.json`, drives three hosts: Grok Bot seats, Claude Code / Codex / Cursor / Copilot through the plugin marketplace, and the company's own Microsoft Agent Framework runtime on Aspire.

## Start here

| You want to | Do |
| --- | --- |
| Understand the company | Read `AGENTS.md` (generated), then `docs/architecture.md` |
| Change the company | Open a trail, edit `company.json`, run `pwsh tools/build.ps1`, commit with `/pmcro:commit` |
| Build and test | `dotnet build Pmcro.slnx` and `dotnet test Pmcro.slnx` |
| Run the runtime | `aspire run` (host Ollama with `qwen3:8b`; see `src/Pmcro.AppHost/appsettings.json`) |
| Build the docs | `dotnet tool restore`, then `dotnet docfx docs/docfx.json --serve` |
| Install the skills in Claude Code | `/plugin marketplace add <path or repo>`, then `/plugin install pmcro@tooensure-pmcro-skills` |

## Layout

| Path | What it is | Convention |
| --- | --- | --- |
| `company.json` | The single source of truth | This repo |
| `AGENTS.md`, `CLAUDE.md`, `.claude/` | Context files and host settings (generated) | agents.md, Claude Code `.claude` directory |
| `plugins/<plugin>/skills/` | Skills the company ships | Agent Skills and the dotnet/skills layout |
| `.agents/skills/` | Skills for working on this repo (vendored from dotnet/skills, plus `powershell-execution`) | dotnet/skills |
| `chiefs/<id>/AGENT.md` | One seat prompt per bot (generated) | Grok Bot templates, MAF instructions |
| `src/` | `Pmcro.AppHost` (Aspire), `Pmcro.Runtime` (MAF), `Pmcro.ServiceDefaults` | Aspire and MAF templates |
| `tests/` | xUnit tests and marketplace layout checks | |
| `docs/` | DocFX site; `docs/company/` is generated | DocFX |
| `trails/`, `queue/` | Append-only records and seed intents | PMCR-O |
| `eng/` | `scaffold.ps1` (official templates), `sync-upstream.ps1`, validators, `STACK.md` | dotnet/skills `eng/` |

How this repo was created is itself reproducible: `eng/scaffold.ps1` runs only published templates.
