# Builds the Flutter web UI and embeds it into the Go server.
#
# Usage: ./build-webui.ps1 [-Release]
#
# Run from the stagesync-server directory (or anywhere, paths are resolved
# relative to this script).

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterApp = Join-Path $root "..\theatre_companion_app"
$webUiDir = Join-Path $root "internal\coreserver\webui"

Write-Host "==> flutter build web (in $flutterApp)"
Push-Location $flutterApp
try {
    flutter build web --release
} finally {
    Pop-Location
}

Write-Host "==> Copying build output to $webUiDir"
Get-ChildItem -Path $webUiDir -Force | Remove-Item -Recurse -Force
Copy-Item -Path (Join-Path $flutterApp "build\web\*") -Destination $webUiDir -Recurse -Force

Write-Host "==> go build ./..."
Push-Location $root
try {
    go build ./...
} finally {
    Pop-Location
}

Write-Host "==> Done. Start with: go run ./cmd/server -web-ui"
