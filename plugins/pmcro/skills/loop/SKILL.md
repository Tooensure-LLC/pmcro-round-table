---
name: loop
description: 'Turn one queue item into a trail and run it up to the Checker: 00-frame with raw_intent verbatim beside the true intent, done_means that can fail and the baseline; NN-plan; the Maker''s work; NN-make with real output; a local commit; then stop at HANDOFF: CHECKER REQUIRED. When the trail opens it moves the queue item to taken with scripts/queue-status.ps1. Never writes a check, audit or disposition, never seals, never pushes.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:loop

Role: orchestrator.

## Arguments

`/pmcro:loop <arguments>`: One argument: a queue id (NNNN) or a queue file name. Everything else in the message is ignored.

## What it does

Turn one queue item into a trail and run it up to the Checker: 00-frame with raw_intent verbatim beside the true intent, done_means that can fail and the baseline; NN-plan; the Maker's work; NN-make with real output; a local commit; then stop at HANDOFF: CHECKER REQUIRED. When the trail opens it moves the queue item to taken with scripts/queue-status.ps1. Never writes a check, audit or disposition, never seals, never pushes.

Script: `scripts/queue-status.ps1` in this skill folder. Run it from your repo root; it works on the repo you run it in.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)