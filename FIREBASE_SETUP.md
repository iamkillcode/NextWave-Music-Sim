# Firebase Setup Guide for NextWave

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: **nextwave-music-game**
4. Enable Google Analytics (recommended)
5. Click "Create Project"

## Step 2: Register Your App

### For Web App:
1. In Firebase Console, click the Web icon (</>) to add a web app
2. App nickname: **NextWave Web**
3. Check "Also set up Firebase Hosting"
4. Click "Register app"
5. Copy the Firebase configuration object

### For Android (Optional):
1. Click Android icon to add Android app
2. Android package name: `com.example.mobileGame`
3. Download `google-services.json`
4. Place it in `android/app/`

### For iOS (Optional):
1. Click iOS icon to add iOS app
2. iOS bundle ID: `com.example.mobileGame`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

## Step 3: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Enable **Email/Password** sign-in method
4. Enable **Anonymous** sign-in method (for guest mode)
5. Click "Save"

## Step 4: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create Database"
3. Start in **Test Mode** (we'll add security rules later)
4. Choose a location (select closest to your users)
5. Click "Enable"

## Step 5: Configure Security Rules

### Firestore Rules (for testing):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Players collection
    match /players/{playerId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == playerId;
    }
    
    // Published songs collection
    match /published_songs/{songId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.playerId;
    }
  }
}
```

## Step 6: Update Firebase Configuration

After creating your Firebase project, you'll get a configuration object like this:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "nextwave-music-game.firebaseapp.com",
  projectId: "nextwave-music-game",
  storageBucket: "nextwave-music-game.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456",
  measurementId: "G-XXXXXXXXXX"
};
```

Copy these values and update `lib/firebase_options.dart` with your actual values.

## Step 7: Run FlutterFire CLI (Recommended)

The easiest way to configure Firebase is using FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your Flutter app
flutterfire configure
```

This will:
- Select your Firebase project
- Register your apps (web, Android, iOS)
- Generate `firebase_options.dart` with correct configuration
- Download necessary config files

## Step 8: Test the Setup

1. Run the app: `flutter run -d chrome`
2. Try creating an account
3. Check Firebase Console > Authentication to see the new user
4. Try signing in
5. Complete onboarding
6. Check Firestore to see player data

## Firestore Collections Structure

### `players` collection:
```json
{
  "id": "user_uid",
  "displayName": "Artist Name",
  "email": "user@example.com",
  "isGuest": false,
  "primaryGenre": "Hip Hop",
  "homeRegion": "usa",
  "bio": "Artist bio...",
  "totalStreams": 0,
  "totalLikes": 0,
  "totalSongs": 0,
  "joinDate": "2025-10-11T12:00:00Z",
  "lastActive": "2025-10-11T12:00:00Z",
  "rankTitle": "Upcoming Artist"
}
```

### `published_songs` collection:
```json
{
  "id": "song_id",
  "playerId": "user_uid",
  "playerName": "Artist Name",
  "title": "Song Title",
  "genre": "Hip Hop",
  "genreEmoji": "🎤",
  "quality": 85,
  "streams": 1500,
  "likes": 45,
  "releaseDate": "2025-10-11T12:00:00Z"
}
```

## Troubleshooting

### Error: "API key not valid"
- Make sure you've updated `firebase_options.dart` with your actual API keys
- Check that you've enabled the required authentication methods in Firebase Console

### Error: "Firestore permission denied"
- Check your Firestore security rules
- Make sure you're signed in before trying to write data

### Error: "Firebase initialization failed"
- Check your internet connection
- Verify that all Firebase packages are installed: `flutter pub get`
- Make sure `firebase_options.dart` has correct values

## Next Steps

Once Firebase is working:
- [ ] Test authentication (sign up, sign in, sign out)
- [ ] Test onboarding flow
- [ ] Test publishing songs to Firestore
- [ ] Test leaderboards
- [ ] Add more secure Firestore rules for production
- [ ] Set up Firebase Storage for future profile pictures/audio files
- [ ] Configure Firebase Analytics events
