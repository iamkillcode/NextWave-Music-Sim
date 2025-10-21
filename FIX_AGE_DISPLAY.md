# Fix Age Display Issue - Quick Guide

## Problem
Player dashboard shows age as 14 instead of the selected age 18 during onboarding.

## Root Cause
The `careerStartDate` field was being set to real-world date (October 2025) instead of game-world date (January 2020). When calculating current age, the system was doing:
```
currentAge = selectedAge + (currentGameDate - careerStartDate) / 365
currentAge = 18 + (Jan 2021 - Oct 2025) / 365
currentAge = 18 + (-4 years) = 14 years old
```

## What Was Fixed ✅

### 1. Onboarding Screen (`lib/screens/onboarding_screen.dart`)
- Now fetches current game-world date before creating player profile
- Sets `careerStartDate` to game-world date (Jan 2020) instead of real-world date
- This ensures age calculation works correctly for all new players

### 2. Artist Stats Model (`lib/models/artist_stats.dart`)
- Added documentation explaining that `careerStartDate` MUST be game-world date
- The `getCurrentAge()` function now has clear comments about its purpose

## For Existing Players

If you already created your character, you need to manually fix the `careerStartDate` in Firebase Console:

### Option 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **nextwave-music-sim**
3. Click **Firestore Database** in the sidebar
4. Navigate to `players` collection
5. Find your player document (UID: `xjJFuMCEKMZwkI8uIP34Jl2bfQA3`)
6. Click on the document to edit it
7. Find the `careerStartDate` field
8. Change it to: **January 1, 2020** (or the current game-world date from gameSettings/globalTime)
9. Click **Update**
10. Logout and login to the app (or restart it)

### Option 2: Quick Fix - Delete and Recreate Character

1. Go to Firebase Console → Firestore
2. Delete your player document
3. Log out of the app
4. Log back in and go through onboarding again
5. Your age will now display correctly!

## How Age Works in NextWave

- **Game World Time**: January 1, 2020 (start) → present (based on 1 hour = 1 day)
- **Your Career Start**: When you create your character in game-world time
- **Your Age**: Selected age + (current game date - career start date) in years

### Example:
- You select age 18 during onboarding
- Game world is currently April 19, 2021
- You started your career on January 1, 2020
- Your character is now: 18 + 1.3 years = ~19 years old ✅

## Verification

After fixing:
1. Open the app and login
2. Go to Dashboard
3. Check the age displayed under your artist name
4. It should show your selected age (18) plus years passed in game-world

## For Future Players

All new players created after this fix will have the correct `careerStartDate` automatically set to the game-world date, so they won't experience this issue.

## Technical Details

### Files Changed:
- `lib/screens/onboarding_screen.dart` - Added GameTimeService import and game date fetch
- `lib/models/artist_stats.dart` - Added documentation for getCurrentAge()
- `fix_career_start_dates.dart` - Created script (compilation issues prevent running)

### Key Insight:
The game has TWO different time systems running:
1. **Real-World Time**: Used for scheduling (when you actually play)
2. **Game-World Time**: Used for in-game progression (your character's timeline)

The bug happened because we mixed these two time systems. Career dates must ALWAYS use game-world time! 🎮📅
