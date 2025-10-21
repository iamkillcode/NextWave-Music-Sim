import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../theme/nextwave_theme.dart';
import '../widgets/arcade/glow_button.dart';
import '../widgets/arcade/neon_card.dart';

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
    final baseCost = _promotionTypes[_selectedPromotionType]!['baseCost'] as int;
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
              shaderCallback: (bounds) => NextWaveTheme.crimsonGradient.createShader(bounds),
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
                          color: const Color(0xFFFF453A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF453A).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock,
                              color: Color(0xFFFF453A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getValidationMessage(_selectedPromotionType),
                                style: const TextStyle(
                                  color: Color(0xFFFF453A),
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
                          backgroundColor: const Color(0xFFFF6B9D),
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
    final releasedEPs = releasedAlbums.where((a) => a.type == AlbumType.ep).toList();
    final releasedLPs = releasedAlbums.where((a) => a.type == AlbumType.album).toList();

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
    
    final releasedEPs = releasedAlbums.where((a) => a.type == AlbumType.ep).toList();
    final releasedLPs = releasedAlbums.where((a) => a.type == AlbumType.album).toList();

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF1744)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boost Your Music',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reach millions of potential fans',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('💰', '\$${NumberFormat('#,###').format(widget.artistStats.money)}'),
              const SizedBox(width: 12),
              _buildHeaderStat('👥', NumberFormat('#,###').format(widget.artistStats.fanbase)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String emoji, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
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
      ),
    );
  }

  Widget _buildActiveCampaignsSection() {
    // Get all songs with active promotions
    final activeCampaigns = widget.artistStats.songs.where((song) {
      return song.promoBuffer != null && 
             song.promoBuffer! > 0 && 
             song.promoEndDate != null &&
             song.promoEndDate!.isAfter(widget.currentGameDate);
    }).toList();

    if (activeCampaigns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFF00D9FF), size: 20),
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
                color: const Color(0xFF00D9FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${activeCampaigns.length} running',
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeCampaigns.map((song) {
          final daysRemaining = song.promoEndDate!.difference(widget.currentGameDate).inDays;
          final progress = 1.0 - (daysRemaining / 30.0).clamp(0.0, 1.0);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
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
                        color: Color(0xFF00D9FF),
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
                        color: Color(0xFF00D9FF),
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
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPromotionTypeSelector() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, // Changed to 3 columns for 3 options
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: _promotionTypes.entries.map((entry) {
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (data['color'] as Color).withOpacity(0.2)
                    : const Color(0xFF161B22),
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
                      Text(data['emoji'], style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        data['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,###').format(data['baseCost'])}',
                        style: TextStyle(
                          color: data['color'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!isAvailable)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: 16,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Song to Promote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...songs.map((song) {
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D9FF).withOpacity(0.2)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D9FF)
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Cover art thumbnail
                    if (song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: song.coverArtUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white54),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${song.genre} • ${song.streams} streams',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF32D74B),
                        size: 22,
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
        .where((album) => album.type == 'EP' && album.state == 'released')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select EP to Promote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...releasedEPs.map((ep) {
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D9FF).withOpacity(0.2)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D9FF)
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
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.album, color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.album, color: Colors.white54),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ep.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'EP • ${ep.songIds.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF32D74B),
                        size: 22,
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
        .where((album) => album.type == 'Album' && album.state == 'released')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Album to Promote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...releasedAlbums.map((album) {
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D9FF).withOpacity(0.2)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D9FF)
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Cover art thumbnail
                    if (album.coverArtUrl != null && album.coverArtUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: album.coverArtUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.album, color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.album, color: Colors.white54),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Album • ${album.songIds.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF32D74B),
                        size: 22,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _promoDays.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: const Color(0xFF00D9FF),
                  inactiveColor: Colors.white.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _promoDays = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_promoDays days',
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Budget Multiplier',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _budgetMultiplier,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  activeColor: const Color(0xFFFFD60A),
                  inactiveColor: Colors.white.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _budgetMultiplier = value;
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_budgetMultiplier.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Color(0xFFFFD60A),
                    fontSize: 14,
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
    final estimatedFans = (potentialReach * 0.15 * _budgetMultiplier).round();
    final estimatedStreamsPerDay = (potentialReach * 0.3 * _budgetMultiplier / _promoDays).round();
    final totalStreams = estimatedStreamsPerDay * _promoDays;

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
            '${NumberFormat('#,###').format(potentialReach)} people',
            Icons.people,
          ),
          _buildDetailRow(
            'Estimated Fans',
            '+${NumberFormat('#,###').format(estimatedFans)} fans',
            Icons.person_add,
          ),
          _buildDetailRow(
            'Daily Streams',
            '+${NumberFormat('#,###').format(estimatedStreamsPerDay)} streams/day',
            Icons.play_arrow,
          ),
          _buildDetailRow(
            'Total Streams',
            '+${NumberFormat('#,###').format(totalStreams)} streams',
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
        color: const Color(0xFFFF453A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFFF453A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not enough money (\$${NumberFormat('#,###').format(_totalCost)} required)',
              style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13),
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
      return _selectedSong != null;
    }

    return true;
  }

  String _getButtonText(bool canPromote) {
    if (!_isPromotionTypeAvailable(_selectedPromotionType)) {
      return 'Requirements Not Met';
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
    final actualReach = (potentialReach * reachMultiplier * _budgetMultiplier).round();
    
    // REDUCED FANBASE GAIN: 3-6% conversion rate (down from 12-18%)
    final fansGained =
        (actualReach * (0.03 + random.nextDouble() * 0.03)).round();
    
    final totalStreamsGained =
        (actualReach * (0.25 + random.nextDouble() * 0.1) * _budgetMultiplier).round();
    final fameGain = _calculateFameGain();

    // Update songs
    List<Song> updatedSongs = List.from(widget.artistStats.songs);

    // Use user-selected duration
    final promoDurationDays = _promoDays;
    final promoEndDate =
        widget.currentGameDate.add(Duration(days: promoDurationDays));
    final dailyBuffer = (totalStreamsGained / promoDurationDays).round();

    if (_selectedPromotionType == 'song' && _selectedSong != null) {
      // Promote single song with buffer
      final songIndex = updatedSongs.indexWhere(
        (s) => s.id == _selectedSong!.id,
      );
      if (songIndex != -1) {
        updatedSongs[songIndex] = updatedSongs[songIndex].copyWith(
          promoBuffer: dailyBuffer,
          promoEndDate: promoEndDate,
        );
      }
    } else if (_selectedPromotionType == 'ep' && _selectedAlbum != null) {
      // Promote all songs in the selected EP
      final epSongIds = _selectedAlbum!.songIds.toSet();
      final songBuffer = (totalStreamsGained /
              promoDurationDays /
              epSongIds.length)
          .round();
      updatedSongs = updatedSongs.map((song) {
        if (epSongIds.contains(song.id)) {
          return song.copyWith(
            promoBuffer: songBuffer,
            promoEndDate: promoEndDate,
          );
        }
        return song;
      }).toList();
    } else if (_selectedPromotionType == 'lp' && _selectedAlbum != null) {
      // Promote all songs in the selected Album
      final albumSongIds = _selectedAlbum!.songIds.toSet();
      final songBuffer = (totalStreamsGained /
              promoDurationDays /
              albumSongIds.length)
          .round();
      updatedSongs = updatedSongs.map((song) {
        if (albumSongIds.contains(song.id)) {
          return song.copyWith(
            promoBuffer: songBuffer,
            promoEndDate: promoEndDate,
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
        backgroundColor: const Color(0xFF161B22),
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
                color: const Color(0xFF0A84FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Streams and fans will grow gradually over $_promoDays days as your music gains traction',
                      style: const TextStyle(
                        color: Color(0xFF0A84FF),
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
              style: TextStyle(color: Color(0xFF0A84FF)),
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
              backgroundColor: const Color(0xFFFF6B9D),
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
            style: const TextStyle(
              color: Color(0xFF32D74B),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
