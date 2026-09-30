# require-open-trail.ps1 - the log-before-act hook (EC-SYS-003).
# Exit 0 when at least one trail is open (a trails/ folder with 00-frame.jsonl and no disposition.json); exit 2 (block) otherwise.
# Claude Code: PreToolUse hook, matcher Edit|Write, exec form. Microsoft Agent Framework: function-invocation middleware.
# Fails closed: any case where the repo root or trails cannot be found blocks with exit 2, because Claude Code treats every
# other exit code as non-blocking (trails/0001 02-check h1: exit 64 from a subfolder let the edit through).
param([string]$TrailsDir = '')
try {
  if (-not $TrailsDir) {
    $start = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
    $dir = Get-Item -LiteralPath $start -ErrorAction Stop
    while ($dir -and -not (Test-Path (Join-Path $dir.FullName '.git'))) { $dir = $dir.Parent }
    if (-not $dir) {
      [Console]::Error.WriteLine("Log Before Act (EC-SYS-003): no git repo at or above '$start'; blocking.")
      exit 2
    }
    $TrailsDir = Join-Path $dir.FullName 'trails'
  }
  $open = @(Get-ChildItem -LiteralPath $TrailsDir -Directory -ErrorAction SilentlyContinue | Where-Object {
    (Test-Path (Join-Path $_.FullName '00-frame.jsonl')) -and -not (Test-Path (Join-Path $_.FullName 'disposition.json')) })
  if ($open.Count -eq 0) {
    [Console]::Error.WriteLine('Log Before Act (EC-SYS-003): no open trail. Write trails/NNNN-name/00-frame.jsonl with /pmcro:frame before changing files.')
    exit 2
  }
  "open trail(s): $(($open | ForEach-Object Name) -join ', ')"
  exit 0
} catch {
  [Console]::Error.WriteLine("Log Before Act (EC-SYS-003): hook error, blocking: $($_.Exception.Message)")
  exit 2
}
