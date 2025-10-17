# 🚀 Admin System - Quick Setup

## ⚡ Get Admin Access in 5 Minutes

### **Step 1: Find Your User ID** (2 minutes)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **NextWave-Music-Sim**
3. Go to **Authentication** (left sidebar)
4. Find your account in the users list
5. **Copy the User UID** (long string like `abc123xyz456`)

💡 **Tip:** You can also see your UID in the app by temporarily adding this debug code:
```dart
print('My User ID: ${FirebaseAuth.instance.currentUser?.uid}');
```

---

### **Step 2: Add Yourself as Admin** (2 minutes)

Open `lib/services/admin_service.dart` and find this section:

```dart
static const List<String> ADMIN_USER_IDS = [
  // Add your Firebase User IDs here
  // Example: 'abc123xyz456',
];
```

Replace it with:

```dart
static const List<String> ADMIN_USER_IDS = [
  'YOUR_ACTUAL_USER_ID_HERE',  // Paste your UID here
];
```

**Example:**
```dart
static const List<String> ADMIN_USER_IDS = [
  'K8pQ3mR2xYNf4hT9vLpW1sZcX7jN',  // Manuel's account
];
```

---

### **Step 3: Rebuild and Test** (1 minute)

```powershell
cd C:\Users\Manuel\Documents\GitHub\NextWave\nextwave
flutter run
```

Or rebuild for web:
```powershell
flutter build web --release
npx gh-pages -d build/web
```

---

### **Step 4: Access Admin Dashboard** (30 seconds)

1. Open the game
2. Click **Settings** (⚙️ icon top-right)
3. Scroll down
4. You'll see a **glowing blue "Admin Dashboard" card**
5. Click **"OPEN ADMIN DASHBOARD"**
6. **You're in!** 👑

---

## 🎮 What Can You Do Now?

### **In Admin Dashboard:**

✅ **Initialize NPCs** - Create 10 signature artists for all players  
✅ **Trigger Daily Update** - Manually run game updates  
✅ **Send Global Notifications** - Broadcast messages to all players  
✅ **View Game Stats** - See player count, songs, posts, etc.  
✅ **Manage Admins** - Grant access to others  
✅ **View Error Logs** - Debug issues  
✅ **Reset Data** - Clear all player data (development only!)  

---

## 🔐 Security Check

After setup, verify:

- [ ] Your User ID is in `ADMIN_USER_IDS` list
- [ ] You can see "Admin Dashboard" in Settings
- [ ] You can open the dashboard
- [ ] Non-admin test accounts DON'T see the admin section

---

## 👥 Adding Other Admins

### **Option 1: From Dashboard (Recommended)**

1. Open Admin Dashboard
2. Scroll to "Admin Management"
3. Click "Add Admin"
4. Enter their Firebase User ID
5. Done! They're now an admin

### **Option 2: Hardcode (Permanent)**

Add their ID to the list:

```dart
static const List<String> ADMIN_USER_IDS = [
  'YOUR_USER_ID',
  'TEAMMATE_USER_ID',
  'ANOTHER_ADMIN_ID',
];
```

---

## 🐛 Troubleshooting

### **Issue:** "Access Denied" when opening dashboard

**Fix:** 
1. Check if you saved the file after editing
2. Verify you're using the correct User ID
3. Rebuild the app completely
4. Check for typos in the User ID

### **Issue:** Don't see "Admin Dashboard" in Settings

**Fix:**
1. Check if `_isAdmin` is being set to true
2. Add debug print: `print('Is Admin: $_isAdmin');`
3. Verify Firebase Auth is working

### **Issue:** Can't find my User ID

**Fix:**
1. Add temporary debug code in dashboard:
   ```dart
   print('My ID: ${FirebaseAuth.instance.currentUser?.uid}');
   ```
2. Run app and check console
3. Or use Firebase Console → Authentication

---

## 📱 Example: Your First Admin Action

### **Initialize NPCs:**

1. Open Admin Dashboard
2. Click "Initialize NPCs" under Quick Actions
3. Wait 5-10 seconds
4. See success dialog
5. Check Regional Charts - NPCs are there!
6. All players can now see them!

---

## 🎯 Next Steps

After getting admin access:

1. ✅ Initialize NPCs (one-time setup)
2. ✅ Explore the dashboard
3. ✅ Test sending a notification
4. ✅ Check game statistics
5. ✅ Add team members as admins (if applicable)
6. 📖 Read full documentation: `docs/systems/ADMIN_SYSTEM.md`

---

## 💡 Pro Tips

- **Bookmark the Admin Dashboard** for quick access
- **Use Global Notifications** sparingly (important announcements only)
- **Check Error Logs** weekly to catch issues early
- **Don't give admin access** to players you don't fully trust
- **Test admin functions** in development before using in production

---

## ✨ You're All Set!

You now have full admin control over your game. Use your powers wisely! 👑

**Questions?** Check the full documentation: `docs/systems/ADMIN_SYSTEM.md`

---

*Setup Time: ~5 minutes*  
*Difficulty: Easy*  
*Status: Ready to Use* ✅
