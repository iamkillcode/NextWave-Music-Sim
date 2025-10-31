import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../widgets/app_navigation_wrapper.dart';
import '../services/chat_service.dart';
import 'tunify_screen.dart';
import 'maple_music_screen.dart';
import 'echox_screen.dart';
import 'player_directory_screen.dart';
import 'nexttube_home_screen.dart';
import 'conversation_list_screen.dart';
import 'certifications_screen.dart';

class MediaHubScreen extends StatelessWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const MediaHubScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return AppNavigationWrapper(
      currentIndex: 4, // Media Hub is index 4
      artistStats: artistStats,
      onStatsUpdated: onStatsUpdated,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text(
            'Media Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview at top
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceDark,
                      AppTheme.surfaceElevated,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded,
                            color: AppTheme.accentBlue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Your Reach',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Total Streams',
                          _formatNumber(_getTotalStreams()),
                          Icons.play_arrow_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatColumn(
                          'Followers',
                          _formatNumber(artistStats.fanbase),
                          Icons.people_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatColumn(
                          'Releases',
                          '${artistStats.songs.where((s) => s.state == SongState.released).length}',
                          Icons.album_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Streaming Platforms Section
              const Row(
                children: [
                  Icon(Icons.music_note_rounded,
                      color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Streaming Platforms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App Grid for Streaming
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideScreen ? 4 : 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildAppIcon(
                    context,
                    name: 'Tunify',
                    icon: Icons.music_note_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.successGreen, Color(0xFF1ED760)],
                    ),
                    badge: _formatNumber(_getTunifyStreams()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TunifyScreen(
                            artistStats: artistStats,
                            onStatsUpdated: onStatsUpdated,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAppIcon(
                    context,
                    name: 'Maple Music',
                    icon: Icons.album_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFC3C44), AppTheme.neonPurple],
                    ),
                    badge: _formatNumber(_getMapleMusicStreams()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapleMusicScreen(
                            artistStats: artistStats,
                            onStatsUpdated: onStatsUpdated,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAppIcon(
                    context,
                    name: 'NexTube',
                    icon: Icons.ondemand_video_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF0000), AppTheme.errorRed],
                    ),
                    badge: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NextTubeHomeScreen(
                            artistStats: artistStats,
                            onStatsUpdated: onStatsUpdated,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAppIcon(
                    context,
                    name: 'Players',
                    icon: Icons.people_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.accentBlue, AppTheme.neonPurple],
                    ),
                    badge: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerDirectoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Social Media Section
              const Row(
                children: [
                  Icon(Icons.public_rounded,
                      color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Social Media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App Grid for Social
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideScreen ? 4 : 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildAppIcon(
                    context,
                    name: 'EchoX',
                    icon: Icons.tag_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)],
                    ),
                    badge: '${artistStats.fanbase}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EchoXScreen(
                            artistStats: artistStats,
                            onStatsUpdated: onStatsUpdated,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAppIconWithUnreadBadge(
                    context,
                    name: 'StarChat',
                    icon: Icons.chat_bubble_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConversationListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Misc Section
              const Row(
                children: [
                  Icon(Icons.dashboard_rounded,
                      color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Misc',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App Grid for Misc
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideScreen ? 4 : 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildAppIcon(
                    context,
                    name: 'Certifications',
                    icon: Icons.emoji_events_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    badge: _getCertifiedSongsCount(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CertificationsScreen(
                            artistStats: artistStats,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ), // Close body SingleChildScrollView
      ), // Close Scaffold
    ); // Close AppNavigationWrapper
  }

  Widget _buildAppIcon(
    BuildContext context, {
    required String name,
    required IconData icon,
    required Gradient gradient,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Icon
          Stack(
            children: [
              // Main Icon Container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              // Badge (notification-style indicator)
              if (badge.isNotEmpty)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.errorRed, Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppTheme.backgroundDark, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
          const SizedBox(height: 8),
          // App Name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIconWithUnreadBadge(
    BuildContext context, {
    required String name,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final chatService = ChatService();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Icon with real-time unread badge
          StreamBuilder<int>(
            stream: chatService.streamTotalUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  // Main Icon Container
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  // Badge (real-time unread count)
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.errorRed, Color(0xFFFF8E53)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.backgroundDark, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // App Name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _getTotalStreams() {
    return artistStats.songs
        .where((song) => song.state == SongState.released)
        .fold<int>(0, (sum, song) => sum + song.streams);
  }

  int _getTunifyStreams() {
    // Tunify has 85% of total streams (most popular platform)
    return (_getTotalStreams() * 0.85).round();
  }

  int _getMapleMusicStreams() {
    // Maple Music has 65% of total streams (premium platform)
    return (_getTotalStreams() * 0.65).round();
  }

  String _getCertifiedSongsCount() {
    final certifiedCount = artistStats.songs
        .where((song) =>
            song.state == SongState.released &&
            song.highestCertification != 'none')
        .length;
    return certifiedCount > 0 ? certifiedCount.toString() : '';
  }

  String _formatNumber(int number) {
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
