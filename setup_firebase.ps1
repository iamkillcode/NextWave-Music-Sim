# NextWave Firebase Setup Script
# This script helps you set up Firebase for the NextWave music game

Write-Host "NextWave Firebase Setup" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 1: Install FlutterFire CLI" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
$installFlutterFire = Read-Host "Do you want to install/update FlutterFire CLI? (y/n)"

if ($installFlutterFire -eq "y") {
    Write-Host "Installing FlutterFire CLI..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
    Write-Host "✅ FlutterFire CLI installed" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipping FlutterFire CLI installation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Configure Firebase" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Before proceeding, make sure you have:" -ForegroundColor Yellow
Write-Host "1. Created a Firebase project at https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Enabled Authentication (Email/Password and Anonymous)" -ForegroundColor White
Write-Host "3. Created a Firestore database" -ForegroundColor White
Write-Host ""

$configureNow = Read-Host "Ready to configure? (y/n)"

if ($configureNow -eq "y") {
    Write-Host ""
    Write-Host "Running FlutterFire configure..." -ForegroundColor Yellow
    Write-Host "This will:" -ForegroundColor White
    Write-Host "- Let you select your Firebase project" -ForegroundColor White
    Write-Host "- Register your apps (web, Android, iOS)" -ForegroundColor White
    Write-Host "- Generate firebase_options.dart" -ForegroundColor White
    Write-Host ""
    
    flutterfire configure
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Firebase configured successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Configuration failed. Please check the error messages above." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⏭️  Skipping Firebase configuration" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can run this later with:" -ForegroundColor White
    Write-Host "flutterfire configure" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Step 3: Install Dependencies" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
$installDeps = Read-Host "Do you want to install Flutter dependencies? (y/n)"

if ($installDeps -eq "y") {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    flutter pub get
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 4: Test the App" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test the app, run:" -ForegroundColor White
Write-Host "flutter run -d chrome" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or use the VS Code debugger." -ForegroundColor White
Write-Host ""

Write-Host "For more details, see FIREBASE_SETUP.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
