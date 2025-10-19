# Quick Setup: Enable Google Sign-In in Firebase

## Step-by-Step Guide

### 1. Open Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your NextWave project
3. Click on **Authentication** in the left sidebar

### 2. Enable Google Sign-In Provider
1. Click on the **Sign-in method** tab
2. Find **Google** in the list of providers
3. Click on **Google** to expand it
4. Click the **Enable** toggle switch
5. **Important**: Select a support email (required)
   - Choose your email from the dropdown
6. Click **Save**

### 3. Add Authorized Domains (if needed)
1. In the **Sign-in method** tab
2. Scroll down to **Authorized domains**
3. Common domains are already added:
   - `localhost` (for local development)
   - `yourproject.firebaseapp.com`
   - `yourproject.web.app`
4. If deploying elsewhere, click **Add domain** and enter your custom domain

### 4. Configure OAuth Consent Screen (Optional)
This is only needed if you see warnings about an unverified app:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **OAuth consent screen**
4. Fill in required fields:
   - **App name**: NextWave
   - **User support email**: Your email
   - **Developer contact email**: Your email
   - **App logo**: (optional) Upload your app icon
5. Click **Save and Continue**

### 5. Test the Integration

#### Web Testing:
```bash
cd nextwave
flutter run -d chrome
```

1. App loads → Shows auth screen
2. Click **SIGN IN WITH GOOGLE** button
3. Google popup appears with account selection
4. Select your Google account
5. Grant permissions
6. Should redirect to onboarding (new user) or dashboard (existing user)

#### Common Issues:

**Issue**: "API key not valid"
- **Fix**: Make sure you enabled Google sign-in in step 2
- Wait a few minutes for changes to propagate

**Issue**: "This app hasn't been verified"
- **Fix**: Normal for development! Click "Advanced" → "Go to NextWave (unsafe)"
- For production: Complete OAuth consent screen verification

**Issue**: Popup blocked
- **Fix**: Allow popups in your browser for localhost/firebase domains

**Issue**: "redirect_uri_mismatch"
- **Fix**: Add your domain to authorized domains (step 3)

### 6. Verify in Firestore

After successful sign-in:

1. Go to Firebase Console → **Firestore Database**
2. Open the `players` collection
3. Find the new user document
4. Verify fields:
   ```json
   {
     "id": "google-user-id-here",
     "email": "user@gmail.com",
     "displayName": "Artist Name",
     "gender": null,  // Will be set during onboarding
     "joinDate": "timestamp",
     "lastActive": "timestamp"
   }
   ```

### 7. Mobile Setup (Android/iOS)

#### Android:
1. Download updated `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. SHA-1 fingerprint may be needed:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Add SHA-1 to Firebase Console → Project Settings → Your Apps → Android app

#### iOS:
1. Download updated `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/GoogleService-Info.plist`
3. Update URL schemes in `ios/Runner/Info.plist` (auto-configured by FlutterFire)

## That's It! 🎉

Your users can now sign in with their Google accounts. The authentication flow is:

1. User clicks "SIGN IN WITH GOOGLE"
2. Google OAuth popup appears
3. User grants permission
4. Firebase creates/signs in user
5. App redirects to onboarding or dashboard

## Security Notes

- Firebase handles all OAuth tokens securely
- User passwords never stored in your app
- Users can revoke access via Google Account settings
- All communication encrypted (HTTPS)

## Next Steps

1. Test on all platforms (Web, Android, iOS)
2. Customize OAuth consent screen for better branding
3. Monitor sign-ins in Firebase Console → Authentication → Users
4. Consider adding other providers (Apple, Facebook, etc.)

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Review browser console for client-side errors
3. Verify all config files are up to date
4. Ensure `google_sign_in` package is installed: `flutter pub get`

---

**Documentation**: See `docs/features/GOOGLE_SIGN_IN_AND_GENDER.md` for full details.
