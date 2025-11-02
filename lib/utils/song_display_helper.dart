import '../models/song.dart';

/// Helper class to format song display titles
class SongDisplayHelper {
  /// Formats a song title with featuring artist if it's a collaboration
  /// Example: "Still Dre" becomes "Still Dre (feat. Snoop Dogg)"
  static String getFormattedTitle(Song song) {
    if (song.metadata.containsKey('featuringArtist') &&
        song.metadata['featuringArtist'] != null) {
      final featuringArtist = song.metadata['featuringArtist'] as String;
      return '${song.title} (feat. $featuringArtist)';
    }
    return song.title;
  }

  /// Checks if a song is a collaboration
  static bool isCollaboration(Song song) {
    return song.metadata.containsKey('isCollaboration') &&
        song.metadata['isCollaboration'] == true;
  }

  /// Gets the featuring artist name from a collaboration song
  static String? getFeaturingArtist(Song song) {
    return song.metadata['featuringArtist'] as String?;
  }

  /// Gets the featuring artist ID from a collaboration song
  static String? getFeaturingArtistId(Song song) {
    return song.metadata['featuringArtistId'] as String?;
  }
}
