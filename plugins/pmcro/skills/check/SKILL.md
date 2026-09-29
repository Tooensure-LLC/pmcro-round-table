---
name: check
description: 'Checker only, read-only. Read the frame, plan and make; re-run the proofs yourself; run your own must-fail test, different from the Maker''s; write only NN-check.jsonl with exactly one verdict: PASS, LOOP or HALT.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:check

Role: checker.

## Arguments

`/pmcro:check <arguments>`: One argument: a trail path, trails/NNNN-name. Read-only except the one NN-check.jsonl it writes.

## What it does

Checker only, read-only. Read the frame, plan and make; re-run the proofs yourself; run your own must-fail test, different from the Maker's; write only NN-check.jsonl with exactly one verdict: PASS, LOOP or HALT.

No script: this skill is instructions only.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)