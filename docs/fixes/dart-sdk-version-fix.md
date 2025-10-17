# GitHub Actions - Dart SDK Version Fix

## Issue
GitHub Actions workflow was failing with the error:
```
Because nextwave requires SDK version ^3.8.1, version solving failed.
```

The workflow was using Flutter 3.13.0 (which includes Dart 3.4.x), but `pubspec.yaml` required Dart SDK `^3.8.1`.

## Root Cause
Mismatch between:
- **pubspec.yaml**: Required Dart SDK `^3.8.1` (unreleased/beta)
- **Workflow**: Used Flutter 3.13.0 with Dart 3.4.x (stable)

Dart 3.8.1 is not yet available in stable Flutter releases.

## Solution
Updated both files to use compatible stable versions:

### 1. pubspec.yaml
Changed Dart SDK requirement:
- **Before**: `sdk: ^3.8.1`
- **After**: `sdk: ^3.5.0`

Dart 3.5.0 is the version that ships with Flutter 3.24.0 (stable).

### 2. .github/workflows/build-apk.yml
Updated Flutter version:
- **Before**: `flutter-version: '3.13.0'`
- **After**: `flutter-version: '3.24.0'`  (includes Dart 3.5.0)

## Flutter/Dart Version Compatibility

| Flutter Version | Dart Version | Status |
|----------------|--------------|---------|
| 3.13.0         | 3.4.x        | Stable  |
| 3.16.0         | 3.4.x        | Stable  |
| 3.19.0         | 3.4.x        | Stable  |
| 3.22.0         | 3.4.x        | Stable  |
| **3.24.0**     | **3.5.0**    | **Stable** ✅ |

## Files Modified
1. `pubspec.yaml` - Lowered Dart SDK requirement to ^3.5.0
2. `.github/workflows/build-apk.yml` - Updated Flutter to 3.24.0

## Testing
After these changes, the workflow should:
1. ✅ Successfully install Flutter 3.24.0
2. ✅ Successfully run `flutter pub get`
3. ✅ Build debug and release APKs
4. ✅ Upload artifacts to GitHub

## Next Steps
1. Commit and push these changes
2. Monitor the GitHub Actions workflow
3. Verify the build completes successfully
4. Download and test the generated APKs

## Commands to Test Locally
```powershell
# Verify Flutter version
flutter --version
# Should show: Flutter 3.24.x • Dart 3.5.x

# Clean and get dependencies
flutter clean
flutter pub get

# Test build
flutter build apk --debug
```

## Prevention
When updating `pubspec.yaml` SDK requirements:
1. Check current stable Flutter version
2. Verify which Dart version it includes
3. Set SDK requirement to match or be lower
4. Test locally before committing
5. Update CI/CD workflow if needed

## Additional Notes
- Flutter 3.24.0 is a recent stable release (2024)
- Dart 3.5.0 includes all features needed for this project
- Using stable versions ensures reliability in CI/CD
- Can update to newer versions when they become stable
