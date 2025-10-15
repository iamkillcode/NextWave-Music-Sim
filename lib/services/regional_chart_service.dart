import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';

/// Service for managing regional music charts
/// 
/// Provides functionality to:
/// - Get top songs per region
/// - Check chart positions
/// - Track chart history
class RegionalChartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// All supported regions
  static const List<String> regions = [
    'usa',
    'europe',
    'uk',
    'asia',
    'africa',
    'latin_america',
    'oceania',
  ];

  /// Region display names
  static const Map<String, String> regionNames = {
    'usa': 'United States',
    'europe': 'Europe',
    'uk': 'United Kingdom',
    'asia': 'Asia',
    'africa': 'Africa',
    'latin_america': 'Latin America',
    'oceania': 'Oceania',
  };

  /// Region emoji flags
  static const Map<String, String> regionFlags = {
    'usa': '🇺🇸',
    'europe': '🇪🇺',
    'uk': '🇬🇧',
    'asia': '🇯🇵',
    'africa': '🇳🇬',
    'latin_america': '🇧🇷',
    'oceania': '🇦🇺',
  };

  /// Get top songs for a specific region
  /// 
  /// [region] - Region code (e.g., 'usa', 'africa')
  /// [limit] - Number of songs to return (default: 10)
  /// 
  /// Returns list of songs sorted by regional streams (descending)
  Future<List<Map<String, dynamic>>> getTopSongsByRegion(
    String region, {
    int limit = 10,
  }) async {
    try {
      print('📊 Fetching top $limit songs for region: $region');

      // Query all players to get their songs
      // Note: In production, you'd want a dedicated 'songs' collection
      final playersSnapshot = await _firestore
          .collection('players')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Chart query timeout');
            },
          );

      List<Map<String, dynamic>> allSongs = [];

      // Extract all songs from all players
      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;

        if (songs != null) {
          for (var songData in songs) {
            final songMap = Map<String, dynamic>.from(songData);
            
            // Check if song has streams in this region
            final regionalStreams = songMap['regionalStreams'] as Map<dynamic, dynamic>?;
            if (regionalStreams != null && regionalStreams.containsKey(region)) {
              final streams = (regionalStreams[region] as num?)?.toInt() ?? 0;
              
              if (streams > 0) {
                allSongs.add({
                  'title': songMap['title'] ?? 'Untitled',
                  'artist': artistName,
                  'artistId': doc.id,
                  'genre': songMap['genre'] ?? 'Unknown',
                  'quality': songMap['quality'] ?? 0,
                  'regionalStreams': streams,
                  'totalStreams': songMap['totalStreams'] ?? 0,
                  'likes': songMap['likes'] ?? 0,
                  'releaseDate': songMap['releaseDate'],
                  'state': songMap['state'] ?? 'unknown',
                });
              }
            }
          }
        }
      }

      // Sort by regional streams (descending)
      allSongs.sort((a, b) => 
        (b['regionalStreams'] as int).compareTo(a['regionalStreams'] as int)
      );

      // Return top N songs
      final topSongs = allSongs.take(limit).toList();
      print('✅ Found ${topSongs.length} charting songs in $region');
      
      return topSongs;
    } catch (e) {
      print('❌ Error fetching regional chart: $e');
      return [];
    }
  }

  /// Get chart position for a specific song in a region
  /// 
  /// Returns the position (1-based) or null if not charting
  Future<int?> getChartPosition(
    String songTitle,
    String artistId,
    String region,
  ) async {
    try {
      final topSongs = await getTopSongsByRegion(region, limit: 100);
      
      for (int i = 0; i < topSongs.length; i++) {
        if (topSongs[i]['title'] == songTitle && 
            topSongs[i]['artistId'] == artistId) {
          return i + 1; // 1-based position
        }
      }
      
      return null; // Not charting
    } catch (e) {
      print('❌ Error getting chart position: $e');
      return null;
    }
  }

  /// Get all regions where a song is charting (Top 100)
  Future<Map<String, int>> getSongChartPositions(
    String songTitle,
    String artistId,
  ) async {
    final positions = <String, int>{};

    for (var region in regions) {
      final position = await getChartPosition(songTitle, artistId, region);
      if (position != null && position <= 100) {
        positions[region] = position;
      }
    }

    return positions;
  }

  /// Check if a song is in Top 10 for any region
  Future<bool> isTopTenAnywhere(String songTitle, String artistId) async {
    for (var region in regions) {
      final position = await getChartPosition(songTitle, artistId, region);
      if (position != null && position <= 10) {
        return true;
      }
    }
    return false;
  }

  /// Get the region where a song performs best
  Future<String?> getTopRegionForSong(Song song) async {
    if (song.regionalStreams.isEmpty) return null;

    // Find region with most streams
    String topRegion = '';
    int maxStreams = 0;

    song.regionalStreams.forEach((region, streams) {
      if (streams > maxStreams) {
        maxStreams = streams;
        topRegion = region;
      }
    });

    return topRegion.isNotEmpty ? topRegion : null;
  }

  /// Get summary of an artist's chart performance
  Future<Map<String, dynamic>> getArtistChartSummary(String artistId) async {
    try {
      final doc = await _firestore.collection('players').doc(artistId).get();
      
      if (!doc.exists) {
        return {
          'topTenHits': 0,
          'chartingRegions': 0,
          'highestPosition': null,
          'chartingSongs': 0,
        };
      }

      final data = doc.data()!;
      final songs = data['songs'] as List<dynamic>?;

      if (songs == null || songs.isEmpty) {
        return {
          'topTenHits': 0,
          'chartingRegions': 0,
          'highestPosition': null,
          'chartingSongs': 0,
        };
      }

      int topTenHits = 0;
      Set<String> chartingRegions = {};
      int? highestPosition;
      int chartingSongs = 0;

      for (var songData in songs) {
        final songMap = Map<String, dynamic>.from(songData);
        final title = songMap['title'] ?? '';
        
        for (var region in regions) {
          final position = await getChartPosition(title, artistId, region);
          
          if (position != null) {
            chartingSongs++;
            chartingRegions.add(region);
            
            if (position <= 10) {
              topTenHits++;
            }
            
            if (highestPosition == null || position < highestPosition) {
              highestPosition = position;
            }
          }
        }
      }

      return {
        'topTenHits': topTenHits,
        'chartingRegions': chartingRegions.length,
        'highestPosition': highestPosition,
        'chartingSongs': chartingSongs,
      };
    } catch (e) {
      print('❌ Error getting artist chart summary: $e');
      return {
        'topTenHits': 0,
        'chartingRegions': 0,
        'highestPosition': null,
        'chartingSongs': 0,
      };
    }
  }

  /// Get global chart (all regions combined)
  Future<List<Map<String, dynamic>>> getGlobalChart({int limit = 100}) async {
    try {
      print('🌍 Fetching global top $limit songs');

      final playersSnapshot = await _firestore
          .collection('players')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Global chart query timeout');
            },
          );

      List<Map<String, dynamic>> allSongs = [];

      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;

        if (songs != null) {
          for (var songData in songs) {
            final songMap = Map<String, dynamic>.from(songData);
            final totalStreams = songMap['totalStreams'] ?? 0;

            if (totalStreams > 0) {
              allSongs.add({
                'title': songMap['title'] ?? 'Untitled',
                'artist': artistName,
                'artistId': doc.id,
                'genre': songMap['genre'] ?? 'Unknown',
                'quality': songMap['quality'] ?? 0,
                'totalStreams': totalStreams,
                'likes': songMap['likes'] ?? 0,
                'releaseDate': songMap['releaseDate'],
                'state': songMap['state'] ?? 'unknown',
              });
            }
          }
        }
      }

      // Sort by total streams
      allSongs.sort((a, b) => 
        (b['totalStreams'] as int).compareTo(a['totalStreams'] as int)
      );

      final topSongs = allSongs.take(limit).toList();
      print('✅ Found ${topSongs.length} songs on global chart');
      
      return topSongs;
    } catch (e) {
      print('❌ Error fetching global chart: $e');
      return [];
    }
  }

  /// Calculate chart score based on positions across all regions
  /// Higher score = better overall chart performance
  int calculateChartScore(Map<String, int> positions) {
    if (positions.isEmpty) return 0;

    int score = 0;
    positions.forEach((region, position) {
      // Points: 100 for #1, decreasing by 1 per position
      // Top 10 gets bonus points
      int points = Math.max(0, 101 - position);
      if (position <= 10) {
        points += 50; // Bonus for Top 10
      }
      if (position == 1) {
        points += 100; // Extra bonus for #1
      }
      score += points;
    });

    return score;
  }

  /// Get trending songs (high velocity in regional streams)
  /// This would track songs with rapid growth
  Future<List<Map<String, dynamic>>> getTrendingSongsByRegion(
    String region, {
    int limit = 10,
  }) async {
    // TODO: Implement trending logic based on stream velocity
    // For now, return same as top songs
    // In future, track daily changes and sort by growth rate
    return await getTopSongsByRegion(region, limit: limit);
  }
}

class Math {
  static int max(int a, int b) => a > b ? a : b;
}
