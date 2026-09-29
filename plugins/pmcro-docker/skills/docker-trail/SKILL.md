---
name: docker-trail
description: Run one docker command through a logging wrapper that appends a record to an open trail, so every Docker step can be replayed and checked. USE FOR docker build, run, ps, images, logs, stop and inspect inside a trail. DO NOT USE for push, login, prune, rm, compose, or when no trail is open.
---

# /docker-trail

Role: maker (runs inside Docker, never on the host).

## Steps

1. Have an open trail with `00-frame.jsonl` whose baseline came from `/docker-baseline`.
2. Run each command through `scripts/docker-trail.ps1 -Trail trails/NNNN-name -Step NN -DockerArgs <args>`.
3. The wrapper appends one record to `trails/NNNN-name/NN-docker.jsonl`: the command, exit code, SHA256 of the output and the last lines with absolute paths scrubbed.
4. A blocked attempt is recorded too, with the reason.

## Refused on purpose

No open trail, a sealed trail, absolute paths, commands off the allow list, `--privileged`, a `docker.sock` mount, or an unreachable engine. These stop and ask Shawn.

## Proof

Must-fail cases are listed in `scripts/docker-trail.ps1` header comments; run each with `-DryRun` and expect a throw. A replay reads the `NN-docker.jsonl` records and compares exit codes and output hashes.
