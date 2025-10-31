# WakandaZon Marketplace - Deployment Guide

## Overview
WakandaZon is a secure player-to-player song marketplace implemented with Cloud Functions to prevent money exploits and ensure atomic transactions.

## Features Implemented
✅ Secure server-side purchase transactions
✅ Server-side listing cancellations
✅ Atomic money transfers (buyer → seller)
✅ Song ownership transfers
✅ Purchase history tracking
✅ Security rules preventing direct money manipulation

## Architecture

### Cloud Functions (functions/index.js)
Two new callable functions:

1. **purchaseSong**
   - Validates listing exists and is active
   - Checks buyer has sufficient funds
   - Prevents self-purchase
   - Atomically: deducts buyer money, adds seller money, marks listing sold, creates purchase record, adds song to buyer
   - Returns success/error codes

2. **cancelListing**
   - Validates listing exists and user owns it
   - Returns song to seller's inventory
   - Marks listing as cancelled
   - Atomic transaction ensures consistency

### Client Side (lib/screens/wakandazon_screen.dart)
- Calls Cloud Functions instead of direct Firestore updates
- Handles FirebaseFunctionsException with user-friendly error messages
- Refreshes player data after successful transactions

### Security Rules (firestore.rules)
- **wakandazon_listings**: Read public, create by owners only, update/status changes forbidden (Cloud Functions only)
- **wakandazon_purchases**: Read by buyer/seller only, write forbidden (Cloud Functions only)
- **players collection**: Money field cannot be updated by clients, only by Cloud Functions

## Deployment Steps

### 1. Deploy Cloud Functions
```powershell
cd functions
firebase deploy --only functions:purchaseSong,functions:cancelListing
```

### 2. Deploy Firestore Security Rules
```powershell
firebase deploy --only firestore:rules
```

### 3. Test the Functions (Emulators - Optional)
```powershell
# Start emulators
firebase emulators:start --only functions,firestore

# In another terminal, run the Flutter app
cd ..
flutter run -d chrome
```

### 4. Deploy Full App
```powershell
# Build Flutter web
flutter build web

# Deploy to Firebase Hosting (if applicable)
firebase deploy
```

## Error Handling

The Cloud Functions return specific error codes:

| Error Code | Meaning | User Message |
|------------|---------|--------------|
| `unauthenticated` | User not signed in | "Please sign in to purchase" |
| `not-found` | Listing doesn't exist | "Listing not found" |
| `failed-precondition` | Insufficient funds, sold already, or self-purchase | Specific message from function |
| `permission-denied` | Trying to cancel someone else's listing | "You can only cancel your own listings" |
| `internal` | Unexpected server error | "Purchase failed" |

## Security Guarantees

### Prevented Exploits
1. ❌ **Client money manipulation**: Money field cannot be updated by clients
2. ❌ **Double spending**: Transactions are atomic
3. ❌ **Race conditions**: Firestore transactions ensure listing status is checked and updated atomically
4. ❌ **Fake purchases**: Purchases can only be created by Cloud Functions
5. ❌ **Price manipulation**: Listing price is read server-side within transaction
6. ❌ **Self-trading**: Function prevents buying your own listing

### Transaction Flow
```
Client calls purchaseSong(listingId)
    ↓
Cloud Function starts transaction
    ↓
Read listing (validate active, get price)
    ↓
Read buyer & seller player docs
    ↓
Validate buyer.money >= price
    ↓
Update buyer.money (-price), buyer.songs (+song)
Update seller.money (+price)
Update listing.status = 'sold'
Create purchase record
    ↓
Commit transaction (atomic)
    ↓
Return success to client
    ↓
Client refreshes player data from Firestore
```

## Certification Rankings System

### How It Works
The Certifications screen has two tabs:
1. **My Certifications**: Shows your certified songs and stats
2. **Rankings**: Global leaderboard based on certification scores

