---
name: commit
description: 'The only way the Maker commits: refuses unless the trail is open (00-frame, no disposition), regenerates with tools/build.ps1, runs the plugin validator, scans staged trail files for absolute paths (EC-PORTABLE-005), then makes one local commit whose message names the trail and carries a Trail: trailer. Pushing stays with Shawn.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:commit

Role: maker.

## Arguments

`/pmcro:commit <arguments>`: Two arguments: an open trail path trails/NNNN-name, then a one-line message. Local commit only; never pushes.

## What it does

The only way the Maker commits: refuses unless the trail is open (00-frame, no disposition), regenerates with tools/build.ps1, runs the plugin validator, scans staged trail files for absolute paths (EC-PORTABLE-005), then makes one local commit whose message names the trail and carries a Trail: trailer. Pushing stays with Shawn.

Script: `scripts/commit.ps1` in this skill folder. Run it from your repo root; it works on the repo you run it in.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)