import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';

class WriteSongScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const WriteSongScreen({
    super.key,
    required this.artistStats,
  });

  @override
  State<WriteSongScreen> createState() => _WriteSongScreenState();
}

class _WriteSongScreenState extends State<WriteSongScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedGenre = 'Hip Hop';
  int _effortLevel = 2; // 1-4
  bool _isWriting = false;

  final List<String> _genres = [
    'Hip Hop',
    'Rap',
    'Trap',
    'Drill',
    'R&B',
    'Afrobeat',
    'Jazz',
    'Reggae',
    'Country',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int get _energyCost => 15 + (_effortLevel * 10);

  @override
  Widget build(BuildContext context) {
    final canWrite = widget.artistStats.energy >= _energyCost;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('✍️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Write a Song',
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
            _buildEnergyInfo(),
            const SizedBox(height: 24),
            _buildSongTitleInput(),
            const SizedBox(height: 24),
            _buildGenreSelection(),
            const SizedBox(height: 24),
            _buildEffortSelection(),
            const SizedBox(height: 24),
            _buildSkillsInfo(),
            const SizedBox(height: 24),
            _buildExpectedQuality(),
            const SizedBox(height: 32),
            _buildWriteButton(canWrite),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D9FF).withOpacity(0.2),
            const Color(0xFF7C3AED).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF00D9FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Energy Available',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.artistStats.energy} / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cost: $_energyCost',
              style: const TextStyle(
                color: Color(0xFFFF6B9D),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Song Title',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter your song title...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF21262D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
            ),
            prefixIcon: const Icon(Icons.title, color: Color(0xFF00D9FF)),
          ),
          maxLength: 50,
        ),
      ],
    );
  }

  Widget _buildGenreSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genre',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((genre) {
            final isSelected = _selectedGenre == genre;
            return GestureDetector(
              onTap: () => setState(() => _selectedGenre = genre),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D9FF).withOpacity(0.2)
                      : const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00D9FF) : Colors.white30,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00D9FF) : Colors.white60,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEffortSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Effort Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              _getEffortLabel(_effortLevel),
              style: TextStyle(
                color: _getEffortColor(_effortLevel),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: List.generate(4, (index) {
                  final level = index + 1;
                  final isSelected = _effortLevel >= level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _effortLevel = level),
                      child: Container(
                        height: 40,
                        margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getEffortColor(level).withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _getEffortColor(level)
                                : Colors.white30,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white30,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEffortInfo('Quick', '15 Energy'),
                  _buildEffortInfo('Masterpiece', '45 Energy'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffortInfo(String label, String energy) {
    return Text(
      '$label ($energy)',
      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
    );
  }

  Widget _buildSkillsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Your Skills',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkillBar('Songwriting', widget.artistStats.songwritingSkill),
          const SizedBox(height: 12),
          _buildSkillBar('Lyrics', widget.artistStats.lyricsSkill),
          const SizedBox(height: 12),
          _buildSkillBar('Composition', widget.artistStats.compositionSkill),
        ],
      ),
    );
  }

  Widget _buildSkillBar(String skill, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectedQuality() {
    final expectedQuality = widget.artistStats.calculateSongQuality(_selectedGenre, _effortLevel);
    final qualityRating = widget.artistStats.getSongQualityRating(expectedQuality);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFF9B59B6).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Text(
                'Expected Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${expectedQuality.round()}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qualityRating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Quality Rating',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWriteButton(bool canWrite) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (canWrite && !_isWriting) ? _writeSong : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D9FF),
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isWriting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.create, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    canWrite ? 'Write Song' : 'Not Enough Energy',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getEffortLabel(int level) {
    switch (level) {
      case 1: return 'Quick';
      case 2: return 'Standard';
      case 3: return 'Focused';
      case 4: return 'Masterpiece';
      default: return 'Standard';
    }
  }

  Color _getEffortColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF8E8E93);
      case 2: return const Color(0xFF32D74B);
      case 3: return const Color(0xFF00D9FF);
      case 4: return const Color(0xFFFFD700);
      default: return const Color(0xFF32D74B);
    }
  }

  void _writeSong() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a song title'),
          backgroundColor: Color(0xFFFF6B9D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isWriting = true;
    });

    // Simulate writing process
    Future.delayed(Duration(seconds: _effortLevel), () {
      final songQuality = widget.artistStats.calculateSongQuality(_selectedGenre, _effortLevel);
      final skillGains = widget.artistStats.calculateSkillGains(_selectedGenre, _effortLevel, songQuality);

      // Create new song
      final newSong = Song(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        quality: songQuality.round(),
        createdDate: DateTime.now(),
        state: SongState.written,
      );

      // Update artist stats
      final updatedStats = widget.artistStats.copyWith(
        energy: widget.artistStats.energy - _energyCost,
        creativity: (widget.artistStats.creativity + 5).clamp(0, 100),
        songsWritten: widget.artistStats.songsWritten + 1,
        songwritingSkill: (widget.artistStats.songwritingSkill + skillGains['songwritingSkill']!).clamp(0, 100),
        lyricsSkill: (widget.artistStats.lyricsSkill + skillGains['lyricsSkill']!).clamp(0, 100),
        compositionSkill: (widget.artistStats.compositionSkill + skillGains['compositionSkill']!).clamp(0, 100),
        experience: widget.artistStats.experience + skillGains['experience']!,
        inspirationLevel: (widget.artistStats.inspirationLevel + skillGains['inspirationLevel']!).clamp(0, 100),
        songs: [...widget.artistStats.songs, newSong],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ "${newSong.title}" has been written! Quality: ${newSong.quality}'),
            backgroundColor: const Color(0xFF32D74B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, updatedStats);
      }
    });
  }
}
