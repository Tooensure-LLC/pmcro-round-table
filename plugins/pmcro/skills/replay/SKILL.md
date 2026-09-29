---
name: replay
description: 'Re-verify a trail on this machine: MATCH or MISMATCH with an exit code. Checks paths, seal, Checker PASS, Auditor AUDIT-PASS, that the committed state rebuilds exactly, and that sealed files are unchanged.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:replay

Role: any.

## Arguments

`/pmcro:replay <arguments>`: One argument: a trail path, trails/NNNN-name. Runs tools/replay.ps1 on it and reports MATCH or MISMATCH.

## What it does

Re-verify a trail on this machine: MATCH or MISMATCH with an exit code. Checks paths, seal, Checker PASS, Auditor AUDIT-PASS, that the committed state rebuilds exactly, and that sealed files are unchanged.

Script: `tools/replay.ps1` in the company repo (run from its root).

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)