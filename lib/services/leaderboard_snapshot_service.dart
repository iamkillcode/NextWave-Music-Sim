import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Normalize song snapshot entries (both modern `rankings` and legacy `entries`).
///
/// This is a pure helper so it can be unit-tested. It accepts the raw list
/// from Firestore and returns a list of maps in the canonical shape the UI
/// expects.
List<Map<String, dynamic>> normalizeSongSnapshotEntries(
  List<dynamic> rawList, {
  int limit = 100,
  String usedField = 'rankings',
}) {
  return rawList.take(limit).map((entry) {
    final item = Map<String, dynamic>.from(entry as Map);

    // Normalize legacy key names to the modern keys the UI expects
    final position =
        item['position'] ?? item['rank'] ?? item['rankPosition'] ?? 0;
    final songId = item['songId'] ?? item['id'] ?? item['song_id'] ?? '';
    final title =
        item['title'] ?? item['songName'] ?? item['song_name'] ?? 'Untitled';
    final artist = item['artist'] ??
        item['artistName'] ??
        item['artist_name'] ??
        'Unknown Artist';
    final artistId = item['artistId'] ?? item['artist_id'] ?? '';
    final streams = item['streams'] ??
        item['weeklyStreams'] ??
        item['last7DaysStreams'] ??
        0;
    final totalStreams = item['totalStreams'] ?? item['total_streams'] ?? 0;
    final coverArt =
        item['coverArtUrl'] ?? item['coverArt'] ?? item['cover'] ?? null;
    final movement = item['movement'] ?? item['movementValue'] ?? 0;
    final lastWeekPosition =
        item['lastWeekPosition'] ?? item['lastWeekPos'] ?? null;
    final weeksOnChart = item['weeksOnChart'] ?? item['weeks'] ?? 1;

    if (usedField == 'entries') {
      // legacy snapshot - log for debugging
      print('ℹ️ Using legacy snapshot format (entries) for song: $title');
    }

    return {
      'position': position,
      'songId': songId,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'genre': item['genre'] ?? 'Unknown',
      'streams': streams, // Regional streams for this region
      'totalStreams': totalStreams,
      'coverArtUrl': coverArt,
      'isNPC': item['isNPC'] ?? false,
      'movement': movement, // Chart movement from last week
      'lastWeekPosition': lastWeekPosition,
      'weeksOnChart': weeksOnChart,
    };
  }).toList();
}

/// Normalize artist snapshot entries (modern and legacy shapes).
List<Map<String, dynamic>> normalizeArtistSnapshotEntries(
  List<dynamic> rawList, {
  int limit = 100,
  String usedField = 'rankings',
}) {
  return rawList.take(limit).map((entry) {
    final item = Map<String, dynamic>.from(entry as Map);

    final position = item['position'] ?? item['rank'] ?? 0;
    final artistId = item['artistId'] ?? item['artist_id'] ?? '';
    final artistName = item['artistName'] ??
        item['artist_name'] ??
        item['name'] ??
        'Unknown Artist';
    final streams = item['streams'] ?? item['weeklyStreams'] ?? 0;
    final songCount = item['songCount'] ?? item['releasedSongs'] ?? 0;
    final movement = item['movement'] ?? 0;
    final lastWeekPosition =
        item['lastWeekPosition'] ?? item['lastWeekPos'] ?? null;
    final weeksOnChart = item['weeksOnChart'] ?? item['weeks'] ?? 1;

    if (usedField == 'entries') {
      print(
          'ℹ️ Using legacy snapshot format (entries) for artist: $artistName');
    }

    return {
      'position': position,
      'artistId': artistId,
      'artistName': artistName,
      'streams': streams, // Regional total streams
      'songCount': songCount,
      'isNPC': item['isNPC'] ?? false,
      'movement': movement,
      'lastWeekPosition': lastWeekPosition,
      'weeksOnChart': weeksOnChart,
    };
  }).toList();
}

