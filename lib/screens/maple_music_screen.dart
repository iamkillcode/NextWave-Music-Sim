import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';

class MapleMusicScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const MapleMusicScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<MapleMusicScreen> createState() => _MapleMusicScreenState();
}

class _MapleMusicScreenState extends State<MapleMusicScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;
  String _selectedTab = 'Songs';
  bool _isFollowing = false;

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

  List<Song> get releasedSongs => _currentStats.songs
      .where(
        (s) =>
            s.state == SongState.released &&
            s.streamingPlatforms.contains('maple_music'),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    // Calculate monthly listeners from last 7 days streams
    // Monthly ≈ 4.3 weeks of activity (30 days / 7 days per week)
    final last7DaysStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.last7DaysStreams,
    );
    final monthlyListeners =
        (last7DaysStreams * 4.3).round(); // Based on recent weekly activity

    // Followers is a separate metric (40% of fanbase on this platform)
    final followers =
        (_currentStats.fanbase * 0.4).round(); // 40% of fanbase on Maple Music

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: CustomScrollView(
        slivers: [
          // Apple Music-style Header
          SliverToBoxAdapter(
              child: _buildArtistHeader(followers, monthlyListeners)),
          // Action Buttons & Navigation
          SliverToBoxAdapter(child: _buildActionButtonsAndNav()),
          // Content based on selected tab
          SliverToBoxAdapter(child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  // Apple Music-style Artist Header
  Widget _buildArtistHeader(int followers, int monthlyListeners) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFC3C44).withOpacity(0.5), // Apple Music red
            const Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Glassmorphism overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Artist profile circle (Apple Music style)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentStats.avatarUrl == null
                      ? const Color(0xFFFC3C44)
                      : Colors.transparent,
                  image: _currentStats.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_currentStats.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFC3C44).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: _currentStats.avatarUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          // Artist Name and Stats
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Artist Name
                Text(
                  _currentStats.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Monthly Listeners (consistent with Tunify)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatNumber(monthlyListeners)} monthly listeners',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Followers
                Text(
                  '${_formatNumber(followers)} Followers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Platform badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC3C44).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFC3C44).withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    '🍎 Maple Music Artist',
                    style: TextStyle(
                      color: Color(0xFFFC3C44),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Apple Music-style Action Buttons
  Widget _buildActionButtonsAndNav() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Play and Shuffle Buttons
          Row(
            children: [
              // Play Button (Red accent)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: const Text(
                    'Play',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC3C44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Shuffle Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.shuffle, size: 20),
                  label: const Text(
                    'Shuffle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFC3C44),
                    side: const BorderSide(
                      color: Color(0xFFFC3C44),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Follow Button and More Options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Follow Button
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFollowing = !_isFollowing;
                  });
                },
                icon: Icon(
                  _isFollowing ? Icons.check_circle : Icons.add_circle_outline,
                  size: 20,
                ),
                label: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isFollowing
                      ? const Color(0xFFFC3C44).withOpacity(0.2)
                      : Colors.transparent,
                  side: BorderSide(
                    color: _isFollowing
                        ? const Color(0xFFFC3C44)
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // More Options
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: Colors.white.withOpacity(0.7),
                  size: 28,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Navigation Tabs
          _buildNavigationTabs(),
        ],
      ),
    );
  }

  // Apple Music-style Navigation Tabs
  Widget _buildNavigationTabs() {
    final tabs = ['Songs', 'Albums', 'About'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tabs.map((tab) {
        final isSelected = _selectedTab == tab;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = tab;
            });
          },
          child: Column(
            children: [
              Text(
                tab,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFC3C44)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 50,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFFC3C44) : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 'Songs':
        return _buildSongsTab();
      case 'Albums':
        return _buildAlbumsTab();
      case 'About':
        return _buildAboutTab();
      default:
        return _buildSongsTab();
    }
  }

  // Songs Tab - Show released songs on Maple Music
  Widget _buildSongsTab() {
    if (releasedSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No songs on Maple Music yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Release your songs to Maple Music to see them here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Releases',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${releasedSongs.length} song${releasedSongs.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Song List
          ...releasedSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildSongTile(song, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildSongTile(Song song, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: (() {
          final cover = song.coverArtUrl;
          if (cover != null && cover.isNotEmpty) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: cover,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFC3C44),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFC3C44).withOpacity(0.3),
                          const Color(0xFFFF6B9D).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFC3C44).withOpacity(0.3),
                  const Color(0xFFFF6B9D).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }()),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _currentStats.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatNumber(song.streams),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('🍎', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '\$${(song.streams * 0.01).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF4CD964), // Apple green
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
          onPressed: () {},
        ),
      ),
    );
  }

  // Albums Tab - Show released albums and singles
  Widget _buildAlbumsTab() {
    if (releasedSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.album_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No albums yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Release songs on Maple Music to see them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Singles & Albums Section
          const Text(
            'Singles & Albums',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Grid of album covers
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: releasedSongs.length,
            itemBuilder: (context, index) {
              final song = releasedSongs[index];
              return _buildAlbumCard(song);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Song song) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFC3C44).withOpacity(0.8),
                    const Color(0xFFFC3C44).withOpacity(0.4),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  song.genreEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          // Song info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Single • ${song.genre}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // About Tab - Artist Stats and Platform Info
  Widget _buildAboutTab() {
    final totalStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );
    final totalRevenue = totalStreams * 0.01; // $0.01 per stream

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Section
          const Text(
            'Your Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Streams',
            _formatNumber(totalStreams),
            Icons.play_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Total Revenue',
            '\$$totalRevenue',
            Icons.attach_money,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Songs Released',
            '${releasedSongs.length}',
            Icons.music_note,
          ),
          const SizedBox(height: 32),

          // Platform Info
          const Text(
            'About Maple Music',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🍎', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Premium Platform',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Royalty Rate', '\$0.01 per stream'),
                _buildInfoRow('Popularity', '65% reach'),
                _buildInfoRow('Best For', 'Premium audience'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC3C44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFC3C44).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFC3C44),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Maple Music pays 3.3x more per stream than other platforms!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFC3C44).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFC3C44), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
}
