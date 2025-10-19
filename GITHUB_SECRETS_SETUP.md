# GitHub Secrets Setup Guide

To enable automated builds via GitHub Actions, you need to add your Firebase configuration files as GitHub Secrets.

## Required Secrets

### 1. GOOGLE_SERVICES_JSON (Android)

**Location:** `android/app/google-services.json`

**Steps:**
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `GOOGLE_SERVICES_JSON`
5. Value: Copy the entire contents of `android/app/google-services.json`
6. Click **Add secret**

**Command to copy (Windows PowerShell):**
```powershell
Get-Content android\app\google-services.json | Set-Clipboard
```

### 2. GOOGLE_SERVICE_INFO_PLIST (iOS)

**Location:** `ios/Runner/GoogleService-Info.plist`

**Steps:**
1. First, you need to download this file from Firebase Console:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `nextwave-music-sim`
   - Click the gear icon → **Project Settings**
   - Scroll to **Your apps** section
   - Find your iOS app or add one if it doesn't exist:
     - Click **Add app** → iOS
     - iOS bundle ID: `com.nextwave.musicgame`
     - App nickname: `NextWave`
     - Download `GoogleService-Info.plist`

2. Once you have the file:
   - Go to GitHub repository **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `GOOGLE_SERVICE_INFO_PLIST`
   - Value: Copy the entire contents of the plist file
   - Click **Add secret**

**Command to copy (if file exists locally):**
```powershell
Get-Content ios\Runner\GoogleService-Info.plist | Set-Clipboard
```

## Verification

After adding both secrets, you can verify by:

1. Going to **Settings** → **Secrets and variables** → **Actions**
2. You should see:
   - `GOOGLE_SERVICES_JSON`
   - `GOOGLE_SERVICE_INFO_PLIST`

## Trigger Build

Once secrets are configured:

1. Push to main branch, or
2. Go to **Actions** tab → **Build Mobile Apps** → **Run workflow**

The workflow will automatically create the Firebase config files during the build process.

## Security Notes

- ⚠️ **Never commit `google-services.json` or `GoogleService-Info.plist` to your repository**
- ✅ These files are already in `.gitignore`
- ✅ GitHub Secrets are encrypted and only accessible during workflow runs
- ✅ Secret values are masked in logs

## Troubleshooting

**Error: "File google-services.json is missing"**
- Make sure you added the `GOOGLE_SERVICES_JSON` secret correctly
- Check that the secret name is exactly `GOOGLE_SERVICES_JSON` (case-sensitive)
- Verify the secret value contains valid JSON

**Error: "GoogleService-Info.plist not found"**
- Make sure you added the `GOOGLE_SERVICE_INFO_PLIST` secret correctly
- Check that the secret name is exactly `GOOGLE_SERVICE_INFO_PLIST` (case-sensitive)
- Verify the secret value contains valid XML plist format

**iOS app not in Firebase Console:**
- Add iOS app in Firebase Console with bundle ID: `com.nextwave.musicgame`
- Download the `GoogleService-Info.plist` file
- Copy to `ios/Runner/GoogleService-Info.plist` locally (for local builds)
- Add to GitHub Secrets (for CI/CD builds)
