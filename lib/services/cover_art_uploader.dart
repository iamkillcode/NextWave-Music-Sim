import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Helper service for uploading cover art to Firebase Storage
class CoverArtUploader {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Picks an image from gallery and uploads it to Firebase Storage
  /// Returns the public download URL or null if cancelled/failed
  static Future<String?> pickAndUploadCoverArt({
    required String userId,
    required String songId,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
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
      return await uploadCoverArtBytes(
        imageBytes: imageBytes,
        userId: userId,
        songId: songId,
      );
    } catch (e) {
      print('Error picking and uploading cover art: $e');
      rethrow;
    }
  }

  /// Uploads image bytes to Firebase Storage
  /// Returns the public download URL
  static Future<String> uploadCoverArtBytes({
    required Uint8List imageBytes,
    required String userId,
    required String songId,
  }) async {
    try {
      // Generate unique filename with hash to prevent caching issues
      final hash = md5.convert(imageBytes).toString().substring(0, 8);
      final fileName = '${songId}_$hash.jpg';

      // Create storage reference
      final storageRef = _storage.ref().child('cover-art/$userId/$fileName');

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      // Upload the file
      final uploadTask = await storageRef.putData(imageBytes, metadata);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('Cover art uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading cover art bytes: $e');
      rethrow;
    }
  }

  /// Deletes a cover art file from Firebase Storage
  /// Useful when replacing or removing album art
  static Future<void> deleteCoverArt(String storageUrl) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(storageUrl);
      if (!uri.host.contains('firebasestorage.googleapis.com')) {
        throw Exception('Invalid Firebase Storage URL');
      }

      // Get reference from URL and delete
      final ref = _storage.refFromURL(storageUrl);
      await ref.delete();
      print('Cover art deleted successfully: $storageUrl');
    } catch (e) {
      print('Error deleting cover art: $e');
      // Don't rethrow - deletion failures shouldn't block other operations
    }
  }
}
