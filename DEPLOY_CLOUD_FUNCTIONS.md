# Deploy Cloud Functions Guide

## Problem
The admin dashboard is not showing because the Cloud Functions haven't been deployed to Firebase yet. The `checkAdminStatus` function exists locally but isn't running on Firebase servers.

## Solution: Deploy Cloud Functions

### Prerequisites
1. Install Firebase CLI globally:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

### Deploy Cloud Functions

1. Navigate to your project root:
```bash
cd /home/artemis/Codebase/NextWave-Music-Sim
```

2. Install function dependencies:
```bash
cd functions
npm install
cd ..
```

3. Deploy all Cloud Functions:
```bash
firebase deploy --only functions
```

This will deploy ALL functions including:
- `checkAdminStatus` (admin verification)
- `sendGiftToPlayer` (admin gifts)
- `secureSongCreation` (anti-cheat)
- `secureStatUpdate` (stat validation)
- `dailyGameUpdate` (automatic game progression)
- `weeklyLeaderboardUpdate` (charts)
- And many more...

### Expected Output
```
✔  functions: Finished running predeploy script.
i  functions: preparing codebase default for deployment
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudbuild.googleapis.com is enabled
✔  functions: required API cloudfunctions.googleapis.com is enabled
i  functions: uploading functions archive...
✔  functions: functions archive uploaded successfully
i  functions: creating Node.js 18 function checkAdminStatus(us-central1)...
i  functions: creating Node.js 18 function sendGiftToPlayer(us-central1)...
[... more functions ...]
✔  functions[checkAdminStatus(us-central1)]: Successful create operation.
✔  functions[sendGiftToPlayer(us-central1)]: Successful create operation.
[... more functions ...]

✔  Deploy complete!
```

## After Deployment

1. **Wait 1-2 minutes** for functions to fully activate
2. **Restart your Flutter app** to clear any cached errors
3. **Login with admin account** (UID: xjJFuMCEKMZwkI8uIP34Jl2bfQA3)
4. **Go to Settings** - you should now see the cyan Admin Dashboard card
5. **Click "OPEN ADMIN DASHBOARD"** to access admin features

## Alternative: Use Firebase Console

If you can't deploy via CLI, you can:

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: nextwave-music-sim
3. Go to "Functions" in the left sidebar
4. You should see if functions are deployed or not
5. If no functions are deployed, you MUST use the CLI to deploy them

## Troubleshooting

### Error: "Command not found: firebase"
```bash
npm install -g firebase-tools
```

### Error: "Not logged in"
```bash
firebase login
```

### Error: "No project active"
```bash
firebase use nextwave-music-sim
```

### Error: "Permission denied"
Make sure you have Owner or Editor role in Firebase Console:
1. Go to Firebase Console
2. Settings (gear icon) → Users and permissions
3. Check your role

### Functions deploy but still getting errors
1. Check Firebase Console → Functions → Logs for error messages
2. Make sure Firestore security rules allow function access
3. Wait 2-3 minutes for functions to fully activate
4. Clear app cache and restart

## Quick Deploy Command

For fast deployment after making changes:
```bash
cd /home/artemis/Codebase/NextWave-Music-Sim && firebase deploy --only functions
```

## Verify Deployment

After deployment, check Firebase Console:
1. Go to Functions section
2. You should see ~20+ functions listed
3. Each should show status: "Active"
4. Click on `checkAdminStatus` to see details

## Important Notes

- First deployment takes 5-10 minutes
- Subsequent deployments take 2-3 minutes
- Functions run in `us-central1` region
- Make sure your app uses `FirebaseFunctions.instanceFor(region: 'us-central1')`
- Admin functions require authentication
- Cost: Firebase free tier includes 2M invocations/month (plenty for this app)

## Security Notes

After deployment, the following security features will be active:
- ✅ Server-side admin validation
- ✅ Anti-cheat protection for all game actions
- ✅ Secure stat updates with validation
- ✅ Server-authoritative game progression
- ✅ Automatic daily/weekly updates via scheduled functions
