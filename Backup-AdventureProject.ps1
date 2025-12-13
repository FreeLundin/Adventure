<#
Backup-AdventureProject.ps1
Creates timestamped zip backups of key project folders and metadata.
Usage examples:
    pwsh .\Backup-AdventureProject.ps1            # default backup (excludes DerivedDataCache)
    pwsh .\Backup-AdventureProject.ps1 -IncludeDerivedDataCache $true -IncludeBinaries $true
#>
[CmdletBinding()]
param(
    [switch]$IncludeDerivedDataCache = $false,
    [switch]$IncludeBinaries = $false,
    [string]$ProjectRoot = "${PWD}",
    [string]$OutDir = "${PWD}\backups"
)

function Ensure-Path {
    param ($p)
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p | Out-Null
    }
}

try {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    Ensure-Path -p $OutDir
    $backupBase = Join-Path $OutDir "Adventure_backup_$ts"
    Ensure-Path -p $backupBase

    Write-Host "Backup start: $ts"
    Write-Host "ProjectRoot: $ProjectRoot"

    # Always include project files and Source/Config/Content/Saved
    $toZip = @()
    $candidates = @(
        "*.uproject",
        "*.sln",
        "Source",
        "Config",
        "Content",
        "Saved",
        "Build",
        ".github",
        "README.md"
    )

    foreach ($item in $candidates) {
        $full = Join-Path $ProjectRoot $item
        if (Test-Path $full) { $toZip += $full }
    }

    if ($IncludeBinaries -and (Test-Path (Join-Path $ProjectRoot 'Binaries'))) {
        $toZip += (Join-Path $ProjectRoot 'Binaries')
    }

    if ($IncludeDerivedDataCache -and (Test-Path (Join-Path $ProjectRoot 'DerivedDataCache'))) {
        $toZip += (Join-Path $ProjectRoot 'DerivedDataCache')
    }

    # Generate a small metadata manifest
    $manifest = @{
        Time = (Get-Date).ToString('o')
        Machine = $env:COMPUTERNAME
        User = $env:USERNAME
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        DotNet = (try { dotnet --version } catch { 'dotnet not found' })
        VisualStudio = (Get-ChildItem 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\Setup\Instances' -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.Name } ) -join ','
        EngineCandidates = @("C:\\Program Files\\Epic Games\\UE_5.7", "C:\\Program Files\\Epic Games\\UE_5.71", "C:\\Program Files\\Epic Games\\UE_5.6")
    }
    $manifestPath = Join-Path $backupBase 'backup_manifest.json'
    $manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $manifestPath -Encoding UTF8

    # Create zip archives per top-level item to avoid Compress-Archive stream limits on very large single archives
    $archives = @()
    foreach ($src in $toZip) {
        $name = Split-Path $src -Leaf
        $zipName = Join-Path $backupBase ("$name" + "_$ts.zip")
        Write-Host "Compressing: $src -> $zipName"
        try {
            Compress-Archive -LiteralPath $src -DestinationPath $zipName -Force -ErrorAction Stop
            $archives += $zipName
        }
        catch {
            Write-Warning "Compress-Archive failed for $src: $_. Trying robocopy fallback (uncompressed mirror)."
            $fallbackDir = Join-Path $backupBase ("$name" + "_raw_$ts")
            robocopy $src $fallbackDir /MIR /NFL /NDL /NJH /NJS | Out-Null
            $archives += $fallbackDir
        }
    }

    # Create a quick filelist
    $fileListPath = Join-Path $backupBase 'backup_filelist.txt'
    Get-ChildItem -Path $backupBase -Recurse | Select-Object FullName, Length | Out-String | Out-File -FilePath $fileListPath -Encoding UTF8

    Write-Host "Backup completed: $backupBase"
    Write-Host "Archives / folders in backup dir:"
    Get-ChildItem $backupBase | ForEach-Object { Write-Host " - $($_.Name)" }
    Write-Host "Manifest: $manifestPath"
    Write-Host "To restore: unzip the desired archive(s) into a restored working directory and verify with Engine/Editor. Do not overwrite live work without checking."
}
catch {
    Write-Error "Backup failed: $_"
    exit 1
}

