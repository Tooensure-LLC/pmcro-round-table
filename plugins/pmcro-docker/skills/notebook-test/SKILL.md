---
name: notebook-test
description: Check a test notebook (.ipynb) that records Docker test steps, without running it. USE FOR validating a notebook's shape and that it holds no docker build or run step while the hardware gate is closed. DO NOT USE to execute notebooks, start containers, or install Jupyter.
---

# /pmcro-docker:notebook-test

A notebook is a readable, repeatable list of test steps. Until Shawn says the company PC's hardware is checked
(learn/STATE.md records crashes during Docker builds), this skill only validates notebooks; it never runs them.

## Arguments

`/pmcro-docker:notebook-test <path-to.ipynb>`: one relative path to a notebook file.

## Steps

1. Run `scripts/validate-notebook.ps1 -Path <path-to.ipynb>` from the repo root.
2. It passes only when the file parses as JSON, `nbformat` is 4, there is at least one cell, and no code cell contains `docker build` or `docker run`.
3. Start from `assets/sample.ipynb`; it passes the validator.

Exit 0 is PASS, exit 1 is FAIL with one line per fault.