/// Service for querying weekly leaderboard snapshots
///
/// The Cloud Function generates weekly snapshots with proper regional rankings.
/// This service queries those pre-computed snapshots for better performance
/// and accurate regional competition.
class LeaderboardSnapshotService {
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

  /// Get the latest song chart for a specific region or global
  ///
  /// [region] - Region code (e.g., 'usa', 'europe') or 'global'
  /// [limit] - Number of results to return (default: 100)
  ///
  /// Returns list of ranked songs with movement tracking
  Future<List<Map<String, dynamic>>> getLatestSongChart({
    required String region,
    int limit = 100,
  }) async {
    try {
      print('📊 Fetching latest $region song chart from snapshots');

      // Query for the most recent snapshot for this region
      // Document naming: songs_global_YYYYWW or songs_usa_YYYYWW
      final snapshot = await _firestore
          .collection('leaderboard_history')
          .where('type', isEqualTo: 'songs')
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Chart snapshot query timeout');
        },
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ No chart snapshots found for $region');
        return [];
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Support both new and legacy snapshot formats. New snapshots use
      // `rankings`, older/manual scripts used `entries` with different keys.
      List<dynamic>? rawList = data['rankings'] as List<dynamic>?;
      var usedField = 'rankings';
      if (rawList == null) {
        rawList = data['entries'] as List<dynamic>?;
        usedField = 'entries';
      }

      if (rawList == null) {
        print('⚠️ No rankings/entries in snapshot');
        return [];
      }

      // Normalize snapshot entries into the canonical shape
      final chartData = normalizeSongSnapshotEntries(rawList,
          limit: limit, usedField: usedField);

      print(
          '✅ Loaded ${chartData.length} songs from $region snapshot (week ${data['weekId']})');

      // Debug: Print first 3 songs to verify movement data
      if (chartData.isNotEmpty) {
        print('🔍 Sample data from snapshot:');
        for (var i = 0; i < chartData.length && i < 3; i++) {
          final song = chartData[i];
          print(
              '  #${i + 1}: ${song['title']} - movement=${song['movement']}, lastWeek=${song['lastWeekPosition']}, weeksOnChart=${song['weeksOnChart']}');
        }
      }

      return chartData;
    } catch (e) {
      // Check if error is due to missing index (indexes are building)
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index')) {
        print(
            '⚠️ Firestore index is still building. Charts will be available once index is ready.');
        print('   This usually takes 5-10 minutes after deployment.');
        print(
            '   Chart will fall back to daily/real-time data in the meantime.');
      } else {
        print('❌ Error fetching song chart snapshot: $e');
      }
      return [];
    }
  }

  /// Get the latest artist chart for a specific region or global
  ///
  /// [region] - Region code (e.g., 'usa', 'europe') or 'global'
  /// [limit] - Number of results to return (default: 100)
  ///
  /// Returns list of ranked artists with movement tracking
  Future<List<Map<String, dynamic>>> getLatestArtistChart({
    required String region,
    int limit = 100,
  }) async {
    try {
      print('📊 Fetching latest $region artist chart from snapshots');

      final snapshot = await _firestore
          .collection('leaderboard_history')
          .where('type', isEqualTo: 'artists')
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Artist chart snapshot query timeout');
        },
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ No artist chart snapshots found for $region');
        return [];
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Support both new and legacy snapshot formats. New snapshots use
      // `rankings`, older/manual scripts used `entries` with different keys.
      List<dynamic>? rawList = data['rankings'] as List<dynamic>?;
      var usedField = 'rankings';
      if (rawList == null) {
        rawList = data['entries'] as List<dynamic>?;
        usedField = 'entries';
      }

      if (rawList == null) {
        print('⚠️ No rankings/entries in snapshot');
        return [];
      }

      // Normalize snapshot entries into the canonical shape
      final chartData = normalizeArtistSnapshotEntries(rawList,
          limit: limit, usedField: usedField);

      print(
          '✅ Loaded ${chartData.length} artists from $region snapshot (week ${data['weekId']})');
      return chartData;
    } catch (e) {
      // Check if error is due to missing index (indexes are building)
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index')) {
        print(
            '⚠️ Firestore index is still building. Charts will be available once index is ready.');
        print('   This usually takes 5-10 minutes after deployment.');
        print(
            '   Chart will fall back to daily/real-time data in the meantime.');
      } else {
        print('❌ Error fetching artist chart snapshot: $e');
      }
      return [];
    }
  }

  /// Get chart position for a specific song in a region
  ///
  /// Returns the position (1-based) or null if not charting
  Future<int?> getSongChartPosition({
    required String songId,
    required String region,
  }) async {
    try {
      final chart = await getLatestSongChart(region: region, limit: 200);

      for (final entry in chart) {
        if (entry['songId'] == songId) {
          return entry['position'] as int;
        }
      }

      return null; // Not charting
    } catch (e) {
      print('❌ Error getting song chart position: $e');
      return null;
    }
  }

  /// Get chart position for a specific artist in a region
  ///
  /// Returns the position (1-based) or null if not charting
  Future<int?> getArtistChartPosition({
    required String artistId,
    required String region,
  }) async {
    try {
      final chart = await getLatestArtistChart(region: region, limit: 200);

      for (final entry in chart) {
        if (entry['artistId'] == artistId) {
          return entry['position'] as int;
        }
      }

      return null; // Not charting
    } catch (e) {
      print('❌ Error getting artist chart position: $e');
      return null;
    }
  }

  /// Get all regional positions for a song
  ///
  /// Returns map of region -> position for all regions where song is charting
  Future<Map<String, int>> getSongRegionalPositions({
    required String songId,
  }) async {
    final positions = <String, int>{};

    // Check global chart
    final globalPos =
        await getSongChartPosition(songId: songId, region: 'global');
    if (globalPos != null) {
      positions['global'] = globalPos;
    }

    // Check all regional charts
    for (var region in regions) {
      final position =
          await getSongChartPosition(songId: songId, region: region);
      if (position != null && position <= 100) {
        positions[region] = position;
      }
    }

    return positions;
  }

  /// Check if a song is in Top 10 for any region
  Future<bool> isTopTenAnywhere(String songId) async {
    for (var region in ['global', ...regions]) {
      final position =
          await getSongChartPosition(songId: songId, region: region);
      if (position != null && position <= 10) {
        return true;
      }
    }
    return false;
  }

  /// Get chart summary for the current week
  ///
  /// Returns metadata about available charts (week ID, timestamp, etc.)
  Future<Map<String, dynamic>?> getCurrentWeekInfo() async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard_history')
          .where('type', isEqualTo: 'songs')
          .where('region', isEqualTo: 'global')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      return {
        'weekId': data['weekId'],
        'timestamp': (data['timestamp'] as Timestamp).toDate(),
        'totalSongs': (data['rankings'] as List?)?.length ?? 0,
      };
    } catch (e) {
      print('❌ Error getting week info: $e');
      return null;
    }
  }

  /// Format stream count for display
  String formatStreams(int streams) {
    if (streams >= 1000000000) {
      return '${(streams / 1000000000).toStringAsFixed(1)}B';
    } else if (streams >= 1000000) {
      return '${(streams / 1000000).toStringAsFixed(1)}M';
    } else if (streams >= 1000) {
      return '${(streams / 1000).toStringAsFixed(1)}K';
    }
    return streams.toString();
  }

  /// Get movement indicator icon
  String getMovementIcon(int movement) {
    if (movement > 0) return '↑';
    if (movement < 0) return '↓';
    return '—';
  }

  /// Get movement color
  Color getMovementColor(int movement) {
    if (movement > 0) return const Color(0xFF4CAF50); // Green
    if (movement < 0) return const Color(0xFFF44336); // Red
    return const Color(0xFF9E9E9E); // Gray
  }
}
