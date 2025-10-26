# 🚀 Push Notifications - Quick Deploy Guide

## Overview
This guide walks you through deploying push notifications to production.

---

## ⚡ Quick Steps

### 1. Install Dependencies (DONE ✅)
```powershell
cd c:\Users\Manuel\Documents\GitHub\NextWave\nextwave
flutter pub get
```

### 2. Deploy Cloud Functions
```powershell
cd functions
firebase deploy --only functions:onPostEngagement,functions:onChartUpdate,functions:checkRivalChartPositions
```

### 3. Test on Device
```powershell
# Android
flutter run -d android

# iOS (requires Mac)
flutter run -d ios
```

---

## 📱 Firebase Console Setup

### Android (DONE ✅)
1. Go to Firebase Console → Project Settings
2. Your Apps → Android App
3. Download `google-services.json` (if not already done)
4. Place in `android/app/`

### iOS (Mac Required)
1. Go to Firebase Console → Project Settings
2. Cloud Messaging tab
3. Upload APNs Auth Key:
   - Get from Apple Developer Account
   - Certificates, Identifiers & Profiles
   - Keys → Create New Key
   - Enable Apple Push Notifications service
   - Download .p8 file
   - Upload to Firebase

---

## 🧪 Testing Notifications

### Test Post Engagement
1. Sign in as two different users
2. User A creates a post on EchoX
3. User B likes the post 100+ times (can manually update Firestore)
4. User A should receive: "🔥 Your post is blowing up!"

### Test Chart Notifications
1. Have a song on the charts
2. Wait for weekly chart update (runs every hour for testing)
3. Should receive notification if in top 10 or moved significantly

### Test Rival Notifications
1. Have a song on the charts
2. Have another player with a song ranked above you
3. Wait for 6-hour check
4. If rival's position improved, you'll get notified

---

## 🔍 Debugging

### Check FCM Token
```dart
// In dashboard_screen_new.dart, add:
print('FCM Token: ${_pushNotificationService.fcmToken}');
```

### View Cloud Function Logs
```powershell
# All functions
firebase functions:log

# Specific function
firebase functions:log --only onPostEngagement
```

### Test with Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send test message
3. Use FCM token from player document in Firestore
4. Send notification to verify FCM setup works

---

## 📋 Deployment Checklist

- [x] firebase_messaging package added to pubspec.yaml
- [x] PushNotificationService created
- [x] main.dart updated with FCM background handler
- [x] dashboard_screen_new.dart calls initialize()
- [x] AndroidManifest.xml permissions added
- [x] iOS Info.plist updated with UIBackgroundModes
- [x] Cloud Functions added to index.js
- [ ] **Deploy Cloud Functions to production**
- [ ] **Test on physical Android device**
- [ ] **Test on physical iOS device (Mac required)**

---

## 🎯 Next Steps

1. **Deploy Functions:**
   ```powershell
   cd functions
   firebase deploy --only functions:onPostEngagement,functions:onChartUpdate,functions:checkRivalChartPositions
   ```

2. **Test on Device:**
   ```powershell
   flutter run -d android
   ```

3. **Monitor Logs:**
   ```powershell
   firebase functions:log --only onPostEngagement
   ```

4. **Create Test Posts:**
   - Sign in to app
   - Go to EchoX (Media Hub → EchoX)
   - Create a post
   - Have another account like it 100+ times
   - Check for notification

---

## 📞 Troubleshooting

### "No FCM Token" Error
**Solution:** Ensure user has granted notification permissions. Check device settings.

### "Cloud Function Not Triggered"
**Solution:** Check Firestore rules allow Cloud Functions to read/write. View logs with `firebase functions:log`.

### "Notification Not Showing on Android"
**Solution:** 
1. Check device notification settings
2. Verify AndroidManifest.xml has POST_NOTIFICATIONS permission
3. Test with Android 13+ device

### "Notification Not Showing on iOS"
**Solution:**
1. Upload APNs certificate to Firebase
2. Test on physical device (not simulator)
3. Check Info.plist has UIBackgroundModes

---

**Ready to deploy!** Run the Cloud Functions deployment command above to activate push notifications.
