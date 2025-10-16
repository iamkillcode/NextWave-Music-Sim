# Quick Fix: Cloud Functions Permission Error

## Error Message
```
Failed to create function: Unable to retrieve the repository metadata.
Ensure that the Cloud Functions service account has 
'artifactregistry.repositories.list' and 'artifactregistry.repositories.get' permissions.
```

## Solution (2 minutes)

### Method 1: Using Google Cloud Console (Recommended)

1. **Go to IAM Settings:**
   - Visit: https://console.cloud.google.com/iam-admin/iam
   - Select project: **nextwave-music-sim**

2. **Find Service Account:**
   - Look for: `service-554743988495@gcf-admin-robot.iam.gserviceaccount.com`
   - Or look for: "**Cloud Functions Service Agent**"

3. **Add Role:**
   - Click the pencil icon (edit) next to that service account
   - Click **"ADD ANOTHER ROLE"**
   - Search for: **Artifact Registry Reader**
   - Select: `roles/artifactregistry.reader`
   - Click **SAVE**

4. **Retry Deployment:**
```powershell
firebase deploy --only functions
```

---

### Method 2: Using gcloud CLI (Faster)

```powershell
# Run this command
gcloud projects add-iam-policy-binding nextwave-music-sim `
  --member="serviceAccount:service-554743988495@gcf-admin-robot.iam.gserviceaccount.com" `
  --role="roles/artifactregistry.reader"

# Then deploy
firebase deploy --only functions
```

---

### Method 3: Automatic (Let Firebase handle it)

Sometimes Firebase can automatically grant permissions if you have Owner/Editor role:

```powershell
# Ensure you're logged in as project owner
firebase login --reauth

# Try deploying again
firebase deploy --only functions
```

---

## Why This Happens

**Background:**
- Firebase Cloud Functions now uses **Artifact Registry** instead of **Container Registry**
- The Cloud Functions service account needs permission to read from Artifact Registry
- This is a one-time setup per project

**After fixing once:**
- All future deployments will work
- No need to grant permissions again

---

## Expected Successful Output

After fixing permissions:
```
✔ functions[dailyGameUpdate]: Successful create operation.
✔ functions[triggerDailyUpdate]: Successful create operation.
✔ functions[catchUpMissedDays]: Successful create operation.
✔ Deploy complete!

Functions deployed:
  - dailyGameUpdate (scheduled: 0 0 * * *)
  - triggerDailyUpdate (https callable)
  - catchUpMissedDays (https callable)
```

---

## Next Steps After Successful Deployment

1. **Verify Functions:**
```powershell
firebase functions:list
```

2. **Check Logs:**
```powershell
firebase functions:log
```

3. **Test Manual Trigger:**
From your Flutter app:
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('triggerDailyUpdate')
  .call();
print('Success: ${result.data}');
```

---

*Issue: Artifact Registry Permissions*  
*Fix Time: 2 minutes*  
*Happens Once: Yes (one-time setup)*
