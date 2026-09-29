---
name: github-templates
description: Apply GitHub templates (seed issue form, PR template, CODEOWNERS, workflows that replay trails, run layout checks and turn a labeled seed issue into a queue PR) so the PMCR-O loop runs on GitHub and always stops at a human merge. USE FOR wiring a repo to the trail workflow. DO NOT USE to merge, approve, push to the default branch, or change branch protection.
---

# /github-templates

Role: maker.

## Steps

1. Open or extend a trail first (`/frame`).
2. Dry run: `scripts/apply-github-templates.ps1` lists each file as NEW or EXISTS. It changes nothing.
3. Show Shawn the list. Apply with `-Apply` only after he says go. Existing files are never overwritten.
4. Read `references/autonomy-gates.md` before enabling the workflows: what runs by itself and where a human must decide.
5. Templates live in `assets/.github/`: `ISSUE_TEMPLATE/seed-intent.yml`, `pull_request_template.md`, `CODEOWNERS`, `dependabot.yml`, and `workflows/` (`ci.yml` build and test, `docs.yml` DocFX to GitHub Pages, `pmcro-replay.yml`, `marketplace-layout.yml`, `seed-to-queue.yml`).

## Rules

- No workflow merges, approves, or pushes to the default branch. The most it does is open a pull request.
- Issue text is untrusted: it reaches scripts only through environment variables.
- Git commit, push, branch protection and installing `gh` are Shawn's calls.
