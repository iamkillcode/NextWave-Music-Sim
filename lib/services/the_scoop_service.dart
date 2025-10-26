import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_item.dart';
import 'dart:math';
import 'unified_chart_service.dart';
import 'game_time_service.dart';

class TheScoopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  final UnifiedChartService _charts = UnifiedChartService();

  /// Get latest news items
  Stream<List<NewsItem>> getNewsStream({int limit = 50}) {
    return _firestore
        .collection('news')
        // Keep ordering by real timestamp for index compatibility; display uses game time
        // Order primarily by in-game time; use real timestamp as tiebreaker/fallback
        .orderBy('gameTimestamp', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get news items for a specific category
  Stream<List<NewsItem>> getNewsByCategory(NewsCategory category,
      {int limit = 20}) {
    return _firestore
        .collection('news')
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('gameTimestamp', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Create a news item
  Future<void> createNewsItem(NewsItem newsItem) async {
    // Stamp game time for The Scoop posts
    DateTime? gameDate;
    try {
      gameDate = await GameTimeService().getCurrentGameDate();
    } catch (_) {}

    final data = newsItem.toJson();
    if (gameDate != null) {
      data['gameTimestamp'] = Timestamp.fromDate(gameDate);
    }

    await _firestore.collection('news').add(data);
  }

  /// Generate news for chart movement
  Future<void> generateChartNews({
    required String artistName,
    required String songTitle,
    required int position,
    required int? previousPosition,
    String? artistId,
  }) async {
    String headline;
    String body;

    if (previousPosition == null) {
      // New entry
      headline = '🎵 "$songTitle" Debuts at #$position!';
      body =
          '$artistName enters the Spotlight Charts with "$songTitle" at position #$position. The track is already making waves in the music industry!';
    } else if (position < previousPosition) {
      final movement = previousPosition - position;
      headline = '📈 $artistName Climbs to #$position!';
      body =
          '"$songTitle" by $artistName surges $movement spots to #$position on the Spotlight Charts. The hit single continues its impressive run!';
    } else if (position == 1) {
      headline = '👑 $artistName Claims #1 Spot!';
      body =
          '"$songTitle" by $artistName reaches the top of the Spotlight Charts! This marks a career milestone for the artist.';
    } else {
      headline = '⭐ $artistName Holds Strong at #$position';
      body =
          '"$songTitle" maintains its position on the charts. $artistName\'s fanbase continues to show unwavering support!';
    }

    final newsItem = NewsItem(
      id: '',
      headline: headline,
      body: body,
      category: NewsCategory.chartMovement,
      timestamp: DateTime.now(),
      relatedArtistId: artistId,
      relatedArtistName: artistName,
      metadata: {
        'songTitle': songTitle,
        'position': position,
        'previousPosition': previousPosition,
      },
    );

    await createNewsItem(newsItem);
  }

  /// Generate news for new release
  Future<void> generateReleaseNews({
    required String artistName,
    required String title,
    required bool isAlbum,
    String? artistId,
  }) async {
    final type = isAlbum ? 'Album' : 'Single';
    final emoji = isAlbum ? '💿' : '🎵';

    final headlines = [
      '$emoji $artistName Drops New $type "$title"',
      '🎉 Breaking: $artistName Releases "$title"',
      '⚡ New Music Alert: $artistName\'s "$title" Is Here!',
    ];

    final bodies = [
      '$artistName has just released "$title", their latest $type. Fans are already streaming it worldwide!',
      'The wait is over! $artistName\'s highly anticipated $type "$title" is now available on all platforms.',
      '$artistName surprises fans with the release of "$title". The new $type is expected to dominate the charts!',
    ];

    final newsItem = NewsItem(
      id: '',
      headline: headlines[_random.nextInt(headlines.length)],
      body: bodies[_random.nextInt(bodies.length)],
      category: NewsCategory.newRelease,
      timestamp: DateTime.now(),
      relatedArtistId: artistId,
      relatedArtistName: artistName,
      metadata: {
        'title': title,
        'isAlbum': isAlbum,
      },
    );

    await createNewsItem(newsItem);
  }

  /// Generate news for milestones
  Future<void> generateMilestoneNews({
    required String artistName,
    required String milestone,
    required String description,
    String? artistId,
  }) async {
    final newsItem = NewsItem(
      id: '',
      headline: '🎉 $artistName Achieves $milestone!',
      body: description,
      category: NewsCategory.milestone,
      timestamp: DateTime.now(),
      relatedArtistId: artistId,
      relatedArtistName: artistName,
      metadata: {
        'milestone': milestone,
      },
    );

    await createNewsItem(newsItem);
  }

  /// Generate drama/gossip news
  Future<void> generateDramaNews({
    required String headline,
    required String body,
    String? artistId,
    String? artistName,
  }) async {
    final newsItem = NewsItem(
      id: '',
      headline: '🔥 $headline',
      body: body,
      category: NewsCategory.drama,
      timestamp: DateTime.now(),
      relatedArtistId: artistId,
      relatedArtistName: artistName,
    );

    await createNewsItem(newsItem);
  }

  /// Generate random industry news (for flavor)
  Future<void> generateRandomIndustryNews() async {
    final newsTemplates = [
      {
        'headline': '🎭 Industry Insiders Predict Next Big Genre Trend',
        'body':
            'Music analysts suggest that fusion genres are set to dominate the charts in upcoming months. Artists experimenting with unique sounds are gaining traction.',
        'category': NewsCategory.drama,
      },
      {
        'headline': '💰 Streaming Numbers Hit All-Time High',
        'body':
            'The music industry celebrates record-breaking streaming numbers this quarter. Independent artists are leading the charge in innovation.',
        'category': NewsCategory.milestone,
      },
      {
        'headline': '🎤 Virtual Concert Revolution Continues',
        'body':
            'More artists are embracing virtual performances, reaching global audiences like never before. The future of live music is evolving.',
        'category': NewsCategory.collaboration,
      },
      {
        'headline': '⭐ Critics Praise New Wave of Underground Talent',
        'body':
            'Music critics are spotlighting emerging artists who are breaking conventional boundaries. The underground scene is more vibrant than ever.',
        'category': NewsCategory.drama,
      },
    ];

    final template = newsTemplates[_random.nextInt(newsTemplates.length)];
    final category = NewsCategory.values.firstWhere(
      (e) => e.toString() == 'NewsCategory.${template['category']}',
      orElse: () => NewsCategory.drama,
    );

    final newsItem = NewsItem(
      id: '',
      headline: template['headline'] as String,
      body: template['body'] as String,
      category: category,
      timestamp: DateTime.now(),
    );

    await createNewsItem(newsItem);
  }

  /// Format timestamp for display
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  // ===== Scoop Content (Charts-driven) =====

  Future<List<Map<String, dynamic>>> getTodaysHits({int limit = 4}) async {
    // Top daily singles (global)
    final songs = await _charts.getSongsChart(
      period: 'daily',
      type: 'singles',
      region: 'global',
      limit: limit,
    );
    return songs;
  }

  Future<Map<String, dynamic>?> getWeeklyTopSong() async {
    final list = await _charts.getSongsChart(
      period: 'weekly',
      type: 'singles',
      region: 'global',
      limit: 1,
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<Map<String, dynamic>?> getWeeklyTopAlbum() async {
    final list = await _charts.getSongsChart(
      period: 'weekly',
      type: 'albums',
      region: 'global',
      limit: 1,
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<Map<String, dynamic>?> getWeeklyTopArtist() async {
    final list = await _charts.getArtistsChart(
      period: 'weekly',
      region: 'global',
      limit: 1,
      sortBy: 'streams',
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<Map<String, dynamic>>> getNewThisWeek({int limit = 12}) async {
    // We use daily singles (which include releaseDate) and filter to last 7 days
    final daily = await _charts.getSongsChart(
      period: 'daily',
      type: 'singles',
      region: 'global',
      limit: 200,
    );

    // Use in-game time for the cutoff window
    final currentGame = await GameTimeService().getCurrentGameDate();
    final cutoff = currentGame.subtract(const Duration(days: 7));
    List<Map<String, dynamic>> recent = [];
    for (final s in daily) {
      final rd = s['releaseDate'];
      DateTime? d;
      if (rd is Timestamp) d = rd.toDate();
      if (rd is DateTime) d = rd;
      if (d != null && d.isAfter(cutoff)) {
        recent.add(s);
      }
    }
    // Fallback: if none found, just take first N of daily
    if (recent.isEmpty) {
      recent = daily.take(limit).toList();
    }
    return recent.take(limit).toList();
  }

  String shortStreams(int n) => _charts.formatStreams(n);

  /// Highest debut on this week's singles chart (requires snapshot fields)
  Future<Map<String, dynamic>?> getHighestDebutSong() async {
    final list = await _charts.getSongsChart(
      period: 'weekly',
      type: 'singles',
      region: 'global',
      limit: 200,
    );
    if (list.isEmpty) return null;

    // Only compute if snapshot keys are present
    final hasSnapshotKeys = list.first.containsKey('lastWeekPosition');
    if (!hasSnapshotKeys) return null;

    final debuts = list.where((e) {
      final lwp = e['lastWeekPosition'];
      if (lwp == null) return true; // new entry
      if (lwp is int) return lwp > 100 || lwp <= 0; // off-chart last week
      return false;
    }).toList();

    if (debuts.isEmpty) return null;
    debuts.sort((a, b) =>
        (a['position'] as int? ?? 999).compareTo(b['position'] as int? ?? 999));
    return debuts.first;
  }

  /// Biggest upward movement on this week's singles chart (requires snapshot fields)
  Future<Map<String, dynamic>?> getBiggestMoverSong() async {
    final list = await _charts.getSongsChart(
      period: 'weekly',
      type: 'singles',
      region: 'global',
      limit: 200,
    );
    if (list.isEmpty) return null;
    final hasSnapshotKeys = list.first.containsKey('movement');
    if (!hasSnapshotKeys) return null;

    // Positive movement means climbed up (lower position number).
    final movers = list.where((e) {
      final m = e['movement'];
      return m is int && m > 0;
    }).toList();
    if (movers.isEmpty) return null;

    movers.sort((a, b) =>
        ((b['movement'] as int?) ?? 0).compareTo((a['movement'] as int?) ?? 0));
    return movers.first;
  }
}
