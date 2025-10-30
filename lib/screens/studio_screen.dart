import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/game_time_service.dart';
import 'release_manager_screen.dart';

class StudioScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const StudioScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen>
    with TickerProviderStateMixin {
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

  List<Song> get writtenSongs =>
      _currentStats.songs.where((s) => s.state == SongState.written).toList();
  List<Song> get recordedSongs =>
      _currentStats.songs.where((s) => s.state == SongState.recorded).toList();
  List<Song> get releasedSongs =>
      _currentStats.songs.where((s) => s.state == SongState.released).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          '🎙️ Studio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Written Songs'),
            Tab(text: 'Recorded Songs'),
            Tab(text: 'Released Songs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWrittenSongsTab(),
          _buildRecordedSongsTab(),
          _buildReleasedSongsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReleaseManagerScreen(
                artistStats: _currentStats,
                onStatsUpdated: (updatedStats) {
                  setState(() {
                    _currentStats = updatedStats;
                  });
                  widget.onStatsUpdated(updatedStats);
                },
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFFE94560),
        icon: const Icon(Icons.library_music_rounded),
        label: const Text('Releases (EPs/Albums)'),
      ),
    );
  }

  Widget _buildWrittenSongsTab() {
    if (writtenSongs.isEmpty) {
      return _buildEmptyState(
        icon: '📝',
        title: 'No Written Songs',
        subtitle: 'Go write some songs first!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: writtenSongs.length,
      itemBuilder: (context, index) {
        final song = writtenSongs[index];
        return _buildSongCard(
          song: song,
          actionButton: _buildRecordButton(song),
        );
      },
    );
  }

  Widget _buildRecordedSongsTab() {
    if (recordedSongs.isEmpty) {
      return _buildEmptyState(
        icon: '🎤',
        title: 'No Recorded Songs',
        subtitle: 'Record some written songs first!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recordedSongs.length,
      itemBuilder: (context, index) {
        final song = recordedSongs[index];
        return _buildSongCard(
          song: song,
          actionButton: _buildReleaseButton(song),
        );
      },
    );
  }

  Widget _buildReleasedSongsTab() {
    if (releasedSongs.isEmpty) {
      return _buildEmptyState(
        icon: '🎵',
        title: 'No Released Songs',
        subtitle: 'Release some recorded songs on Tunify!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: releasedSongs.length,
      itemBuilder: (context, index) {
        final song = releasedSongs[index];
        return _buildSongCard(
          song: song,
          actionButton: _buildStreamingStats(song),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard({
    required Song song,
    required Widget actionButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF21262D),
            const Color(0xFF30363D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                song.genreEmoji,
                style: const TextStyle(fontSize: 24),
              ),
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
                      '${song.genre} • ${song.qualityRating}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStateColor(song.state),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  song.stateDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Quality', '${song.finalQuality}%'),
              const SizedBox(width: 8),
              if (song.recordingQuality != null)
                _buildInfoChip('Recording', '${song.recordingQuality}%'),
              if (song.state == SongState.released) ...[
                const SizedBox(width: 8),
                _buildInfoChip('Streams', _formatNumber(song.streams)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRecordButton(Song song) {
    final canAfford = _currentStats.energy >= 30 && _currentStats.money >= 1000;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAfford ? () => _recordSong(song) : null,
        icon: const Icon(Icons.mic),
        label: Text(canAfford
            ? 'Record Song (-30 Energy, -\$1K)'
            : 'Need 30 Energy & \$1K'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D9FF),
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey.shade700,
          disabledForegroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseButton(Song song) {
    final canAfford = _currentStats.money >= 5000;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAfford ? () => _releaseSong(song) : null,
        icon: const Icon(Icons.publish),
        label: Text(
            canAfford ? 'Release on Tunify (-\$5K)' : 'Need \$5K for Release'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DB954), // Spotify green
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade700,
          disabledForegroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingStats(Song song) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                _formatNumber(song.streams),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Streams',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                _formatNumber(song.likes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Likes',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '\$${_formatNumber((song.streams * 0.003).round())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Earnings',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _recordSong(Song song) {
    // Calculate recording quality based on current stats and random factors
    final baseQuality =
        ((_currentStats.songwritingSkill + _currentStats.compositionSkill) / 2)
            .round();
    final randomFactor =
        (DateTime.now().millisecondsSinceEpoch % 21) - 10; // -10 to +10
    final recordingQuality = (baseQuality + randomFactor).clamp(1, 100);

    final updatedSongs = _currentStats.songs.map((s) {
      if (s.id == song.id) {
        return s.copyWith(
          state: SongState.recorded,
          recordingQuality: recordingQuality,
          recordedDate: DateTime.now(),
        );
      }
      return s;
    }).toList();

    setState(() {
      _currentStats = _currentStats.copyWith(
        energy: _currentStats.energy - 30,
        money: _currentStats.money - 1000,
        experience: _currentStats.experience + 25,
        songs: updatedSongs,
      );
    });

    widget.onStatsUpdated(_currentStats);

    _showMessage(
        '🎤 Successfully recorded "${song.title}"!\nRecording Quality: $recordingQuality%');
  }

  void _releaseSong(Song song) {
    // Switch to in-game date for release timestamp
    _releaseSongInternal(song);
  }

  Future<void> _releaseSongInternal(Song song) async {
    final currentGameDate = await GameTimeService().getCurrentGameDate();
    final updatedSongs = _currentStats.songs.map((s) {
      if (s.id == song.id) {
        // Generate initial streams based on quality and genre
        final initialStreams = (song.estimatedStreams * 0.001)
            .round(); // Start with 0.1% of estimated
        final initialLikes = (initialStreams * 0.05).round(); // 5% like rate

        return s.copyWith(
          state: SongState.released,
          releasedDate: currentGameDate,
          streams: initialStreams,
          likes: initialLikes,
        );
      }
      return s;
    }).toList();

    // Calculate hype gain from release
    final hypeGain = _currentStats.calculateHypeFromRelease(song.finalQuality);

    setState(() {
      _currentStats = _currentStats.copyWith(
        money: _currentStats.money - 5000,
        fame: _currentStats.fame + (song.finalQuality ~/ 10),
        songsWritten:
            _currentStats.songsWritten + 1, // ✅ Increment when released!
        songs: updatedSongs,
        inspirationLevel: (_currentStats.inspirationLevel + hypeGain).clamp(0, 150), // 🔥 Add hype from release
        lastActivityDate: currentGameDate, // ✅ Update activity for fame decay
      );
    });

    widget.onStatsUpdated(_currentStats);

    _showMessage(
        '🎵 "${song.title}" is now live on Tunify!\n+${song.finalQuality ~/ 10} Fame, +$hypeGain Hype');
  }

  Color _getStateColor(SongState state) {
    switch (state) {
      case SongState.written:
        return Colors.orange;
      case SongState.recorded:
        return Colors.blue;
      case SongState.released:
        return const Color(0xFF1DB954);
      case SongState.scheduled:
        return Colors.purple;
    }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
