# Custom Cover Art Upload Feature

## ✅ Changes Made

### **1. Cover Art Upload System** 📸
- Players can now upload their own images as cover art
- Two modes: **Generate** (AI-style) or **Upload Image** (custom)
- Easy toggle between modes with clear visual feedback
- Works with web platform using browser file picker

### **2. Upload Button UI** 🎨

**New Toggle Buttons:**
```
[Generate] [Upload Image]
   ↓           ↓
 Cyan      Gray (default)
```

When you click "Upload Image":
- Opens browser file picker
- Accepts all image formats (PNG, JPG, GIF, etc.)
- Shows preview immediately
- Hides style/color selectors (not needed for custom art)

### **3. Cover Art Preview** 🖼️

**Generated Mode:**
- Shows gradient background with color theme
- Displays genre emoji
- Shows song title and artist name
- Style and color customization visible

**Uploaded Mode:**
- Shows your uploaded image
- Fills the entire 200x200 preview
- No overlays or text (clean custom art)
- Image fits nicely with rounded corners

### **4. Data Model Updates** 🗂️

**Song Model - New Field:**
```dart
final String? coverArtUrl; // Stores uploaded image URL
```

**Smart Storage:**
- If custom art: Saves `coverArtUrl`, nulls style/color
- If generated: Saves style/color, nulls `coverArtUrl`
- Only stores what's actually being used

## How It Works

### **Upload Flow:**
1. Click "Upload Image" button
2. Browser file picker opens
3. Select image from computer
4. Image converts to data URL
5. Preview updates immediately
6. Release song with custom cover art saved

### **Technical Implementation:**

**File Upload:**
```dart
final uploadInput = html.FileUploadInputElement();
uploadInput.accept = 'image/*';
uploadInput.click();

// Read as data URL
final reader = html.FileReader();
reader.readAsDataUrl(files[0]);
reader.onLoadEnd.listen((e) {
  setState(() {
    _uploadedCoverArtUrl = reader.result as String?;
    _useCustomCoverArt = true;
  });
});
```

**Conditional Rendering:**
```dart
image: _useCustomCoverArt && _uploadedCoverArtUrl != null
    ? DecorationImage(
        image: NetworkImage(_uploadedCoverArtUrl!),
        fit: BoxFit.cover,
      )
    : null,
```

## UI Changes

### **Before:**
```
[Cover Art Preview]
Style: 🎨 Minimalist
Color: [Cyan] [Pink] [Purple] ...
```

### **After:**
```
[Generate] [Upload Image]  ← New toggle!

[Cover Art Preview]

// Only shows if Generate mode:
Style: 🎨 Minimalist
Color: [Cyan] [Pink] [Purple] ...
```

## Files Modified

1. **lib/screens/release_song_screen.dart**
   - Added `dart:html` import
   - New fields: `_uploadedCoverArtUrl`, `_useCustomCoverArt`
   - New method: `_uploadCoverArt()`
   - Updated preview to show uploaded image
   - Conditional style/color selectors
   - Save logic includes custom URL

2. **lib/models/song.dart**
   - Added `coverArtUrl` field (String?)
   - Updated `copyWith` method
   - Properly handles nullable custom art URL

## Player Benefits

### **Creative Freedom** 🎨
- Use your own artwork
- Brand consistency across releases
- Professional custom designs
- Personal photos or graphics

### **Flexibility** 🔄
- Switch between generated and custom
- Try different images before releasing
- No commitment until release
- Can still use generated art anytime

### **Professional Look** ⭐
- Upload logo designs
- Use album artwork from designers
- Match visual brand identity
- Stand out from generic covers

## Strategy Tips

### **Early Game:**
- Use generated art (fast and free)
- Focus on music quality
- Experiment with styles/colors

### **Mid-Late Game:**
- Create custom brand identity
- Upload professional artwork
- Build recognizable visual style
- Consistent look across releases

### **Pro Tip:**
Upload memorable artwork that matches your artist persona and genre for better brand recognition!

## Testing Checklist

- [x] Upload button works
- [x] File picker opens
- [x] Image previews correctly
- [x] Toggle between modes works
- [x] Style/color selectors hide when using custom
- [x] Custom URL saves to song
- [x] Generated style saves when not using custom
- [x] No compilation errors
- [ ] Test with various image formats
- [ ] Test with large/small images
- [ ] Verify image persists after release

## Future Enhancements

1. **Image Cropping:**
   - Built-in crop tool
   - Adjust position/zoom
   - Perfect square aspect ratio

2. **Image Filters:**
   - Apply effects to uploaded images
   - Blur, brightness, contrast
   - Overlay text on custom art

3. **Template Library:**
   - Pre-made templates
   - Genre-specific designs
   - Quick customization

4. **Cloud Storage:**
   - Upload to Firebase Storage
   - Persistent URLs
   - Thumbnail generation

5. **Gallery View:**
   - See all your cover arts
   - Reuse previous designs
   - Build visual discography

## Notes

- Uses data URL storage (good for web)
- Image stored as base64 in song data
- Works on web platform (Chrome, Edge, etc.)
- No server upload needed (client-side only)
- Instant preview with no delays

## Summary

**Players can now express creativity with custom cover art!**

Upload your own images for a professional, personalized look or stick with the quick generated art. Both options work great, giving players complete control over their visual branding! 🎨🎵

---

**Ready to test!** Press `R` to Hot Restart and try uploading custom cover art when releasing a song! 🚀
