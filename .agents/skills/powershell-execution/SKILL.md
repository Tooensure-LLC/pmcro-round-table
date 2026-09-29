---
name: powershell-execution
description: Runs repo commands on Windows reliably from an agent. USE FOR choosing pwsh vs Windows PowerShell 5.1, passing JSON or jq filters to native tools (gh, git, dotnet), reading UTF-8 output from native tools, long builds that outlive a tool call, and killing a stuck process without killing yourself. DO NOT USE FOR writing trail frames (use /pmcro:frame) or committing (use /pmcro:commit).
---

# PowerShell execution

Every failure listed here happened for real while this repo was built. Each one has a fixed rule. The full cases are in [references/failure-corpus.md](references/failure-corpus.md).

## When to Use

- Any shell command an agent runs on this Windows machine: repo scripts, `gh`, `git`, `dotnet`, `docker`.
- Before any command that passes quotes, JSON or a jq filter to a native executable.
- Before starting a command that may run longer than one tool call (restore, build, `aspire run`).

## When Not to Use

- Writing trail frames: use `/pmcro:frame`. Committing: use `/pmcro:commit`.

## Rules

| When | Do | Never |
|------|----|-------|
| Running any repo script | `pwsh -NoProfile -ExecutionPolicy Bypass -File <script>` (PowerShell 7) | Rely on Windows PowerShell 5.1 for native-argument quoting |
| Filtering `gh api` output | Pipe to `ConvertFrom-Json` and filter in PowerShell | Pass a `--jq` filter that contains `"` under 5.1 (quotes are dropped, gh reports `function not defined`) |
| Reading text from a native tool | Set `[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)` first | Save native output under 5.1 defaults (the OEM code page turns an em dash into `ΓÇö`) |
| A command may exceed ~60 s | `Start-Process` it hidden with output redirected to `.local/<name>.log`, then poll the log tail | Block the tool call on a long restore or build |
| Killing a stuck process | Match on the script path and exclude `$PID` | Match on a word that also appears in your own command line (you kill yourself) |
| A native tool fails | Report its exit code and the last lines of output as the result | Treat a missing success line as success |

## Validation

- [ ] The command ran under `pwsh` or was proven 5.1-safe.
- [ ] Every claim of success quotes real output or an exit code.
- [ ] Long jobs left a log in `.local/` and their final `EXIT=` line was read.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `dotnet new` crashes with `0xC0000005` | Pin the SDK with `global.json` (10.0.x). The crash was seen with the 11.0 RC SDK as the default. |
| `ENOENT` writing a new file through an MCP file tool | Create the parent directory first; the tool does not create it. |
| `ENOSPC` on a small removable drive | Check `Get-Volume` free space before writing; build only on the Dev Drive (U:). |
