import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/game_time_service.dart';
import '../services/nexttube_service.dart';
import 'nexttube_video_detail_screen.dart';
import '../services/certifications_service.dart';

/// Screen showing detailed information about a released album
/// Displays tracklist with individual song streams
class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  final List<Song> songs;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.songs,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late final GameTimeService _gameTimeService;
  late Album _album;
  late List<Song> _songs;
  final _certService = CertificationsService();
  bool _eligibilityLoading = false;
  AlbumEligibility? _eligibility;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _gameTimeService = GameTimeService();
    _album = widget.album;
    _songs = List<Song>.from(widget.songs);
    _loadAlbumEligibility();
  }

  Future<void> _loadAlbumEligibility() async {
    setState(() => _eligibilityLoading = true);
    try {
      final list = await _certService.listAlbumEligibility();
      final found = list.firstWhere(
        (e) => e.id == _album.id,
        orElse: () => AlbumEligibility(
          id: _album.id,
          title: _album.title,
          units: _album.eligibleUnits,
          currentTier: _album.highestCertification,
          currentLevel: _album.certificationLevel,
          nextTier: 'none',
          nextLevel: 0,
          eligibleNow: false,
        ),
      );
      if (mounted) setState(() => _eligibility = found);
    } catch (e) {
      // best-effort; keep silent in UI
    } finally {
      if (mounted) setState(() => _eligibilityLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total streams from all songs
    final totalStreams = _songs.fold<int>(0, (sum, song) => sum + song.streams);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(_album.title),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Header with Cover Art
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF161B22),
                    const Color(0xFF0D1117),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Album Cover Art
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF1C2128),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _album.coverArtUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: _album.coverArtUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _album.typeEmoji,
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _album.typeEmoji,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Album Title
                  Text(
                    _album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Album Type
                  Text(
                    _album.typeDisplay,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(
                        icon: Icons.music_note,
                        label: '${_songs.length} songs',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        icon: Icons.bar_chart,
                        label: _formatNumber(totalStreams),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      if (_album.highestCertification.toLowerCase() != 'none' &&
                          (_album.certificationLevel) > 0)
                        _buildCertificationChip(_album),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Release Date
                  if (_album.releasedDate != null)
                    Text(
                      'Released ${_gameTimeService.formatGameDate(_album.releasedDate!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Streaming Platforms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (_album.streamingPlatforms.isNotEmpty
                            ? _album.streamingPlatforms
                            : <String>['tunify', 'maple_music'])
                        .map((platform) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                platform == 'tunify' ? '🎵 Tunify' : '🍁 Maple',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_eligibilityLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_eligibility?.eligibleNow == true)
                    ElevatedButton.icon(
                      onPressed:
                          _submitting ? null : _handleSubmitCertification,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: Text(
                          'Submit for Certification (${_eligibility!.nextTier} ${_eligibility!.nextLevel > 1 ? 'x${_eligibility!.nextLevel}' : ''})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            // Tracklist Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tracklist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Song List
                  ..._songs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final song = entry.value;
                    return _buildSongTile(index + 1, song);
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationChip(Album album) {
    final tier = album.highestCertification.toLowerCase();
    final level = album.certificationLevel;
    Color color;
    String label;
    switch (tier) {
      case 'silver':
        color = Colors.grey.shade300;
        label = 'Silver';
        break;
      case 'gold':
        color = Colors.amberAccent;
        label = 'Gold';
        break;
      case 'platinum':
        color = Colors.lightBlueAccent;
        label = level > 1 ? 'Platinum x$level' : 'Platinum';
        break;
      case 'multi_platinum':
        color = Colors.purpleAccent;
        label = level > 1 ? 'Multi-Platinum x$level' : 'Multi-Platinum';
        break;
      case 'diamond':
        color = Colors.cyanAccent;
        label = level > 1 ? 'Diamond x$level' : 'Diamond';
        break;
      default:
        color = Colors.white70;
        label = tier;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int trackNumber, Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Track Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$trackNumber',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (song.highestCertification.toLowerCase() != 'none' &&
                    song.certificationLevel > 0)
                  _buildSongCertBadge(song),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      song.genre,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Streams + Official link
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(song.streams),
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if ((song.hasOfficialVideo) ||
                      ((song.officialVideoId ?? '').isNotEmpty))
                    Tooltip(
                      message: 'View Official Video',
                      child: IconButton(
                        icon: const Icon(Icons.ondemand_video_rounded,
                            color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          final id = song.officialVideoId;
                          if (id == null || id.isEmpty) return;
                          final video =
                              await NextTubeService().getVideoById(id);
                          if (video == null) return;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NextTubeVideoDetailScreen(
                                video: video,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'streams',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildSongCertBadge(Song song) {
    final tier = song.highestCertification.toLowerCase();
    final level = song.certificationLevel;
    Color color;
    String label;
    switch (tier) {
      case 'silver':
        color = Colors.grey.shade300;
        label = 'Silver';
        break;
      case 'gold':
        color = Colors.amberAccent;
        label = 'Gold';
        break;
      case 'platinum':
        color = Colors.lightBlueAccent;
        label = level > 1 ? 'Platinum x$level' : 'Platinum';
        break;
      case 'multi_platinum':
        color = Colors.purpleAccent;
        label = level > 1 ? 'Multi-Platinum x$level' : 'Multi-Platinum';
        break;
      case 'diamond':
        color = Colors.cyanAccent;
        label = level > 1 ? 'Diamond x$level' : 'Diamond';
        break;
      default:
        color = Colors.white70;
        label = tier;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitCertification() async {
    setState(() => _submitting = true);
    try {
      final res = await _certService.submitAlbum(_album.id);
      if (res.awarded == true) {
        setState(() {
          _album = _album.copyWith(
            highestCertification: res.tier ?? _album.highestCertification,
            certificationLevel: res.level ?? _album.certificationLevel,
            eligibleUnits: res.units ?? _album.eligibleUnits,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Awarded ${res.tier} ${res.level ?? ''}'.trim()),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadAlbumEligibility();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Not eligible yet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submit failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
