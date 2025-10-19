# Quick Fix: GitHub Actions Build Failure

## Problem
GitHub Actions fails with: "File google-services.json is missing"

## Solution (3 Steps)

### Step 1: Run the Setup Script
```powershell
.\setup-github-secrets.ps1
```

This will copy your Firebase configs to clipboard one at a time.

### Step 2: Add to GitHub Secrets

**For Android (GOOGLE_SERVICES_JSON):**
1. Go to: https://github.com/iamkillcode/NextWave-Music-Sim/settings/secrets/actions
2. Click "New repository secret"
3. Name: `GOOGLE_SERVICES_JSON`
4. Value: Paste from clipboard (the script copied it for you)
5. Click "Add secret"
6. Press ENTER in the PowerShell window to continue

**For iOS (GOOGLE_SERVICE_INFO_PLIST):**
1. Same page: https://github.com/iamkillcode/NextWave-Music-Sim/settings/secrets/actions
2. Click "New repository secret"
3. Name: `GOOGLE_SERVICE_INFO_PLIST`
4. Value: Paste from clipboard (the script copied it for you)
5. Click "Add secret"

### Step 3: Push and Build
```powershell
git add .
git commit -m "Fix: Add iOS Podfile and update workflow for Firebase configs"
git push
```

The GitHub Actions workflow will now:
- ✅ Create `google-services.json` from secrets
- ✅ Create `GoogleService-Info.plist` from secrets
- ✅ Build Android APK
- ✅ Build iOS IPA
- ✅ Create GitHub Release with both files

## Verification

After pushing, check the Actions tab:
- Go to: https://github.com/iamkillcode/NextWave-Music-Sim/actions
- The latest workflow run should succeed
- Download artifacts: Android APK and iOS IPA

## Security Note
- ✅ Firebase configs are stored as encrypted GitHub Secrets
- ✅ Never committed to the repository
- ✅ Only accessible during workflow runs
- ✅ Secret values are masked in logs
