# GitHub Actions - APK Build Setup

This repository includes a GitHub Actions workflow that automatically builds Android APK files on every push to the main branch.

## 🚀 Features

- **Automatic Builds**: Builds APKs on every push to `main` branch
- **Manual Triggers**: Can be manually triggered via GitHub Actions UI
- **Multiple ABIs**: Creates split APKs for different architectures (arm64-v8a, armeabi-v7a, x86_64)
- **Debug & Release**: Builds both debug and release APKs
- **Artifact Storage**: Stores APKs for download (14 days for debug, 30 days for release)
- **Build Summary**: Provides detailed build information in GitHub UI

## 📋 Setup Instructions

### 1. Add Firebase Configuration (Optional but Recommended)

To include Firebase in your builds, you need to add your `google-services.json` as a GitHub secret:

1. **Encode your google-services.json file:**
   ```powershell
   # On Windows PowerShell
   $content = Get-Content android\app\google-services.json -Raw
   $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
   $encoded = [Convert]::ToBase64String($bytes)
   $encoded | Set-Clipboard
   # The encoded content is now in your clipboard
   ```

   Or use this simpler command:
   ```powershell
   [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard
   ```

2. **Add the secret to GitHub:**
   - Go to your repository on GitHub
   - Navigate to **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `GOOGLE_SERVICES_JSON`
   - Value: Paste the base64-encoded content from your clipboard
   - Click **Add secret**

### 2. Configure Signing (Optional for Release APKs)

For signed release APKs, you'll need to add signing configuration:

1. **Create or use existing keystore:**
   ```powershell
   keytool -genkey -v -keystore nextwave-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nextwave
   ```

2. **Encode keystore:**
   ```powershell
   [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("nextwave-release-key.jks")) | Set-Clipboard
   ```

3. **Add secrets to GitHub:**
   - `KEYSTORE_BASE64`: Base64-encoded keystore file
   - `KEYSTORE_PASSWORD`: Keystore password
   - `KEY_ALIAS`: Key alias (e.g., "nextwave")
   - `KEY_PASSWORD`: Key password

4. **Update the workflow** (add before "Build APK (Release)" step):
   ```yaml
   - name: Decode keystore
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     env:
       KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
     run: |
       echo "$KEYSTORE_BASE64" | base64 --decode > android/app/keystore.jks

   - name: Create key.properties
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     run: |
       cat > android/key.properties << EOF
       storePassword=${{ secrets.KEYSTORE_PASSWORD }}
       keyPassword=${{ secrets.KEY_PASSWORD }}
       keyAlias=${{ secrets.KEY_ALIAS }}
       storeFile=keystore.jks
       EOF
   ```

## 🎯 Usage

### Automatic Builds

The workflow runs automatically when you push to the `main` branch:

```powershell
git add .
git commit -m "Update app"
git push origin main
```

### Manual Builds

1. Go to your repository on GitHub
2. Click on **Actions** tab
3. Select **Build Android APK** workflow
4. Click **Run workflow** button
5. Select branch and click **Run workflow**

### Download APKs

After a build completes:

1. Go to the **Actions** tab
2. Click on the completed workflow run
3. Scroll to the **Artifacts** section at the bottom
4. Download:
   - `debug-apks` - Debug APK files
   - `release-apks` - Release APK files
   - `release-info` - Build information

## 📦 APK Types

The workflow generates split APKs for different CPU architectures:

- `app-armeabi-v7a-debug.apk` / `app-armeabi-v7a-release.apk` - 32-bit ARM devices
- `app-arm64-v8a-debug.apk` / `app-arm64-v8a-release.apk` - 64-bit ARM devices (most modern phones)
- `app-x86_64-debug.apk` / `app-x86_64-release.apk` - Intel/AMD devices

**Recommended**: Use `app-arm64-v8a-release.apk` for most modern Android devices.

## 🔍 Troubleshooting

### Build Fails with "google-services.json not found"

If you don't need Firebase, you can:
1. Remove Firebase dependencies from `pubspec.yaml`
2. Remove Firebase initialization from `lib/main.dart`

Or add the `GOOGLE_SERVICES_JSON` secret as described above.

### Build Fails with Gradle Errors

Check the Gradle memory settings in `android/gradle.properties`. The workflow uses the settings from your repository.

### APK Too Large

To reduce APK size:
- Use `--split-per-abi` (already enabled)
- Enable ProGuard/R8 in `android/app/build.gradle.kts`
- Remove unused dependencies

## 📊 Build Status

You can add a build status badge to your README.md:

```markdown
![Build APK](https://github.com/iamkillcode/NextWave-Music-Sim/workflows/Build%20Android%20APK/badge.svg)
```

Result:
![Build APK](https://github.com/iamkillcode/NextWave-Music-Sim/workflows/Build%20Android%20APK/badge.svg)

## 🔄 Workflow Triggers

The workflow runs on:
- **Push to main**: Automatic build on every commit
- **Pull requests**: Automatic build to verify PRs don't break the build
- **Manual dispatch**: Can be triggered manually from GitHub UI
- **Excludes**: Markdown files and documentation changes

## 💡 Tips

1. **Cache**: The workflow uses Flutter and Gradle caching to speed up builds
2. **Retention**: Debug APKs are kept for 14 days, release APKs for 30 days
3. **Build Summary**: Check the workflow summary for quick APK information
4. **Parallel Builds**: Consider creating separate workflows for debug and release if needed

## 📝 Next Steps

1. Add the `GOOGLE_SERVICES_JSON` secret
2. (Optional) Set up keystore signing for release builds
3. Push a commit to trigger the first build
4. Download and test the generated APKs

## 🆘 Support

If you encounter issues:
1. Check the workflow logs in GitHub Actions
2. Review the error messages
3. Ensure all secrets are correctly configured
4. Verify `android/gradle.properties` settings match your local build
