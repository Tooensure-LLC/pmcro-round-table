# Failure corpus

Each case is one real failure from `trails/0001-foundation`, with the fix. The format (case, symptom, cause, rule) follows the failure-corpus idea in agent-shells/powershell-skills (MIT). The cases themselves are this repo's own.

## PS51-JQ-QUOTES

- Symptom: `gh api ... --jq '.tree[] | select(.type=="blob")'` failed with `function not defined: blob/0`.
- Cause: Windows PowerShell 5.1 drops the embedded double quotes when it passes arguments to a native executable.
- Rule: parse with `ConvertFrom-Json` in PowerShell, or run under pwsh 7.

## PS51-OEM-ENCODING

- Symptom: vendored SKILL.md files contained `ΓÇö` where upstream had an em dash.
- Cause: 5.1 decodes native stdout with the OEM code page.
- Rule: set `[Console]::OutputEncoding` to UTF-8 before capturing native output. `eng/sync-upstream.ps1` does this.

## SELF-KILL-MATCH

- Symptom: a cleanup command killed its own shell.
- Cause: it stopped every process whose command line matched `tool-manifest`, and its own command line contained that word.
- Rule: match on the target script path and exclude `$PID`.

## LONG-CALL-TIMEOUT

- Symptom: `Device did not respond within 60s` during template scaffolding and a validator build.
- Cause: restore and build ran inside a single blocking tool call.
- Rule: start the job hidden with output going to a log, then poll the log.

## SDK-RC-CRASH

- Symptom: `dotnet new install` and `dotnet new search` crashed with `0xC0000005`.
- Cause: the default SDK was 11.0.100-rc.1. The crash stopped once `global.json` pinned 10.0.401.
- Rule: every repo pins its SDK in `global.json`.
