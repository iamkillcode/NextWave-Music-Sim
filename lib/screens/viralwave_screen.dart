import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../theme/nextwave_theme.dart';
import '../theme/app_theme.dart';

class ViralWaveScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final DateTime currentGameDate;

  const ViralWaveScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
    required this.currentGameDate,
  });

  @override
  State<ViralWaveScreen> createState() => _ViralWaveScreenState();
}

class _ViralWaveScreenState extends State<ViralWaveScreen> {
  String _selectedPromotionType = 'song';
  Song? _selectedSong;
  Album? _selectedAlbum;

  // Custom promotion settings
  int _promoDays = 7; // Default 7 days
  double _budgetMultiplier = 1.0; // 1.0 = base cost, 2.0 = double cost/effect

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Anti-exploit constants
  static const int maxConcurrentPromosPerItem =
      3; // Max 3 active promos on same song/EP/album
  static const int maxDailyBufferPerSong =
      50000; // Cap daily streams boost per song

  final Map<String, Map<String, dynamic>> _promotionTypes = {
    'song': {
      'name': 'Single Song',
      'emoji': '🎵',
      'baseCost': 2000, // Increased from 500
      'baseReach': 3000, // Reduced from 5000
      'color': NextWaveTheme.neonCyan,
      'description': 'Promote one song to targeted audiences',
    },
    'ep': {
      'name': 'EP Campaign',
      'emoji': '💿',
      'baseCost': 8000, // Increased from 2000
      'baseReach': 12000, // Reduced from 25000,
      'color': NextWaveTheme.warningOrange,
      'description': 'Promote your EP across multiple channels',
    },
    'lp': {
      'name': 'Album Campaign',
      'emoji': '💽',
      'baseCost': 20000, // Increased from 5000
      'baseReach': 25000, // Reduced from 50000
      'color': NextWaveTheme.crimsonRed,
      'description': 'Major album promotional campaign',
    },
  };

  // Calculate total cost based on base cost, days, and budget multiplier
  int get _totalCost {
    final baseCost =
        _promotionTypes[_selectedPromotionType]!['baseCost'] as int;
    // Cost = base × days × budget multiplier
    return (baseCost * _promoDays * _budgetMultiplier).round();
  }

