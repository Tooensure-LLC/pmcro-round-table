#Requires -RunAsAdministrator
# Creates a 200 GB expandable Dev Drive (ReFS) at U:, backed by C:\DevDrives\pmcro-dev.vhdx (outside OneDrive).
# Microsoft Dev Drive guidance: https://learn.microsoft.com/windows/dev-drive/
$ErrorActionPreference = 'Stop'
$log   = Join-Path $PSScriptRoot 'create-devdrive.log'
Start-Transcript -Path $log -Force | Out-Null
try {
  $dir   = 'C:\DevDrives'
  $vhdx  = Join-Path $dir 'pmcro-dev.vhdx'
  $letter = 'U'
  $sizeMB = 200 * 1024

  if (Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue) { throw "Drive letter $letter is already in use." }
  if (Test-Path $vhdx) { throw "$vhdx already exists; refusing to overwrite." }
  New-Item -ItemType Directory -Path $dir -Force | Out-Null

  # 1. Create + attach expandable VHDX, partition, assign letter (diskpart works on Windows Home; New-VHD needs Hyper-V)
  $dp = Join-Path $PSScriptRoot 'create.diskpart'
  @"
create vdisk file="$vhdx" maximum=$sizeMB type=expandable
select vdisk file="$vhdx"
attach vdisk
convert gpt
create partition primary
assign letter=$letter
"@ | Set-Content -Path $dp -Encoding ascii
  diskpart /s $dp
  if ($LASTEXITCODE -ne 0) { throw "diskpart failed ($LASTEXITCODE)" }
  Start-Sleep -Seconds 3

  # 2. Format as Dev Drive (ReFS, dev volume)
  Format-Volume -DriveLetter $letter -DevDrive -FileSystem ReFS -NewFileSystemLabel 'PMCRO-Dev' -Confirm:$false -Force | Out-Null

  # 3. Trust the dev volume (performance mode with Defender) and report state
  fsutil devdrv trust "$($letter):"
  fsutil devdrv query "$($letter):"

  # 4. Re-attach at every boot (diskpart-attached VHDX does not auto-mount)
  $ap = Join-Path $dir 'attach-pmcro-dev.diskpart'
  @"
select vdisk file="$vhdx"
attach vdisk
"@ | Set-Content -Path $ap -Encoding ascii
  $action  = New-ScheduledTaskAction -Execute 'diskpart.exe' -Argument "/s `"$ap`""
  $trigger = New-ScheduledTaskTrigger -AtStartup
  $princ   = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  Register-ScheduledTask -TaskName 'PMCRO Dev Drive attach' -Action $action -Trigger $trigger -Principal $princ -Force | Out-Null

  # 5. Standard layout: package caches on the Dev Drive (Microsoft recommendation), source under src
  $folders = 'U:\src','U:\packages\nuget','U:\packages\npm','U:\packages\pip'
  $folders | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

  Get-Volume -DriveLetter $letter | Format-List DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining
  'RESULT: OK'
} catch {
  "RESULT: FAILED - $($_.Exception.Message)"
} finally {
  Stop-Transcript | Out-Null
}
