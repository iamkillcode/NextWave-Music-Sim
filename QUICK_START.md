# Quick Firebase Setup Steps

## Option 1: Automatic Setup (Recommended)

Run this command in your terminal:
```powershell
cd "c:\Users\Manuel\Documents\GitHub\NextWave\mobile_game"
flutterfire configure
```

This will:
1. Let you select or create a Firebase project
2. Register your app for web, Android, and iOS
3. Automatically generate `firebase_options.dart` with correct values

## Option 2: Manual Setup

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add Project"
3. Name: **nextwave-music-game**
4. Enable Google Analytics
5. Click "Create Project"

### Step 2: Add Web App
1. Click the Web icon (`</>`)
2. App nickname: **NextWave Web**
3. Click "Register app"
4. Copy the config values

### Step 3: Enable Authentication
1. Go to Authentication > Sign-in method
2. Enable "Email/Password"
3. Enable "Anonymous"
4. Click "Save"

### Step 4: Create Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in "Test mode"
4. Choose your location
5. Click "Enable"

### Step 5: Update firebase_options.dart
Replace the values in `lib/firebase_options.dart` with your actual Firebase config.

## Testing

After setup, run:
```powershell
flutter run -d chrome
```

Then:
1. Click "Sign Up"
2. Create an account
3. Complete onboarding
4. Check Firebase Console to see the new user

## Troubleshooting

### "API key not valid" error
- You need to replace the demo API key with your real Firebase API key
- Run `flutterfire configure` or manually update `firebase_options.dart`

### Permission denied in Firestore
- Go to Firestore > Rules
- Make sure you're in test mode or have proper rules set

### Can't sign in
- Check that Email/Password is enabled in Authentication > Sign-in method
- Check browser console for detailed error messages
