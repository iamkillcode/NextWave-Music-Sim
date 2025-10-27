import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/nexttube_video.dart';
import '../services/nexttube_service.dart';
import '../services/player_content_service.dart';
import '../services/cover_art_uploader.dart';
import '../services/remote_config_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _updateCost();
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

      // Duplicate checks
      if (await svc.hasVideoForSongAndType(
          songId: _selectedSong!.id, type: _type, withinDays: 30)) {
        _showSnack(
            'You already uploaded a ${_typeLabel(_type)} video for this song recently');
        setState(() => _isSubmitting = false);
        return;
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
        _showSnack('Uploaded to NexTube: ${video.title}');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.ondemand_video_rounded, color: Colors.white),
            SizedBox(width: 8),
            // Ensure title doesn't overflow on small widths
            Flexible(
              child: Text(
                'NexTube: Upload Music Video',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF21262D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSongPicker(),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildProducerSelector(),
            const SizedBox(height: 16),
            _buildTextFields(),
            const SizedBox(height: 16),
            _buildThumbnailPicker(),
            const SizedBox(height: 16),
            _buildCostCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSongPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Released Song',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF21262D),
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
              filled: true,
              fillColor: Color(0xFF30363D),
              border: OutlineInputBorder(),
            ),
          ),
          if (_releasedSongs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No released songs yet',
                  style: TextStyle(color: Colors.white54)),
            )
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Video Type',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Official', NextTubeVideoType.official),
              _chip('Lyrics', NextTubeVideoType.lyrics),
              _chip('Live', NextTubeVideoType.live),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProducerSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Producer (placeholder)',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProducer,
            dropdownColor: const Color(0xFF21262D),
            items: const [
              DropdownMenuItem(
                  value: 'Indie Producer',
                  child: Text('Indie Producer',
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: 'Studio Producer',
                  child: Text('Studio Producer (+20% cost)',
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: 'Top-tier Producer',
                  child: Text('Top-tier Producer (+50% cost)',
                      style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedProducer = val;
                _updateCost();
              });
            },
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF30363D),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, NextTubeVideoType type) {
    final selected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _type = type;
        _updateCost();
      }),
      selectedColor: const Color(0xFFFF6B6B),
      backgroundColor: const Color(0xFF30363D),
      labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
    );
  }

  Widget _buildTextFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Title & Description',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Video title',
              filled: true,
              fillColor: Color(0xFF30363D),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Optional description',
              filled: true,
              fillColor: Color(0xFF30363D),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thumbnail',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(8),
                  image: _thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_thumbnailUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: _thumbnailUrl == null
                    ? const Icon(Icons.image, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pickThumbnail,
                icon: const Icon(Icons.upload_file),
                label: Text(_thumbnailUrl == null ? 'Upload' : 'Change'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.black),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Color(0xFFFFD700)),
          const SizedBox(width: 8),
          const Text('Production Cost',
              style: TextStyle(color: Colors.white70)),
          const Spacer(),
          Text('\$$_estimatedCost',
              style: const TextStyle(
                  color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: const Icon(Icons.cloud_upload),
        label: Text(_isSubmitting ? 'Uploading...' : 'Upload to NexTube'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF21262D),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }
}
