import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';

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

class _TunifyScreenState extends State<TunifyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;
  String _selectedTab = 'Popular';
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
    .where((s) => s.state == SongState.released && (s.streamingPlatforms.contains('tunify') || s.streamingPlatforms.isEmpty))
    .toList();

  List<Album> get releasedAlbums => _currentStats.albums
    .where((a) => a.state == AlbumState.released && (a.streamingPlatforms.contains('tunify') || a.streamingPlatforms.isEmpty))
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header Section with Artist Profile
          SliverToBoxAdapter(child: _buildArtistHeader(monthlyListeners)),
          // Action Buttons & Navigation
          SliverToBoxAdapter(child: _buildActionButtonsAndNav()),
          // Content based on selected tab
          SliverToBoxAdapter(child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  // Enhanced Spotify-like Artist Header with dynamic gradient
  Widget _buildArtistHeader(int monthlyListeners) {
    // Dynamic color based on artist name
    final headerColor = _getArtistColor();

    return Container(
      height: 420,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            headerColor.withOpacity(0.8),
            headerColor.withOpacity(0.4),
            const Color(0xFF121212),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Noise texture effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Back button with blur effect
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // More options button
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {},
              ),
            ),
          ),
          // Artist Profile Circle (realistic Spotify style)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _currentStats.avatarUrl == null
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                headerColor.withOpacity(0.9),
                                headerColor,
                              ],
                            )
                          : null,
                      image: _currentStats.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_currentStats.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 3,
                      ),
                    ),
                    child: _currentStats.avatarUrl == null
                        ? Center(
                            child: Text(
                              _getArtistInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Artist Name and Stats at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Verified badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF1DB954),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified Artist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Artist Name
                Text(
                  _currentStats.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                // Monthly Listeners with icon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatNumber(monthlyListeners)} monthly listeners',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
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

  // Get dynamic color based on artist name
  Color _getArtistColor() {
    final colors = [
      const Color(0xFF1DB954), // Spotify green
      const Color(0xFFE13300), // Red
      const Color(0xFF8E44AD), // Purple
      const Color(0xFF3498DB), // Blue
      const Color(0xFFE74C3C), // Coral
      const Color(0xFFF39C12), // Orange
      const Color(0xFF1ABC9C), // Turquoise
      const Color(0xFFE91E63), // Pink
    ];
    final hash = _currentStats.name.hashCode.abs();
    return colors[hash % colors.length];
  }

  // Get artist initials for profile circle
  String _getArtistInitials() {
    final words = _currentStats.name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return _currentStats.name.substring(0, 1).toUpperCase();
  }

  // Action Buttons and Navigation Bar (realistic Spotify layout)
  Widget _buildActionButtonsAndNav() {
    final totalStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );
    final totalSongs = releasedSongs.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF121212), Colors.black],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge(Icons.music_note_rounded, '$totalSongs songs'),
              const SizedBox(width: 16),
              _buildStatBadge(
                Icons.play_circle_outline,
                _formatNumber(totalStreams),
              ),
              const SizedBox(width: 16),
              _buildStatBadge(
                Icons.favorite_border,
                '${_formatNumber(_currentStats.fanbase)} fans',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons Row
          Row(
            children: [
              // Play Button (Large, Spotify Green)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 32,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              // Shuffle Button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.shuffle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              // Follow Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                  },
                  icon: Icon(
                    _isFollowing ? Icons.check : Icons.person_add_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        _isFollowing ? Colors.transparent : Colors.transparent,
                    side: BorderSide(
                      color: _isFollowing
                          ? const Color(0xFF1DB954)
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // More Options
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    _showArtistOptions();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Navigation Tabs
          Row(
            children: [
              _buildNavTab('Popular', _selectedTab == 'Popular'),
              const SizedBox(width: 32),
              _buildNavTab('Albums', _selectedTab == 'Albums'),
              const SizedBox(width: 32),
              _buildNavTab('About', _selectedTab == 'About'),
            ],
          ),
        ],
      ),
    );
  }

  // Stat badge widget
  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Show artist options bottom sheet
  void _showArtistOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white),
                title: const Text(
                  'Share artist',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: Colors.white),
                title: const Text(
                  'Copy link',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.radio_rounded, color: Colors.white),
                title: const Text(
                  'Go to artist radio',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.white),
                title: const Text(
                  'Report',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // Content based on selected tab
  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 'Popular':
        return _buildPopularTracksContent();
      case 'Albums':
        return _buildAlbumsContent();
      case 'About':
        return _buildAboutContent();
      default:
        return _buildPopularTracksContent();
    }
  }

  // Popular Tracks List (Enhanced Spotify-style)
  Widget _buildPopularTracksContent() {
  if (releasedSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Release your first song to see it here!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort songs by streams (descending)
    final popularSongs = List<Song>.from(releasedSongs)
      ..sort((a, b) => b.streams.compareTo(a.streams));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, const Color(0xFF0A0A0A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${popularSongs.length} songs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Song list
          ...popularSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildPopularTrackItem(index + 1, song);
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPopularTrackItem(int rank, Song song) {
    final isTopTrack = rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                // Rank Number with special styling for top 3
                SizedBox(
                  width: 32,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isTopTrack ? const Color(0xFF1DB954) : Colors.white,
                      fontSize: isTopTrack ? 18 : 16,
                      fontWeight:
                          isTopTrack ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Album Art - show cover art if available
                song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1DB954),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getArtistColor().withOpacity(0.8),
                                  _getArtistColor().withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getArtistColor().withOpacity(0.8),
                              _getArtistColor().withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            song.genreEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (song.streamingPlatforms.contains('tunify'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1DB954,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🎵', style: TextStyle(fontSize: 10)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Tunify',
                                    style: TextStyle(
                                      color: Color(0xFF1DB954),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              song.genre,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Stream Count with icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(song.streams),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${(song.streams * 0.003).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: const Color(0xFF1DB954).withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // More options
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      _showTrackOptions(song);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Albums Tab - Group songs by release or show singles
  Widget _buildAlbumsContent() {
    if (releasedSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.album_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No albums yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Release songs to see them here',
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
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Singles & EPs Section
          const Text(
            'Singles & EPs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
            // Grid of released albums
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: releasedAlbums.length,
              itemBuilder: (context, index) {
                final album = releasedAlbums[index];
                return _buildAlbumTile(album);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumTile(Album album) {
    final cover = album.coverArtUrl;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade900, Colors.grey.shade800],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: cover != null
                    ? Image.network(cover, fit: BoxFit.cover)
                    : const Icon(Icons.album_rounded, size: 48, color: Colors.white30),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
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
                    '${album.typeDisplay} • ${album.songIds.length} songs',
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

  Widget _buildAlbumCard(Song song) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
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
                    _getArtistColor().withOpacity(0.8),
                    _getArtistColor().withOpacity(0.4),
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

  // About Tab - Artist bio and stats
  Widget _buildAboutContent() {
    final totalStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );
    final totalRevenue = totalStreams * 0.003;
    final avgQuality = releasedSongs.isEmpty
        ? 0
        : releasedSongs.fold<int>(0, (sum, song) => sum + song.finalQuality) ~/
            releasedSongs.length;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          const Text(
            'About',
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
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildAboutStat(
                  'Total Streams',
                  _formatNumber(totalStreams),
                  Icons.play_circle_outline,
                ),
                const Divider(color: Color(0xFF282828), height: 32),
                _buildAboutStat(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
                const Divider(color: Color(0xFF282828), height: 32),
                _buildAboutStat(
                  'Fanbase',
                  _formatNumber(_currentStats.fanbase),
                  Icons.people_rounded,
                ),
                const Divider(color: Color(0xFF282828), height: 32),
                _buildAboutStat(
                  'Avg Quality',
                  '$avgQuality%',
                  Icons.star_rounded,
                ),
                const Divider(color: Color(0xFF282828), height: 32),
                _buildAboutStat(
                  'Total Songs',
                  '${releasedSongs.length}',
                  Icons.music_note_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Artist on Tunify section
          const Text(
            'Artist on Tunify',
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1DB954).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1DB954).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Streaming Platform',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Platform', 'Tunify'),
                const SizedBox(height: 8),
                _buildInfoRow('Royalty Rate', '\$0.003 per stream'),
                const SizedBox(height: 8),
                _buildInfoRow('Popularity', '85% global reach'),
                const SizedBox(height: 8),
                _buildInfoRow('Best For', 'Maximum exposure'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAboutStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1DB954), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
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
    );
  }

  void _showTrackOptions(Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Song header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Cover art or genre emoji
                    (() {
                      final cover = song.coverArtUrl;
                      if (cover != null && cover.isNotEmpty) {
                        return Container(
                          width: 56,
                          height: 56,
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
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1DB954),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getArtistColor().withOpacity(0.8),
                                      _getArtistColor().withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    song.genreEmoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getArtistColor().withOpacity(0.8),
                              _getArtistColor().withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            song.genreEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      );
                    }()),
                    const SizedBox(width: 16),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentStats.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF404040), height: 1),
              ListTile(
                leading: const Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Like',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.playlist_add_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Add to playlist',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Add to queue',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.radio_rounded, color: Colors.white),
                title: const Text(
                  'Go to song radio',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white),
                title: const Text(
                  'Share',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'View song stats',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatNumber(song.streams),
                    style: const TextStyle(
                      color: Color(0xFF1DB954),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumberDetailed(int number) {
    // Format like "968,661,097" with commas
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
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

    final totalStreams = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );
    final totalLikes = releasedSongs.fold<int>(
      0,
      (sum, song) => sum + song.likes,
    );
    final totalEarnings = (totalStreams * 0.003).round();
    final avgQuality =
        releasedSongs.fold<int>(0, (sum, song) => sum + song.finalQuality) ~/
            releasedSongs.length;

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
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Streams',
                  _formatNumber(totalStreams),
                  Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Likes',
                  _formatNumber(totalLikes),
                  Icons.favorite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Earnings',
                  '\$${_formatNumber(totalEarnings)}',
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg Quality',
                  '$avgQuality%',
                  Icons.star,
                ),
              ),
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
              // Cover art or genre emoji
              (() {
                final cover = song.coverArtUrl;
                if (cover != null && cover.isNotEmpty) {
                  return Container(
                    width: 56,
                    height: 56,
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1DB954),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getArtistColor().withOpacity(0.8),
                                _getArtistColor().withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              song.genreEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Text(song.genreEmoji,
                    style: const TextStyle(fontSize: 24));
              }()),
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
              _buildStreamingStatChip(
                'Streams',
                song.streams,
                Icons.play_arrow,
              ),
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
      genreStats[song.genre]!['streams'] =
          genreStats[song.genre]!['streams']! + song.streams;
      genreStats[song.genre]!['songs'] = genreStats[song.genre]!['songs']! + 1;
      genreStats[song.genre]!['quality'] =
          genreStats[song.genre]!['quality']! + song.finalQuality;
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTrendingSongCard(int rank) {
    final trendingSongs = [
      {
        'title': 'Midnight Vibes',
        'artist': 'SoulMaster',
        'genre': 'R&B',
        'streams': 15600000,
      },
      {
        'title': 'Street Legend',
        'artist': 'RapKing',
        'genre': 'Hip Hop',
        'streams': 12300000,
      },
      {
        'title': 'Afro Magic',
        'artist': 'RhythmQueen',
        'genre': 'Afrobeat',
        'streams': 8900000,
      },
      {
        'title': 'Country Road',
        'artist': 'CowboyJoe',
        'genre': 'Country',
        'streams': 7200000,
      },
      {
        'title': 'Jazz Fusion',
        'artist': 'SmoothSax',
        'genre': 'Jazz',
        'streams': 5800000,
      },
      {
        'title': 'Trap Nation',
        'artist': 'BeatMaker',
        'genre': 'Trap',
        'streams': 4500000,
      },
      {
        'title': 'Drill Sergeant',
        'artist': 'UrbanFlow',
        'genre': 'Drill',
        'streams': 3200000,
      },
      {
        'title': 'Island Time',
        'artist': 'ReggaeMon',
        'genre': 'Reggae',
        'streams': 2100000,
      },
      {
        'title': 'Rap Battle',
        'artist': 'LyricLord',
        'genre': 'Rap',
        'streams': 1800000,
      },
      {
        'title': 'R&B Smooth',
        'artist': 'VelvetVoice',
        'genre': 'R&B',
        'streams': 1500000,
      },
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
              color:
                  rank <= 3 ? const Color(0xFFFFD700) : const Color(0xFF30363D),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
      case 'r&b':
        emoji = '💕';
        break;
      case 'hip hop':
        emoji = '🎤';
        break;
      case 'rap':
        emoji = '🎯';
        break;
      case 'trap':
        emoji = '🔥';
        break;
      case 'drill':
        emoji = '💀';
        break;
      case 'afrobeat':
        emoji = '🌍';
        break;
      case 'country':
        emoji = '🤠';
        break;
      case 'jazz':
        emoji = '🎺';
        break;
      case 'reggae':
        emoji = '🌴';
        break;
      default:
        emoji = '🎵';
        break;
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
