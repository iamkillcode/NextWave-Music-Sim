import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/streaming_platform.dart';
import '../services/stream_growth_service.dart';

class ReleaseSongScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Song song;

  const ReleaseSongScreen({
    super.key,
    required this.artistStats,
    required this.song,
  });

  @override
  State<ReleaseSongScreen> createState() => _ReleaseSongScreenState();
}

class _ReleaseSongScreenState extends State<ReleaseSongScreen> {
  bool _releaseNow = true;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));
  bool _isProcessing = false;
  final Set<String> _selectedPlatforms = {
    'tunify',
  }; // Can select multiple platforms
  String? _uploadedCoverArtUrl; // URL of uploaded cover art image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🚀', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Release Song',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSongPreview(),
            const SizedBox(height: 32),
            _buildPlatformSelector(),
            const SizedBox(height: 32),
            _buildCoverArtDesigner(),
            const SizedBox(height: 32),
            _buildReleaseOptions(),
            const SizedBox(height: 32),
            _buildExpectedResults(),
            const SizedBox(height: 32),
            _buildReleaseButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadCoverArt() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Read image as bytes and convert to base64
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      setState(() {
        _uploadedCoverArtUrl = dataUrl;
      });
    } catch (e) {
      print('Error uploading cover art: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload cover art'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSongPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFF9B59B6).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(widget.song.genreEmoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            widget.song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.song.genre,
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quality: ${widget.song.finalQuality} - ${widget.song.qualityRating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  Widget _buildPlatformSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_upload, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Choose Streaming Platforms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select one or both platforms to distribute your music',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...StreamingPlatform.all.map(
            (platform) => _buildPlatformOption(platform),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformOption(StreamingPlatform platform) {
    final isSelected = _selectedPlatforms.contains(platform.id);

    // ✨ FAME GATE: Maple Music requires 50 fame
    final isLocked =
        platform.id == 'maple_music' && widget.artistStats.fame < 50;
    final requiredFame = platform.id == 'maple_music' ? 50 : 0;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  // Don't allow deselecting if it's the only one selected
                  if (_selectedPlatforms.length > 1) {
                    _selectedPlatforms.remove(platform.id);
                  }
                } else {
                  _selectedPlatforms.add(platform.id);
                }
              });
            },
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFF1C2128)
                : (isSelected
                    ? Color(platform.getColorValue()).withOpacity(0.2)
                    : const Color(0xFF30363D)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked
                  ? Colors.white12
                  : (isSelected
                      ? Color(platform.getColorValue())
                      : Colors.white30),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Text(platform.emoji,
                          style: const TextStyle(fontSize: 32)),
                      if (isLocked)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              platform.name,
                              style: TextStyle(
                                color: isLocked
                                    ? Colors.white38
                                    : (isSelected
                                        ? Color(platform.getColorValue())
                                        : Colors.white),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade700,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$requiredFame Fame Required',
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLocked
                              ? 'Unlock at $requiredFame fame to access this premium platform'
                              : platform.description,
                          style: TextStyle(
                            color: isLocked ? Colors.white38 : Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && !isLocked)
                    Icon(
                      Icons.check_circle,
                      color: Color(platform.getColorValue()),
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPlatformStat(
                    '💰',
                    '\$${platform.royaltiesPerStream.toStringAsFixed(3)}/stream',
                    platform,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformStat(
    String emoji,
    String text,
    StreamingPlatform platform,
  ) {
    final isSelected = _selectedPlatforms.contains(platform.id);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverArtDesigner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Design Cover Art',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload your cover art image',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadCoverArt,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _uploadedCoverArtUrl != null ? 'Change Image' : 'Upload Image',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Cover art preview
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: _uploadedCoverArtUrl != null
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
                image: _uploadedCoverArtUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_uploadedCoverArtUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _uploadedCoverArtUrl != null
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Colors.white.withOpacity(0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cover art yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (_uploadedCoverArtUrl != null)
            Center(
              child: Text(
                '✓ Cover art uploaded',
                style: TextStyle(
                  color: const Color(0xFF32D74B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleaseOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Release Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _releaseNow = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _releaseNow
                    ? const Color(0xFF00D9FF).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _releaseNow ? const Color(0xFF00D9FF) : Colors.white30,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color:
                        _releaseNow ? const Color(0xFF00D9FF) : Colors.white60,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Release Now',
                          style: TextStyle(
                            color: _releaseNow ? Colors.white : Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Go live immediately',
                          style: TextStyle(
                            color:
                                _releaseNow ? Colors.white60 : Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_releaseNow)
                    const Icon(Icons.check_circle, color: Color(0xFF00D9FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _releaseNow = false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_releaseNow
                    ? const Color(0xFF9B59B6).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      !_releaseNow ? const Color(0xFF9B59B6) : Colors.white30,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color:
                        !_releaseNow ? const Color(0xFF9B59B6) : Colors.white60,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Release',
                          style: TextStyle(
                            color: !_releaseNow ? Colors.white : Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set a future release date',
                          style: TextStyle(
                            color:
                                !_releaseNow ? Colors.white60 : Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_releaseNow)
                    const Icon(Icons.check_circle, color: Color(0xFF9B59B6)),
                ],
              ),
            ),
          ),
          if (!_releaseNow) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Release Date',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF9B59B6).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF9B59B6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.edit,
                            color: Color(0xFF9B59B6),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF9B59B6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Building anticipation can boost initial streams by up to 25%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildExpectedResults() {
    final estimatedStreams = widget.song.estimatedStreams;

    // Calculate combined revenue from all selected platforms
    double totalRevenue = 0;
    for (final platformId in _selectedPlatforms) {
      final platform = StreamingPlatform.getById(platformId);
      totalRevenue += estimatedStreams * platform.royaltiesPerStream;
    }
    final estimatedRevenue = totalRevenue.round();

    final fameGain = (widget.song.finalQuality * 0.5).round();
    final fanbaseGain = (widget.song.finalQuality * 2).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF32D74B), size: 20),
              SizedBox(width: 8),
              Text(
                'Expected Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildExpectedStat(
            Icons.play_circle_outline,
            'Estimated Streams',
            _formatNumber(estimatedStreams),
            const Color(0xFF00D9FF),
          ),
          const SizedBox(height: 12),
          _buildExpectedStat(
            Icons.attach_money,
            'Estimated Revenue',
            '\$${_formatNumber(estimatedRevenue)}',
            const Color(0xFF32D74B),
          ),
          const SizedBox(height: 12),
          _buildExpectedStat(
            Icons.star,
            'Fame Gain',
            '+$fameGain',
            const Color(0xFFFFD700),
          ),
          const SizedBox(height: 12),
          _buildExpectedStat(
            Icons.people,
            'New Fans',
            '+${_formatNumber(fanbaseGain)}',
            const Color(0xFFFF6B9D),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF00D9FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Higher quality songs perform better and earn more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
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

  Widget _buildExpectedStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _releaseSong,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    _releaseNow ? 'Release Now' : 'Schedule Release',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9B59B6),
              onPrimary: Colors.white,
              surface: Color(0xFF21262D),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF21262D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  void _releaseSong() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing
    Future.delayed(const Duration(seconds: 2), () {
      final releaseDate = _releaseNow ? DateTime.now() : _scheduledDate;

      // Calculate realistic initial streams based on artist's ACTUAL fanbase
      // Not based on unrealistic global population estimates
      final baseInitialStreams = widget.artistStats.fanbase > 0
          ? widget.artistStats.fanbase // Fanbase is the starting point
          : 10; // Absolute minimum for brand new artists with no fans

      // Quality multiplier (0.4 to 1.0) - even great songs start small for new artists
      final qualityMultiplier = (widget.song.finalQuality / 100.0) * 0.6 + 0.4;

      // Platform multiplier - more platforms = more reach (1.0 to 1.5)
      final platformMultiplier = 1.0 + (_selectedPlatforms.length - 1) * 0.25;

      // Calculate realistic initial streams (first day release)
      final realisticInitialStreams =
          (baseInitialStreams * qualityMultiplier * platformMultiplier).round();

      // Fame gain should be gradual - based on quality, not instant massive jump
      final fameGain = _releaseNow
          ? (widget.song.finalQuality * 0.1)
              .round()
              .clamp(1, 5) // Max 5 fame on release
          : 0;

      // Fanbase gain should also be gradual and realistic
      final fanbaseGain = _releaseNow
          ? (widget.song.finalQuality * 0.5)
              .round()
              .clamp(5, 50) // 5-50 new fans max on release
          : 0;

      // Calculate virality score for this song
      final streamGrowthService = StreamGrowthService();
      final viralityScore = streamGrowthService.calculateViralityScore(
        songQuality: widget.song.finalQuality,
        artistFame: widget.artistStats.fame,
        artistFanbase: widget.artistStats.fanbase,
      );

      // Calculate loyal fanbase growth from releasing quality music
      final loyalFanbaseGrowth =
          streamGrowthService.calculateLoyalFanbaseGrowth(
        currentLoyalFanbase: widget.artistStats.loyalFanbase,
        songQuality: widget.song.finalQuality,
        totalFanbase: widget.artistStats.fanbase + fanbaseGain,
      );

      // Calculate regional fanbase growth from releasing this song
      final regionalFanbaseGrowth =
          streamGrowthService.calculateRegionalFanbaseGrowth(
        currentRegion: widget.artistStats.currentRegion,
        originRegion: widget.artistStats
            .currentRegion, // The region where the song is released becomes origin
        songQuality: widget.song.finalQuality,
        genre: widget.song.genre,
        currentGlobalFanbase: widget.artistStats.fanbase,
        currentRegionalFanbase: widget.artistStats.regionalFanbase,
      );

      // Update regional fanbase map
      final updatedRegionalFanbase = Map<String, int>.from(
        widget.artistStats.regionalFanbase,
      );
      regionalFanbaseGrowth.forEach((region, growth) {
        updatedRegionalFanbase[region] =
            (updatedRegionalFanbase[region] ?? 0) + growth;
      });

      // Initialize regional streams for the song (release day gets some initial streams)
      final initialRegionalStreams = _releaseNow
          ? streamGrowthService.calculateRegionalStreamDistribution(
              totalDailyStreams: realisticInitialStreams,
              currentRegion: widget.artistStats.currentRegion,
              regionalFanbase: updatedRegionalFanbase,
              genre: widget.song.genre,
            )
          : <String, int>{};

      // Update song state with cover art, platforms, virality, and regional data
      final updatedSong = widget.song.copyWith(
        state: SongState.released,
        releasedDate: releaseDate,
        streams: _releaseNow
            ? realisticInitialStreams
            : 0, // Initial streams based on artist's actual fanbase
        regionalStreams: initialRegionalStreams,
        likes: _releaseNow
            ? (realisticInitialStreams * 0.3).round()
            : 0, // 30% of streams become likes
        coverArtUrl: _uploadedCoverArtUrl,
        streamingPlatforms: _selectedPlatforms.toList(),
        viralityScore: viralityScore,
        daysOnChart: 0,
        peakDailyStreams: _releaseNow ? realisticInitialStreams : 0,
      );

      // Update artist stats with loyal fanbase growth and regional fanbase
      // Note: Royalty payments are calculated daily, not on release
      final updatedStats = widget.artistStats.copyWith(
        money: widget
            .artistStats.money, // No immediate payment - royalties paid daily
        fame: widget.artistStats.fame + (_releaseNow ? fameGain : 0),
        fanbase: widget.artistStats.fanbase + (_releaseNow ? fanbaseGain : 0),
    loyalFanbase: (widget.artistStats.loyalFanbase + loyalFanbaseGrowth)
      .clamp(0, 1e12)
      .toInt(),
        regionalFanbase: updatedRegionalFanbase,
        songs: widget.artistStats.songs
            .map((s) => s.id == updatedSong.id ? updatedSong : s)
            .toList(),
      );

      // Show success message
      if (mounted) {
        final platformNames = _selectedPlatforms
            .map((id) => StreamingPlatform.getById(id).name)
            .join(' & ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _releaseNow
                  ? '🚀 "${widget.song.title}" is now live on $platformNames!'
                  : '📅 "${widget.song.title}" scheduled for ${releaseDate.day}/${releaseDate.month}/${releaseDate.year} on $platformNames',
            ),
            backgroundColor: const Color(0xFF32D74B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, updatedStats);
      }
    });
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
