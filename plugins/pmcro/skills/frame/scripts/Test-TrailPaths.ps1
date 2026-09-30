# Test-TrailPaths.ps1 - the one absolute-path scan for trails (EC-PORTABLE-005, EC-0001). Dot-source it:
#   . "$PSScriptRoot/Test-TrailPaths.ps1"; $hits = Get-TrailPathHits -Text $jsonl
# Used by frame.ps1, commit.ps1, tools/replay.ps1 and tools/check-queue.ps1 so they cannot disagree (trails/0001 02-check D6).
# Rules, applied to every JSON string value and property name (a line that is not JSON is scanned as one string):
#   drive-rooted token anywhere   C:\x  C:/x  (not "U:" alone, not "http://")
#   UNC token anywhere            \\server\share
#   POSIX-rooted path only when it starts a value: "/Users/x" is a path; "mentions /Users/ in prose" is not.
$script:TrailPathRules = @(
  @{ name = 'drive'; re = [regex]'(?<![A-Za-z0-9])[A-Za-z]:[\\/](?=[A-Za-z0-9._$~-])' },
  @{ name = 'unc';   re = [regex]'(?<![A-Za-z0-9\\])\\\\[A-Za-z0-9._-]+\\[A-Za-z0-9._$-]+' },
  @{ name = 'posix'; re = [regex]'^/(Users|home|root|mnt|tmp|var|etc|opt|srv|Volumes)/' }
)

function Get-PathHitsInString([string]$s) {
  foreach ($r in $script:TrailPathRules) { $m = $r.re.Match($s); if ($m.Success) { "$($r.name): $($m.Value)" } }
}

function Get-JsonStrings($node) {
  if ($null -eq $node) { return }
  if ($node -is [string]) { $node; return }
  if ($node -is [System.Collections.IDictionary]) { foreach ($k in $node.Keys) { [string]$k; Get-JsonStrings $node[$k] }; return }
  if ($node -is [System.Collections.IEnumerable]) { foreach ($i in $node) { Get-JsonStrings $i }; return }
  if ($node -is [pscustomobject]) { foreach ($p in $node.PSObject.Properties) { $p.Name; Get-JsonStrings $p.Value } }
}

function Get-TrailPathHits([string]$Text) {
  foreach ($line in ($Text -split "`r?`n")) {
    if (-not $line.Trim()) { continue }
    $obj = $null
    try { $obj = $line | ConvertFrom-Json -Depth 64 -ErrorAction Stop } catch { $obj = $null }
    $strings = if ($null -ne $obj) { @(Get-JsonStrings $obj) } else { @($line) }
    foreach ($s in $strings) { Get-PathHitsInString $s }
  }
}

# EC-0001 positive control: the scan must catch samples built by the same serializer that writes frames.
function Assert-TrailPathScanWorks {
  $samples = @(
    ([ordered]@{ p = 'C:' + [char]92 + 'probe' } | ConvertTo-Json -Compress),
    ([ordered]@{ p = [string]([char]92) + [char]92 + 'server' + [char]92 + 'share' } | ConvertTo-Json -Compress),
    ([ordered]@{ p = '/home/probe' } | ConvertTo-Json -Compress)
  )
  foreach ($s in $samples) { if (-not @(Get-TrailPathHits -Text $s).Count) { throw "EC-0001: path scan missed its own control sample $s; scan not trusted" } }
  $prose = ([ordered]@{ p = 'the scan ignores /Users/, /home/ style words in prose and U: alone and https://x.y/z' } | ConvertTo-Json -Compress)
  if (@(Get-TrailPathHits -Text $prose).Count) { throw 'EC-0001: path scan flagged prose; scan not trusted' }
}
