import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing Spotlight Charts
/// - Spotlight 200: Albums only
/// - Spotlight Hot 100: Singles only, ranks by last 7 days streams
class SpotlightChartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SpotlightChartService();

  /// Get Spotlight 200 - Albums only
  /// Returns top 200 albums sorted by total streams
  Future<List<Map<String, dynamic>>> getSpotlight200({int limit = 200}) async {
    try {
      print('🌟 Fetching Spotlight 200 (Albums)');

      final playersSnapshot =
          await _firestore.collection('players').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Spotlight 200 query timeout');
        },
      );

      List<Map<String, dynamic>> allAlbums = [];

      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;

        if (songs != null) {
          for (var songData in songs) {
            final songMap = Map<String, dynamic>.from(songData);
            final isAlbum = songMap['isAlbum'] as bool? ?? false;
            final songState = songMap['state'] ?? 'unknown';
            final totalStreams =
                songMap['streams'] ?? songMap['totalStreams'] ?? 0;

            // Only include released albums
            if (songState == 'released' && isAlbum && totalStreams > 0) {
              allAlbums.add({
                'title': songMap['title'] ?? 'Untitled',
                'artist': artistName,
                'artistId': doc.id,
                'genre': songMap['genre'] ?? 'Unknown',
                'quality': songMap['quality'] ?? 0,
                'totalStreams': totalStreams,
                'likes': songMap['likes'] ?? 0,
                'releaseDate': songMap['releaseDate'],
                'state': songState,
                'isAlbum': true,
              });
            }
          }
        }
      }

      // Sort by total streams
      allAlbums.sort((a, b) =>
          (b['totalStreams'] as int).compareTo(a['totalStreams'] as int));

      final topAlbums = allAlbums.take(limit).toList();
      print('✅ Found ${topAlbums.length} albums on Spotlight 200');

      return topAlbums;
    } catch (e) {
      print('❌ Error fetching Spotlight 200: $e');
      return [];
    }
  }

  /// Get Spotlight Hot 100 - Singles only
  /// Ranks ALL singles by their streams gained in the last 7 in-game days
  /// Chart effectively "resets" every 7 days as older streams drop off
  Future<List<Map<String, dynamic>>> getSpotlightHot100(
      {int limit = 100}) async {
    try {
      print('🔥 Fetching Spotlight Hot 100 (Singles)');

      final playersSnapshot =
          await _firestore.collection('players').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Spotlight Hot 100 query timeout');
        },
      );

      List<Map<String, dynamic>> allSingles = [];

      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;

        if (songs != null) {
          for (var songData in songs) {
            final songMap = Map<String, dynamic>.from(songData);
            final isAlbum = songMap['isAlbum'] as bool? ?? false;
            final songState = songMap['state'] ?? 'unknown';
            final last7DaysStreams = songMap['last7DaysStreams'] as int? ?? 0;
            final totalStreams =
                songMap['streams'] ?? songMap['totalStreams'] ?? 0;

            // Only include released singles with streams in the last 7 days
            if (songState == 'released' && !isAlbum && last7DaysStreams > 0) {
              allSingles.add({
                'title': songMap['title'] ?? 'Untitled',
                'artist': artistName,
                'artistId': doc.id,
                'genre': songMap['genre'] ?? 'Unknown',
                'quality': songMap['quality'] ?? 0,
                'totalStreams': totalStreams,
                'last7DaysStreams': last7DaysStreams,
                'likes': songMap['likes'] ?? 0,
                'releaseDate': songMap['releaseDate'],
                'state': songState,
                'isAlbum': false,
              });
            }
          }
        }
      }

      // Sort by last 7 days streams (this creates the "reset" effect)
      allSingles.sort((a, b) => (b['last7DaysStreams'] as int)
          .compareTo(a['last7DaysStreams'] as int));

      final topSingles = allSingles.take(limit).toList();
      print('✅ Found ${topSingles.length} singles on Spotlight Hot 100');

      return topSingles;
    } catch (e) {
      print('❌ Error fetching Spotlight Hot 100: $e');
      return [];
    }
  }

  /// Get chart position for a song in Spotlight 200
  Future<int?> getSpotlight200Position(
      String songTitle, String artistId) async {
    try {
      final chart = await getSpotlight200(limit: 200);

      for (int i = 0; i < chart.length; i++) {
        if (chart[i]['title'] == songTitle &&
            chart[i]['artistId'] == artistId) {
          return i + 1;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting Spotlight 200 position: $e');
      return null;
    }
  }

  /// Get chart position for a song in Spotlight Hot 100
  Future<int?> getHot100Position(String songTitle, String artistId) async {
    try {
      final chart = await getSpotlightHot100(limit: 100);

      for (int i = 0; i < chart.length; i++) {
        if (chart[i]['title'] == songTitle &&
            chart[i]['artistId'] == artistId) {
          return i + 1;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting Hot 100 position: $e');
      return null;
    }
  }

  /// Check if a song is currently on any Spotlight chart
  Future<Map<String, int?>> getSpotlightPositions(
      String songTitle, String artistId, bool isAlbum) async {
    final positions = <String, int?>{};

    if (isAlbum) {
      positions['spotlight200'] =
          await getSpotlight200Position(songTitle, artistId);
    } else {
      positions['hot100'] = await getHot100Position(songTitle, artistId);
    }

    return positions;
  }
}
