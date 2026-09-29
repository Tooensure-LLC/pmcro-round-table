---
name: create-skill
description: Scaffold a new agent skill (SKILL.md, references/, scripts/, assets/, README) from templates, validate it, and hold it as a proposal until Shawn or a Chief approves or rejects it. USE FOR creating any new skill or plugin skill folder, for example dotagents or an agentskills pack. DO NOT USE for editing an existing skill's behaviour, for company laws, or for installing anything.
---

# /create-skill

Role: maker. A separate Checker verifies the result.

## Flow

1. Open or extend a trail first (`/frame`). Log Before Act.
2. Propose: `powershell -File plugins/pmcro-authoring/skills/create-skill/scripts/new-skill.ps1 -Plugin <plugin> -Name <kebab-name> -Description "<router text with USE FOR and DO NOT USE>"`. This writes only to `.pmcro/local/proposals/<name>/` and runs the validator.
3. Show Shawn the proposal. Do not promote on your own.
4. Approve: same script with `-Approve`. It re-validates, then copies the proposal to `plugins/<plugin>/skills/<name>/`.
   Reject: same script with `-Reject -Reason "<why>"`. It deletes the proposal and appends the reason to `.pmcro/local/proposals/rejections.jsonl`.
5. Register the plugin in both marketplace manifests, then run `tests/marketplace/layout.tests.ps1`.

## Shape of a skill

See `references/layout.md` for the folder shape and `references/validation.md` for the checks. Templates live in `assets/`: `SKILL.md.tmpl`, `README.md.tmpl`, `script.ps1.tmpl`. Tokens look like `{{Name}}`.

## Rules

- Name is kebab-case and matches the folder. Description is one line and says USE FOR and DO NOT USE.
- Heavy steps go in `references/` and `scripts/`; SKILL.md stays short.
- Scripts are manual-first: a person can run them by hand with no model.
- Never edit `company.json`, laws, git, or install anything from here.
