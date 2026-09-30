<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->
# pmcro

The PMCR-O loop as skills (/pmcro:seed, /pmcro:loop, /pmcro:frame, /pmcro:check, /pmcro:seal, /pmcro:replay, /pmcro:commit) and the company seats as agents (@<bot-id>). Generated from company.json.

## Invoke

- A skill: `/pmcro:<skill> <arguments>`. Each `skills/<skill>/SKILL.md` says how its arguments are read.
- A seat: `@<bot-id>`, for example `@cto-checker /pmcro:check trails/<name>`.

| Skill | Role | Arguments |
| --- | --- | --- |
| `/pmcro:frame` | orchestrator | Two arguments: a draft JSON file, then the relative output path trails/NNNN-name/NN-role.jsonl. Refuses an absolute path and refuses to overwrite. |
| `/pmcro:check` | checker | One argument: a trail path, trails/NNNN-name. Read-only except the one NN-check.jsonl it writes. |
| `/pmcro:seal` | reflector | One argument: a trail path, trails/NNNN-name. Needs the latest check to be PASS and Shawn saying go. |
| `/pmcro:replay` | any | One argument: a trail path, trails/NNNN-name. Runs tools/replay.ps1 on it and reports MATCH or MISMATCH. |
| `/pmcro:seed` | orchestrator | Everything after the command is Shawn's words, kept verbatim as raw_intent, even when messy. Returns the new queue id (NNNN). |
| `/pmcro:commit` | maker | Two arguments: an open trail path trails/NNNN-name, then a one-line message. Local commit only; never pushes. |
| `/pmcro:loop` | orchestrator | One argument: a queue id (NNNN) or a queue file name. Everything else in the message is ignored. |
| `/pmcro:audit` | auditor | Two arguments: a trail path trails/NNNN-name, then a draft JSON file with the four pillars and a finding. Auditor only; runs after seal. |

| Agent | Seat | Group |
| --- | --- | --- |
| `@chief-of-staff` | Chief of Staff | Leadership |
| `@ceo` | CEO | Leadership |
| `@cto` | CTO Chief | Build |
| `@cto-checker` | CTO Checker | Build |
| `@cpo` | CPO | Build |
| `@cdo` | CDO | Build |
| `@ciso` | CISO | Build |
| `@coo` | COO | Run |
| `@cfo` | CFO | Run |
| `@clo` | CLO | Run |
| `@chief-agent-officer` | Chief Agent Officer | Run |
| `@cro` | CRO | Grow |
| `@cmo` | CMO | Grow |
| `@cco` | CCO | Grow |
| `@auditor` | Auditor | Outside the chain |

The files under `agents/` are GitHub Copilot custom-agent definitions. Codex plugin installs expose this plugin's skills, but do not install those `.agent.md` files as native Codex agents.