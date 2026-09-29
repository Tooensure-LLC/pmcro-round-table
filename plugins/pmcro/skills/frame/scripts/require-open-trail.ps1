# require-open-trail.ps1 - the log-before-act hook (EC-SYS-003).
# Exit 0 when at least one trail is open (a trails/ folder with 00-frame.jsonl and no disposition.json); exit 2 (block) otherwise.
# Claude Code: PreToolUse hook, matcher Edit|Write. Microsoft Agent Framework: function-invocation middleware.
param([string]$TrailsDir = '')
$ErrorActionPreference = 'Stop'
# Trails = <current folder>/trails: hosts run hooks from the project root (trails/0010-pmcro-plugin-self-contained).
if (-not $TrailsDir) {
  $here = (Get-Location).Path
  if (-not (Test-Path (Join-Path $here '.git'))) {
    [Console]::Error.WriteLine('Log Before Act (EC-SYS-003): run from the repo root (no .git in the current folder).')
    exit 2
  }
  $TrailsDir = Join-Path $here 'trails'
}
$open = @(Get-ChildItem $TrailsDir -Directory -ErrorAction SilentlyContinue | Where-Object {
  (Test-Path (Join-Path $_.FullName '00-frame.jsonl')) -and -not (Test-Path (Join-Path $_.FullName 'disposition.json')) })
if ($open.Count -eq 0) {
  [Console]::Error.WriteLine('Log Before Act (EC-SYS-003): no open trail. Write trails/NNNN-name/00-frame.jsonl with /frame before changing files.')
  exit 2
}
"open trail(s): $(($open | ForEach-Object Name) -join ', ')"
exit 0
