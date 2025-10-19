# 🚨 QUICK FIX: Google Sign-In Client ID Required

## The Problem
```
Error signing in with Google: ClientID not set
```

## The Solution (2 Steps)

### Step 1: Get Your OAuth Client ID

1. Open: https://console.firebase.google.com/project/nextwave-music-sim/settings/general
2. Scroll to **"Your apps"** section
3. Click on your **Web app** (🌐 icon)
4. Copy the **Web Client ID** (looks like: `554743988495-xxxxx.apps.googleusercontent.com`)

**OR**

1. Open: https://console.firebase.google.com/project/nextwave-music-sim/authentication/providers
2. Click **Google**
3. Expand **Web SDK configuration**
4. Copy the **Web client ID**

### Step 2: Add to index.html

Open `web/index.html` and uncomment/update this line (around line 10):

**BEFORE:**
```html
<!-- <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com"> -->
```

**AFTER:**
```html
<meta name="google-signin-client_id" content="554743988495-YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com">
```

### Step 3: Test

```bash
flutter clean
flutter pub get
flutter run -d chrome --web-renderer html
```

Click "SIGN IN WITH GOOGLE" - it should work now! ✅

---

## Why This Happens

Google Sign-In on web requires an OAuth 2.0 Client ID to authenticate users. This ID tells Google which app is requesting sign-in and where to redirect users after authentication.

## Full Documentation

See: `docs/fixes/GOOGLE_SIGNIN_CLIENT_ID_FIX.md` for complete details including:
- Alternative configuration methods
- Troubleshooting common errors
- Production deployment notes
- Security considerations

---

**Need the Client ID?** You MUST get it from Firebase Console - I cannot provide it as it's project-specific and secure.
