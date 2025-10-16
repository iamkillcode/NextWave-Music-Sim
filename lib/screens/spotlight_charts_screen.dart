import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/spotlight_chart_service.dart';

class SpotlightChartsScreen extends StatefulWidget {
  const SpotlightChartsScreen({super.key});

  @override
  State<SpotlightChartsScreen> createState() => _SpotlightChartsScreenState();
}

class _SpotlightChartsScreenState extends State<SpotlightChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SpotlightChartService _chartService;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chartService = SpotlightChartService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'Spotlight Charts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
              icon: Icon(Icons.album),
              text: 'Spotlight 200\n(Albums)',
            ),
            Tab(
              icon: Icon(Icons.whatshot),
              text: 'Hot 100\n(Singles)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpotlight200(),
          _buildHot100(),
        ],
      ),
    );
  }

  Widget _buildSpotlight200() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chartService.getSpotlight200(limit: 200),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading chart',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No albums charting yet',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final position = index + 1;
            final isCurrentUser = album['artistId'] == _currentUserId;

            return _buildChartEntry(
              position: position,
              songData: album,
              chartColor: const Color(0xFFFFD700), // Gold for Spotlight 200
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildHot100() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chartService.getSpotlightHot100(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF4500),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading chart',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final singles = snapshot.data ?? [];

        if (singles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.whatshot, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No singles charting yet',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chart resets every 7 game days',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Info banner about reset
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF4500).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFF4500), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hot 100 ranks singles by streams gained in the last 7 game days',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: singles.length,
                itemBuilder: (context, index) {
                  final single = singles[index];
                  final position = index + 1;
                  final isCurrentUser = single['artistId'] == _currentUserId;

                  return _buildChartEntry(
                    position: position,
                    songData: single,
                    chartColor: const Color(0xFFFF4500), // Orange-red for Hot 100
                    isCurrentUser: isCurrentUser,
                    isHot100: true, // Show 7-day streams instead of total
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartEntry({
    required int position,
    required Map<String, dynamic> songData,
    required Color chartColor,
    required bool isCurrentUser,
    bool isHot100 = false,
  }) {
    final songTitle = songData['title'] as String? ?? 'Untitled';
    final artistName = songData['artist'] as String? ?? 'Unknown Artist';
    final genre = songData['genre'] as String? ?? 'Unknown';
    // For Hot 100, show 7-day streams; for Spotlight 200, show total streams
    final streams = isHot100 
        ? (songData['last7DaysStreams'] as int? ?? 0)
        : (songData['totalStreams'] as int? ?? 0);

    // Medal colors for top 3
    Color? medalColor;
    IconData? medalIcon;
    if (position == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events;
    } else if (position == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events;
    } else if (position == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? chartColor.withOpacity(0.15)
            : const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser 
            ? Border.all(color: chartColor, width: 2)
            : null,
        boxShadow: [
          if (position <= 3)
            BoxShadow(
              color: medalColor!.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCurrentUser ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your song "$songTitle" is #$position!'),
                backgroundColor: chartColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Position/Medal
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: position <= 3 ? medalColor : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: position <= 3
                        ? Icon(medalIcon, color: Colors.white, size: 28)
                        : Text(
                            '#$position',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isCurrentUser) ...[
                            const Icon(Icons.person, color: Color(0xFF00D9FF), size: 14),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              artistName,
                              style: TextStyle(
                                color: isCurrentUser ? const Color(0xFF00D9FF) : Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getGenreColor(genre).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: _getGenreColor(genre),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.music_note, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            _formatStreams(streams),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trending indicator for top 10
                if (position <= 10)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.trending_up,
                      color: chartColor,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'pop': return Colors.pink;
      case 'ballad': return Colors.purple;
      case 'edm': return Colors.cyan;
      case 'rock': return Colors.red;
      case 'alternative': return Colors.orange;
      case 'r&b': return Colors.amber;
      case 'hip hop': return Colors.yellow;
      case 'rap': return Colors.lime;
      case 'trap': return Colors.green;
      case 'drill': return Colors.teal;
      case 'afrobeat': return Colors.deepOrange;
      case 'country': return Colors.brown;
      case 'jazz': return Colors.indigo;
      case 'reggae': return Colors.lightGreen;
      default: return Colors.grey;
    }
  }

  String _formatStreams(int streams) {
    if (streams >= 1000000) {
      return '${(streams / 1000000).toStringAsFixed(1)}M';
    } else if (streams >= 1000) {
      return '${(streams / 1000).toStringAsFixed(1)}K';
    }
    return streams.toString();
  }
}
