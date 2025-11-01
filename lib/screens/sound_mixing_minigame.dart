import 'package:flutter/material.dart';
import 'dart:math';
import '../models/song.dart';
import '../services/sound_mixing_service.dart';
import '../theme/app_theme.dart';

/// Sound Mixing Minigame - Interactive mixing board for recording songs
/// Players adjust Bass, Mids, Treble, Vocals, and Effects to match genre-specific ideal mixes
class SoundMixingMinigame extends StatefulWidget {
  final Song song;
  final Function(int qualityBonus) onComplete;

  const SoundMixingMinigame({
    super.key,
    required this.song,
    required this.onComplete,
  });

  @override
  State<SoundMixingMinigame> createState() => _SoundMixingMinigameState();
}

class _SoundMixingMinigameState extends State<SoundMixingMinigame>
    with SingleTickerProviderStateMixin {
  final SoundMixingService _mixingService = SoundMixingService();

  // Mixing parameters (0-100)
  double _bass = 50.0;
  double _mids = 50.0;
  double _treble = 50.0;
  double _vocals = 50.0;
  double _effects = 50.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentScore = 0;
  String _feedback = 'Adjust the levels to match your genre!';
  Color _feedbackColor = Colors.white70;

  @override
  void initState() {
    super.initState();

    // Pulse animation for VU meters
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Randomize starting positions slightly for challenge
    _randomizeStartingPosition();
  }

  void _randomizeStartingPosition() {
    final random = Random();
    setState(() {
      _bass = 40 + random.nextDouble() * 20; // 40-60
      _mids = 40 + random.nextDouble() * 20;
      _treble = 40 + random.nextDouble() * 20;
      _vocals = 40 + random.nextDouble() * 20;
      _effects = 40 + random.nextDouble() * 20;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateMix() {
    final result = _mixingService.evaluateMix(
      genre: widget.song.genre,
      bass: _bass,
      mids: _mids,
      treble: _treble,
      vocals: _vocals,
      effects: _effects,
    );

    setState(() {
      _currentScore = result['score'];
      _feedback = result['feedback'];
      _feedbackColor = result['color'];
    });
  }

  void _finishMixing() {
    final qualityBonus = _mixingService.calculateQualityBonus(_currentScore);
    widget.onComplete(qualityBonus);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        height: 650,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
              AppTheme.backgroundDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.neonGreen.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonGreen.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildScoreDisplay(),
                    const SizedBox(height: 24),
                    _buildMixingBoard(),
                    const SizedBox(height: 24),
                    _buildIdealMixHint(),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.neonGreen.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.neonGreen, AppTheme.neonPurple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.equalizer, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sound Mixing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.song.title} • ${widget.song.genre}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _feedbackColor.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _feedbackColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Text(
                'Mix Quality: $_currentScore%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _feedback,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _feedbackColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildQualityBar(),
        ],
      ),
    );
  }

  Widget _buildQualityBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: _currentScore / 100,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getQualityColor(_currentScore),
                          _getQualityColor(_currentScore).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 90) return const Color(0xFF00FF00); // Perfect
    if (score >= 75) return const Color(0xFF32D74B); // Great
    if (score >= 60) return const Color(0xFFFFD60A); // Good
    if (score >= 40) return const Color(0xFFFF9500); // Okay
    return const Color(0xFFFF3B30); // Poor
  }

  Widget _buildMixingBoard() {
    return Column(
      children: [
        _buildSlider(
          label: '🔊 Bass',
          value: _bass,
          color: const Color(0xFFFF3B30),
          onChanged: (value) {
            setState(() => _bass = value);
            _updateMix();
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: '🎵 Mids',
          value: _mids,
          color: const Color(0xFFFF9500),
          onChanged: (value) {
            setState(() => _mids = value);
            _updateMix();
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: '✨ Treble',
          value: _treble,
          color: const Color(0xFFFFD60A),
          onChanged: (value) {
            setState(() => _treble = value);
            _updateMix();
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: '🎤 Vocals',
          value: _vocals,
          color: const Color(0xFF32D74B),
          onChanged: (value) {
            setState(() => _vocals = value);
            _updateMix();
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: '🎛️ Effects',
          value: _effects,
          color: const Color(0xFF0A84FF),
          onChanged: (value) {
            setState(() => _effects = value);
            _updateMix();
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                '${value.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildIdealMixHint() {
    final idealMix = _mixingService.getIdealMix(widget.song.genre);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neonPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: AppTheme.neonPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Genre Hint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            idealMix['description'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final qualityBonus = _mixingService.calculateQualityBonus(_currentScore);
    final bonusText = qualityBonus > 0
        ? '+$qualityBonus%'
        : qualityBonus < 0
            ? '$qualityBonus%'
            : 'No Change';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _finishMixing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Finish Mix ($bonusText Quality)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
