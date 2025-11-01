import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/studio.dart';
import '../models/world_region.dart';
import 'sound_mixing_minigame.dart';

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

  List<Song> get writtenSongs =>
      _currentStats.songs.where((s) => s.state == SongState.written).toList();

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
    final meetsRequirements = studio.meetsRequirements(_currentStats);
    final attitude = studio.getAttitude(_currentStats);
    final baseCost = studio.getAdjustedPrice(false, regionMultiplier, attitude);
    final producerCost =
        studio.getAdjustedPrice(true, regionMultiplier, attitude);
    final canAffordBasic = _currentStats.money >= baseCost &&
        _currentStats.energy >= 30 &&
        meetsRequirements;
    final canAffordProducer = _currentStats.money >= producerCost &&
        _currentStats.energy >= 30 &&
        meetsRequirements;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            studio.getTierColor().withOpacity(meetsRequirements ? 0.2 : 0.1),
            const Color(0xFF21262D).withOpacity(meetsRequirements ? 1.0 : 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: meetsRequirements
              ? studio.getTierColor().withOpacity(0.5)
              : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Text(
                    studio.getTierIcon(),
                    style: const TextStyle(fontSize: 32),
                  ),
                  if (!meetsRequirements)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      style: TextStyle(
                        color:
                            meetsRequirements ? Colors.white : Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      studio.location,
                      style: TextStyle(
                        color:
                            meetsRequirements ? Colors.white60 : Colors.white30,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: studio.getAttitudeColor(attitude),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attitude.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            studio.description,
            style: TextStyle(
              color: meetsRequirements ? Colors.white70 : Colors.white38,
              fontSize: 13,
            ),
          ),

          // Requirements Section
          if (studio.requirements.minFame > 0 ||
              studio.requirements.minAlbums > 0 ||
              studio.requirements.minSongsReleased > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: meetsRequirements
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: meetsRequirements
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        meetsRequirements ? Icons.check_circle : Icons.lock,
                        color: meetsRequirements ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meetsRequirements ? 'ACCESS GRANTED' : 'REQUIREMENTS',
                        style: TextStyle(
                          color: meetsRequirements ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (studio.requirements.minFame > 0)
                    _buildRequirementRow(
                      'Fame',
                      studio.requirements.minFame,
                      _currentStats.fame,
                      Icons.whatshot,
                    ),
                  if (studio.requirements.minAlbums > 0)
                    _buildRequirementRow(
                      'Albums',
                      studio.requirements.minAlbums,
                      _currentStats.albumsSold > 0
                          ? (_currentStats.albumsSold / 1000).ceil()
                          : 0,
                      Icons.album,
                    ),
                  if (studio.requirements.minSongsReleased > 0)
                    _buildRequirementRow(
                      'Released Songs',
                      studio.requirements.minSongsReleased,
                      _currentStats.songs
                          .where((s) => s.state == SongState.released)
                          .length,
                      Icons.music_note,
                    ),
                ],
              ),
            ),
          ],

          // Attitude Description
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: studio.getAttitudeColor(attitude).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getAttitudeIcon(attitude),
                  color: studio.getAttitudeColor(attitude),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    studio.getAttitudeDescription(attitude),
                    style: TextStyle(
                      color: studio.getAttitudeColor(attitude),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exclusive Note
          if (studio.exclusiveNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.purple,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studio.exclusiveNote,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Connection Benefits
          if (studio.hasConnectionBenefits()) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studio.getConnectionBenefit(),
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('Quality', '${studio.qualityRating}%', Icons.star),
              const SizedBox(width: 8),
              _buildStatChip('Rep', '${studio.reputation}%', Icons.trending_up),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Fame', '+${studio.getFameBonus()}', Icons.whatshot),
            ],
          ),
          if (studio.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: studio.specialties.map((specialty) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  onPressed: canAffordBasic
                      ? () => _showSongSelectionDialog(studio, false)
                      : null,
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
                    onPressed: canAffordProducer
                        ? () => _showSongSelectionDialog(studio, true)
                        : null,
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

  void _recordSongAtStudio(Song song, Studio studio, bool useProducer) async {
    // If Self Produce, launch Sound Mixing Minigame first
    int qualityBonus = 0;
    if (!useProducer) {
      final result = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SoundMixingMinigame(
          song: song,
          onComplete: (bonus) => Navigator.pop(context, bonus),
        ),
      );

      // If user cancelled the minigame
      if (result == null) return;
      qualityBonus = result;
    }

    final regionMultiplier = _currentRegion?.costOfLivingMultiplier ?? 1.0;
    final attitude = studio.getAttitude(_currentStats);
    final cost =
        studio.getAdjustedPrice(useProducer, regionMultiplier, attitude);

    // Calculate recording quality with attitude modifier
    final studioQuality = studio.qualityRating;
    final studioRepBonus = (studio.reputation / 100.0) * 10;
    final producerBonus = useProducer ? (studio.producerSkill / 100.0) * 15 : 0;
    final specialtyBonus = studio.specialties
            .any((s) => s.toLowerCase() == song.genre.toLowerCase())
        ? 10
        : 0;
    final attitudeModifier = studio.getAttitudeQualityModifier(attitude);

    // Apply mixing quality bonus/penalty (only for Self Produce)
    final baseQuality = studioQuality +
        studioRepBonus +
        producerBonus +
        specialtyBonus +
        qualityBonus;
    final recordingQuality =
        (baseQuality * attitudeModifier).clamp(1, 100).round();

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

    // Build success message
    String producerText = useProducer ? '\n🎛️ With studio producer!' : '';
    String mixingText = '';
    if (!useProducer) {
      if (qualityBonus > 0) {
        mixingText = '\n🎛️ Excellent mix! +$qualityBonus quality bonus';
      } else if (qualityBonus < 0) {
        mixingText = '\n🎛️ Poor mix. $qualityBonus quality penalty';
      } else {
        mixingText = '\n🎛️ Decent mix. No quality change';
      }
    }
    String attitudeText = attitude != StudioAttitude.neutral
        ? '\n${_getAttitudeEmoji(attitude)} Studio Attitude: ${attitude.name}'
        : '';
    _showMessage('🎤 Recorded "${song.title}" at ${studio.name}!\n'
        'Recording Quality: $recordingQuality%'
        '$producerText$mixingText$attitudeText\n'
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

  Widget _buildRequirementRow(
      String label, int required, int current, IconData icon) {
    final met = current >= required;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 6),
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            '$current/$required',
            style: TextStyle(
              color: met ? Colors.green : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAttitudeIcon(StudioAttitude attitude) {
    switch (attitude) {
      case StudioAttitude.welcoming:
        return Icons.celebration;
      case StudioAttitude.friendly:
        return Icons.thumb_up;
      case StudioAttitude.neutral:
        return Icons.remove_circle_outline;
      case StudioAttitude.skeptical:
        return Icons.help_outline;
      case StudioAttitude.dismissive:
        return Icons.thumb_down;
      case StudioAttitude.closed:
        return Icons.block;
    }
  }

  String _getAttitudeEmoji(StudioAttitude attitude) {
    switch (attitude) {
      case StudioAttitude.welcoming:
        return '🎉';
      case StudioAttitude.friendly:
        return '😊';
      case StudioAttitude.neutral:
        return '😐';
      case StudioAttitude.skeptical:
        return '🤔';
      case StudioAttitude.dismissive:
        return '😒';
      case StudioAttitude.closed:
        return '🚫';
    }
  }
}
