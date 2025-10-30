import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/artist_stats.dart';
import '../models/pending_practice.dart';
import '../widgets/app_navigation_wrapper.dart';
import '../theme/app_theme.dart';
import 'practice_screen.dart';
import 'unified_charts_screen.dart';
import 'side_hustle_screen.dart';
import 'viralwave_screen.dart';

class ActivityHubScreen extends StatelessWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final DateTime currentGameDate;
  final List<PendingPractice> pendingPractices;
  final Function(PendingPractice) onPracticeStarted;

  const ActivityHubScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
    required this.currentGameDate,
    required this.pendingPractices,
    required this.onPracticeStarted,
  });

  String _formatMoney(int amount) {
    final formatter = NumberFormat('#,###');
    return '\$${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final isSmallScreen = screenWidth < 450; // Increased from 400 to support 430x932 screens

    return AppNavigationWrapper(
      currentIndex: 1, // Activity Hub is index 1
      artistStats: artistStats,
      onStatsUpdated: onStatsUpdated,
      currentGameDate: currentGameDate,
      pendingPractices: pendingPractices,
      onPracticeStarted: onPracticeStarted,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: Text(
            '⚡ Activity Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.backgroundElevated, AppTheme.backgroundDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDefault, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.flash_on,
                            color: AppTheme.neonGreen,
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grow Your Career',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Practice, promote, compete, and earn',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    // Stats row
                    Row(
                      children: [
                        _buildQuickStat('⚡', '${artistStats.energy}', 'Energy', isSmallScreen),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildQuickStat('💰', _formatMoney(artistStats.money), 'Money', isSmallScreen),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildQuickStat(
                          '🎵',
                          '${artistStats.songs.length}',
                          'Songs',
                          isSmallScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 32),

              // Apps grid
              Text(
                'Choose an Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideScreen ? 4 : 2,
                crossAxisSpacing: isSmallScreen ? 12 : 16,
                mainAxisSpacing: isSmallScreen ? 12 : 16,
                childAspectRatio: 1.0,
                children: [
                  _buildAppCard(
                    context,
                    name: 'Practice',
                    emoji: '🎸',
                    gradient: LinearGradient(
                      colors: [AppTheme.warningOrange, AppTheme.warningOrange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    badge: '15 ⚡',
                    description: 'Improve your skills',
                    isSmallScreen: isSmallScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PracticeScreen(
                            artistStats: artistStats,
                            onStatsUpdated: onStatsUpdated,
                            pendingPractices: pendingPractices,
                            onPracticeStarted: onPracticeStarted,
                            currentDate: currentGameDate,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAppCard(
                    context,
                    name: 'Spotlight Charts',
                    emoji: '📊',
                    gradient: AppTheme.neonGreenGradient,
                    badge: 'Top 100',
                    description: 'View leaderboards',
                    isSmallScreen: isSmallScreen,
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
                    gradient: LinearGradient(
                      colors: [AppTheme.warningOrange, AppTheme.warningOrange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    badge: artistStats.activeSideHustle != null
                        ? 'Active'
                        : 'Jobs',
                    description: 'Earn extra money',
                    isSmallScreen: isSmallScreen,
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
                    gradient: AppTheme.neonPurpleGradient,
                    badge: 'Promote',
                    description: 'Boost your music',
                    isSmallScreen: isSmallScreen,
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
      ), // Close Scaffold
    ); // Close AppNavigationWrapper
  }

  Widget _buildQuickStat(String emoji, String value, String label, bool isSmallScreen) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderDefault, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: isSmallScreen ? 10 : 11,
              ),
              overflow: TextOverflow.ellipsis,
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
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDefault, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: isSmallScreen ? 60 : 70,
                        height: isSmallScreen ? 60 : 70,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
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
                            style: TextStyle(fontSize: isSmallScreen ? 30 : 36),
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 4 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.surfaceDark,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // App name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: isSmallScreen ? 10 : 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
