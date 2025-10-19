# Google Sign-In OAuth Client ID Setup (REQUIRED)

## The Error You're Seeing

```
Error signing in with Google: Assertion failed:
appClientId != null
"ClientID not set. Either set it on a <meta name="google-signin-client_id" content="CLIENT_ID" /> tag, 
or pass clientId when initializing GoogleSignIn"
```

This means the Google OAuth Client ID for web is not configured.

## Quick Fix Steps

### Step 1: Get Your OAuth Client ID from Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **nextwave-music-sim**
3. Click on **⚙️ Settings** (gear icon) → **Project settings**
4. Scroll down to **Your apps** section
5. Find your **Web app** (the one with icon 🌐)
6. Look for **Web Client ID** under SDK setup and configuration
7. Copy the Client ID (looks like: `554743988495-xxxxxxxxx.apps.googleusercontent.com`)

### Step 2: Option A - Add to index.html (Recommended)

Add this meta tag to `web/index.html` inside the `<head>` section:

```html
<head>
  <!-- ... existing meta tags ... -->
  
  <!-- Google Sign-In Client ID -->
  <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com">
  
  <!-- ... rest of head ... -->
</head>
```

### Step 2: Option B - Configure in Code

Update `lib/services/firebase_service.dart`:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
);
```

## Detailed Instructions

### Finding Your Web Client ID

#### Method 1: From Firebase Console

1. **Firebase Console** → **Authentication** → **Sign-in method**
2. Click on **Google** provider
3. Expand **Web SDK configuration**
4. Copy the **Web client ID**

#### Method 2: From Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **nextwave-music-sim**
3. Navigate to **APIs & Services** → **Credentials**
4. Look for **OAuth 2.0 Client IDs**
5. Find the one for **Web client** (Auto-created by Firebase)
6. Copy the **Client ID**

### Complete index.html Update

Here's what your `web/index.html` should look like with the Google Sign-In meta tag:

```html
<!DOCTYPE html>
<html>
<head>
  <base href="/NextWave-Music-Sim/">
  
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="NextWave - Music Artist Simulation Game">
  
  <!-- Google Sign-In Client ID - REQUIRED FOR GOOGLE AUTH -->
  <meta name="google-signin-client_id" content="554743988495-XXXXXXXXXXXXXXXX.apps.googleusercontent.com">
  
  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="NextWave">
  
  <!-- ... rest of head ... -->
</head>
<body>
  <!-- ... body content ... -->
</body>
</html>
```

## Alternative: Configure GoogleSignIn with ClientId

If you prefer to configure it in code instead of HTML:

### Update `lib/services/firebase_service.dart`

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  // ... existing code ...
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web, you MUST provide the client ID
    clientId: kIsWeb 
        ? '554743988495-XXXXXXXXXXXXXXXX.apps.googleusercontent.com'
        : null,
  );
  
  // ... rest of code ...
}
```

## How to Get Your Actual Client ID

Since I can't access your Firebase Console, here's how to get it:

### Quick Command (if you have Firebase CLI)

```bash
firebase apps:sdkconfig WEB
```

This will show your Web app configuration including the OAuth client ID.

### Manual Steps

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Open project: **nextwave-music-sim** (Project ID visible in your firebase_options.dart)
3. Go to **Project Settings** (⚙️ gear icon)
4. Scroll to **Your apps** section
5. Click on your Web app
6. In **SDK setup and configuration**, you'll see:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyDizURd-S2nzUmYGNNqr0dhedIAewckEkk",
     authDomain: "nextwave-music-sim.firebaseapp.com",
     projectId: "nextwave-music-sim",
     // ... other config
   };
   ```
7. Below that, click on **"Google Sign-In"** or **"Authentication"**
8. The OAuth Client ID will be shown

## Testing After Setup

After adding the Client ID:

```bash
# Clean build
flutter clean
flutter pub get

# Run in Chrome
flutter run -d chrome --web-renderer html
```

Then:
1. Click **SIGN IN WITH GOOGLE**
2. Google account selection popup should appear
3. Select your account
4. Should redirect to onboarding or dashboard

## Common Issues

### Issue: Still getting "ClientID not set" error

**Solution:**
- Make sure you added the meta tag in the `<head>` section, not `<body>`
- Verify the Client ID is the **Web Client ID**, not Android or iOS
- Hard refresh Chrome: `Ctrl+Shift+R` or `Cmd+Shift+R`

### Issue: "redirect_uri_mismatch" error

**Solution:**
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- **APIs & Services** → **Credentials**
- Edit the OAuth 2.0 Client ID for Web
- Add authorized redirect URIs:
  - `http://localhost`
  - `http://localhost:8080`
  - Your production domain

### Issue: Can't find Web Client ID

**Solution:**
If you don't see a Web Client ID in Firebase Console:

1. Go to **Authentication** → **Sign-in method**
2. Click **Google**
3. If not enabled, enable it
4. Firebase will auto-create an OAuth client
5. The Client ID will appear in **Web SDK configuration**

## Production Deployment Note

When deploying to production (Firebase Hosting, GitHub Pages, etc.):

1. Update the Client ID with your production OAuth client
2. Or use the same Client ID but add production domain to authorized origins
3. Update `web/index.html` with the correct base href

## Example: Complete Working Setup

**web/index.html:**
```html
<head>
  <meta name="google-signin-client_id" content="554743988495-abc123xyz789.apps.googleusercontent.com">
  <!-- ... other meta tags ... -->
</head>
```

**lib/services/firebase_service.dart:**
```dart
// No changes needed if using meta tag approach
// GoogleSignIn() will automatically read the client ID from the meta tag

final GoogleSignIn _googleSignIn = GoogleSignIn();
```

That's it! The error will be resolved once you add your Web Client ID.

## Need Help Finding Your Client ID?

Run this in your terminal to open Firebase Console directly to the right place:

```bash
start https://console.firebase.google.com/project/nextwave-music-sim/settings/general
```

Then scroll down to **Your apps** and click on the Web app (🌐 icon).

---

**TL;DR:**
1. Get OAuth Client ID from Firebase Console
2. Add to `web/index.html`: `<meta name="google-signin-client_id" content="YOUR_CLIENT_ID">`
3. Run `flutter clean && flutter pub get`
4. Test with `flutter run -d chrome --web-renderer html`
