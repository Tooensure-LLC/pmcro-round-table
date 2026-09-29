---
name: docker-baseline
description: Record the real docker CLI, engine and dotnet versions and whether the engine is reachable, before any docker command. USE FOR the baseline in a trail frame that involves Docker. DO NOT USE to start Docker, install anything, or run containers.
---

# /docker-baseline

Role: orchestrator (baseline for the frame).

## Steps

1. Run `scripts/docker-baseline.ps1` from the repo root.
2. Paste the JSON it prints into the frame's `baseline`.
3. If it exits 2 (CLI missing, engine down, or dotnet missing), the trail stops and asks Shawn. Do not start Docker Desktop or install anything yourself.

## Proof

Must-fail: with the engine stopped the script exits 2. That proves the gate can fail before a run is allowed.
