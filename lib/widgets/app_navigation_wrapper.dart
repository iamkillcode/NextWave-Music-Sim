import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/pending_practice.dart';
import '../screens/activity_hub_screen.dart';
import '../screens/music_hub_screen.dart';
import '../screens/the_scoop_screen.dart';
import '../screens/media_hub_screen.dart';
import '../screens/world_map_screen.dart';
import 'glassmorphic_bottom_nav.dart';

/// Wrapper widget that provides consistent bottom navigation across all screens
///
/// Usage:
/// ```dart
/// return AppNavigationWrapper(
///   currentIndex: 0, // Index of current screen
///   artistStats: artistStats,
///   onStatsUpdated: (stats) => setState(() => artistStats = stats),
///   child: YourScreenContent(),
/// );
/// ```
class AppNavigationWrapper extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final DateTime? currentGameDate;
  final List<PendingPractice>? pendingPractices;
  final Function(PendingPractice)? onPracticeStarted;
  final VoidCallback? onImmediateSave;
  final VoidCallback? onDebouncedSave;

  const AppNavigationWrapper({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.artistStats,
    required this.onStatsUpdated,
    this.currentGameDate,
    this.pendingPractices,
    this.onPracticeStarted,
    this.onImmediateSave,
    this.onDebouncedSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return GlassmorphicBottomNav(
      currentIndex: currentIndex,
      onTap: (index) {
        // Don't navigate if already on the selected screen
        if (index == currentIndex) return;

        Widget? targetScreen;

        switch (index) {
          case 0:
            // Home - pop back to dashboard
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          case 1:
            // Activity Hub
            targetScreen = ActivityHubScreen(
              artistStats: artistStats,
              onStatsUpdated: onStatsUpdated,
              currentGameDate: currentGameDate ?? DateTime.now(),
              pendingPractices: pendingPractices ?? [],
              onPracticeStarted: onPracticeStarted ?? (_) {},
            );
            break;
          case 2:
            // Music Hub
            targetScreen = MusicHubScreen(
              artistStats: artistStats,
              onStatsUpdated: onStatsUpdated,
            );
            break;
          case 3:
            // The Scoop
            targetScreen = TheScoopScreen(
              artistStats: artistStats,
              onStatsUpdated: onStatsUpdated,
            );
            break;
          case 4:
            // Media Hub
            targetScreen = MediaHubScreen(
              artistStats: artistStats,
              onStatsUpdated: onStatsUpdated,
            );
            break;
          case 5:
            // World Map
            targetScreen = WorldMapScreen(
              artistStats: artistStats,
              onStatsUpdated: onStatsUpdated,
            );
            break;
        }

        if (targetScreen != null) {
          // Replace current screen instead of pushing
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetScreen!),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Scoop'),
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Media'),
        BottomNavigationBarItem(icon: Icon(Icons.public), label: 'World'),
      ],
    );
  }
}
