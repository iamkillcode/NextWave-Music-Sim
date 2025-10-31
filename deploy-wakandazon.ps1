# WakandaZon Marketplace - Quick Deploy Script
# Run this from the nextwave root directory

Write-Host "🎵 WakandaZon Marketplace Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if in correct directory
if (-Not (Test-Path "functions/index.js")) {
    Write-Host "❌ Error: Please run this script from the NextWave root directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 1: Deploying Cloud Functions..." -ForegroundColor Yellow
cd functions
firebase deploy --only functions:purchaseSong,functions:cancelListing
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Function deployment failed!" -ForegroundColor Red
    exit 1
}
cd ..
Write-Host "✅ Cloud Functions deployed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "🔒 Step 2: Deploying Firestore Security Rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Security rules deployment failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Security rules deployed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 Deployment Complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Test the marketplace purchase flow" -ForegroundColor Gray
Write-Host "2. Test the cancel listing flow" -ForegroundColor Gray
Write-Host "3. Verify security rules prevent direct money changes" -ForegroundColor Gray
Write-Host ""
Write-Host "To run the app:" -ForegroundColor White
Write-Host "  flutter run -d chrome" -ForegroundColor Gray
Write-Host ""
