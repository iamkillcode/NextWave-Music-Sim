# Quick setup script to copy Firebase config to clipboard for GitHub Secrets
# Run this from the project root directory

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  GitHub Secrets Setup - Firebase Config Files" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Android google-services.json
Write-Host "1. Copying Android google-services.json..." -ForegroundColor Yellow
if (Test-Path "android\app\google-services.json") {
    Get-Content "android\app\google-services.json" -Raw | Set-Clipboard
    Write-Host "   ✓ Copied to clipboard!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Next steps:" -ForegroundColor White
    Write-Host "   1. Go to: https://github.com/iamkillcode/NextWave-Music-Sim/settings/secrets/actions" -ForegroundColor White
    Write-Host "   2. Click 'New repository secret'" -ForegroundColor White
    Write-Host "   3. Name: GOOGLE_SERVICES_JSON" -ForegroundColor Cyan
    Write-Host "   4. Value: Paste from clipboard" -ForegroundColor White
    Write-Host "   5. Click 'Add secret'" -ForegroundColor White
    Write-Host ""
    Write-Host "   Press ENTER when done..." -ForegroundColor Yellow
    Read-Host
} else {
    Write-Host "   ✗ File not found: android\app\google-services.json" -ForegroundColor Red
    Write-Host ""
}

# iOS GoogleService-Info.plist
Write-Host "2. Copying iOS GoogleService-Info.plist..." -ForegroundColor Yellow
if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    Get-Content "ios\Runner\GoogleService-Info.plist" -Raw | Set-Clipboard
    Write-Host "   ✓ Copied to clipboard!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Next steps:" -ForegroundColor White
    Write-Host "   1. Go to: https://github.com/iamkillcode/NextWave-Music-Sim/settings/secrets/actions" -ForegroundColor White
    Write-Host "   2. Click 'New repository secret'" -ForegroundColor White
    Write-Host "   3. Name: GOOGLE_SERVICE_INFO_PLIST" -ForegroundColor Cyan
    Write-Host "   4. Value: Paste from clipboard" -ForegroundColor White
    Write-Host "   5. Click 'Add secret'" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "   ✗ File not found: ios\Runner\GoogleService-Info.plist" -ForegroundColor Red
    Write-Host ""
    Write-Host "   You need to download this file from Firebase Console:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://console.firebase.google.com/project/nextwave-music-sim/settings/general" -ForegroundColor White
    Write-Host "   2. Scroll to 'Your apps'" -ForegroundColor White
    Write-Host "   3. Find iOS app or click 'Add app' → iOS" -ForegroundColor White
    Write-Host "   4. Bundle ID: com.nextwave.musicgame" -ForegroundColor Cyan
    Write-Host "   5. Download GoogleService-Info.plist" -ForegroundColor White
    Write-Host "   6. Save to: ios\Runner\GoogleService-Info.plist" -ForegroundColor White
    Write-Host "   7. Re-run this script" -ForegroundColor White
    Write-Host ""
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Setup complete! Your builds will now work on GitHub Actions." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
