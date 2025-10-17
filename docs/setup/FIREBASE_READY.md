# 🎵 NextWave - Firebase Setup Complete Guide

## Summary

Great progress! FlutterFire CLI is installed and working. Now you need to:
1. Login to Firebase
2. Complete the configuration
3. Enable Authentication & Firestore
4. Test the app

---

## ✅ Step 1: Login to Firebase (REQUIRED)

Open PowerShell and run:

```powershell
firebase login
```

This will:
- Open your browser
- Ask you to sign in with your Google account
- Grant Firebase CLI access

**If `firebase` command is not found**, install Firebase CLI:
```powershell
npm install -g firebase-tools
```

---

## ✅ Step 2: Configure Firebase for NextWave

After logging in, run:

```powershell
cd "c:\Users\Manuel\Documents\GitHub\NextWave\mobile_game"
flutterfire configure
```

Or with full path:
```powershell
& "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure
```

**What happens:**
1. Creates or selects Firebase project "nextwave"
2. Registers your Flutter app (web, Android, iOS)
3. Generates `firebase_options.dart` with real API keys
4. Downloads configuration files

**Select these options:**
- Project: **nextwave** (or create new)
- Platforms: **Web, Android, iOS** (select all)
- Web app name: **NextWave Web**
- Android package: **com.example.mobileGame**
- iOS bundle ID: **com.example.mobileGame**

---

## ✅ Step 3: Enable Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **nextwave** project
3. Click **Authentication** in left menu
4. Click **Get Started**
5. Enable these sign-in methods:
   - ✅ **Email/Password** (click Enable → Save)
   - ✅ **Anonymous** (click Enable → Save)

---

## ✅ Step 4: Create Firestore Database

1. In Firebase Console, click **Firestore Database**
2. Click **Create Database**
3. Select **Start in test mode** (for now)
4. Choose location: **us-central** (or closest to you)
5. Click **Enable**

**Important:** Test mode allows anyone to read/write for 30 days. We'll add security rules later.

---

## ✅ Step 5: Install Dependencies

```powershell
cd "c:\Users\Manuel\Documents\GitHub\NextWave\mobile_game"
flutter pub get
```

---

## ✅ Step 6: Run the App!

```powershell
flutter run -d chrome
```

Or use VS Code:
- Press **F5**
- Or click **Run → Start Debugging**

---

## 🎮 Testing the Setup

### Test Authentication:
1. App loads → Shows login screen ✅
2. Click **Sign Up** tab
3. Enter email: `test@nextwave.com`
4. Enter password: `password123`
5. Click **Sign Up** → Should succeed ✅

### Test Onboarding:
1. After sign up → Onboarding screen appears ✅
2. Page 1: Enter artist name: "DJ Test"
3. Page 2: Select genre: "Hip Hop"
4. Page 3: Select region: "USA 🇺🇸"
5. Page 4: Enter bio (optional)
6. Click **Complete** → Enters dashboard ✅

### Test Firestore:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Open **Firestore Database**
3. Check `players` collection → Should see your artist ✅

### Test Publishing Songs:
1. In dashboard, click **Write Song**
2. Title: "Test Track", Genre: "Hip Hop", Effort: High
3. Click **Write Song** → Song appears in list ✅
4. Click **Record Album** action
5. Select a studio, record the song ✅
6. Click **Tunify** tab → Release song ($5K) ✅
7. Go to **Leaderboard** → Should see your song! ✅

---

## 🔧 Troubleshooting

### Error: "firebase: command not found"

Install Firebase CLI:
```powershell
npm install -g firebase-tools
```

Then run:
```powershell
firebase login
```

### Error: "API key not valid"

This means `flutterfire configure` hasn't run yet. Run it again:
```powershell
& "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure
```

### Error: "Permission denied" in Firestore

1. Go to Firebase Console → Firestore Database → Rules
2. Make sure you're in test mode:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 11, 11);
    }
  }
}
```

### Error: "User not found" after login

Wait a few seconds, then check Firebase Console → Authentication → Users tab.
If the user is there, refresh the app.

### Can't see published songs in leaderboard

1. Make sure you **released** the song from Tunify (costs $5K)
2. Refresh the leaderboard screen
3. Check Firestore → `published_songs` collection

---

## 🎯 Next Steps After Setup

Once Firebase is working:

### 1. **Add Security Rules** (Important for production!)

Go to Firestore → Rules and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Players collection
    match /players/{playerId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.auth.uid == playerId;
      allow delete: if request.auth != null && request.auth.uid == playerId;
    }
    
    // Published songs collection
    match /published_songs/{songId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.playerId;
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.playerId;
    }
  }
}
```

### 2. **Enable Firebase Analytics** (Optional)

Already included! Check Firebase Console → Analytics for user metrics.

### 3. **Test on Mobile**

```powershell
# Android
flutter run -d android

# iOS (Mac only)
flutter run -d ios
```

### 4. **Build for Production**

```powershell
# Web
flutter build web

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle
```

---

## 📚 Additional Resources

- **Firebase Console**: https://console.firebase.google.com/
- **FlutterFire Docs**: https://firebase.flutter.dev/
- **Firebase Auth Guide**: https://firebase.google.com/docs/auth
- **Firestore Guide**: https://firebase.google.com/docs/firestore

---

## 🎉 Summary Checklist

- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`
- [ ] Configure: `flutterfire configure`
- [ ] Enable Authentication (Email + Anonymous)
- [ ] Create Firestore Database (Test mode)
- [ ] Run app: `flutter run -d chrome`
- [ ] Test sign up → onboarding → dashboard
- [ ] Publish a song and check leaderboard
- [ ] Update Firestore security rules

---

**Questions? Check FIREBASE_SETUP.md for detailed explanations!**

🎵 Ready to make music and dominate the charts! 🎵
