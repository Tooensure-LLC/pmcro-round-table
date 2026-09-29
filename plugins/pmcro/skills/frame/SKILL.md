---
name: frame
description: 'Open or extend a trail: write one frame (00-frame, NN-plan, NN-make, NN-reflect) only after the EC-0001 scan proves it can fail and finds no absolute path. The frame keeps Shawn''s words verbatim as raw_intent beside the true intent, done_means that can fail, and every baseline a proof needs, before anything changes.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:frame

Role: orchestrator.

## Arguments

`/pmcro:frame <arguments>`: Two arguments: a draft JSON file, then the relative output path trails/NNNN-name/NN-role.jsonl. Refuses an absolute path and refuses to overwrite.

## What it does

Open or extend a trail: write one frame (00-frame, NN-plan, NN-make, NN-reflect) only after the EC-0001 scan proves it can fail and finds no absolute path. The frame keeps Shawn's words verbatim as raw_intent beside the true intent, done_means that can fail, and every baseline a proof needs, before anything changes.

Script: `scripts/frame.ps1` in this skill folder. Run it from your repo root; it works on the repo you run it in.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)