# PowerShell script to set gradle-wrapper to use a local Gradle zip
# Usage: run from repo root or provide full path. Example:
#   powershell -ExecutionPolicy Bypass -File android\scripts\setup_gradle_local.ps1

$wrapperPath = Join-Path $PSScriptRoot "..\gradle\wrapper\gradle-wrapper.properties" | Resolve-Path -ErrorAction Stop
$wrapperPath = $wrapperPath.ProviderPath

$props = Get-Content -Path $wrapperPath -ErrorAction Stop
$distLineIndex = $props | Select-String -Pattern '^distributionUrl=' -SimpleMatch | Select-Object -First 1 | ForEach-Object { $_.LineNumber }
if (-not $distLineIndex) {
    Write-Error "Could not find a 'distributionUrl' line in $wrapperPath"
    exit 1
}

$current = ($props[$distLineIndex - 1]).Trim()
Write-Host "Current distributionUrl:`n  $current`n"

# Offer to open the remote URL in browser so user can download it elsewhere
if ($current -match '=(.*)$') { $remoteUrl = $matches[1].Trim() }
if ($remoteUrl) {
    Write-Host "If you need to download the file manually, the URL is: $remoteUrl"
    $open = Read-Host "Open the URL in your browser now? (Y/n)"
    if ($open -eq '' -or $open -match '^[Yy]') { Start-Process $remoteUrl }
}

# Prompt for local file path
while ($true) {
    $localPath = Read-Host "Enter full path to the downloaded Gradle zip (or press Enter to cancel)"
    if ([string]::IsNullOrWhiteSpace($localPath)) {
        Write-Host "Cancelled. No changes made."; exit 0
    }
    if (-not (Test-Path $localPath)) {
        Write-Host "File not found: $localPath`nPlease try again." -ForegroundColor Yellow
        continue
    }
    break
}

# Convert local Windows path to file URI
$abs = (Resolve-Path $localPath).ProviderPath
$uri = 'file:///' + ($abs -replace '\\','/')
$uri = $uri -replace ' ','%20'

# Replace distributionUrl line
$props[$distLineIndex - 1] = "distributionUrl=$uri"
Set-Content -Path $wrapperPath -Value $props -Encoding UTF8

Write-Host "Updated distributionUrl to local file URI:`n  $uri" -ForegroundColor Green
Write-Host "Now run 'flutter clean' and then 'flutter run' to build using the local Gradle distribution." -ForegroundColor Cyan
