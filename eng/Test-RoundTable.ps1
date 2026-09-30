# Test-RoundTable.ps1 - check docs/round-table.html and prove each check can fail (EC-0001 style: mutations first, real page last).
# Usage (repo root): pwsh -File eng/Test-RoundTable.ps1 [-RulesOff]   Exit 0 = PASS, 1 = FAIL. -RulesOff switches every check off: it must FAIL.
param([switch]$RulesOff)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot; Set-Location $root
$titles = @(([IO.File]::ReadAllText('company.json') | ConvertFrom-Json -Depth 64).bots.title)
function Read-Text([string]$p) { ([IO.File]::ReadAllText((Join-Path $root $p))) -replace "`r`n", "`n" }
$dec = { param($s) [Net.WebUtility]::HtmlDecode([string]$s) }
$absRe = '^(?i:[a-z][a-z0-9+.\-]*:|//|/|\\)'
function R1([string]$s, [string]$p, [string]$r) { ([regex]$p).Replace($s, $r, 1) }

function Get-Faults($x) {
  $f = New-Object Collections.Generic.List[string]
  if ($RulesOff) { return @() }
  $h = $x.h
  if ($h -notmatch '(?i)^<!doctype html>\n<html') { $f.Add('SELFCONTAINED: no doctype') }
  $arts = @([regex]::Matches($h, '(?s)<article class="blk"(?<a>[^>]*)>(?<i>.*?)</article>'))
  if ($arts.Count -ne $x.n) { $f.Add("COMPLETE: $($arts.Count) blocks in the page, $($x.n) in the transcript") }
  foreach ($a in $arts) {
    $at = $a.Groups['a'].Value; $in = $a.Groups['i'].Value
    $c = [regex]::Match($at, 'data-chief="([^"]+)"'); $t = [regex]::Match($at, 'data-trail="([^"]+)"'); $w = [regex]::Match($in, '<h2 class="who">I am the ([^<]+):</h2>')
    if (-not $c.Success -or $titles -notcontains (& $dec $c.Groups[1].Value)) { $f.Add('SPEAKER: a block has no data-chief that is a company.json title') }
    if (-not $w.Success -or -not $c.Success -or (& $dec $w.Groups[1].Value) -ne (& $dec $c.Groups[1].Value)) { $f.Add('SPEAKER: a block has no "I am the [title]:" heading matching its Chief') }
    if (-not $t.Success -or -not ($t.Groups[1].Value -eq 'none' -or (Test-Path "trails/$($t.Groups[1].Value)"))) { $f.Add('TRAIL: a block has no trail or a trail with no folder') }
    if ($in -notmatch '<blockquote class="seed"><strong>Seed:</strong>\s*\S') { $f.Add('SEED: a block has no seed') }
    if ($in -notmatch '<div class="body">\s*\S') { $f.Add('BODY: a block has no text') }
    if ($in -notmatch '<button class="play" type="button">Play</button>') { $f.Add('CONTROLS: a block has no Play button') }
    $ad = [regex]::Match($at, 'data-addressee="([^"]+)"'); if ($ad.Success -and $titles -notcontains (& $dec $ad.Groups[1].Value)) { $f.Add('SPEAKER: an addressee is not a Chief title') }
    if ($c.Success -and $h -notmatch [regex]::Escape("<option value=`"$($c.Groups[1].Value)`"")) { $f.Add('FILTER: block Chief missing from the Chief filter') }
    if ($t.Success -and $h -notmatch [regex]::Escape("<option value=`"$($t.Groups[1].Value)`"")) { $f.Add('FILTER: block trail missing from the trail filter') }
  }
  foreach ($id in 'play-all', 'pause', 'skip', 'stop', 'speed', 'voice', 'f-chief', 'f-trail') { if ($h -notmatch "id=`"$id`"") { $f.Add("CONTROLS: no #$id") } }
  if ($h -notmatch 'speechSynthesis' -or $h -notmatch 'SpeechSynthesisUtterance') { $f.Add('CONTROLS: no built-in speech synthesis') }
  foreach ($m in [regex]::Matches($h, '(?i)\b(href|src|action|formaction|poster|srcset|cite|background)\s*=\s*["'']([^"'']*)["'']')) { if ($m.Groups[2].Value.Trim() -match $absRe) { $f.Add("ABSOLUTE: $($m.Groups[1].Value)=$($m.Groups[2].Value)") } }
  $code = (@([regex]::Matches($h, '(?is)<(script|style)\b[^>]*>(.*?)</\1>') | ForEach-Object { $_.Groups[2].Value })) -join "`n"
  if ($code -match '(?i)https?:|//[a-z0-9.\-]+\.[a-z]|@import|url\(\s*["'']?(?!data:|#)|\bfetch\s*\(|XMLHttpRequest|WebSocket|sendBeacon|EventSource|\bimport\s*\(|importScripts') { $f.Add("EXTERNAL: script or style can reach outside the page: $($Matches[0])") }
  if ($h -match '(?i)<(link|base|img|iframe|embed|object|video|audio|source|form)\b|<script[^>]+\bsrc\b') { $f.Add('SELFCONTAINED: a tag that loads or submits outside the page') }
  if ($h -ne $x.fresh) { $f.Add('DRIFT: the page differs from a fresh build of its source') }
  $res = @((($x.dx | ConvertFrom-Json -Depth 32).build.resource) | ForEach-Object { $_.files })
  if ($res -notcontains 'round-table.html') { $f.Add('DOCFX: docs/docfx.json has no resource entry for round-table.html') }
  if ($x.toc -notmatch '(?m)^\s*href:\s*round-table-view\.md\s*$') { $f.Add('DOCFX: docs/toc.yml has no round-table-view.md entry') }
  if ($x.dup) { $f.Add('DOCFX: docs/round-table.md would build to round-table.html and collide with the page (DuplicateOutputFiles)') }
  if ($x.md -notmatch 'round-table\.html') { $f.Add('DOCFX: docs/round-table-view.md does not point at the page') }
  foreach ($m in [regex]::Matches($x.md, '\]\(([^)]*)\)|(?i)(?:src|href)\s*=\s*"([^"]*)"')) { $v = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }; if ($v -match $absRe) { $f.Add("ABSOLUTE: docs/round-table-view.md links $v") } }
  $f.ToArray()
}

& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Build-RoundTable.ps1') -Out '.local/rt-fresh.html' | Out-Null
$base = @{ dup = (Test-Path 'docs/round-table.md'); h = (Read-Text 'docs/round-table.html'); dx = (Read-Text 'docs/docfx.json'); toc = (Read-Text 'docs/toc.yml'); md = (Read-Text 'docs/round-table-view.md'); fresh = (Read-Text '.local/rt-fresh.html'); n = @(((Read-Text 'eng/round-table/transcript.json') | ConvertFrom-Json -Depth 8).blocks).Count }
$art = '(?s)<article class="blk".*?</article>\n'
$muts = @(
  @('block without heading (speaker missing)', 'SPEAKER', { $args[0].h = (R1 $args[0].h '<h2 class="who">[^<]*</h2>' '') }),
  @('block with empty data-chief', 'SPEAKER', { $args[0].h = (R1 $args[0].h 'data-chief="[^"]*"' 'data-chief=""') }),
  @('block by a name that is not a Chief', 'SPEAKER', { $args[0].h = (R1 $args[0].h 'data-chief="[^"]*"' 'data-chief="Nobody"') }),
  @('absolute https link', 'ABSOLUTE', { $args[0].h = $args[0].h.Replace('</main>', '<a href="https://example.test/x">x</a></main>') }),
  @('protocol-relative link', 'ABSOLUTE', { $args[0].h = $args[0].h.Replace('</main>', '<a href="//example.test/x">x</a></main>') }),
  @('root-absolute link', 'ABSOLUTE', { $args[0].h = $args[0].h.Replace('</main>', '<a href="/docs/x.html">x</a></main>') }),
  @('file: link', 'ABSOLUTE', { $args[0].h = $args[0].h.Replace('</main>', '<a href="file:///x/y.html">x</a></main>') }),
  @('fetch call in the script', 'EXTERNAL', { $args[0].h = $args[0].h.Replace('(function(){', 'fetch("x.json");(function(){') }),
  @('external stylesheet file', 'SELFCONTAINED', { $args[0].h = $args[0].h.Replace('</head>', '<link rel="stylesheet" href="x.css"></head>') }),
  @('block dropped', 'COMPLETE', { $args[0].h = (R1 $args[0].h $art '') }),
  @('Play button removed from a block', 'CONTROLS', { $args[0].h = $args[0].h.Replace('<button class="play" type="button">Play</button>', '') }),
  @('speed control removed', 'CONTROLS', { $args[0].h = $args[0].h.Replace('id="speed"', 'id="spd"') }),
  @('voice chooser removed', 'CONTROLS', { $args[0].h = $args[0].h.Replace('id="voice"', 'id="vc"') }),
  @('trail with no folder', 'TRAIL', { $args[0].h = (R1 $args[0].h 'data-trail="[^"]*"' 'data-trail="9999-nope"') }),
  @('hand edit of the page', 'DRIFT', { $args[0].h = $args[0].h + '<!-- edit -->' }),
  @('docfx resource entry missing', 'DOCFX', { $args[0].dx = $args[0].dx.Replace('round-table.html', 'x.html') }),
  @('wrapper md named like the page', 'DOCFX', { $args[0].dup = $true }),
  @('toc entry missing', 'DOCFX', { $args[0].toc = $args[0].toc.Replace('round-table-view.md', 'x.md') })
)
$missed = 0
foreach ($m in $muts) {
  $x = $base.Clone(); & $m[2] $x
  $hit = @(Get-Faults $x | Where-Object { $_ -like "$($m[1])*" })
  if ($hit.Count) { "MUST-FAIL ok      $($m[0]) -> $($hit[0])" } else { "MUST-FAIL MISSED  $($m[0]) (expected $($m[1]))"; $missed++ }
}
$real = @(Get-Faults $base)
$real | ForEach-Object { "FAIL $_" }
"mutations: $($muts.Count), missed: $missed; real page: $(@($real).Count) faults, $($base.n) blocks"
if ($missed -or $real.Count) { 'RESULT FAIL'; exit 1 } else { 'RESULT PASS'; exit 0 }
