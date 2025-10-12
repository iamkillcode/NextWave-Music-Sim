# Project Rename Migration Guide
**From:** `mobile_game` → **To:** `nextwave`  
**Date:** October 11, 2025

## ✅ Completed Changes

### 1. Flutter Project Name
- **File:** `pubspec.yaml`
- **Change:** `name: mobile_game` → `name: nextwave`
- **Description:** Changed to "NextWave - Music Artist Simulation Game"

### 2. Android Configuration
- **Package Name:** `com.example.mobile_game` → `com.nextwave.musicgame`
- **Files Changed:**
  - `android/app/build.gradle.kts` (namespace & applicationId)
  - `android/app/src/main/AndroidManifest.xml` (app label: "NextWave")
  - `android/app/src/main/kotlin/com/nextwave/musicgame/MainActivity.kt` (package declaration and file location)

### 3. iOS Configuration
- **Bundle ID:** `com.example.mobileGame` → `com.nextwave.musicgame`
- **Files Changed:**
  - `ios/Runner/Info.plist` (CFBundleDisplayName: "NextWave", CFBundleName: "nextwave")
  - `ios/Runner.xcodeproj/project.pbxproj` (PRODUCT_BUNDLE_IDENTIFIER for Runner and RunnerTests)

### 4. Dart Imports
- **File:** `test/widget_test.dart`
- **Change:** `import 'package:mobile_game/main.dart';` → `import 'package:nextwave/main.dart';`

### 5. Build Cache
- Ran `flutter clean` to remove old build artifacts
- Ran `flutter pub get` to regenerate dependencies with new project name

## 🔄 Remaining Steps

### Step 1: Rename Root Directory
The root directory is still named `mobile_game`. You have two options:

**Option A: Manual Rename (Recommended)**
1. Close VS Code and any terminals
2. In File Explorer, navigate to `C:\Users\Manuel\Documents\GitHub\NextWave\`
3. Rename `mobile_game` folder to `nextwave`
4. Reopen the project in VS Code from the new location

**Option B: PowerShell Command**
```powershell
cd "C:\Users\Manuel\Documents\GitHub\NextWave"
Rename-Item -Path "mobile_game" -NewName "nextwave"
```

### Step 2: Update Firebase Configuration
Your Firebase `google-services.json` files still reference the old package name. You need to:

1. **Go to Firebase Console:** https://console.firebase.google.com/project/nextwave-music-sim
2. **Android App Settings:**
   - Go to Project Settings → Your Apps → Android app
   - Add a new Android app with package name: `com.nextwave.musicgame`
   - Download the new `google-services.json`
   - Replace files:
     - `android/app/google-services.json`
     - `google-services.json` (root directory)

3. **iOS App Settings (if applicable):**
   - Add a new iOS app with bundle ID: `com.nextwave.musicgame`
   - Download the new `GoogleService-Info.plist`
   - Replace: `ios/Runner/GoogleService-Info.plist`

4. **Re-run FlutterFire CLI:**
   ```powershell
   flutterfire configure
   ```
   - This will regenerate `lib/firebase_options.dart` with the correct configuration

### Step 3: Test the Build
After renaming the directory and updating Firebase:

```powershell
# Navigate to new directory
cd "C:\Users\Manuel\Documents\GitHub\NextWave\nextwave"

# Clean and rebuild
flutter clean
flutter pub get

# Test Android build
flutter build apk --debug

# Test iOS build (if on macOS)
flutter build ios --debug

# Or just run the app
flutter run
```

## 📋 Summary of Changes

| Component | Old Value | New Value |
|-----------|-----------|-----------|
| Project Name | `mobile_game` | `nextwave` |
| Project Description | "A new Flutter project." | "NextWave - Music Artist Simulation Game" |
| Android Package | `com.example.mobile_game` | `com.nextwave.musicgame` |
| iOS Bundle ID | `com.example.mobileGame` | `com.nextwave.musicgame` |
| App Display Name | "mobile_game" / "Mobile Game" | "NextWave" |
| Dart Package Import | `package:mobile_game/...` | `package:nextwave/...` |

## 🔍 Verification Checklist

After completing all steps, verify:

- [ ] Root directory is named `nextwave`
- [ ] App builds successfully: `flutter build apk --debug`
- [ ] No import errors in Dart files
- [ ] Firebase connection works (check with authentication test)
- [ ] App displays "NextWave" as the app name on device
- [ ] New Firebase configuration files are in place
- [ ] `firebase_options.dart` has correct configuration

## 🚨 Important Notes

### About Package Names
- **Android Package Name** and **iOS Bundle ID** are **permanent identifiers**
- Once you publish your app to Google Play or App Store with these IDs, they **cannot be changed**
- We changed from `com.example.mobile_game` to `com.nextwave.musicgame` because:
  - `com.example.*` is for testing only and not allowed in production
  - `com.nextwave.musicgame` is professional and matches your game branding

### About Firebase
- The old Firebase configuration points to `com.example.mobile_game`
- You **must** update Firebase to recognize the new package name
- Both old and new configurations can coexist in Firebase during migration
- After migration, you can remove the old `com.example.mobile_game` app from Firebase

## 🐛 Troubleshooting

### "Package doesn't exist" error
- Make sure you ran `flutter pub get` after renaming
- Check all import statements use `package:nextwave/...`

### Firebase authentication not working
- Verify new `google-services.json` / `GoogleService-Info.plist` are in place
- Run `flutterfire configure` again
- Check Firebase Console has the new app registered

### Build fails with "Namespace not specified"
- Verify `android/app/build.gradle.kts` has `namespace = "com.nextwave.musicgame"`
- Make sure `MainActivity.kt` is in the correct directory and has correct package declaration

### App name still shows as "mobile_game"
- Check `android/app/src/main/AndroidManifest.xml` has `android:label="NextWave"`
- Check `ios/Runner/Info.plist` has `<string>NextWave</string>` for CFBundleDisplayName
- Rebuild the app completely with `flutter clean && flutter pub get && flutter run`

## 📞 Next Steps After Migration

1. **Complete Firebase Setup:**
   - Follow `FIREBASE_READY.md` for Firebase configuration
   - Enable Email/Password and Anonymous authentication
   - Create Firestore database with security rules

2. **Test Authentication Flow:**
   - Sign up with email/password
   - Test guest mode (anonymous auth)
   - Complete 4-page onboarding wizard
   - Verify profile is created in Firestore

3. **Test Game Features:**
   - Dashboard and energy system
   - Song creation and publishing
   - World travel
   - Leaderboards (Hot 100, Top Artists, Spotlight 200)

4. **Prepare for Production:**
   - Generate app icons
   - Create app signing keys for Android
   - Configure iOS provisioning profiles
   - Update Firestore security rules for production
   - Set up proper error tracking (Firebase Crashlytics)

---

**Migration prepared by:** GitHub Copilot  
**Status:** ✅ Code changes complete, manual steps remaining
