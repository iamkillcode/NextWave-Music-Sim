# GitHub Actions Setup Helper
# This script helps you prepare secrets for GitHub Actions

Write-Host "🚀 NextWave GitHub Actions Setup Helper" -ForegroundColor Cyan
Write-Host ""

# Check if google-services.json exists
$googleServicesPath = "android\app\google-services.json"
if (Test-Path $googleServicesPath) {
    Write-Host "✅ Found google-services.json" -ForegroundColor Green
    Write-Host ""
    Write-Host "Encoding google-services.json..." -ForegroundColor Yellow
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($googleServicesPath)
        $encoded = [Convert]::ToBase64String($bytes)
        $encoded | Set-Clipboard
        
        Write-Host "✅ Encoded content copied to clipboard!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Go to: https://github.com/iamkillcode/NextWave-Music-Sim/settings/secrets/actions" -ForegroundColor White
        Write-Host "2. Click 'New repository secret'" -ForegroundColor White
        Write-Host "3. Name: GOOGLE_SERVICES_JSON" -ForegroundColor White
        Write-Host "4. Value: Paste from clipboard (Ctrl+V)" -ForegroundColor White
        Write-Host "5. Click 'Add secret'" -ForegroundColor White
        Write-Host ""
        
        # Show first and last few characters for verification
        $preview = $encoded.Substring(0, [Math]::Min(50, $encoded.Length)) + "..." + 
                   $encoded.Substring([Math]::Max(0, $encoded.Length - 50))
        Write-Host "Preview: $preview" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Error encoding file: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  google-services.json not found at: $googleServicesPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "1. Add your google-services.json file to android/app/" -ForegroundColor White
    Write-Host "2. Or continue without Firebase (workflow will use placeholder)" -ForegroundColor White
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# Optional: Check for keystore
Write-Host "📱 Checking for keystore (optional for signed builds)..." -ForegroundColor Cyan
$keystorePath = "nextwave-release-key.jks"
if (Test-Path $keystorePath) {
    Write-Host "✅ Found keystore: $keystorePath" -ForegroundColor Green
    Write-Host ""
    
    $response = Read-Host "Do you want to encode the keystore for GitHub Actions? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        try {
            $keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
            $keystoreEncoded = [Convert]::ToBase64String($keystoreBytes)
            
            Write-Host ""
            Write-Host "✅ Keystore encoded!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Add these secrets to GitHub:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Secret Name: KEYSTORE_BASE64" -ForegroundColor Yellow
            Write-Host "Value: (copied to clipboard)" -ForegroundColor White
            $keystoreEncoded | Set-Clipboard
            Write-Host ""
            Read-Host "Press Enter after adding KEYSTORE_BASE64"
            
            Write-Host ""
            $storePassword = Read-Host "Enter keystore password" -AsSecureString
            $storePlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))
            Write-Host "Secret Name: KEYSTORE_PASSWORD" -ForegroundColor Yellow
            Write-Host "Value: $storePlain" -ForegroundColor White
            
            Write-Host ""
            $keyAlias = Read-Host "Enter key alias"
            Write-Host "Secret Name: KEY_ALIAS" -ForegroundColor Yellow
            Write-Host "Value: $keyAlias" -ForegroundColor White
            
            Write-Host ""
            $keyPassword = Read-Host "Enter key password" -AsSecureString
            $keyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))
            Write-Host "Secret Name: KEY_PASSWORD" -ForegroundColor Yellow
            Write-Host "Value: $keyPlain" -ForegroundColor White
            
            Write-Host ""
            Write-Host "⚠️  Remember to configure signing in android/app/build.gradle.kts" -ForegroundColor Yellow
        }
        catch {
            Write-Host "❌ Error encoding keystore: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "ℹ️  No keystore found (builds will be unsigned)" -ForegroundColor Gray
    Write-Host "   To create one, run:" -ForegroundColor Gray
    Write-Host "   keytool -genkey -v -keystore nextwave-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nextwave" -ForegroundColor Gray
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✨ Setup complete! Push to main branch to trigger your first build." -ForegroundColor Green
Write-Host ""
Write-Host "To push:" -ForegroundColor Cyan
Write-Host "  git add ." -ForegroundColor White
Write-Host '  git commit -m "Add GitHub Actions for APK builds"' -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor White
Write-Host ""
Write-Host "View builds at:" -ForegroundColor Cyan
Write-Host "  https://github.com/iamkillcode/NextWave-Music-Sim/actions" -ForegroundColor White
Write-Host ""
