import 'package:flutter/material.dart';
import 'dart:math';
import '../models/artist_stats.dart';
import '../models/song.dart';

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

  final Map<String, Map<String, dynamic>> _promotionTypes = {
    'song': {
      'name': 'Single Song',
      'emoji': '🎵',
      'energyCost': 10,
      'moneyCost': 100,
      'baseReach': 5000,
      'color': const Color(0xFF00D9FF),
      'description': 'Promote one song to gain streams and fans',
    },
    'single': {
      'name': 'Single (1-2 songs)',
      'emoji': '💿',
      'energyCost': 15,
      'moneyCost': 300,
      'baseReach': 12000,
      'color': const Color(0xFF9B59B6),
      'description': 'Promote a single for wider reach',
    },
    'ep': {
      'name': 'EP (3-6 songs)',
      'emoji': '📀',
      'energyCost': 20,
      'moneyCost': 800,
      'baseReach': 25000,
      'color': const Color(0xFFFF9F0A),
      'description': 'Promote an EP to multiple audiences',
    },
    'lp': {
      'name': 'LP/Album (7+ songs)',
      'emoji': '💽',
      'energyCost': 30,
      'moneyCost': 2000,
      'baseReach': 50000,
      'color': const Color(0xFFFF1744),
      'description': 'Major album promotion campaign',
    },
  };

  @override
  Widget build(BuildContext context) {
    final releasedSongs = widget.artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList();

    final canPromote =
        widget.artistStats.energy >= _currentEnergyCost &&
        widget.artistStats.money >= _currentMoneyCost;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Text(
              '📱 ViralWave',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Promotion Platform',
              style: TextStyle(color: Colors.white60, fontSize: 14),
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

                    const SizedBox(height: 24),

                    // Song/Album selector
                    if (_selectedPromotionType == 'song')
                      _buildSongSelector(releasedSongs)
                    else
                      _buildAlbumInfo(),

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

  int get _currentEnergyCost =>
      _promotionTypes[_selectedPromotionType]!['energyCost'] as int;

  int get _currentMoneyCost =>
      _promotionTypes[_selectedPromotionType]!['moneyCost'] as int;

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
              _buildHeaderStat('⚡', '${widget.artistStats.energy}'),
              const SizedBox(width: 12),
              _buildHeaderStat('💰', '\$${widget.artistStats.money}'),
              const SizedBox(width: 12),
              _buildHeaderStat('👥', '${widget.artistStats.fanbase}'),
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

  Widget _buildPromotionTypeSelector() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: _promotionTypes.entries.map((entry) {
        final isSelected = _selectedPromotionType == entry.key;
        final data = entry.value;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPromotionType = entry.key;
              _selectedSong = null;
            });
          },
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
            child: Column(
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
                  '${data['energyCost']} ⚡ | \$${data['moneyCost']}',
                  style: TextStyle(
                    color: data['color'],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                    Text('🎵', style: const TextStyle(fontSize: 24)),
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

  Widget _buildAlbumInfo() {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _promotionTypes[_selectedPromotionType]!['color'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About ${_promotionTypes[_selectedPromotionType]!['name']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _promotionTypes[_selectedPromotionType]!['description'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF0A84FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This campaign will boost all your released songs',
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontSize: 13,
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

  Widget _buildCampaignDetails() {
    final data = _promotionTypes[_selectedPromotionType]!;
    final potentialReach = _calculatePotentialReach();
    final estimatedFans = (potentialReach * 0.15).round();
    final estimatedStreams = (potentialReach * 0.3).round();

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
            'Cost',
            '${data['energyCost']} ⚡ + \$${data['moneyCost']}',
            Icons.payments,
          ),
          _buildDetailRow(
            'Potential Reach',
            '$potentialReach people',
            Icons.people,
          ),
          _buildDetailRow(
            'Estimated Fans',
            '+$estimatedFans fans',
            Icons.person_add,
          ),
          _buildDetailRow(
            'Estimated Streams',
            '+$estimatedStreams streams',
            Icons.play_arrow,
          ),
          _buildDetailRow('Fame Boost', '+${_calculateFameGain()}', Icons.star),
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
    final needsEnergy = widget.artistStats.energy < _currentEnergyCost;
    final needsMoney = widget.artistStats.money < _currentMoneyCost;

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
              needsEnergy && needsMoney
                  ? 'Need more energy and money'
                  : needsEnergy
                  ? 'Not enough energy'
                  : 'Not enough money',
              style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  bool _canLaunchCampaign() {
    if (_selectedPromotionType == 'song') {
      return _selectedSong != null;
    }
    return true;
  }

  String _getButtonText(bool canPromote) {
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
    final fameBonus = (widget.artistStats.fame * 100).toInt();
    final fanbaseBonus = (widget.artistStats.fanbase * 50).toInt();

    return baseReach + fameBonus + fanbaseBonus;
  }

  int _calculateFameGain() {
    switch (_selectedPromotionType) {
      case 'song':
        return 3;
      case 'single':
        return 5;
      case 'ep':
        return 10;
      case 'lp':
        return 20;
      default:
        return 3;
    }
  }

  void _launchCampaign() {
    final random = Random();
    final potentialReach = _calculatePotentialReach();

    // Calculate actual results with some randomness (80-120% of estimate)
    final reachMultiplier = 0.8 + random.nextDouble() * 0.4;
    final actualReach = (potentialReach * reachMultiplier).round();
    final fansGained = (actualReach * (0.12 + random.nextDouble() * 0.06))
        .round();
    final streamsGained = (actualReach * (0.25 + random.nextDouble() * 0.1))
        .round();
    final fameGain = _calculateFameGain();

    // Update songs
    List<Song> updatedSongs = List.from(widget.artistStats.songs);

    if (_selectedPromotionType == 'song' && _selectedSong != null) {
      // Promote single song
      final songIndex = updatedSongs.indexWhere(
        (s) => s.id == _selectedSong!.id,
      );
      if (songIndex != -1) {
        updatedSongs[songIndex] = updatedSongs[songIndex].copyWith(
          streams: updatedSongs[songIndex].streams + streamsGained,
        );
      }
    } else {
      // Promote all released songs
      updatedSongs = updatedSongs.map((song) {
        if (song.state == SongState.released) {
          final songBoost =
              (streamsGained /
                      updatedSongs
                          .where((s) => s.state == SongState.released)
                          .length)
                  .round();
          return song.copyWith(streams: song.streams + songBoost);
        }
        return song;
      }).toList();
    }

    // Update artist stats
    final updatedStats = widget.artistStats.copyWith(
      energy: widget.artistStats.energy - _currentEnergyCost,
      money: widget.artistStats.money - _currentMoneyCost,
      fanbase: widget.artistStats.fanbase + fansGained,
      fame: widget.artistStats.fame + fameGain,
      songs: updatedSongs,
    );

    widget.onStatsUpdated(updatedStats);

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
                'Campaign Successful!',
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
              'Your ${_promotionTypes[_selectedPromotionType]!['name']} campaign reached $actualReach people!',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildResultRow('👥 New Fans', '+$fansGained'),
            _buildResultRow('▶️ Streams', '+$streamsGained'),
            _buildResultRow('⭐ Fame', '+$fameGain'),
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
