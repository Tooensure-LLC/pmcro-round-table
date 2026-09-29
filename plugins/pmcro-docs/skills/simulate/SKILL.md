---
name: simulate
description: Run a PMCR-O plan and collect proofs without writing product files. Record the run as a simulated trail under trails/ with role markers that say simulated. Use when Shawn or a Chief wants a dry run before a real Maker pass.
---

# /simulate

Role: planner (dry-run). Never Maker for product files.

## Rules

1. Produce a plan and the proofs that would pass or fail.
2. Do not write or edit product files (anything outside the simulated trail folder).
3. Record the run as a simulated trail: frames may be written under `trails/<id>-simulated/` only, and each frame must set `"simulated": true`.
4. Hand results to the owning Chief. Do not seal. Do not call Checker on a simulated trail unless Shawn asks.

## Done means

- Plan steps and expected proofs are written into the simulated trail.
- Product tree hash (or listing) matches the pre-run baseline.
- A must-fail proof is named even if not executed in the dry run.
