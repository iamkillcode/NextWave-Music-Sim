# Google Sign-In & Gender Selection Features

## Overview
This document describes the new authentication and profile customization features added to NextWave.

## Features Implemented

### 1. Google Sign-In Authentication

**What it does:**
- Allows users to sign up and log in using their Google/Gmail account
- Provides a seamless single-click authentication experience
- Automatically creates player profile with Google account information

**How to use:**
1. On the login screen, you'll see both traditional email/password forms AND a Google Sign-In button
2. Click "SIGN IN WITH GOOGLE"
3. Select your Google account in the popup
4. If you're a new user, you'll be taken to onboarding to complete your profile
5. If you're an existing user, you'll go directly to the dashboard

**Technical implementation:**
- Package: `google_sign_in: ^6.2.1`
- Service method: `FirebaseService.signInWithGoogle()`
- Handles both new user onboarding and existing user login
- Gracefully handles user cancellation

### 2. Gender Selection System

**What it does:**
- Allows players to optionally set their gender during onboarding or in settings
- One-time setting - can only be set once to prevent abuse
- Completely optional - "Prefer not to say" is a valid option

**Available options:**
- Male 👨
- Female 👩
- Other 🧑
- Prefer not to say 🔒

**Where to set:**
- **New users**: During onboarding (page 4 of 6)
- **Existing users**: Settings screen → Gender section (only shows if not yet set)

**How it works:**
```dart
// Gender field in player profile
{
  "gender": "male" | "female" | "other" | null,
  // ... other fields
}
```

**One-time enforcement:**
- Once set in Firestore, the gender field cannot be changed
- Settings screen checks `_hasSetGender` flag
- If already set, gender section is hidden in settings
- Attempting to set again shows warning: "⚠️ You can only set your gender once"

## Code Changes

### 1. **pubspec.yaml**
```yaml
dependencies:
  google_sign_in: ^6.2.1  # Added for Google authentication
```

### 2. **lib/models/multiplayer_player.dart**
```dart
class MultiplayerPlayer {
  final String? gender; // New field: 'male', 'female', 'other', or null
  
  const MultiplayerPlayer({
    // ... existing fields
    this.gender,
    // ...
  });
}
```

### 3. **lib/services/firebase_service.dart**
```dart
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google account
  Future<UserCredential?> signInWithGoogle() async {
    // Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) return null; // User cancelled
    
    // Get auth credentials
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // Sign in to Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    
    // Create/update player profile
    if (userCredential.user != null) {
      await _createOrUpdatePlayer(userCredential.user!);
    }
    
    return userCredential;
  }
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();  // Sign out from Google
    await _auth.signOut();          // Sign out from Firebase
  }
}
```

### 4. **lib/screens/auth_screen.dart**
```dart
// Added Google Sign-In handler
Future<void> _handleGoogleSignIn() async {
  final firebaseService = FirebaseService();
  final userCredential = await firebaseService.signInWithGoogle();
  
  if (userCredential == null) return; // User cancelled
  
  // Check if new user or existing user
  final userDoc = await FirebaseFirestore.instance
      .collection('players')
      .doc(userCredential.user!.uid)
      .get();
  
  if (!userDoc.exists || incomplete profile) {
    // Navigate to onboarding
  } else {
    // Navigate to dashboard
  }
}

// UI includes Google button with divider
- OR divider -
[SIGN IN WITH GOOGLE] button (blue background, Google logo)
```

### 5. **lib/screens/onboarding_screen.dart**
```dart
// Added gender selection page (page 4 of 6)
String? _selectedGender;

Widget _buildGenderSelectionPage() {
  // Shows 4 gender options with icons and colors
  // Male: Blue, Female: Pink, Other: Purple, Prefer not to say: Gray
}

// Gender saved in player profile
final playerData = {
  'gender': _selectedGender,
  // ... other fields
};
```

### 6. **lib/screens/settings_screen.dart**
```dart
String? _currentGender;
bool _hasSetGender = false;

// Load current gender from Firestore
Future<void> _loadSettings() async {
  _currentGender = data['gender'] as String?;
  _hasSetGender = data['gender'] != null;
}

// One-time gender setter
Future<void> _setGender(String? gender) async {
  if (_hasSetGender) {
    // Show warning: already set
    return;
  }
  
  await _firestore.collection('players').doc(userId).update({
    'gender': gender,
  });
  
  setState(() {
    _currentGender = gender;
    _hasSetGender = true;
  });
}

// UI: Only show if not set
if (!_hasSetGender) {
  _buildGenderCard()  // 4 buttons: male, female, other, prefer not to say
}
```

## User Flow

### New User with Google Sign-In
1. Click "SIGN IN WITH GOOGLE" on auth screen
2. Select Google account → Firebase authentication
3. Redirected to onboarding:
   - Page 1: Welcome
   - Page 2: Artist name
   - Page 3: Age selection
   - **Page 4: Gender selection** ← NEW
   - Page 5: Genre selection
   - Page 6: Region selection
