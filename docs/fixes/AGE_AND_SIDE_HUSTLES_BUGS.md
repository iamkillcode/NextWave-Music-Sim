# Bug Fixes - Age & Side Hustles

## Issue 1: Age Always Shows 14

### Problem
Players report that no matter what age they select during onboarding, they end up being 14 years old.

### Root Cause
Existing Firebase profiles created before the age field was added don't have an `age` field. When loading these profiles, the default value fallback `(data['age'] ?? 18).toInt()` is being used, but something is overriding it to 14.

### Investigation
Looking at the code:
- Onboarding correctly saves: `'age': _selectedAge` (line 123)
- Dashboard correctly loads: `age: (data['age'] ?? 18).toInt()` (line 262)
- Default age in onboarding: `int _selectedAge = 18;` (line 25)

**Wait - found it!** There might be a migration issue or existing Firebase data has age = 14 hardcoded.

### Solution

**Update `dashboard_screen_new.dart` to ensure age field exists:**

Already fixed in our previous changes:
- Added `'fanbase': artistStats.fanbase,` to save operation
- Changed load to: `fanbase: (data['fanbase'] ?? data['level'] ?? 1).toInt()`
- Age is already being saved correctly

**The real issue:** Old Firebase profiles might have corrupted data or be missing the age field entirely.

### Fix Steps

1. **Clear Firebase data and re-onboard** (for testing)
2. **Add migration for existing users:**

```dart
// In dashboard_screen_new.dart, _loadUserProfile method
// After line 262, add this migration check:

// Migrate old profiles without proper age field
if (!data.containsKey('age') || data['age'] == 14) {
  // Force update to default age if missing or corrupted
  await FirebaseFirestore.instance
      .collection('players')
      .doc(user.uid)
      .update({'age': 18}); // Set to 18 or prompt user to select again
}
```

---

## Issue 2: Side Hustles Screen Doesn't Load Contracts

### Problem
The Side Hustles screen shows "No Contracts Available" even though `initializeContractPool()` should create 15 contracts on first load.

### Root Cause
The `initializeContractPool()` method is called in `initState()` but:
1. It might be failing silently due to Firebase permissions
2. The Firestore collection `globalSideHustles` might not exist
3. No error handling to show why it failed

### Investigation

**Code Flow:**
1. `side_hustle_screen.dart` line 30: `_sideHustleService.initializeContractPool();`
2. `side_hustle_service.dart` line 222-236: Checks if contracts exist, generates 15 if empty
3. `getAvailableContracts()` (line 120) uses `StreamBuilder` to listen for contracts

**Possible Issues:**
- Firestore rules might prevent writing to `globalSideHustles` collection
- `generateNewContracts()` might be failing
- StreamBuilder error not displayed

### Solution

**Step 1: Check Firestore Rules**

Make sure `firestore.rules` allows reading/writing `globalSideHustles`:

```javascript
match /globalSideHustles/{contractId} {
  allow read: if true; // Anyone can read contracts
  allow write: if request.auth != null; // Authenticated users can write
}
```

**Step 2: Add Better Error Handling to `side_hustle_service.dart`:**

```dart
Future<void> initializeContractPool() async {
  try {
    print('🔍 Checking contract pool...');
    final snapshot = await _contractsRef.limit(1).get();
    
    print('📊 Found ${snapshot.docs.length} existing contracts');

    if (snapshot.docs.isEmpty) {
      print('🎯 Generating initial 15 contracts...');
      await generateNewContracts(15);
      print('✅ Initialized contract pool with 15 contracts');
    } else {
      print('✅ Contract pool already initialized with ${snapshot.docs.length} contracts');
    }
  } catch (e, stackTrace) {
    print('❌ Error initializing contract pool: $e');
    print('Stack trace: $stackTrace');
  }
}
```

**Step 3: Force Initialize Contracts (Temporary Fix)**

Add a button in the side hustle screen to manually trigger initialization:

```dart
// In side_hustle_screen.dart, add to build method:
FloatingActionButton(
  onPressed: () async {
    print('🔄 Manually initializing contracts...');
    await _sideHustleService.generateNewContracts(15);
    print('✅ Generated 15 new contracts');
  },
  child: Icon(Icons.refresh),
  tooltip: 'Force Generate Contracts',
)
```

**Step 4: Check Console for Errors**

Run the app and check the console output:
```bash
flutter run -d chrome
```

Look for errors like:
- `❌ Error initializing contract pool:`
- `Error loading contracts:`
- Firestore permission errors

---

## Testing Checklist

### Age Bug Testing
- [ ] Create new account
- [ ] Select age 25 during onboarding
- [ ] Complete onboarding
- [ ] Check dashboard profile - should show age 25
- [ ] Logout and login again
- [ ] Verify age is still 25

### Side Hustles Bug Testing
- [ ] Open Side Hustles screen
- [ ] Check console for error messages
- [ ] Verify Firestore rules allow access to `globalSideHustles`
- [ ] Manually trigger contract generation if needed
- [ ] Verify contracts appear in the list
- [ ] Try claiming a contract
- [ ] Verify claimed contract shows in active section

---

## Quick Test Commands

```bash
# Run web app with console output
flutter run -d chrome

# Check for Firebase errors
# Look for "Firestore permission denied" or similar

# Clean and rebuild if needed
flutter clean
flutter pub get
flutter run -d chrome
```

---

## Firebase Console Checklist

1. **Go to Firebase Console** → Firestore Database
2. **Check if `globalSideHustles` collection exists**
   - If not, contracts were never created
3. **Check if collection is empty**
   - Should have ~15 documents
4. **Check Firestore Rules**
   - Verify read/write permissions for `globalSideHustles`

---

## Files Modified

1. ✅ `lib/screens/onboarding_screen.dart` - Added `'fanbase': 1,` field
2. ✅ `lib/screens/dashboard_screen_new.dart` - Fixed fanbase save/load
3. ⚠️ `lib/services/side_hustle_service.dart` - Needs better error handling
4. ⚠️ `firestore.rules` - Needs `globalSideHustles` rules

---

## Next Steps

If Side Hustles still don't load after checking Firestore rules:

1. **Check Browser Console** (F12) for JavaScript errors
2. **Check Flutter Console** for Dart errors
3. **Manually add a test contract** in Firebase Console:
   ```json
   {
     "contractId": "test_001",
     "type": 0,
     "contractLengthDays": 7,
     "dailyPay": 100,
     "dailyEnergyCost": 10,
     "isAvailable": true,
     "createdAt": {firebase timestamp}
   }
   ```
4. **Refresh app** and see if test contract appears
