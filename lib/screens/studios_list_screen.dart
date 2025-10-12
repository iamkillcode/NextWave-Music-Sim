import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/studio.dart';
import '../models/world_region.dart';

class StudiosListScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const StudiosListScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<StudiosListScreen> createState() => _StudiosListScreenState();
}

class _StudiosListScreenState extends State<StudiosListScreen> {
  late ArtistStats _currentStats;
  List<Studio> _studios = [];
  WorldRegion? _currentRegion;

  @override
  void initState() {
    super.initState();
    _currentStats = widget.artistStats;
    _loadStudios();
  }

  void _loadStudios() {
    final regions = WorldRegion.getAllRegions();
    _currentRegion = regions.firstWhere(
      (r) => r.id == _currentStats.currentRegion,
      orElse: () => regions.first,
    );
    _studios = Studio.getStudiosByRegion(_currentStats.currentRegion);
  }

  List<Song> get writtenSongs => _currentStats.songs.where((s) => s.state == SongState.written).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _currentRegion?.flag ?? '🎙️',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Studios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentRegion?.name ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _studios.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _studios.length,
              itemBuilder: (context, index) {
                return _buildStudioCard(_studios[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎙️', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No Studios Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Travel to another region to find studios!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioCard(Studio studio) {
    final regionMultiplier = _currentRegion?.costOfLivingMultiplier ?? 1.0;
    final baseCost = studio.getTotalCost(false, regionMultiplier);
    final producerCost = studio.getTotalCost(true, regionMultiplier);
    final canAffordBasic = _currentStats.money >= baseCost && _currentStats.energy >= 30;
    final canAffordProducer = _currentStats.money >= producerCost && _currentStats.energy >= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            studio.getTierColor().withOpacity(0.2),
            const Color(0xFF21262D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: studio.getTierColor().withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                studio.getTierIcon(),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      studio.location,
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
                  color: studio.getTierColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  studio.tier.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            studio.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('Quality', '${studio.qualityRating}%', Icons.star),
              const SizedBox(width: 8),
              _buildStatChip('Rep', '${studio.reputation}%', Icons.trending_up),
              const SizedBox(width: 8),
              _buildStatChip('Fame', '+${studio.getFameBonus()}', Icons.whatshot),
            ],
          ),
          if (studio.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: studio.specialties.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    specialty,
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canAffordBasic ? () => _showSongSelectionDialog(studio, false) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    disabledBackgroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Self Produce',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_formatNumber(baseCost)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (studio.hasProducer) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAffordProducer ? () => _showSongSelectionDialog(studio, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      disabledBackgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Studio Producer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_formatNumber(producerCost)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showSongSelectionDialog(Studio studio, bool useProducer) {
    if (writtenSongs.isEmpty) {
      _showMessage('❌ No songs available to record!\nWrite songs first.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF21262D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Song to Record at ${studio.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: writtenSongs.length,
              itemBuilder: (context, index) {
                final song = writtenSongs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: const Color(0xFF30363D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Text(
                      song.genreEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${song.genre} • Quality: ${song.quality}%',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00D9FF),
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _recordSongAtStudio(song, studio, useProducer);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  void _recordSongAtStudio(Song song, Studio studio, bool useProducer) {
    final regionMultiplier = _currentRegion?.costOfLivingMultiplier ?? 1.0;
    final cost = studio.getTotalCost(useProducer, regionMultiplier);

    // Calculate recording quality
    final studioQuality = studio.qualityRating;
    final studioRepBonus = (studio.reputation / 100.0) * 10;
    final producerBonus = useProducer ? (studio.producerSkill / 100.0) * 15 : 0;
    final specialtyBonus = studio.specialties.any((s) => s.toLowerCase() == song.genre.toLowerCase()) ? 10 : 0;
    
    final recordingQuality = (studioQuality + studioRepBonus + producerBonus + specialtyBonus).clamp(1, 100).round();

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
        money: _currentStats.money - cost,
        experience: _currentStats.experience + 30,
        fame: _currentStats.fame + studio.getFameBonus(),
        songs: updatedSongs,
      );
    });

    widget.onStatsUpdated(_currentStats);

    String producerText = useProducer ? '\n🎛️ With studio producer!' : '';
    _showMessage('🎤 Recorded "${song.title}" at ${studio.name}!\n'
                'Recording Quality: $recordingQuality%'
                '$producerText\n'
                '+${studio.getFameBonus()} Fame');
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
