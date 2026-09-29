---
name: seal
description: 'Reflector only, after the latest Checker verdict is PASS and Shawn says go: write disposition.json with the hash of every trail frame (file_hashes_at_seal). Refuses without a PASS and never overwrites a seal. After sealing, the Reflector moves the trail''s queue items to done, or partly_done with what remains, using the loop skill''s queue-status script.'
---
<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->

# /pmcro:seal

Role: reflector.

## Arguments

`/pmcro:seal <arguments>`: One argument: a trail path, trails/NNNN-name. Needs the latest check to be PASS and Shawn saying go.

## What it does

Reflector only, after the latest Checker verdict is PASS and Shawn says go: write disposition.json with the hash of every trail frame (file_hashes_at_seal). Refuses without a PASS and never overwrites a seal. After sealing, the Reflector moves the trail's queue items to done, or partly_done with what remains, using the loop skill's queue-status script.

Script: `scripts/seal.ps1` in this skill folder. Run it from your repo root; it works on the repo you run it in.

## References

- `AGENTS.md` (laws, earned constraints, reply style)
- `../loop/references/pmcro-loop.md` (where this skill sits in the loop)