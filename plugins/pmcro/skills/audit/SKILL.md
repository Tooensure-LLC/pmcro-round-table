---
name: audit
description: 'Auditor only, outside the chain, reports to Shawn: after a trail is sealed ACCEPT with a Checker PASS, sample it and write audit.jsonl with the four pillars (falsifiable, grounded, challenged, cost something) and a finding of AUDIT-PASS or AUDIT-HOLD. A trail is listed only after Checker PASS and this AUDIT-PASS. Refuses an unsealed trail, a non-PASS check, a finding not in the set, an absolute path (EC-0001), and never overwrites an existing finding (Append-Only).'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:audit

Role: auditor.

## Arguments

`/pmcro:audit <arguments>`: Two arguments: a trail path trails/NNNN-name, then a draft JSON file with the four pillars and a finding. Auditor only; runs after seal.

## What it does

Auditor only, outside the chain, reports to Shawn: after a trail is sealed ACCEPT with a Checker PASS, sample it and write audit.jsonl with the four pillars (falsifiable, grounded, challenged, cost something) and a finding of AUDIT-PASS or AUDIT-HOLD. A trail is listed only after Checker PASS and this AUDIT-PASS. Refuses an unsealed trail, a non-PASS check, a finding not in the set, an absolute path (EC-0001), and never overwrites an existing finding (Append-Only).

Script: `scripts/audit.ps1` in this skill folder. Run it from your repo root; it works on the repo you run it in.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)