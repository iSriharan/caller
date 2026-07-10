# PowerShell script to configure Gradle proxy settings for the current user
# Prompts for proxy host/port and optional credentials.
# It writes to %USERPROFILE%\.gradle\gradle.properties and sets HTTP(S)_PROXY for the session.

$home = $Env:USERPROFILE
if (-not $home) { Write-Error "Cannot determine USERPROFILE."; exit 1 }
$gradleDir = Join-Path $home ".gradle"
$propsPath = Join-Path $gradleDir "gradle.properties"

if (-not (Test-Path $gradleDir)) { New-Item -ItemType Directory -Path $gradleDir -Force | Out-Null }

Write-Host "Configure Gradle proxy settings (leave blank to skip a value)." -ForegroundColor Cyan
$host = Read-Host "Proxy host (e.g. proxy.company.com)"
if ([string]::IsNullOrWhiteSpace($host)) { Write-Host "No host provided; aborting."; exit 0 }
$port = Read-Host "Proxy port (e.g. 8080)"
if ([string]::IsNullOrWhiteSpace($port)) { Write-Host "No port provided; aborting."; exit 0 }
$user = Read-Host "Username (optional)"
$pass = $null
if (-not [string]::IsNullOrWhiteSpace($user)) {
    $pass = Read-Host "Password (optional, will be stored in plain text)"
}

$lines = @()
$lines += "systemProp.http.proxyHost=$host"
$lines += "systemProp.http.proxyPort=$port"
$lines += "systemProp.https.proxyHost=$host"
$lines += "systemProp.https.proxyPort=$port"
if (-not [string]::IsNullOrWhiteSpace($user)) {
    $lines += "systemProp.http.proxyUser=$user"
    $lines += "systemProp.https.proxyUser=$user"
}
if (-not [string]::IsNullOrWhiteSpace($pass)) {
    $lines += "systemProp.http.proxyPassword=$pass"
    $lines += "systemProp.https.proxyPassword=$pass"
}

Set-Content -Path $propsPath -Value $lines -Encoding UTF8
Write-Host "Wrote proxy settings to $propsPath" -ForegroundColor Green

# Suggest setting environment variables for current session
$proxyUrl = if ($user -and $pass) { "http://$user`:$pass@$host`:$port/" } else { "http://$host`:$port/" }
Write-Host "To apply for current PowerShell session run:" -ForegroundColor Cyan
Write-Host "`$env:HTTP_PROXY='$proxyUrl'" -ForegroundColor Yellow
Write-Host "`$env:HTTPS_PROXY='$proxyUrl'" -ForegroundColor Yellow
Write-Host "Or reopen your shell to pick up the new settings." -ForegroundColor Cyan

Write-Host "Done. Run 'flutter clean' then 'flutter run' to retry the build." -ForegroundColor Green
