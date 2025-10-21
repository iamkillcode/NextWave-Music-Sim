// Debug tool to verify monthly listeners calculation for Tunify and Maple Music
// Run this to see the discrepancy between current implementation and expected behavior

import '../models/artist_stats.dart';
import '../models/song.dart';

class MonthlyListenersVerification {
  /// Verify monthly listeners for both platforms and report discrepancies
  static Map<String, dynamic> verifyMonthlyListeners(ArtistStats artistStats) {
    // Get all released songs
    final releasedSongs = artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList();

    // Calculate total streams across all songs
    final totalStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );

    // Calculate last 7 days streams (available in Song model)
    final last7DaysStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.last7DaysStreams,
    );

    // Calculate last 1 day streams (available in Song model)
    final lastDayStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.lastDayStreams,
    );

    // ========================================
    // TUNIFY - Current Implementation
    // ========================================
    final tunifyCurrentMonthlyListeners = (totalStreams * 0.3).round();

    // TUNIFY - Proposed Fix (using last7DaysStreams as proxy)
    // Monthly ≈ 4.3 weeks worth of weekly streams
    final tunifyProposedMonthlyListeners = (last7DaysStreams * 4.3).round();

    // ========================================
    // MAPLE MUSIC - Current Implementation
    // ========================================
    final mapleMusicCurrentFollowers = (artistStats.fanbase * 0.4).round();

    // MAPLE MUSIC - Proposed Fix (same calculation as Tunify)
    final mapleMusicProposedMonthlyListeners =
        (last7DaysStreams * 4.3).round();

    // Calculate discrepancy percentages
    final tunifyDiscrepancyPercent = tunifyCurrentMonthlyListeners > 0
        ? ((tunifyProposedMonthlyListeners - tunifyCurrentMonthlyListeners) /
                tunifyCurrentMonthlyListeners *
                100)
            .toStringAsFixed(1)
        : 'N/A';

    return {
      'artistName': artistStats.name,
      'totalReleasedSongs': releasedSongs.length,
      'totalLifetimeStreams': totalStreams,
      'last7DaysStreams': last7DaysStreams,
      'lastDayStreams': lastDayStreams,
      'tunify': {
        'currentImplementation': {
          'label': 'Monthly Listeners (Current)',
          'value': tunifyCurrentMonthlyListeners,
          'formula': 'totalStreams * 0.3',
          'problem':
              'Uses lifetime streams, not actual monthly activity. Becomes inaccurate over time.',
        },
        'proposedFix': {
          'label': 'Monthly Listeners (Proposed)',
          'value': tunifyProposedMonthlyListeners,
          'formula': 'last7DaysStreams * 4.3',
          'benefit':
              'Uses recent activity (last 7 days) as proxy for monthly listeners. More accurate.',
        },
        'discrepancy': {
          'percentChange': tunifyDiscrepancyPercent,
          'absoluteDiff':
              tunifyProposedMonthlyListeners - tunifyCurrentMonthlyListeners,
        },
      },
      'mapleMusic': {
        'currentImplementation': {
          'label': 'Followers (Current)',
          'value': mapleMusicCurrentFollowers,
          'formula': 'fanbase * 0.4',
          'problem':
              'Shows follower count, NOT monthly listeners. Inconsistent with Tunify.',
        },
        'proposedFix': {
          'label': 'Monthly Listeners (Proposed)',
          'value': mapleMusicProposedMonthlyListeners,
          'formula': 'last7DaysStreams * 4.3',
          'benefit':
              'Consistent with Tunify. Shows actual listening activity, not just followers.',
        },
        'discrepancy': {
          'note':
              'Cannot compare followers to monthly listeners - different metrics',
          'currentlyMissing': 'Monthly listeners metric entirely',
        },
      },
      'recommendations': [
        '✅ Use last7DaysStreams * 4.3 as proxy for monthly listeners (30 days ≈ 4.3 weeks)',
        '✅ Apply same calculation to both Tunify and Maple Music for consistency',
        '✅ Keep followers as separate metric (can show both followers AND monthly listeners)',
        '⚠️ Future enhancement: Track daily streams for accurate 30-day rolling window',
      ],
    };
  }

  /// Print formatted verification report to console
  static void printVerificationReport(ArtistStats artistStats) {
    final report = verifyMonthlyListeners(artistStats);

    print('\n${'=' * 80}');
    print('🎵 MONTHLY LISTENERS VERIFICATION REPORT');
    print('=' * 80);
    print('\n📊 Artist: ${report['artistName']}');
    print('📀 Released Songs: ${report['totalReleasedSongs']}');
    print('🌍 Total Lifetime Streams: ${_formatNumber(report['totalLifetimeStreams'])}');
    print(
        '📈 Last 7 Days Streams: ${_formatNumber(report['last7DaysStreams'])}');
    print('📉 Last Day Streams: ${_formatNumber(report['lastDayStreams'])}');

    print('\n${'-' * 80}');
    print('🎵 TUNIFY (Spotify-like)');
    print('-' * 80);

    final tunify = report['tunify'] as Map<String, dynamic>;
    final tunifyCurrent =
        tunify['currentImplementation'] as Map<String, dynamic>;
    final tunifyProposed = tunify['proposedFix'] as Map<String, dynamic>;
    final tunifyDisc = tunify['discrepancy'] as Map<String, dynamic>;

    print('\n❌ Current Implementation:');
    print('   ${tunifyCurrent['label']}: ${_formatNumber(tunifyCurrent['value'])}');
    print('   Formula: ${tunifyCurrent['formula']}');
    print('   Problem: ${tunifyCurrent['problem']}');

    print('\n✅ Proposed Fix:');
    print('   ${tunifyProposed['label']}: ${_formatNumber(tunifyProposed['value'])}');
    print('   Formula: ${tunifyProposed['formula']}');
    print('   Benefit: ${tunifyProposed['benefit']}');

    print('\n📊 Discrepancy:');
    print('   Change: ${tunifyDisc['percentChange']}%');
    print(
        '   Absolute Difference: ${tunifyDisc['absoluteDiff'] >= 0 ? '+' : ''}${_formatNumber(tunifyDisc['absoluteDiff'])}');

    print('\n${'-' * 80}');
    print('🍎 MAPLE MUSIC (Apple Music-like)');
    print('-' * 80);

    final mapleMusic = report['mapleMusic'] as Map<String, dynamic>;
    final mapleCurrent =
        mapleMusic['currentImplementation'] as Map<String, dynamic>;
    final mapleProposed = mapleMusic['proposedFix'] as Map<String, dynamic>;
    final mapleDisc = mapleMusic['discrepancy'] as Map<String, dynamic>;

    print('\n❌ Current Implementation:');
    print('   ${mapleCurrent['label']}: ${_formatNumber(mapleCurrent['value'])}');
    print('   Formula: ${mapleCurrent['formula']}');
    print('   Problem: ${mapleCurrent['problem']}');

    print('\n✅ Proposed Fix:');
    print('   ${mapleProposed['label']}: ${_formatNumber(mapleProposed['value'])}');
    print('   Formula: ${mapleProposed['formula']}');
    print('   Benefit: ${mapleProposed['benefit']}');

    print('\n📊 Discrepancy:');
    print('   Note: ${mapleDisc['note']}');
    print('   Currently Missing: ${mapleDisc['currentlyMissing']}');

    print('\n${'-' * 80}');
    print('💡 RECOMMENDATIONS');
    print('-' * 80);
    final recommendations = report['recommendations'] as List<dynamic>;
    for (final rec in recommendations) {
      print('   $rec');
    }

    print('\n${'=' * 80}\n');
  }

  /// Format numbers with K, M, B suffixes
  static String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
