import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/regional_chart_service.dart';

class RegionalChartsScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const RegionalChartsScreen({
    super.key,
    required this.artistStats,
  });

  @override
  State<RegionalChartsScreen> createState() => _RegionalChartsScreenState();
}

class _RegionalChartsScreenState extends State<RegionalChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RegionalChartService _chartService = RegionalChartService();
  
  // Region data
  final List<Map<String, dynamic>> _regions = [
    {'id': 'global', 'name': 'Global', 'flag': '🌍', 'color': Color(0xFF9C27B0)},
    {'id': 'usa', 'name': 'USA', 'flag': '🇺🇸', 'color': Color(0xFF2196F3)},
    {'id': 'europe', 'name': 'Europe', 'flag': '🇪🇺', 'color': Color(0xFF4CAF50)},
    {'id': 'uk', 'name': 'UK', 'flag': '🇬🇧', 'color': Color(0xFFF44336)},
    {'id': 'asia', 'name': 'Asia', 'flag': '🇯🇵', 'color': Color(0xFFFF9800)},
    {'id': 'africa', 'name': 'Africa', 'flag': '🇳🇬', 'color': Color(0xFF00BCD4)},
    {'id': 'latin_america', 'name': 'Latin America', 'flag': '🇧🇷', 'color': Color(0xFF8BC34A)},
    {'id': 'oceania', 'name': 'Oceania', 'flag': '🇦🇺', 'color': Color(0xFFE91E63)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _regions.length, vsync: this);
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
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Regional Charts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00D9FF),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: _regions.map((region) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(region['flag'], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(region['name']),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _regions.map((region) {
          return _buildChartTab(region);
        }).toList(),
      ),
    );
  }

  Widget _buildChartTab(Map<String, dynamic> region) {
    final regionId = region['id'] as String;
    final regionColor = region['color'] as Color;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: regionId == 'global' 
          ? _chartService.getGlobalChart(limit: 10)
          : _chartService.getTopSongsByRegion(regionId, limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(regionColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading charts',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final chartData = snapshot.data ?? [];

        if (chartData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  region['flag'],
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  'No songs charting yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  regionId == 'global' 
                      ? 'Release songs to see them chart!'
                      : 'No songs from ${region['name']} yet',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Chart header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [regionColor.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    region['flag'],
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${region['name']} Top 10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${chartData.length} songs charting',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chart list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chartData.length,
                itemBuilder: (context, index) {
                  final songData = chartData[index];
                  final position = index + 1;
                  final isCurrentUser = songData['artistId'] == FirebaseAuth.instance.currentUser?.uid;
                  
                  return _buildChartEntry(
                    position: position,
                    songData: songData,
                    regionColor: regionColor,
                    isCurrentUser: isCurrentUser,
                    regionId: regionId,
                  );
                },
              ),
            ),

            // Your songs on this chart
            _buildYourSongsSection(regionId, regionColor),
          ],
        );
      },
    );
  }

  Widget _buildChartEntry({
    required int position,
    required Map<String, dynamic> songData,
    required Color regionColor,
    required bool isCurrentUser,
    required String regionId,
  }) {
    final song = songData['song'] as Song;
    final artistName = songData['artistName'] as String;
    final streams = regionId == 'global' 
        ? song.streams 
        : (song.regionalStreams[regionId] ?? 0);

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
            ? regionColor.withOpacity(0.15)
            : const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser 
            ? Border.all(color: regionColor, width: 2)
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
            // Could show song details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your song "${song.title}" is #$position!'),
                backgroundColor: regionColor,
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
                        song.title,
                        style: TextStyle(
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
                              color: _getGenreColor(song.genre).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              song.genre,
                              style: TextStyle(
                                color: _getGenreColor(song.genre),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.music_note, size: 12, color: Colors.white54),
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

                // Trend indicator (could be enhanced with historical data)
                if (position <= 3)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYourSongsSection(String regionId, Color regionColor) {
    return FutureBuilder<Map<String, int>>(
      future: _loadYourChartPositions(regionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final positions = snapshot.data!;
        final topSong = positions.entries.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            border: Border(top: BorderSide(color: Colors.white12, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: regionColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your Charting Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${positions.length} song${positions.length > 1 ? 's' : ''} on the chart',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Highest: "${topSong.key}" at #${topSong.value}',
                style: TextStyle(
                  color: regionColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _loadYourChartPositions(String regionId) async {
    final positions = <String, int>{};
    
    for (final song in widget.artistStats.songs) {
      if (song.state != SongState.released) continue;

      final position = regionId == 'global'
          ? await _chartService.getChartPosition(
              song.title,
              FirebaseAuth.instance.currentUser!.uid,
              'global',
            )
          : await _chartService.getChartPosition(
              song.title,
              FirebaseAuth.instance.currentUser!.uid,
              regionId,
            );

      if (position != null && position <= 10) {
        positions[song.title] = position;
      }
    }

    // Sort by position (lowest/best first)
    final sortedEntries = positions.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return Map.fromEntries(sortedEntries);
  }

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'pop':
        return const Color(0xFFE91E63);
      case 'hip hop':
      case 'rap':
        return const Color(0xFF9C27B0);
      case 'rock':
        return const Color(0xFFF44336);
      case 'edm':
      case 'electronic':
        return const Color(0xFF00BCD4);
      case 'r&b':
        return const Color(0xFFFF9800);
      case 'country':
        return const Color(0xFF8BC34A);
      case 'jazz':
        return const Color(0xFFFFEB3B);
      case 'ballad':
        return const Color(0xFF2196F3);
      case 'trap':
      case 'drill':
        return const Color(0xFF673AB7);
      case 'afrobeat':
        return const Color(0xFFFF5722);
      case 'reggae':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _formatStreams(int streams) {
    if (streams >= 1000000000) {
      return '${(streams / 1000000000).toStringAsFixed(1)}B';
    } else if (streams >= 1000000) {
      return '${(streams / 1000000).toStringAsFixed(1)}M';
    } else if (streams >= 1000) {
      return '${(streams / 1000).toStringAsFixed(1)}K';
    }
    return streams.toString();
  }
}
