import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

/// Helper service for uploading crew symbols/logos to Firebase Storage
class CrewSymbolUploader {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Picks an image from gallery and uploads it as crew symbol
  /// Returns the public download URL or null if cancelled/failed
  static Future<String?> pickAndUploadCrewSymbol({
    required String crewId,
    double maxWidth = 512,
    double maxHeight = 512,
    int imageQuality = 90,
  }) async {
    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Upload to Storage and return URL
      return await uploadCrewSymbolBytes(
        imageBytes: imageBytes,
        crewId: crewId,
      );
    } catch (e) {
      print('Error picking and uploading crew symbol: $e');
      rethrow;
    }
  }

  /// Uploads image bytes to Firebase Storage as crew symbol
  /// Returns the public download URL
  static Future<String> uploadCrewSymbolBytes({
    required Uint8List imageBytes,
    required String crewId,
  }) async {
    try {
      // Generate unique filename with hash to prevent caching issues
      final hash = md5.convert(imageBytes).toString().substring(0, 8);
      final fileName = '${crewId}_$hash.jpg';

      // Create storage reference in crew-symbols folder
      final storageRef = _storage.ref().child('crew-symbols/$fileName');

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      // Upload the file
      final uploadTask = await storageRef.putData(imageBytes, metadata);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Crew symbol uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading crew symbol bytes: $e');
      rethrow;
    }
  }

  /// Deletes a crew symbol file from Firebase Storage
  /// Useful when replacing or removing crew logo
  static Future<void> deleteCrewSymbol(String storageUrl) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(storageUrl);
      if (!uri.host.contains('firebasestorage.googleapis.com')) {
        throw Exception('Invalid Firebase Storage URL');
      }

      // Get reference from URL and delete
      final ref = _storage.refFromURL(storageUrl);
      await ref.delete();
      print('✅ Crew symbol deleted successfully: $storageUrl');
    } catch (e) {
      print('❌ Error deleting crew symbol: $e');
      // Don't rethrow - deletion failures shouldn't block other operations
    }
  }
}
