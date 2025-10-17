# Settings Screen Updates

## New Features Added

### 1. **Avatar Upload** 📸
- **Location**: Account section (top of settings)
- **Feature**: Click the camera icon on the avatar to upload a custom image
- **Implementation**: 
  - Uses browser file picker (works on web platform)
  - Converts image to data URL and stores in Firestore
  - Avatar persists across sessions
  - Falls back to initial letter avatar if no image uploaded

### 2. **No Email Display** 📧
- **Location**: Account section
- **Change**: Email field now shows "No email" instead of the user's email
- **Purpose**: Privacy and simplified account display

### 3. **Delete Account** 🗑️
- **Location**: Danger Zone section (bottom of settings)
- **Feature**: Permanently delete user account and all associated data
- **Safety**: 
  - Shows confirmation dialog with warning message
  - Explains that deletion is permanent and irreversible
  - Deletes both Firestore player data and Firebase Auth account
  - Redirects to auth screen after deletion

## Updated UI Elements

### Account Card
```
┌─────────────────────────────────┐
│  [Avatar with]  Artist Name     │
│  [camera icon]  No email        │
└─────────────────────────────────┘
```

### Danger Zone Card
```
┌─────────────────────────────────┐
│         [LOGOUT]                │
│     [DELETE ACCOUNT]            │
└─────────────────────────────────┘
```

## Technical Details

### Avatar Storage
- **Storage Method**: Data URL stored in Firestore
- **Field Name**: `avatarUrl` in players collection
- **Image Format**: Accepts any image format (png, jpg, gif, etc.)
- **Size**: Limited by browser and Firestore document size

### Delete Account Flow
1. User clicks "DELETE ACCOUNT" button
2. Confirmation dialog appears with warning
3. If confirmed:
   - Deletes player document from Firestore
   - Deletes Firebase Authentication account
   - Navigates to auth screen

## Usage

### Upload Avatar
1. Open Settings screen
2. Click the small camera icon on the bottom-right of the avatar
3. Select an image from your device
4. Image uploads and displays immediately

### Delete Account
1. Scroll to bottom of Settings screen
2. Click "DELETE ACCOUNT" button (red)
3. Read the warning carefully
4. Click "DELETE FOREVER" to confirm (or CANCEL to abort)
5. Account and all data will be permanently deleted

## Error Handling
- Avatar upload failures show error snackbar
- Account deletion failures show error snackbar with suggestion to re-login
- All operations wrapped in try-catch blocks

## Next Steps
- Consider adding image size validation
- Consider adding avatar cropping functionality
- Consider adding "Download my data" before account deletion
- Consider adding re-authentication before account deletion (security best practice)