  @override
  Widget build(BuildContext context) {
    final releasedSongs = widget.artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList();

    final canPromote = widget.artistStats.money >= _totalCost;

    return Scaffold(
      backgroundColor: NextWaveTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: NextWaveTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  NextWaveTheme.crimsonGradient.createShader(bounds),
              child: const Text(
                '📱 ViralWave',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Promotion Platform',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: releasedSongs.isEmpty
          ? _buildNoSongsView()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Platform header
                    _buildHeaderCard(),

                    const SizedBox(height: 24),

                    // Active campaigns section
                    _buildActiveCampaignsSection(),

                    const SizedBox(height: 24),

                    // Promotion type selector
                    const Text(
                      'Select Campaign Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPromotionTypeSelector(),

                    const SizedBox(height: 12),

                    // Show validation message if selected type is not available
                    if (!_isPromotionTypeAvailable(_selectedPromotionType))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock,
                              color: AppTheme.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getValidationMessage(_selectedPromotionType),
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Show warning if selected item has max concurrent promos
                    if (_selectedPromotionType == 'song' &&
                        _selectedSong != null &&
                        _hasMaxConcurrentPromos(_selectedSong!))
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warningOrange.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: AppTheme.warningOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Maximum concurrent promotions reached for "${_selectedSong!.title}". Wait for current promos to complete.',
                                style: const TextStyle(
                                  color: AppTheme.warningOrange,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Song/Album selector
                    if (_selectedPromotionType == 'song')
                      _buildSongSelector(releasedSongs)
                    else if (_selectedPromotionType == 'ep')
                      _buildEPSelector()
                    else
                      _buildAlbumSelector(),

                    const SizedBox(height: 24),

                    // Promotion customization controls
                    _buildPromotionControls(),

                    const SizedBox(height: 24),

                    // Campaign details
                    _buildCampaignDetails(),

                    const SizedBox(height: 24),

                    // Launch button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canPromote && _canLaunchCampaign()
                            ? _launchCampaign
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonPurple,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getButtonText(canPromote),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    if (!canPromote) _buildErrorMessage(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Check if a promotion type is available based on released songs/albums
  bool _isPromotionTypeAvailable(String promotionType) {
    final releasedSongs = widget.artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList();

    final releasedAlbums = widget.artistStats.albums
        .where((a) => a.state == AlbumState.released)
        .toList();

    // Get EPs and Albums separately
    final releasedEPs =
        releasedAlbums.where((a) => a.type == AlbumType.ep).toList();
    final releasedLPs =
        releasedAlbums.where((a) => a.type == AlbumType.album).toList();

    switch (promotionType) {
      case 'song':
        // Need at least 1 released song
        return releasedSongs.isNotEmpty;
      case 'ep':
        // Need at least 1 released EP
        return releasedEPs.isNotEmpty;
      case 'lp':
        // Need at least 1 released Album
        return releasedLPs.isNotEmpty;
      default:
        return false;
    }
  }

  /// Get the validation message for unavailable promotion types
  String _getValidationMessage(String promotionType) {
    final releasedAlbums = widget.artistStats.albums
        .where((a) => a.state == AlbumState.released)
        .toList();

    final releasedEPs =
        releasedAlbums.where((a) => a.type == AlbumType.ep).toList();
    final releasedLPs =
        releasedAlbums.where((a) => a.type == AlbumType.album).toList();

    switch (promotionType) {
      case 'song':
        return 'Need at least 1 released song';
      case 'ep':
        return 'Need at least 1 released EP (you have ${releasedEPs.length})';
      case 'lp':
        return 'Need at least 1 released Album (you have ${releasedLPs.length})';
      default:
        return 'Not available';
    }
  }

  Widget _buildNoSongsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Released Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Release songs first to promote them on ViralWave!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.neonPurple, AppTheme.errorRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                    isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: isTinyScreen ? 20 : (isSmallScreen ? 24 : 28),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boost Your Music',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTinyScreen ? 2 : 4),
                    Text(
                      'Reach millions of potential fans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              _buildHeaderStat(
                  '💰',
                  '\$${NumberFormat('#,###').format(widget.artistStats.money)}',
                  isSmallScreen,
                  isTinyScreen),
              SizedBox(width: isSmallScreen ? 8 : 12),
              _buildHeaderStat(
                  '👥',
                  NumberFormat('#,###').format(widget.artistStats.fanbase),
                  isSmallScreen,
                  isTinyScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
      String emoji, String value, bool isSmallScreen, bool isTinyScreen) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isTinyScreen ? 6 : (isSmallScreen ? 8 : 10)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji,
                style: TextStyle(
                    fontSize: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16))),
            SizedBox(width: isTinyScreen ? 4 : 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCampaignsSection() {
    // Get all songs/EPs/Albums with active promotions
    final activeSongs = widget.artistStats.songs.where((song) {
      return song.promoBuffer != null &&
          song.promoBuffer! > 0 &&
          song.promoEndDate != null &&
          song.promoEndDate!.isAfter(widget.currentGameDate);
    }).toList();

    // Find promoted albums/EPs by checking if their songs have active promos
    final promotedAlbums = <Album>[];
    for (final album in widget.artistStats.albums) {
      if (album.state == AlbumState.released) {
        final albumSongsWithPromo =
            activeSongs.where((s) => album.songIds.contains(s.id)).toList();
        // If all album songs have the same promo end date, it's an album/EP campaign
        if (albumSongsWithPromo.isNotEmpty &&
            albumSongsWithPromo.length == album.songIds.length) {
          final endDate = albumSongsWithPromo.first.promoEndDate;
          if (albumSongsWithPromo.every((s) => s.promoEndDate == endDate)) {
            promotedAlbums.add(album);
          }
        }
      }
    }

    // Get songs that are NOT part of an album campaign
    final promotedAlbumSongIds =
        promotedAlbums.expand((a) => a.songIds).toSet();
    final standaloneSongs =
        activeSongs.where((s) => !promotedAlbumSongIds.contains(s.id)).toList();

    final totalCampaigns = promotedAlbums.length + standaloneSongs.length;

    if (totalCampaigns == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.accentBlue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Active Campaigns',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCampaigns running',
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Show promoted albums/EPs
        ...promotedAlbums.map<Widget>((album) {
          final firstSong = widget.artistStats.songs
              .firstWhere((s) => s.id == album.songIds.first);
          final daysRemaining =
              firstSong.promoEndDate!.difference(widget.currentGameDate).inDays;
          final totalDailyBuffer = album.songIds.fold<int>(0, (sum, songId) {
            final song =
                widget.artistStats.songs.firstWhere((s) => s.id == songId);
            return sum + (song.promoBuffer ?? 0);
          });

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: album.type == AlbumType.ep
                    ? AppTheme.warningOrange.withOpacity(0.3)
                    : AppTheme.neonPurple.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      album.type == AlbumType.ep ? '💿' : '💽',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                          ),
                          Text(
                            '${album.type == AlbumType.ep ? "EP" : "Album"} Campaign • ${album.songIds.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${daysRemaining}d left',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '+${NumberFormat('#,###').format(totalDailyBuffer)}/day total',
                  style: TextStyle(
                    color: album.type == AlbumType.ep
                        ? AppTheme.warningOrange
                        : AppTheme.neonPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),

        // Show standalone song campaigns
        ...standaloneSongs.map<Widget>((song) {
          final daysRemaining =
              song.promoEndDate!.difference(widget.currentGameDate).inDays;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentBlue.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${daysRemaining}d left',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '+${NumberFormat('#,###').format(song.promoBuffer)}/day',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      song.genre,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPromotionTypeSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, // Changed to 3 columns for 3 options
      crossAxisSpacing: isSmallScreen ? 8 : 12,
      mainAxisSpacing: isSmallScreen ? 8 : 12,
      childAspectRatio: isTinyScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.1),
      children: _promotionTypes.entries.map<Widget>((entry) {
        final isSelected = _selectedPromotionType == entry.key;
        final data = entry.value;
        final isAvailable = _isPromotionTypeAvailable(entry.key);

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedPromotionType = entry.key;
                    _selectedSong = null;
                  });
                }
              : null,
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.4,
            child: Container(
              padding:
                  EdgeInsets.all(isTinyScreen ? 6 : (isSmallScreen ? 8 : 12)),
              decoration: BoxDecoration(
                color: isSelected
                    ? (data['color'] as Color).withOpacity(0.2)
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (data['color'] as Color)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data['emoji'],
                        style: TextStyle(
                            fontSize:
                                isTinyScreen ? 24 : (isSmallScreen ? 28 : 32)),
                      ),
                      SizedBox(
                          height: isTinyScreen ? 4 : (isSmallScreen ? 6 : 8)),
                      Text(
                        data['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isTinyScreen ? 10 : (isSmallScreen ? 11 : 13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTinyScreen ? 2 : 4),
                      Text(
                        '\$${NumberFormat('#,###').format(data['baseCost'])}',
                        style: TextStyle(
                          color: data['color'],
                          fontSize:
                              isTinyScreen ? 9 : (isSmallScreen ? 10 : 11),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!isAvailable)
                    Positioned(
                      top: isTinyScreen ? 2 : 4,
                      right: isTinyScreen ? 2 : 4,
                      child: Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: isTinyScreen ? 14 : 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSongSelector(List<Song> songs) {
    // Filter songs based on search query
    final filteredSongs = songs.where((song) {
      if (_searchQuery.isEmpty) return true;
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.genre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by streams descending
    filteredSongs.sort((a, b) => b.streams.compareTo(a.streams));

    // Limit to top 20 songs if not searching
    final displaySongs = _searchQuery.isEmpty
        ? (filteredSongs.length > 20
            ? filteredSongs.sublist(0, 20)
            : filteredSongs)
        : filteredSongs;

    // Responsive check
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Song to Promote',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${songs.length} total',
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by song title or genre...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search, color: AppTheme.accentBlue),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.accentBlue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTinyScreen ? 10 : 14,
              vertical: isTinyScreen ? 10 : 14,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Show result count
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${displaySongs.length} song${displaySongs.length == 1 ? "" : "s"} found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          )
        else if (songs.length > 20)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accentBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing top 20 by streams. Use search to find specific songs.',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Song list
        if (displaySongs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No songs found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...displaySongs.map<Widget>((song) {
            final isSelected = _selectedSong?.id == song.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSong = song;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue.withOpacity(0.2)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cover art thumbnail
                      if (song.coverArtUrl != null &&
                          song.coverArtUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: song.coverArtUrl!,
                            width:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            height:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note,
                                  color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          height: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.music_note,
                              color: Colors.white54),
                        ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${song.genre} • ${NumberFormat('#,###').format(song.streams)} streams',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: isSmallScreen ? 20 : 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEPSelector() {
    final releasedEPs = widget.artistStats.albums
        .where((album) =>
            album.type == AlbumType.ep && album.state == AlbumState.released)
        .toList();

    // Filter EPs based on search query
    final filteredEPs = releasedEPs.where((ep) {
      if (_searchQuery.isEmpty) return true;
      return ep.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Responsive check
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select EP to Promote',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${releasedEPs.length} total',
                style: const TextStyle(
                  color: AppTheme.warningOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        if (releasedEPs.length > 5)
          Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search EPs...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: AppTheme.warningOrange),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.warningOrange, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTinyScreen ? 10 : 14,
                    vertical: isTinyScreen ? 10 : 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

        if (filteredEPs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No EPs found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredEPs.map<Widget>((ep) {
            final isSelected = _selectedAlbum?.id == ep.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAlbum = ep;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue.withOpacity(0.2)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cover art thumbnail
                      if (ep.coverArtUrl != null && ep.coverArtUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: ep.coverArtUrl!,
                            width:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            height:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Icon(Icons.album,
                                  color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          height: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.album, color: Colors.white54),
                        ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'EP • ${ep.songIds.length} songs',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: isSmallScreen ? 20 : 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAlbumSelector() {
    final releasedAlbums = widget.artistStats.albums
        .where((album) =>
            album.type == AlbumType.album && album.state == AlbumState.released)
        .toList();

    // Filter albums based on search query
    final filteredAlbums = releasedAlbums.where((album) {
      if (_searchQuery.isEmpty) return true;
      return album.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Responsive check
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Album to Promote',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${releasedAlbums.length} total',
                style: const TextStyle(
                  color: AppTheme.neonPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        if (releasedAlbums.length > 5)
          Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Albums...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: AppTheme.neonPurple),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.neonPurple, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTinyScreen ? 10 : 14,
                    vertical: isTinyScreen ? 10 : 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

        if (filteredAlbums.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Albums found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredAlbums.map<Widget>((album) {
            final isSelected = _selectedAlbum?.id == album.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAlbum = album;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue.withOpacity(0.2)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cover art thumbnail
                      if (album.coverArtUrl != null &&
                          album.coverArtUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: album.coverArtUrl!,
                            width:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            height:
                                isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              height:
                                  isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                              color: Colors.grey[800],
                              child: const Icon(Icons.album,
                                  color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          height: isTinyScreen ? 40 : (isSmallScreen ? 45 : 50),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.album, color: Colors.white54),
                        ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Album • ${album.songIds.length} songs',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: isSmallScreen ? 20 : 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPromotionControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isTinyScreen = screenWidth < 380;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _promoDays.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppTheme.accentBlue,
                  inactiveColor: Colors.white.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _promoDays = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12),
                  vertical: isTinyScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_promoDays days',
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Budget Multiplier',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _budgetMultiplier,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  activeColor: AppTheme.warningOrange,
                  inactiveColor: Colors.white.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _budgetMultiplier = value;
                    });
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12),
                  vertical: isTinyScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_budgetMultiplier.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: AppTheme.warningOrange,
                    fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignDetails() {
    final data = _promotionTypes[_selectedPromotionType]!;
    final totalCost = _totalCost;
    final potentialReach = _calculatePotentialReach();

    // Show ranges for estimates (actual results vary)
    // Reach: 80-120% of potential
    final reachMin = (potentialReach * 0.8 * _budgetMultiplier).round();
    final reachMax = (potentialReach * 1.2 * _budgetMultiplier).round();

    // Fans: 3-6% conversion
    final fansMin = (reachMin * 0.03).round();
    final fansMax = (reachMax * 0.06).round();

    // Daily streams: 20-40% of reach * multiplier
    final dailyStreamsMin = (reachMin * 0.20).round();
    final dailyStreamsMax = (reachMax * 0.40).round();

    final totalStreamsMin = dailyStreamsMin * _promoDays;
    final totalStreamsMax = dailyStreamsMax * _promoDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (data['color'] as Color).withOpacity(0.2),
            (data['color'] as Color).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (data['color'] as Color).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign Summary',
            style: TextStyle(
              color: data['color'],
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Total Cost',
            '\$${NumberFormat('#,###').format(totalCost)}',
            Icons.payments,
          ),
          _buildDetailRow(
            'Duration',
            '$_promoDays in-game days',
            Icons.schedule,
          ),
          _buildDetailRow(
            'Budget Level',
            '${_budgetMultiplier.toStringAsFixed(1)}x',
            Icons.trending_up,
          ),
          _buildDetailRow(
            'Potential Reach',
            '${NumberFormat('#,###').format(reachMin)}-${NumberFormat('#,###').format(reachMax)} people',
            Icons.people,
          ),
          _buildDetailRow(
            'Estimated Fans',
            '+${NumberFormat('#,###').format(fansMin)}-${NumberFormat('#,###').format(fansMax)} fans',
            Icons.person_add,
          ),
          _buildDetailRow(
            'Daily Streams',
            '+${NumberFormat('#,###').format(dailyStreamsMin)}-${NumberFormat('#,###').format(dailyStreamsMax)} streams/day',
            Icons.play_arrow,
          ),
          _buildDetailRow(
            'Total Streams',
            '+${NumberFormat('#,###').format(totalStreamsMin)}-${NumberFormat('#,###').format(totalStreamsMax)} streams',
            Icons.trending_up,
          ),
          _buildDetailRow(
            'Fame Boost',
            '+${_calculateFameGain()}',
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.errorRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not enough money (\$${NumberFormat('#,###').format(_totalCost)} required)',
              style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  bool _canLaunchCampaign() {
    // Check if promotion type is available
    if (!_isPromotionTypeAvailable(_selectedPromotionType)) {
      return false;
    }

    // For song promotion, need to select a song
    if (_selectedPromotionType == 'song') {
      if (_selectedSong == null) return false;

      // Check if song already has max concurrent promos
      if (_hasMaxConcurrentPromos(_selectedSong!)) {
        return false;
      }
    } else if (_selectedAlbum != null) {
      // Check if any song in album has max concurrent promos
      final albumSongs = widget.artistStats.songs
          .where((s) => _selectedAlbum!.songIds.contains(s.id))
          .toList();

      if (albumSongs.any((s) => _hasMaxConcurrentPromos(s))) {
        return false;
      }
    }

    return true;
  }

  // Check if a song already has maximum concurrent promotions
  bool _hasMaxConcurrentPromos(Song song) {
    if (song.promoBuffer == null || song.promoBuffer! <= 0) return false;
    if (song.promoEndDate == null ||
        song.promoEndDate!.isBefore(widget.currentGameDate)) return false;

    // For now, we'll use buffer size as a proxy for number of concurrent promos
    // This is approximate but prevents extreme stacking
    final estimatedPromoCount = (song.promoBuffer! / 1000).ceil();
    return estimatedPromoCount >= maxConcurrentPromosPerItem;
  }

  String _getButtonText(bool canPromote) {
    if (!_isPromotionTypeAvailable(_selectedPromotionType)) {
      return 'Requirements Not Met';
    }

    // Check for max concurrent promos
    if (_selectedPromotionType == 'song' && _selectedSong != null) {
      if (_hasMaxConcurrentPromos(_selectedSong!)) {
        return 'Max Promos Active';
      }
    } else if (_selectedAlbum != null) {
      final albumSongs = widget.artistStats.songs
          .where((s) => _selectedAlbum!.songIds.contains(s.id))
          .toList();
      if (albumSongs.any((s) => _hasMaxConcurrentPromos(s))) {
        return 'Max Promos Active';
      }
    }

    if (!_canLaunchCampaign()) {
      return _selectedPromotionType == 'song'
          ? 'Select a Song'
          : 'Launch Campaign';
    }
    if (!canPromote) {
      return 'Insufficient Resources';
    }
    return 'Launch Campaign';
  }

  int _calculatePotentialReach() {
    final baseReach =
        _promotionTypes[_selectedPromotionType]!['baseReach'] as int;
    // REDUCED BONUSES: Fame and fanbase bonuses are now much smaller
    final fameBonus = widget.artistStats.fame * 20; // Reduced from 100
    final fanbaseBonus = widget.artistStats.fanbase * 10; // Reduced from 50

    return baseReach + fameBonus + fanbaseBonus;
  }

  int _calculateFameGain() {
    int baseFame;
    switch (_selectedPromotionType) {
      case 'song':
        baseFame = 1; // Reduced from 3
        break;
      case 'ep':
        baseFame = 3; // Reduced from 10
        break;
      case 'lp':
        baseFame = 8; // Reduced from 20
        break;
      default:
        baseFame = 1;
    }
    // Scale with budget multiplier
    return (baseFame * _budgetMultiplier).round();
  }

  void _launchCampaign() {
    final random = Random();
    final potentialReach = _calculatePotentialReach();

    // Calculate actual results with some randomness (80-120% of estimate)
    final reachMultiplier = 0.8 + random.nextDouble() * 0.4;
    final actualReach =
        (potentialReach * reachMultiplier * _budgetMultiplier).round();

    // REDUCED FANBASE GAIN: 3-6% conversion rate (down from 12-18%)
    final fansGained =
        (actualReach * (0.03 + random.nextDouble() * 0.03)).round();

    // ✅ FIX: Calculate DAILY buffer first, then multiply by days for total
    // This ensures more days = more TOTAL streams (not diluted)
    // Added more randomness: 20-40% conversion rate (was 25-35%)
    final streamConversionRate = 0.20 + random.nextDouble() * 0.20;
    final dailyStreamsBase =
        (actualReach * streamConversionRate * _budgetMultiplier).round();
    final dailyBuffer = dailyStreamsBase; // This is the per-day boost
    final totalStreamsGained = dailyBuffer * _promoDays; // Total over campaign
    final fameGain = _calculateFameGain();

    // Update songs
    List<Song> updatedSongs = List.from(widget.artistStats.songs);

    // Use user-selected duration
    final promoDurationDays = _promoDays;
    final promoEndDate =
        widget.currentGameDate.add(Duration(days: promoDurationDays));

    if (_selectedPromotionType == 'song' && _selectedSong != null) {
      // Promote single song with buffer
      final songIndex = updatedSongs.indexWhere(
        (s) => s.id == _selectedSong!.id,
      );
      if (songIndex != -1) {
        final existingSong = updatedSongs[songIndex];
        // ADD to existing promo buffer instead of replacing, but CAP at maxDailyBufferPerSong
        final newBuffer = ((existingSong.promoBuffer ?? 0) + dailyBuffer)
            .clamp(0, maxDailyBufferPerSong);
        final newEndDate = (existingSong.promoEndDate != null &&
                existingSong.promoEndDate!.isAfter(promoEndDate))
            ? existingSong.promoEndDate
            : promoEndDate;

        updatedSongs[songIndex] = existingSong.copyWith(
          promoBuffer: newBuffer,
          promoEndDate: newEndDate,
        );
      }
    } else if (_selectedPromotionType == 'ep' && _selectedAlbum != null) {
      // Promote all songs in the selected EP
      final epSongIds = _selectedAlbum!.songIds.toSet();
      final songBuffer =
          (totalStreamsGained / promoDurationDays / epSongIds.length).round();
      updatedSongs = updatedSongs.map((song) {
        if (epSongIds.contains(song.id)) {
          // ADD to existing promo buffer for each song, but CAP at maxDailyBufferPerSong
          final newBuffer = ((song.promoBuffer ?? 0) + songBuffer)
              .clamp(0, maxDailyBufferPerSong);
          final newEndDate = (song.promoEndDate != null &&
                  song.promoEndDate!.isAfter(promoEndDate))
              ? song.promoEndDate
              : promoEndDate;

          return song.copyWith(
            promoBuffer: newBuffer,
            promoEndDate: newEndDate,
          );
        }
        return song;
      }).toList();
    } else if (_selectedPromotionType == 'lp' && _selectedAlbum != null) {
      // Promote all songs in the selected Album
      final albumSongIds = _selectedAlbum!.songIds.toSet();
      final songBuffer =
          (totalStreamsGained / promoDurationDays / albumSongIds.length)
              .round();
      updatedSongs = updatedSongs.map((song) {
        if (albumSongIds.contains(song.id)) {
          // ADD to existing promo buffer for each song, but CAP at maxDailyBufferPerSong
          final newBuffer = ((song.promoBuffer ?? 0) + songBuffer)
              .clamp(0, maxDailyBufferPerSong);
          final newEndDate = (song.promoEndDate != null &&
                  song.promoEndDate!.isAfter(promoEndDate))
              ? song.promoEndDate
              : promoEndDate;

          return song.copyWith(
            promoBuffer: newBuffer,
            promoEndDate: newEndDate,
          );
        }
        return song;
      }).toList();
    }

    // Update artist stats
    // ✅ FIX: Don't add fanbase instantly - it will grow gradually through daily streams
    final updatedStats = widget.artistStats.copyWith(
      money: widget.artistStats.money - _totalCost,
      // fanbase: widget.artistStats.fanbase + fansGained, // REMOVED - no instant gain
      fame: widget.artistStats.fame + fameGain,
      songs: updatedSongs,
      lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
    );

    widget.onStatsUpdated(updatedStats);

    // Get the promoted item name for display
    String promotedItemName = 'Unknown';
    if (_selectedPromotionType == 'song' && _selectedSong != null) {
      promotedItemName = _selectedSong!.title;
    } else if (_selectedAlbum != null) {
      promotedItemName = _selectedAlbum!.title;
    }

    // Show results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Campaign Launched!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your campaign for "$promotedItemName" is now active!',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildResultRow('📅 Duration', '$_promoDays in-game days'),
            _buildResultRow('👥 Potential Fans', '~$fansGained (gradual)'),
            _buildResultRow('▶️ Daily Streams', '+$dailyBuffer/day'),
            _buildResultRow('▶️ Total Streams', '+$totalStreamsGained'),
            _buildResultRow('⭐ Fame Boost', '+$fameGain'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.accentBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Streams and fans will grow gradually over $_promoDays days as your music gains traction',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(color: AppTheme.accentBlue),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedSong = null;
                _selectedAlbum = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Launch Another',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
