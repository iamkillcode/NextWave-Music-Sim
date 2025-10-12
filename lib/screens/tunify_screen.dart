import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';

class TunifyScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const TunifyScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<TunifyScreen> createState() => _TunifyScreenState();
}

class _TunifyScreenState extends State<TunifyScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentStats = widget.artistStats;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Song> get releasedSongs => _currentStats.songs.where((s) => s.state == SongState.released).toList();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tunify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Streaming Platform',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1DB954),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Music'),
            Tab(text: 'Analytics'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyMusicTab(),
          _buildAnalyticsTab(),
          _buildTrendingTab(),
        ],
      ),
    );
  }

  Widget _buildMyMusicTab() {
    if (releasedSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'No Released Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Record and release songs in the Studio first!',
              style: TextStyle(color: Colors.white60, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: releasedSongs.length,
      itemBuilder: (context, index) {
        final song = releasedSongs[index];
        return _buildSongStreamingCard(song);
      },
    );
  }

  Widget _buildAnalyticsTab() {
    if (releasedSongs.isEmpty) {
      return const Center(
        child: Text(
          'No analytics available\nRelease songs to see your performance!',
          style: TextStyle(color: Colors.white60, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    final totalStreams = releasedSongs.fold<int>(0, (sum, song) => sum + song.streams);
    final totalLikes = releasedSongs.fold<int>(0, (sum, song) => sum + song.likes);
    final totalEarnings = (totalStreams * 0.003).round();
    final avgQuality = releasedSongs.fold<int>(0, (sum, song) => sum + song.finalQuality) ~/ releasedSongs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAnalyticsCard('Total Streams', _formatNumber(totalStreams), Icons.play_arrow)),
              const SizedBox(width: 12),
              Expanded(child: _buildAnalyticsCard('Total Likes', _formatNumber(totalLikes), Icons.favorite)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAnalyticsCard('Total Earnings', '\$${_formatNumber(totalEarnings)}', Icons.attach_money)),
              const SizedBox(width: 12),
              Expanded(child: _buildAnalyticsCard('Avg Quality', '$avgQuality%', Icons.star)),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Genre Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildGenreAnalytics(),
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    // Simulate global trending songs
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Global Trending 🔥',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(10, (index) => _buildTrendingSongCard(index + 1)),
      ],
    );
  }

  Widget _buildSongStreamingCard(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF21262D),
            const Color(0xFF1DB954).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(song.genreEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${song.genre} • Released ${_formatTimeAgo(song.releasedDate!)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreamingStatChip('Streams', song.streams, Icons.play_arrow),
              _buildStreamingStatChip('Likes', song.likes, Icons.favorite),
              _buildStreamingStatChip('Quality', song.finalQuality, Icons.star),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (song.streams / song.estimatedStreams).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress to potential: ${((song.streams / song.estimatedStreams) * 100).clamp(0, 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingStatChip(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(
            label == 'Quality' ? '$value%' : _formatNumber(value),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF21262D),
            const Color(0xFF1DB954).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGenreAnalytics() {
    final genreStats = <String, Map<String, int>>{};
    
    for (final song in releasedSongs) {
      genreStats[song.genre] ??= {'streams': 0, 'songs': 0, 'quality': 0};
      genreStats[song.genre]!['streams'] = genreStats[song.genre]!['streams']! + song.streams;
      genreStats[song.genre]!['songs'] = genreStats[song.genre]!['songs']! + 1;
      genreStats[song.genre]!['quality'] = genreStats[song.genre]!['quality']! + song.finalQuality;
    }

    return genreStats.entries.map((entry) {
      final genre = entry.key;
      final stats = entry.value;
      final avgQuality = stats['quality']! ~/ stats['songs']!;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _getGenreEmoji(genre),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    genre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${stats['songs']} songs • ${_formatNumber(stats['streams']!)} streams',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$avgQuality%',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTrendingSongCard(int rank) {
    final trendingSongs = [
      {'title': 'Midnight Vibes', 'artist': 'SoulMaster', 'genre': 'R&B', 'streams': 15600000},
      {'title': 'Street Legend', 'artist': 'RapKing', 'genre': 'Hip Hop', 'streams': 12300000},
      {'title': 'Afro Magic', 'artist': 'RhythmQueen', 'genre': 'Afrobeat', 'streams': 8900000},
      {'title': 'Country Road', 'artist': 'CowboyJoe', 'genre': 'Country', 'streams': 7200000},
      {'title': 'Jazz Fusion', 'artist': 'SmoothSax', 'genre': 'Jazz', 'streams': 5800000},
      {'title': 'Trap Nation', 'artist': 'BeatMaker', 'genre': 'Trap', 'streams': 4500000},
      {'title': 'Drill Sergeant', 'artist': 'UrbanFlow', 'genre': 'Drill', 'streams': 3200000},
      {'title': 'Island Time', 'artist': 'ReggaeMon', 'genre': 'Reggae', 'streams': 2100000},
      {'title': 'Rap Battle', 'artist': 'LyricLord', 'genre': 'Rap', 'streams': 1800000},
      {'title': 'R&B Smooth', 'artist': 'VelvetVoice', 'genre': 'R&B', 'streams': 1500000},
    ];

    final song = trendingSongs[rank - 1];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? const Color(0xFFFFD700) : const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _getGenreEmoji(song['genre'] as String),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${song['artist']} • ${song['genre']}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatNumber(song['streams'] as int),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
  Widget _getGenreEmoji(String genre) {
    String emoji;
    switch (genre.toLowerCase()) {
      case 'r&b': emoji = '💕'; break;
      case 'hip hop': emoji = '🎤'; break;
      case 'rap': emoji = '🎯'; break;
      case 'trap': emoji = '🔥'; break;
      case 'drill': emoji = '💀'; break;
      case 'afrobeat': emoji = '🌍'; break;
      case 'country': emoji = '🤠'; break;
      case 'jazz': emoji = '🎺'; break;
      case 'reggae': emoji = '🌴'; break;
      default: emoji = '🎵'; break;
    }
    return Text(emoji, style: const TextStyle(fontSize: 24));
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

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return '${difference.inMinutes}m ago';
  }
}