4. Profile created with all info including gender
5. Enter dashboard

### Existing User Without Gender Set
1. Log in (email/password or Google)
2. Go to Settings screen
3. See "Gender (One-Time Setting)" section
4. Choose one of 4 options
5. Gender saved permanently
6. Section disappears from settings

### Existing User With Gender Already Set
1. Log in
2. Go to Settings screen
3. Gender section not visible (already set)
4. Cannot change gender

## Firebase Console Setup (Required for Google Sign-In)

### 1. Enable Google Sign-In Method
```
Firebase Console → Authentication → Sign-in method
→ Click "Google" → Enable → Save
```

### 2. Configure OAuth Consent Screen (if needed)
```
Google Cloud Console → APIs & Services → OAuth consent screen
→ Configure app name, support email, logo, etc.
```

### 3. Add Authorized Domains
```
Firebase Console → Authentication → Settings → Authorized domains
→ Add your domain (e.g., yourapp.web.app)
```

### 4. Download Updated Config Files
After enabling Google Sign-In, you may need to:
- Android: Download new `google-services.json`
- iOS: Download new `GoogleService-Info.plist`
- Web: Configuration auto-updated

## Testing

### Test Google Sign-In
1. Run app: `flutter run -d chrome`
2. Click "SIGN IN WITH GOOGLE"
3. Verify popup appears with Google account selection
4. Sign in and verify:
   - New user → goes to onboarding
   - Existing user → goes to dashboard
5. Check Firestore:
   - Player document created with Google email
   - `displayName` populated if onboarding completed

### Test Gender Selection

**During Onboarding:**
1. Create new account (email or Google)
2. Complete onboarding pages
3. On page 4, select a gender option
4. Complete onboarding
5. Check Firestore: `gender` field should be set
6. Go to Settings → Gender section should NOT appear

**In Settings (Existing User):**
1. Log in with account that has no gender set
2. Go to Settings
3. Verify "Gender (One-Time Setting)" section visible
4. Select a gender
5. Verify success message
6. Refresh settings → section should disappear
7. Check Firestore: `gender` field should be set

**One-Time Enforcement:**
1. Try setting gender in settings
2. Refresh page or restart app
3. Gender section should be gone
4. Firestore data should show gender value

## Benefits

### Google Sign-In
- ✅ Faster registration (1 click vs form filling)
- ✅ No password to remember
- ✅ More secure (Google's authentication)
- ✅ Pre-filled email from Google account
- ✅ Better user experience on mobile

### Gender Selection
- ✅ Optional personalization
- ✅ Privacy-respecting (prefer not to say option)
- ✅ One-time setting prevents profile spam
- ✅ Can be used for future features (achievements, rankings, etc.)
- ✅ Analytics and demographic insights (if needed)

## Privacy & Security Notes

1. **Google Sign-In:**
   - Only email and basic profile info accessed
   - User can revoke access via Google Account settings
   - Firebase Auth tokens handled securely
   - No Google password stored in app

2. **Gender Data:**
   - Completely optional field
   - "Prefer not to say" is a valid choice
   - One-time setting protects against spam
   - Stored securely in Firestore
   - Not displayed publicly (yet)

## Future Enhancements

Possible uses for gender field:
- Gender-based achievements/awards
- Personalized UI themes or icons
- Analytics for developer insights
- Leaderboard filtering options
- Targeted in-game events

## Troubleshooting

### Google Sign-In Issues

**Problem:** "API key not valid" or 403 error
- **Solution:** Enable Google Sign-In in Firebase Console
- Check that OAuth client ID is configured

**Problem:** Popup doesn't appear
- **Solution:** Check browser popup blocker settings
- Verify authorized domains in Firebase Console

**Problem:** User sees "access denied"
- **Solution:** Check OAuth consent screen configuration
- Ensure app is not in restricted mode

### Gender Selection Issues

**Problem:** Can't set gender in settings
- **Solution:** May have already been set
- Check Firestore document for `gender` field
- If set, section won't appear

**Problem:** Gender section visible after setting
- **Solution:** Refresh settings screen
- Check that Firestore write succeeded
- Verify `_hasSetGender` flag loading correctly

## Related Files

- `lib/services/firebase_service.dart` - Google Sign-In implementation
- `lib/screens/auth_screen.dart` - Google Sign-In button UI
- `lib/screens/onboarding_screen.dart` - Gender selection during onboarding
- `lib/screens/settings_screen.dart` - One-time gender setting
- `lib/models/multiplayer_player.dart` - Gender field in player model

## Summary

These features enhance user authentication and profile customization in NextWave:
- **Google Sign-In**: Faster, more secure authentication
- **Gender Selection**: Optional personalization with privacy protection
- **One-Time Setting**: Prevents abuse while allowing profile completion

Both features integrate seamlessly with existing Firebase infrastructure and follow best practices for user privacy and data security.
