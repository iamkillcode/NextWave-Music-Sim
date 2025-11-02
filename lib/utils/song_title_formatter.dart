import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';
import '../models/collaboration.dart';

/// Utility class for formatting song titles with featuring artists
class SongTitleFormatter {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the display title for a song, including featuring artist if it's a collab
  /// Example: "Still Dre (feat. Snoop Dogg)"
  static Future<String> getDisplayTitle(
    Song song,
    String currentUserId,
  ) async {
    try {
      // Check if this song is part of a collaboration
      final collabQuery = await _firestore
          .collection('collaborations')
          .where('songId', isEqualTo: song.id)
          .where('status',
              whereIn: ['accepted', 'recording', 'recorded', 'released'])
          .limit(1)
          .get();

      if (collabQuery.docs.isEmpty) {
        // Not a collab song, return original title
        return song.title;
      }

      final collab = Collaboration.fromJson(collabQuery.docs.first.data());

      // Determine who is the featuring artist
      // If current user is the primary artist, show featuring artist name
      // If current user is the featuring artist, show primary artist name
      final featuringName = collab.primaryArtistId == currentUserId
          ? collab.featuringArtistName
          : collab.primaryArtistName;

      return '${song.title} (feat. $featuringName)';
    } catch (e) {
      print('Error formatting song title: $e');
      return song.title;
    }
  }

  /// Get display title synchronously from collaboration data (when you already have the collab)
  static String getDisplayTitleFromCollab(
    String songTitle,
    Collaboration collab,
    String currentUserId,
  ) {
    final featuringName = collab.primaryArtistId == currentUserId
        ? collab.featuringArtistName
        : collab.primaryArtistName;

    return '$songTitle (feat. $featuringName)';
  }

  /// Get a simplified display for song lists that shows both artists
  /// Example: "Still Dre - Dr. Dre feat. Snoop Dogg"
  static String getFullDisplayTitle(
    String songTitle,
    Collaboration collab,
  ) {
    return '$songTitle - ${collab.primaryArtistName} feat. ${collab.featuringArtistName}';
  }
}
