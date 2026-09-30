# Build-RoundTable.ps1 - render docs/round-table.html from eng/round-table/template.html, transcript.json and company.json.
# Usage (repo root): pwsh -File eng/Build-RoundTable.ps1 [-Export <conversations zip>] [-Transcript <json>] [-Out docs/round-table.html]
# With -Export it first re-reads the export and rewrites the transcript (file name and sha256 only, never the path).
# A block is an assistant reply part that opens "I am the <company.json title>"; its text runs verbatim to the next opener or the reply's end.
# Trail of a block: the first trail id in the seed, else in the reply, that has a folder under trails/; else none. No timestamps: two renders are identical.
param([string]$Export = '', [string]$Transcript = 'eng/round-table/transcript.json', [string]$Out = 'docs/round-table.html')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot; Set-Location $root
$utf8 = New-Object System.Text.UTF8Encoding($false)
$bots = @(([IO.File]::ReadAllText('company.json') | ConvertFrom-Json -Depth 64).bots)
$titles = @($bots.title)
function NL([string]$s) { $s -replace "`r`n", "`n" }

if ($Export) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $z = [IO.Compression.ZipFile]::OpenRead($Export)
  try { $e = @($z.Entries | Where-Object { $_.Name -eq 'conversations.json' })[0]; $sr = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8); $js = $sr.ReadToEnd(); $sr.Dispose() } finally { $z.Dispose() }
  $convs = @($js | ConvertFrom-Json -Depth 64)
  $alt = (($titles | Sort-Object { $_.Length } -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|')
  $open = [regex]"\*{0,2}I am the (?<t>$alt)(?=,| and I|:)"
  $hey = [regex]"\bHey (?<t>$alt),"
  $tre = [regex]'\b\d{4}-[a-z][a-z0-9-]*'
  $blocks = @(); $n = 0; $msgs = 0
  foreach ($cv in $convs) {
    $seed = ''; $mi = -1
    foreach ($m in @($cv.chat_messages)) {
      $mi++; $msgs++
      $t = NL ([string]$m.text)
      if ($m.sender -eq 'human') { $seed = $t; continue }
      $ms = @($open.Matches($t))
      for ($k = 0; $k -lt $ms.Count; $k++) {
        $en = if ($k + 1 -lt $ms.Count) { $ms[$k + 1].Index } else { $t.Length }
        $txt = $t.Substring($ms[$k].Index, $en - $ms[$k].Index).Trim()
        $title = $ms[$k].Groups['t'].Value
        $h = $hey.Match($txt); $addr = if ($h.Success) { $h.Groups['t'].Value } else { $null }
        $trail = 'none'
        foreach ($src in @($seed, $txt)) { foreach ($tm in $tre.Matches($src)) { if ($trail -eq 'none' -and (Test-Path "trails/$($tm.Value)")) { $trail = $tm.Value } } }
        $n++
        $blocks += [ordered]@{ id = ('rt-{0:d2}' -f $n); chief_id = @($bots | Where-Object { $_.title -eq $title })[0].id; speaker = $title; addressee = $addr; trail = $trail; seed = $seed.Trim(); text = $txt; conversation = ([string]$cv.uuid).Substring(0, 8); message = $mi }
      }
    }
  }
  if (-not $blocks.Count) { throw 'round-table: no block found in the export' }
  $obj = [ordered]@{ source = [ordered]@{ file = [IO.Path]::GetFileName($Export); sha256 = (Get-FileHash -Algorithm SHA256 $Export).Hash; conversations_scanned = $convs.Count; messages_scanned = $msgs }; blocks = $blocks }
  [IO.File]::WriteAllText($Transcript, (($obj | ConvertTo-Json -Depth 8) + "`n"), $utf8)
  "extracted $($blocks.Count) blocks from $($convs.Count) conversations, $msgs messages"
}

$tr = (NL ([IO.File]::ReadAllText($Transcript))) | ConvertFrom-Json -Depth 8
$enc = { param($s) [Net.WebUtility]::HtmlEncode([string]$s) }
$fmt = { param($s) $x = & $enc $s; $x = [regex]::Replace($x, '\*\*(.+?)\*\*', '<strong>$1</strong>'); [regex]::Replace($x, '`([^`\r\n]+)`', '<code>$1</code>') }
$sb = New-Object Text.StringBuilder
$cnt = @{}
foreach ($b in $tr.blocks) {
  if ($titles -notcontains $b.speaker) { throw "round-table: speaker '$($b.speaker)' is not a company.json title ($($b.id))" }
  if ($b.trail -ne 'none' -and -not (Test-Path "trails/$($b.trail)")) { throw "round-table: trail '$($b.trail)' has no folder ($($b.id))" }
  $cnt[$b.speaker] = 1 + [int]$cnt[$b.speaker]
  $hue = (25 + 47 * [array]::IndexOf($titles, $b.speaker)) % 360
  $ad = ''; $heyp = ''
  if ($b.addressee) { $ad = " data-addressee=`"$(& $enc $b.addressee)`""; $heyp = "<p class=`"hey`">Hey $(& $enc $b.addressee),</p>`n" }
  [void]$sb.Append("<article class=`"blk`" id=`"$($b.id)`" data-chief=`"$(& $enc $b.speaker)`" data-trail=`"$(& $enc $b.trail)`"$ad style=`"--h:$hue`">`n<h2 class=`"who`">I am the $(& $enc $b.speaker):</h2>`n<p class=`"meta`"><span class=`"chip`">$(& $enc $b.speaker)</span><span class=`"chip`">Trail: $(& $enc $b.trail)</span><button class=`"play`" type=`"button`">Play</button></p>`n<blockquote class=`"seed`"><strong>Seed:</strong> $(& $fmt $b.seed)</blockquote>`n$heyp<div class=`"body`">$(& $fmt $b.text)</div>`n</article>`n")
}
$copt = ($titles | ForEach-Object { "<option value=`"$(& $enc $_)`">$(& $enc $_) ($([int]$cnt[$_]))</option>" }) -join "`n"
$topt = (@($tr.blocks.trail | Sort-Object -Unique) | ForEach-Object { "<option value=`"$(& $enc $_)`">$(& $enc $_)</option>" }) -join "`n"
$src = "Source: $(& $enc $tr.source.file), sha256 $($tr.source.sha256.Substring(0,12)), $(@($tr.blocks).Count) Chief replies, built from eng/round-table/transcript.json"
$html = (NL ([IO.File]::ReadAllText('eng/round-table/template.html'))).Replace('{{CHIEF_OPTIONS}}', $copt).Replace('{{TRAIL_OPTIONS}}', $topt).Replace('{{SOURCE}}', $src).Replace('{{BLOCKS}}', $sb.ToString())
[IO.File]::WriteAllText((Join-Path $root $Out), $html, $utf8)
"wrote $Out ($(@($tr.blocks).Count) blocks)"
