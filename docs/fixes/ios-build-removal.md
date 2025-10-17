# GitHub Actions - iOS Build Removal

## Change Summary
Removed iOS build workflow from GitHub Actions to focus exclusively on Android APK builds.

## What Was Removed
- **File**: `.github/workflows/ios-build.yml`
- **Runner**: macOS-latest (expensive runner)
- **Build Type**: iOS release builds (unsigned)

## Reasons for Removal

### 1. Cost Optimization
- **macOS runners** are 10x more expensive than Linux runners
- GitHub Actions free tier:
  - Linux: 2,000 minutes/month
  - macOS: 200 minutes/month (counted as 10x)
- Single iOS build: ~15-20 minutes = 150-200 "Linux-equivalent" minutes
- Can burn through free tier in just 10 iOS builds

### 2. Limited Value
- iOS builds were **unsigned** (no codesign)
- Cannot be installed on real devices without proper signing
- Cannot be distributed via TestFlight without Apple Developer account
- Only useful for checking if code compiles for iOS

### 3. Focus on Android
- Primary development platform is Android
- Android APKs can be directly installed and tested
- Split APK optimization reduces download size
- Better developer experience with Android tooling

### 4. Build Time
- iOS builds: ~15-20 minutes on macOS runners
- Android builds: ~5-7 minutes on Linux runners
- Faster feedback loop with Android-only builds

## Current CI/CD Strategy

### What We Build
✅ **Android Debug APKs** - For testing, installed via ADB or direct download
✅ **Android Release APKs** - Production-ready, optimized builds
✅ **Split by ABI** - Smaller downloads (arm64-v8a, armeabi-v7a, x86_64)

### What We Don't Build
❌ **iOS Apps** - Would require:
  - Apple Developer account ($99/year)
  - Proper code signing certificates
  - Provisioning profiles
  - More complex CI/CD setup

## If iOS Builds Are Needed Later

To re-enable iOS builds:

1. **Create new workflow file** `.github/workflows/ios-build.yml`:
```yaml
name: Build iOS

on:
  workflow_dispatch:  # Manual trigger only

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: build/ios/iphoneos/Runner.app
```

2. **Set to manual trigger only** to avoid wasting minutes
3. **Add proper code signing** if distributing to devices
4. **Budget for macOS runner costs** if using frequently

## Alternative: Local iOS Builds

For iOS development:
- Build locally on Mac: `flutter build ios --release`
- Test on simulators: `flutter run -d "iPhone 15"`
- Use Xcode for signing and distribution
- Only run GitHub builds when needed

## Cost Comparison

### Before (with iOS builds)
- Android build: 5 min = 5 minutes
- iOS build: 15 min = 150 minutes (10x multiplier)
- **Total per commit**: 155 minutes

### After (Android only)
- Android build: 5 min = 5 minutes
- **Total per commit**: 5 minutes

**Savings**: 150 minutes per push = **30x more commits** with same budget!

## Files Modified
1. Deleted: `.github/workflows/ios-build.yml`
2. Updated: `.github/README.md` - Clarified Android-only focus
3. Created: `docs/fixes/ios-build-removal.md` - This document

## Impact
- ✅ Reduced CI/CD costs by ~97%
- ✅ Faster build feedback (5 min vs 20 min)
- ✅ More commits within free tier
- ✅ Simplified workflow maintenance
- ✅ Focused on primary platform (Android)

## Recommendations
1. Use Android APKs for development and testing
2. Build iOS locally when needed
3. Only add iOS CI/CD when:
   - Have Apple Developer account
   - Need automated TestFlight distributions
   - Have budget for macOS runner minutes
4. Keep Android builds automated for continuous delivery
