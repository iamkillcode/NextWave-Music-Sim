import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import 'practice_screen.dart';
import 'unified_charts_screen.dart';
import 'side_hustle_screen.dart';
import 'viralwave_screen.dart';

class ActivityHubScreen extends StatelessWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final DateTime currentGameDate;

  const ActivityHubScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
    required this.currentGameDate,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          '⚡ Activity Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2329), Color(0xFF0D1117)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF30363D), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A84FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Color(0xFF0A84FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grow Your Career',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Practice, promote, compete, and earn',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _buildQuickStat('⚡', '${artistStats.energy}', 'Energy'),
                      const SizedBox(width: 16),
                      _buildQuickStat('💰', '\$${artistStats.money}', 'Money'),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        '🎵',
                        '${artistStats.songs.length}',
                        'Songs',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apps grid
            const Text(
              'Choose an Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWideScreen ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildAppCard(
                  context,
                  name: 'Practice',
                  emoji: '🎸',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  badge: '15 ⚡',
                  description: 'Improve your skills',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticeScreen(
                          artistStats: artistStats,
                          onStatsUpdated: onStatsUpdated,
                        ),
                      ),
                    );
                  },
                ),
                _buildAppCard(
                  context,
                  name: 'Spotlight Charts',
                  emoji: '📊',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  badge: 'Top 100',
                  description: 'View leaderboards',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnifiedChartsScreen(),
                      ),
                    );
                  },
                ),
                _buildAppCard(
                  context,
                  name: 'Side Hustle',
                  emoji: '💼',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD60A), Color(0xFFFF9F0A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  badge: artistStats.activeSideHustle != null
                      ? 'Active'
                      : 'Jobs',
                  description: 'Earn extra money',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SideHustleScreen(
                          artistStats: artistStats,
                          onStatsUpdate: onStatsUpdated,
                          currentGameDate: currentGameDate,
                        ),
                      ),
                    );
                  },
                ),
                _buildAppCard(
                  context,
                  name: 'ViralWave',
                  emoji: '📱',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF1744)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  badge: 'Promote',
                  description: 'Boost your music',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViralWaveScreen(
                          artistStats: artistStats,
                          onStatsUpdated: onStatsUpdated,
                          currentGameDate: currentGameDate,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context, {
    required String name,
    required String emoji,
    required Gradient gradient,
    required String badge,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363D), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF453A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF161B22),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // App name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
