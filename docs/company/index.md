<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->
# Tooensure / PMCR-O Agent Company

Version 0.1.0. Runtime: Two hosts, one definition: Grok Bot (one bot per seat, prompt in chiefs/<id>/AGENT.md) and the company's own Microsoft Agent Framework runtime on Aspire (src/Pmcro.Runtime loads the same seat prompts and the same Agent Skills).

**Product:** We sell audited, replayable trails. A trail is the guarantee: a buyer replays it with tools/replay.ps1 and gets MATCH or MISMATCH. A trail is listed only after an independent Checker PASS and an Auditor AUDIT-PASS.

Chiefs frame intents; the PMCR-O loop executes them.

The Checker is always a separate bot. Nobody scores their own work.

Everything is generated from this file. Edit company.json, then run tools/build.ps1. Never hand-edit generated files.

## The loop

Orchestrator > Planner > Maker > Checker > Reflector. The Checker is always a separate bot. Failures become a new seed intent; after 3 loops the work halts to Shawn.

## Roster

| Seat | Group | Reports to |
| --- | --- | --- |
| [Chief of Staff](chiefs/chief-of-staff.md) | Leadership | CEO, then Shawn |
| [CEO](chiefs/ceo.md) | Leadership | Shawn (the human board) |
| [CTO Chief](chiefs/cto.md) | Build | CEO, then Shawn |
| [CTO Checker](chiefs/cto-checker.md) | Build | Shawn |
| [CPO](chiefs/cpo.md) | Build | CEO, then Shawn |
| [CDO](chiefs/cdo.md) | Build | CEO, then Shawn |
| [CISO](chiefs/ciso.md) | Build | CEO directly (not the CTO), then Shawn |
| [COO](chiefs/coo.md) | Run | CEO, then Shawn |
| [CFO](chiefs/cfo.md) | Run | CEO, then Shawn |
| [CLO](chiefs/clo.md) | Run | CEO, then Shawn |
| [Chief Agent Officer](chiefs/chief-agent-officer.md) | Run | CEO, then Shawn |
| [CRO](chiefs/cro.md) | Grow | CEO, then Shawn |
| [CMO](chiefs/cmo.md) | Grow | CEO, then Shawn |
| [CCO](chiefs/cco.md) | Grow | CEO, then Shawn |
| [Auditor](chiefs/auditor.md) | Outside the chain | Shawn only |

## Round tables

- **Executive Round Table** (chair: chief-of-staff): chief-of-staff, ceo, cto, cpo, coo, cfo. Grok Bot group chats hold at most 6 bots.

## Laws

| Id | Law | Meaning |
| --- | --- | --- |
| EC-SYS-003 | Log Before Act | Write the trail entry before changing any file. |
| EC-VERIFY-FIRST-001 | Verify First | No claim of done without real command output. |
| EC-004 | Checker Verdict Only | Nobody scores their own work; only a separate Checker says PASS, LOOP or HALT. |
| EC-009 | MaxLoops | Max 3 loops per trail, then stop and ask Shawn. |
| EC-PORTABLE-005 | Relative Paths | Only relative paths inside trails, so any trail replays on any machine. A path already written into a frame stays as a recorded defect (frames are append-only); the rule binds every frame written after it. |
| LAW-010 | Append-Only | Trail frames are never edited or deleted; corrections are new frames. |

## Earned constraints

- **EC-0001** (old-repo trails/0001-company-founding): Before writing any trail frame, scan its text for absolute paths with a check first proven able to fail on a sample built by the same serializer that writes the trail.
- **EC-0002** (trails/0002-boundary (candidate CC-0001-BOUNDARY from trails/0001-foundation/03-reflect.jsonl; policy approved by Shawn 2026-09-29)): A block by a platform control (bot detection, rate limit, terms of service) is a boundary, not an obstacle. A platform's own policy is a validated resource in the baseline, so the Planner plans only inside it. On a block the Checker gives HALT, the Reflector records the policy and a permitted path (the official API, the account owner acting, or a different goal), and the Orchestrator returns ESCALATE or INTERRUPT. The loop never learns to look more human to get past a control. A trail product names its permitted path and ships its boundary constraints so the buyer, who is bound by the platform's terms once they inject their own account, sees them before the first run. The rule holds on every host: Grok Bot, Claude computer use and the company runtime.

Always ask Shawn first: anything irreversible, deleting, installing, git pushes, and git writes other than the local commit the loop skill makes (Shawn, 2026-09-29), changing laws or policy, spending, giving any bot more authority.

## Trails

Every change to this company is a trail. Trails are append-only and use relative paths, so they replay anywhere.

| Trail | State | Files |
| --- | --- | --- |
| `trails/0001-foundation/` | OPEN (not sealed) | 00-frame.jsonl, 01-make.jsonl, 02-check.jsonl, 03-reflect.jsonl, 04-plan.jsonl, 05-make.jsonl, 06-make.jsonl |
| `trails/0002-boundary/` | OPEN (not sealed) | 00-frame.jsonl, 01-make.jsonl |
| `trails/0003-ec0002-must-fail/` | OPEN (not sealed) | 00-frame.jsonl, 01-plan.jsonl, 02-make.jsonl, 03-plan.jsonl, 04-make.jsonl |
| `trails/0004-round-table/` | OPEN (not sealed) | 00-frame.jsonl, 01-plan.jsonl, 02-make.jsonl, 03-make.jsonl, 04-make.jsonl |

## The company drive

| Folder | What it is |
| --- | --- |
| `src/` | The company runtime: Pmcro.AppHost (Aspire), Pmcro.Runtime (Microsoft Agent Framework, one agent per seat, Agent Skills from plugins/), Pmcro.ServiceDefaults (OpenTelemetry). |
| `plugins/` | The plugin marketplace: Agent Skills and seat agents for Claude Code, Codex, Cursor and the MAF runtime. |
| `chiefs/` | One generated seat prompt per bot: the Grok Bot template and the MAF agent instructions. |
| `trails/ and queue/` | Append-only trails of every change and the seed intents they came from. |
| `docs/` | The DocFX documentation site (company pages are generated into docs/company/). |
| `eng/ and tools/` | Scaffolding from official templates, validators, the generator (tools/build.ps1) and replay. |

## Marketplace

See `marketplace/catalog.json` in the repo. Each bot is a shareable Grok Bot template built from `chiefs/<id>/AGENT.md`, and the same seat runs in the MAF runtime.