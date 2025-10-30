import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/nexttube_video.dart';
import '../services/nexttube_service.dart';
import '../services/player_content_service.dart';
import '../services/cover_art_uploader.dart';
import '../services/remote_config_service.dart';
import '../services/game_time_service.dart';

class NextTubeUploadScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const NextTubeUploadScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<NextTubeUploadScreen> createState() => _NextTubeUploadScreenState();
}

class _NextTubeUploadScreenState extends State<NextTubeUploadScreen> {
  Song? _selectedSong;
  NextTubeVideoType _type = NextTubeVideoType.official;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _thumbnailUrl;
  bool _isSubmitting = false;
  List<Song> _releasedSongs = [];
  int _estimatedCost = 0; // in money units, consistent with ArtistStats.money
  String _selectedProducer = 'Indie Producer';
  DateTime? _scheduledReleaseDate; // In-game date for scheduled release
  DateTime? _currentGameDate; // Current in-game date
  bool _scheduleRelease = false; // Toggle for scheduling

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _updateCost();
    _loadGameDate();
  }

  Future<void> _loadGameDate() async {
    final gameTimeService = GameTimeService();
    final gameDate = await gameTimeService.getCurrentGameDate();
    setState(() {
      _currentGameDate = gameDate;
      _scheduledReleaseDate = gameDate; // Default to today
    });
  }

  Future<void> _loadSongs() async {
    // Prefer using already-loaded stats if songs exist; else fetch from subcollection
    if (widget.artistStats.songs.isNotEmpty) {
      _releasedSongs = widget.artistStats.songs
          .where((s) => s.state == SongState.released)
          .toList();
    } else {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final list = await PlayerContentService().getSongsForPlayer(userId);
        _releasedSongs =
            list.where((s) => s.state == SongState.released).toList();
      }
    }
    setState(() {});
  }

  void _updateCost() {
    // Base production costs: lyrics < live < official
    int base = switch (_type) {
      NextTubeVideoType.lyrics => 300,
      NextTubeVideoType.live => 800,
      NextTubeVideoType.official => 2000,
    };

    // Producer placeholder multiplier
    final producerMultiplier = switch (_selectedProducer) {
      'Indie Producer' => 1.0,
      'Studio Producer' => 1.2,
      'Top-tier Producer' => 1.5,
      _ => 1.0,
    };

    _estimatedCost = (base * producerMultiplier).round();
    setState(() {});
  }

  Future<void> _pickThumbnail() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _selectedSong == null) return;
    final url = await CoverArtUploader.pickAndUploadCoverArt(
      userId: userId,
      songId: _selectedSong!.id,
      maxWidth: 1280,
      maxHeight: 720,
      imageQuality: 80,
    );
    if (url != null) {
      setState(() => _thumbnailUrl = url);
    }
  }

  Future<void> _submit() async {
    if (_selectedSong == null) {
      _showSnack('Please select a released song');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a video title');
      return;
    }

    // Cost check first (fast, no network)
    if (widget.artistStats.money < _estimatedCost) {
      _showSnack('Not enough money. Requires \$$_estimatedCost');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final svc = NextTubeService();
      final config = RemoteConfigService();

      // Client-side checks (can be bypassed, so server validates too)
      if (_type == NextTubeVideoType.official) {
        if ((_selectedSong!.hasOfficialVideo) ||
            ((_selectedSong!.officialVideoId ?? '').isNotEmpty)) {
          _showSnack('This song already has an official video');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Cooldown check
      final cooldownMinutes = config.nexTubeCooldownMinutes;
      final recentUploads = await svc.fetchMyRecentUploadsSince(
        DateTime.now().subtract(Duration(minutes: cooldownMinutes)),
        limit: 1,
      );
      if (recentUploads.isNotEmpty) {
        _showSnack('Please wait $cooldownMinutes minutes between uploads.');
        setState(() => _isSubmitting = false);
        return;
      }

      // Daily limit check
      final dailyLimit = config.nexTubeDailyUploadLimit;
      final uploads24h = await svc.countMyUploadsSince(
        DateTime.now().subtract(const Duration(hours: 24)),
        limitCap: dailyLimit + 1,
      );
      if (uploads24h >= dailyLimit) {
        _showSnack('Daily upload limit reached ($dailyLimit per day).');
        setState(() => _isSubmitting = false);
        return;
      }

      // Duplicate checks - prevent official and lyrics videos from being created more than once per song
      if (_type == NextTubeVideoType.official || _type == NextTubeVideoType.lyrics) {
        if (await svc.hasVideoForSongAndType(
            songId: _selectedSong!.id, type: _type)) {
          _showSnack(
              'You already have a ${_typeLabel(_type)} video for this song. Only one ${_typeLabel(_type)} per song is allowed.');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Title duplicate check
      final duplicateWindowDays = config.nexTubeDuplicateWindowDays;
      final similarityThreshold = config.nexTubeSimilarityThreshold;

      if (await svc.hasRecentDuplicateTitle(_titleController.text,
          withinDays: duplicateWindowDays)) {
        _showSnack('You already used a very similar title recently');
        setState(() => _isSubmitting = false);
        return;
      }

      final recentVideos = await svc.fetchMyRecentUploadsSince(
        DateTime.now().subtract(Duration(days: duplicateWindowDays)),
        limit: 100,
      );
      final normalizedNew = _normalizeTitle(_titleController.text);
      for (final v in recentVideos) {
        final existingNorm = _normalizeTitle(v.title);
        final sim = _jaccardSimilarity(normalizedNew, existingNorm);
        if (sim > similarityThreshold) {
          _showSnack('Title looks like a near-duplicate of a recent upload');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // SERVER-SIDE VALIDATION (enforces rules even if client is bypassed)
      try {
        final callable =
            FirebaseFunctions.instance.httpsCallable('validateNexTubeUpload');
        final result = await callable.call({
          'title': _titleController.text.trim(),
          'songId': _selectedSong!.id,
          'videoType': _typeId(_type),
        });

        final data = result.data as Map<String, dynamic>;
        if (data['allowed'] != true) {
          _showSnack(
              'Upload blocked: ${data['reason'] ?? 'Server validation failed'}');
          setState(() => _isSubmitting = false);
          return;
        }
      } catch (e) {
        // Server validation failed - show error but allow fallback to client checks
        print('Server validation error: $e');
        _showSnack(
            'Warning: Server validation unavailable, using client checks');
      }

      // All checks passed - proceed with upload
      final nextTubeService = svc;
      final video = await nextTubeService.createVideo(
        stats: widget.artistStats,
        song: _selectedSong!,
        type: _type,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        thumbnailUrl: _thumbnailUrl,
        releaseDate: _scheduleRelease ? _scheduledReleaseDate : null,
        rpmCents: 200,
      );

      // Deduct money and reflect in local stats
      var updatedStats = widget.artistStats.copyWith(
        money: widget.artistStats.money - _estimatedCost,
      );

      // If official video, mark linkage on the song
      if (_type == NextTubeVideoType.official) {
        final updatedSongs = updatedStats.songs.map((s) {
          if (s.id == _selectedSong!.id) {
            return s.copyWith(
              officialVideoId: video.id,
              hasOfficialVideo: true,
            );
          }
          return s;
        }).toList();
        updatedStats = updatedStats.copyWith(songs: updatedSongs);
      }

      widget.onStatsUpdated(updatedStats);

      if (mounted) {
        if (_scheduleRelease && _scheduledReleaseDate != null) {
          final gameTimeService = GameTimeService();
          _showSnack('Video scheduled for ${gameTimeService.formatGameDate(_scheduledReleaseDate!)}: ${video.title}');
        } else {
          _showSnack('Published to NexTube: ${video.title}');
        }
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to upload: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _typeId(NextTubeVideoType type) {
    switch (type) {
      case NextTubeVideoType.official:
        return 'official';
      case NextTubeVideoType.lyrics:
        return 'lyrics';
      case NextTubeVideoType.live:
        return 'live';
    }
  }

  String _typeLabel(NextTubeVideoType t) {
    switch (t) {
      case NextTubeVideoType.official:
        return 'official';
      case NextTubeVideoType.lyrics:
        return 'lyrics';
      case NextTubeVideoType.live:
        return 'live';
    }
  }

  String _normalizeTitle(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), '')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
  }

  double _jaccardSimilarity(String a, String b) {
    final sa = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final sb = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (sa.isEmpty && sb.isEmpty) return 1.0;
    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    return union == 0 ? 0.0 : inter / union;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // YouTube-style logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  SizedBox(width: 4),
                  Text(
                    'NexTube',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundDark,
        actions: [
          // YouTube-style create button
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.video_call, color: AppTheme.errorRed, size: 28),
              onPressed: () {},
              tooltip: 'Create',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube-style header
                Text(
                  'Upload video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post a video to your channel',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Main upload card with YouTube styling
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderDefault,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSongPicker(),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildThumbnailPickerYT(isSmallScreen),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildTextFieldsYT(isSmallScreen),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildTypeSelector(),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildProducerSelector(),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildScheduleSelector(isSmallScreen),
                      Divider(color: AppTheme.borderDefault, height: 1),
                      _buildCostCardYT(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSubmitButtonYT(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongPicker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: AppTheme.neonGreen, size: 20),
              const SizedBox(width: 8),
              const Text('Select song',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderDefault),
            ),
            child: DropdownButtonFormField<String>(
              dropdownColor: AppTheme.surfaceDark,
              value: _selectedSong?.id,
              items: _releasedSongs
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.title,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (id) {
                setState(() {
                  _selectedSong = _releasedSongs.firstWhere((s) => s.id == id);
                  if (_titleController.text.isEmpty) {
                    _titleController.text =
                        '${_selectedSong!.title} (Official Video)';
                  }
                });
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                hintText: 'Choose a released song',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ),
          if (_releasedSongs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.white38),
                  const SizedBox(width: 6),
                  const Text('No released songs yet',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_library, color: AppTheme.errorRed, size: 20),
              const SizedBox(width: 8),
              const Text('Video type',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chipYT('Official Music Video', NextTubeVideoType.official, 
                  Icons.play_circle_filled, 'High production quality'),
              _chipYT('Lyrics Video', NextTubeVideoType.lyrics, 
                  Icons.text_fields, 'Animated lyrics display'),
              _chipYT('Live Performance', NextTubeVideoType.live, 
                  Icons.live_tv, 'Concert or studio session'),
            ],
          )
        ],
      ),
    );
  }

  Widget _chipYT(String label, NextTubeVideoType type, IconData icon, String desc) {
    final selected = _type == type;
    return InkWell(
      onTap: () => setState(() {
        _type = type;
        _updateCost();
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected 
              ? AppTheme.errorRed.withOpacity(0.2) 
              : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.errorRed : AppTheme.borderDefault,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, 
                color: selected ? AppTheme.errorRed : Colors.white60, 
                size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerSelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.high_quality, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Production quality',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderDefault, width: 1.5),
            ),
            child: DropdownButton<String>(
              value: _selectedProducer,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.accentBlue),
              items: [
                _producerItem('Indie Producer', 'DIY with smartphone or basic gear', Icons.phone_android),
                _producerItem('Studio Producer', 'Small team with professional equipment', Icons.groups),
                _producerItem('Top-tier Producer', 'High-end production with expert director', Icons.movie),
              ],
              onChanged: (val) => setState(() {
                _selectedProducer = val ?? 'Indie Producer';
                _updateCost();
              }),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _producerItem(String value, String desc, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelector(bool isSmallScreen) {
    final gameTimeService = GameTimeService();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.neonPurple, size: 20),
              const SizedBox(width: 8),
              const Text('Release schedule',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose when your video will be published',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          
          // Publish now option
          InkWell(
            onTap: () => setState(() => _scheduleRelease = false),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_scheduleRelease 
                    ? AppTheme.neonPurple.withOpacity(0.2) 
                    : AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_scheduleRelease ? AppTheme.neonPurple : AppTheme.borderDefault,
                  width: !_scheduleRelease ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.publish, 
                      color: !_scheduleRelease ? AppTheme.neonPurple : Colors.white60, 
                      size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish immediately',
                        style: TextStyle(
                          color: !_scheduleRelease ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: !_scheduleRelease ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Video goes live right away',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Schedule for later option
          InkWell(
            onTap: () => setState(() => _scheduleRelease = true),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _scheduleRelease 
                    ? AppTheme.neonPurple.withOpacity(0.2) 
                    : AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _scheduleRelease ? AppTheme.neonPurple : AppTheme.borderDefault,
                  width: _scheduleRelease ? 2 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, 
                          color: _scheduleRelease ? AppTheme.neonPurple : Colors.white60, 
                          size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule for later',
                            style: TextStyle(
                              color: _scheduleRelease ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: _scheduleRelease ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Set a future in-game date',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Date picker (show when scheduled option is selected)
                  if (_scheduleRelease && _currentGameDate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderDefault),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Release date (in-game)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _scheduledReleaseDate != null 
                                    ? gameTimeService.formatGameDate(_scheduledReleaseDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_calendar, color: AppTheme.neonPurple),
                            onPressed: () => _showGameDatePicker(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGameDatePicker() async {
    if (_currentGameDate == null) return;
    
    final gameTimeService = GameTimeService();
    
    // Allow scheduling up to 30 game days in the future
    final minDate = _currentGameDate!;
    final maxDate = _currentGameDate!.add(Duration(days: 30));
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Schedule release date', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select an in-game date for your video release',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Current game date: ${gameTimeService.formatGameDate(_currentGameDate!)}',
                style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CalendarDatePicker(
                initialDate: _scheduledReleaseDate ?? _currentGameDate!,
                firstDate: minDate,
                lastDate: maxDate,
                currentDate: _currentGameDate,
                onDateChanged: (date) {
                  setState(() {
                    _scheduledReleaseDate = date;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldsYT(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.title, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          // Title field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title (required)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Add a title that describes your video',
                  hintStyle: TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.accentBlue, width: 2),
                  ),
                  counterStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell viewers about your video',
                  hintStyle: TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.accentBlue, width: 2),
                  ),
                  counterStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPickerYT(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: AppTheme.neonPurple, size: 20),
              const SizedBox(width: 8),
              const Text('Thumbnail',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select or upload a picture that shows what\'s in your video',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Thumbnail preview
          GestureDetector(
            onTap: _pickThumbnail,
            child: Container(
              width: isSmallScreen ? double.infinity : 320,
              height: isSmallScreen ? 180 : 180,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _thumbnailUrl != null 
                      ? AppTheme.neonPurple 
                      : AppTheme.borderDefault,
                  width: _thumbnailUrl != null ? 2 : 1.5,
                ),
                image: _thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_thumbnailUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: _thumbnailUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, 
                            color: Colors.white38, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Upload thumbnail',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit, color: Colors.white, size: 16),
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

  Widget _buildCostCardYT() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningOrange.withOpacity(0.1),
            AppTheme.chartGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.chartGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.monetization_on, 
                color: AppTheme.chartGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Production cost',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('\$$_estimatedCost',
                    style: TextStyle(
                        color: AppTheme.chartGold,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.artistStats.money >= _estimatedCost
                  ? AppTheme.successGreen.withOpacity(0.2)
                  : AppTheme.errorRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.artistStats.money >= _estimatedCost
                    ? AppTheme.successGreen
                    : AppTheme.errorRed,
              ),
            ),
            child: Text(
              widget.artistStats.money >= _estimatedCost
                  ? 'Can afford'
                  : 'Insufficient funds',
              style: TextStyle(
                color: widget.artistStats.money >= _estimatedCost
                    ? AppTheme.successGreen
                    : AppTheme.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButtonYT() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: AppTheme.borderDefault, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel', 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting 
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.upload, size: 20),
            label: Text(
              _isSubmitting ? 'Publishing...' : 'Publish',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

}
