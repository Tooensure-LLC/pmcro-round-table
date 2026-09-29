# Autonomy gates

The workflows are autonomous up to a pull request and no further.

| Step | Automatic | Human gate |
| --- | --- | --- |
| Issue filed with the seed form | yes | none needed, it is only text |
| Issue becomes a queue PR | only after the owner adds the "seed" label | the label is the approval |
| Trail changed in a PR | replay and layout checks run | the owner merges; CODEOWNERS requires the owner |
| Seal, law change, delete, install, spend, git push to the default branch | never | always the owner |

Rules baked into the assets: issue text is untrusted, so it reaches scripts through env vars only; no workflow merges, auto-approves or pushes to the default branch; permissions are the minimum per job.

Before turning these on: check the action versions (actions/checkout) against the current release, consider pinning to a commit SHA, and turn on branch protection so the default branch needs a reviewed PR. None of this has run on GitHub yet.