### Scoring System
Each certification level has a point value:
- **Diamond**: 1,000 points
- **Multi-Platinum**: 500 × level (e.g., 3× Multi-Platinum = 1,500 points)
- **Platinum**: 300 points
- **Gold**: 150 points
- **Silver**: 50 points
- **None**: 0 points

### Calculation
```dart
int _getCertificationScore(String cert, int level) {
  switch (cert) {
    case 'diamond':
      return 1000;
    case 'multi_platinum':
      return 500 * level;  // Scales with level
    case 'platinum':
      return 300;
    case 'gold':
      return 150;
    case 'silver':
      return 50;
    default:
      return 0;
  }
}
```

### Data Source
- Streams from Firestore `players` collection in real-time
- Loops through each player's `songs` array
- Sums up certification scores for all songs with `highestCertification != 'none'`
- Sorts players by total score (highest first)

### UI Features
- **Rank Colors**:
  - 🥇 1st Place: Gold (#FFD700)
  - 🥈 2nd Place: Silver (#C0C0C0)
  - 🥉 3rd Place: Bronze (#CD7F32)
  - Others: White (60% opacity)
- **Current User Highlight**: Blue border and "YOU" badge
- **Player Avatars**: Shows 40×40px circular avatars with gradient fallbacks
- **Certification Count**: Shows total number of certified songs
- **Score Display**: Shows total points from all certifications

### Example Rankings
```
🥇 #1 Drake       | 5,800 pts | 12 certifications
🥈 #2 Beyoncé     | 4,200 pts | 9 certifications
🥉 #3 Taylor      | 3,650 pts | 11 certifications
   #4 YOU         | 2,100 pts | 6 certifications (highlighted in blue)
   #5 Kendrick    | 1,850 pts | 5 certifications
```

### Performance Notes
- Uses StreamBuilder for real-time updates
- Filters out players with 0 certifications
- Calculates scores client-side (could be optimized with Firestore aggregation queries in the future)
- Shows loading spinner while fetching data

## Testing Checklist

### Before Production
- [ ] Deploy functions to Firebase
- [ ] Deploy security rules
- [ ] Test purchase flow (successful purchase)
- [ ] Test purchase flow (insufficient funds)
- [ ] Test purchase flow (listing already sold)
- [ ] Test purchase flow (self-purchase blocked)
- [ ] Test cancel flow (successful)
- [ ] Test cancel flow (wrong owner)
- [ ] Verify money transfers in Firestore console
- [ ] Verify songs are added to buyer inventory
- [ ] Verify purchases collection records
- [ ] Test certification rankings display
- [ ] Verify current user highlighted in rankings
- [ ] Test rankings real-time updates

### Security Verification
- [ ] Try to update money field directly from client (should fail)
- [ ] Try to create purchase record directly (should fail)
- [ ] Try to update listing status directly (should fail)
- [ ] Verify transaction rollback on error (listing remains active if purchase fails)

## Troubleshooting

### Functions not found
```
Error: internal/not-found
```
**Solution**: Deploy functions first with `firebase deploy --only functions`

### Permission denied on money update
```
Error: PERMISSION_DENIED: Missing or insufficient permissions
```
**Solution**: This is expected! Security rules are working. Money can only be updated by Cloud Functions.

### Transaction failed
```
Error: Transaction failed: ...
```
**Solution**: Check Cloud Function logs with `firebase functions:log`

### Client shows old money amount
**Solution**: Client refreshes player data after successful purchase. If not updating, check the `onStatsUpdated` callback.

## Future Enhancements
- [ ] Add notifications for purchases/sales
- [ ] Add transaction fee (5-10% marketplace cut)
- [ ] Add search/filter for marketplace
- [ ] Add song preview before purchase
- [ ] Add "Featured Listings" section
- [ ] Add seller ratings/reviews
- [ ] Add bulk listing management
- [ ] Pre-computed certification scores in player docs (for faster rankings)
