import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../widgets/app_navigation_wrapper.dart';
import 'write_song_screen.dart';
import 'studios_list_screen.dart';
import 'release_song_screen.dart';
import 'record_album_screen.dart';
import 'release_manager_screen.dart';
import 'collaboration_screen.dart';
import '../services/game_time_service.dart';

class MusicHubScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const MusicHubScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<MusicHubScreen> createState() => _MusicHubScreenState();
}

class _MusicHubScreenState extends State<MusicHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;
  DateTime?
      _currentGameDate; // Cached current in-game date for timestamp conversion

  @override
  void initState() {
    super.initState();
    _currentStats = widget.artistStats;
    _tabController = TabController(length: 3, vsync: this);
    _prefetchGameDate();
  }

  Future<void> _prefetchGameDate() async {
    try {
      final gameDate = await GameTimeService().getCurrentGameDate();
      if (mounted) setState(() => _currentGameDate = gameDate);
    } catch (_) {
      // Non-fatal: leave null, UI will fall back gracefully
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrapper(
      currentIndex: 2, // Music Hub is index 2
      artistStats: _currentStats,
      onStatsUpdated: (updatedStats) {
        setState(() => _currentStats = updatedStats);
        widget.onStatsUpdated(updatedStats);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Row(
            children: [
              Text('🎵', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Music Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () => _navigateToReleaseManager(),
              icon: const Icon(Icons.library_music),
              tooltip: 'Release Manager',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentBlue,
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Create'),
              Tab(text: 'My Songs'),
              Tab(text: 'Released'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreateTab(),
            _buildMySongsTab(),
            _buildReleasedTab(),
          ],
        ), // Close TabBarView
      ), // Close Scaffold
    ); // Close AppNavigationWrapper
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to create?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionCard(
            title: 'Write a Song',
            subtitle: 'Create new music with your creativity',
            icon: Icons.edit_rounded,
            color: AppTheme.accentBlue,
            energyCost: 15,
            onTap: () => _navigateToWriteSong(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            title: 'Record in Studio',
            subtitle: 'Book a studio to record your songs',
            icon: Icons.mic_rounded,
            color: AppTheme.neonPurple,
            energyCost: 0,
            onTap: () => _navigateToStudios(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            title: 'Record an Album',
            subtitle: 'Create a full album with multiple tracks',
            icon: Icons.album_rounded,
            color: AppTheme.neonPurple,
            energyCost: 40,
            onTap: () => _navigateToRecordAlbum(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            title: 'Manage Releases',
            subtitle: 'Bundle songs into EPs and Albums',
            icon: Icons.library_music,
            color: AppTheme.chartGold,
            energyCost: 0,
            onTap: () => _navigateToReleaseManager(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            title: 'Collaborations',
            subtitle: 'Collaborate with other players on songs',
            icon: Icons.people,
            color: const Color(0xFF9C27B0), // Purple
            energyCost: 0,
            onTap: () => _navigateToCollaborations(),
          ),
          const SizedBox(height: 24),
          _buildStatsOverview(),
        ],
      ),
    );
  }

  Widget _buildMySongsTab() {
    final writtenSongs =
        _currentStats.songs.where((s) => s.state == SongState.written).toList();
    final recordedSongs = _currentStats.songs
        .where((s) => s.state == SongState.recorded)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recordedSongs.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.successGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recorded Songs (${recordedSongs.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recordedSongs
                .map((song) => _buildSongCard(song, isRecorded: true)),
            const SizedBox(height: 24),
          ],
          if (writtenSongs.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.edit, color: AppTheme.accentBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Written Songs (${writtenSongs.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...writtenSongs
                .map((song) => _buildSongCard(song, isRecorded: false)),
          ],
          if (writtenSongs.isEmpty && recordedSongs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.music_note_outlined,
                      size: 80,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No songs yet',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go to the Create tab to write your first song!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleasedTab() {
    final releasedSongs = _currentStats.songs
        .where((s) => s.state == SongState.released)
        .toList()
      ..sort((a, b) => (b.releasedDate ?? DateTime.now())
          .compareTo(a.releasedDate ?? DateTime.now()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch,
                  color: AppTheme.chartGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Released Songs (${releasedSongs.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (releasedSongs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.library_music_outlined,
                      size: 80,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No released songs',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record your songs and release them to the world!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...releasedSongs.map((song) => _buildReleasedSongCard(song)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int energyCost,
    required VoidCallback onTap,
  }) {
    final canPerform = energyCost == 0 || _currentStats.energy >= energyCost;

    return GestureDetector(
      onTap: canPerform ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canPerform
                ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canPerform
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canPerform
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, color: canPerform ? color : Colors.grey, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: canPerform ? Colors.white : Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: canPerform ? Colors.white60 : Colors.white30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (energyCost > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: canPerform
                      ? color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$energyCost ⚡',
                  style: TextStyle(
                    color: canPerform ? color : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongCard(Song song, {required bool isRecorded}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecorded
              ? AppTheme.successGreen.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Cover Art - show cover art if available
          song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: song.coverArtUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isRecorded
                                ? AppTheme.successGreen
                                : AppTheme.accentBlue,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.borderDefault,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          song.genreEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.borderDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      song.genreEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${song.genre} • Quality: ${song.finalQuality}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isRecorded)
            ElevatedButton(
              onPressed: () => _navigateToReleaseSong(song),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.chartGold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Release',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _navigateToStudios(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Record',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleasedSongCard(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.chartGold.withOpacity(0.1),
            AppTheme.neonPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.chartGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cover Art - show cover art if available
              song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.coverArtUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.chartGold,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.chartGold.withOpacity(0.3),
                                AppTheme.neonPurple.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              song.genreEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.chartGold.withOpacity(0.3),
                            AppTheme.neonPurple.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          song.genreEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.genre} • ${song.qualityRating}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.chartGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppTheme.chartGold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${song.finalQuality}',
                      style: const TextStyle(
                        color: AppTheme.chartGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSongStat(
                  Icons.play_arrow, '${_formatNumber(song.streams)} streams'),
              const SizedBox(width: 16),
              _buildSongStat(
                  Icons.favorite, '${_formatNumber(song.likes)} likes'),
              const Spacer(),
              Text(
                // Use in-game calendar for release timestamp; convert legacy real-world timestamps to game dates
                'Released ${_formatGameReleaseDate(song.releasedDate)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Music Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      'Songs Written', '${_currentStats.songsWritten}')),
              Expanded(
                  child: _buildStatItem(
                      'Albums Released', '${_currentStats.albumsSold}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      'Songwriting', '${_currentStats.songwritingSkill}')),
              Expanded(
                  child:
                      _buildStatItem('Lyrics', '${_currentStats.lyricsSkill}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.accentBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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

  // Convert a stored release DateTime into an in-game formatted date string.
  // Heuristic:
  // - If time component is midnight (00:00), assume it's already a game date.
  // - Otherwise treat it as a real-world timestamp and translate it using
  //   the rule 1 real hour = 1 game day relative to the current game date.
  String _formatGameReleaseDate(DateTime? released) {
    if (released == null) return 'Unknown';
    final svc = GameTimeService();

    // Already a game date if saved at midnight (as GameTimeService returns dates at 00:00)
    if (released.hour == 0 && released.minute == 0 && released.second == 0) {
      return svc.formatGameDate(released);
    }

    // Legacy real-world timestamp -> translate using current game date cache
    if (_currentGameDate == null) {
      // Fallback: format the original date (better than empty)
      return svc.formatGameDate(
          DateTime(released.year, released.month, released.day));
    }

    final now = DateTime.now();
    final hoursAgo = now.difference(released).inHours;
    final gameReleaseDate =
        _currentGameDate!.subtract(Duration(days: hoursAgo));
    final normalized = DateTime(
        gameReleaseDate.year, gameReleaseDate.month, gameReleaseDate.day);
    return svc.formatGameDate(normalized);
  }

  void _navigateToWriteSong() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteSongScreen(artistStats: _currentStats),
      ),
    );

    if (result != null && result is ArtistStats) {
      setState(() {
        _currentStats = result;
      });
      widget.onStatsUpdated(_currentStats);
    }
  }

  void _navigateToStudios() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudiosListScreen(
          artistStats: _currentStats,
          onStatsUpdated: (updatedStats) {
            setState(() {
              _currentStats = updatedStats;
            });
            widget.onStatsUpdated(_currentStats);
          },
        ),
      ),
    );
  }

  void _navigateToReleaseSong(Song song) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReleaseSongScreen(
          artistStats: _currentStats,
          song: song,
        ),
      ),
    );

    if (result != null && result is ArtistStats) {
      setState(() {
        _currentStats = result;
      });
      widget.onStatsUpdated(_currentStats);
    }
  }

  void _navigateToRecordAlbum() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordAlbumScreen(artistStats: _currentStats),
      ),
    );

    if (result != null && result is ArtistStats) {
      setState(() {
        _currentStats = result;
      });
      widget.onStatsUpdated(_currentStats);
    }
  }

  void _navigateToReleaseManager() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReleaseManagerScreen(
          artistStats: _currentStats,
          onStatsUpdated: (updatedStats) {
            // Release Manager will notify parent via Navigator.pop
            Navigator.pop(context, updatedStats);
          },
        ),
      ),
    );

    if (result != null && result is ArtistStats) {
      setState(() {
        _currentStats = result;
      });
      widget.onStatsUpdated(_currentStats);
    }
  }

  void _navigateToCollaborations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CollaborationScreen(),
      ),
    );
  }
}
