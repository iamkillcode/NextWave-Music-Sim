import 'package:flutter/material.dart';
import 'dart:math';
import '../models/artist_stats.dart';

class PracticeScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const PracticeScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String? _selectedPractice;
  final int _energyCost = 15;

  final List<Map<String, dynamic>> _practiceOptions = [
    {
      'id': 'songwriting',
      'name': 'Songwriting',
      'emoji': '🎼',
      'description': 'Improve your songwriting skills',
      'color': const Color(0xFF00D9FF),
      'xp': 15,
    },
    {
      'id': 'lyrics',
      'name': 'Lyrics',
      'emoji': '📝',
      'description': 'Work on your lyrical abilities',
      'color': const Color(0xFFFF6B9D),
      'xp': 12,
    },
    {
      'id': 'composition',
      'name': 'Composition',
      'emoji': '🎹',
      'description': 'Practice music composition',
      'color': const Color(0xFF9B59B6),
      'xp': 18,
    },
    {
      'id': 'inspiration',
      'name': 'Inspiration',
      'emoji': '💡',
      'description': 'Gain creative inspiration',
      'color': const Color(0xFFFFD60A),
      'xp': 10,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final canPractice = widget.artistStats.energy >= _energyCost;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🎸 Practice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Energy and stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF39C12).withOpacity(0.2),
                      const Color(0xFFF39C12).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF39C12).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Skills',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSkillMini(
                            'Songwriting',
                            widget.artistStats.songwritingSkill,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSkillMini(
                            'Lyrics',
                            widget.artistStats.lyricsSkill,
                            const Color(0xFFFF6B9D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSkillMini(
                            'Composition',
                            widget.artistStats.compositionSkill,
                            const Color(0xFF9B59B6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSkillMini(
                            'Inspiration',
                            widget.artistStats.inspirationLevel,
                            const Color(0xFFFFD60A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Energy indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Color(0xFFFF6B9D),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Energy: ${widget.artistStats.energy}/100',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Costs $_energyCost ⚡',
                            style: const TextStyle(
                              color: Color(0xFFF39C12),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Practice options title
              const Text(
                'Choose What to Practice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a skill to improve. Better results with higher energy.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Practice options
              ..._practiceOptions.map((option) {
                final isSelected = _selectedPractice == option['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPracticeOption(
                    option: option,
                    isSelected: isSelected,
                    canSelect: canPractice,
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Practice button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedPractice != null && canPractice)
                      ? _practiceSkill
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPractice == null
                        ? 'Select a Practice Option'
                        : canPractice
                        ? 'Start Practicing'
                        : 'Not Enough Energy',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              if (!canPractice) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF453A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFFF453A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You need at least $_energyCost energy to practice',
                          style: const TextStyle(
                            color: Color(0xFFFF453A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillMini(String name, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeOption({
    required Map<String, dynamic> option,
    required bool isSelected,
    required bool canSelect,
  }) {
    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                _selectedPractice = option['id'];
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (option['color'] as Color).withOpacity(0.2)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (option['color'] as Color)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (option['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                option['emoji'],
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['name'],
                    style: TextStyle(
                      color: canSelect
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['description'],
                    style: TextStyle(
                      color: canSelect
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: option['color'], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${option['xp']} XP',
                        style: TextStyle(
                          color: option['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF32D74B),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _practiceSkill() {
    if (_selectedPractice == null || widget.artistStats.energy < _energyCost) {
      return;
    }

    final option = _practiceOptions.firstWhere(
      (opt) => opt['id'] == _selectedPractice,
    );

    final random = Random();
    int skillGain = 2 + (widget.artistStats.energy > 50 ? 1 : 0);

    // Add slight randomness (±1)
    skillGain += random.nextInt(3) - 1;
    skillGain = skillGain.clamp(1, 5);

    Map<String, int> improvements = {};
    String practiceMessage = '';

    switch (_selectedPractice) {
      case 'songwriting':
        improvements['songwritingSkill'] = skillGain;
        improvements['experience'] = option['xp'];
        practiceMessage = '🎼 Practiced songwriting techniques!';
        break;
      case 'lyrics':
        improvements['lyricsSkill'] = skillGain;
        improvements['experience'] = option['xp'];
        practiceMessage = '📝 Worked on lyrical skills!';
        break;
      case 'composition':
        improvements['compositionSkill'] = skillGain;
        improvements['experience'] = option['xp'];
        practiceMessage = '🎹 Practiced music composition!';
        break;
      case 'inspiration':
        improvements['inspirationLevel'] = skillGain * 2;
        improvements['experience'] = option['xp'];
        practiceMessage = '💡 Gained creative inspiration!';
        break;
    }

    // Update stats
    final updatedStats = widget.artistStats.copyWith(
      energy: widget.artistStats.energy - _energyCost,
      creativity: widget.artistStats.creativity + 3,
      fanbase: widget.artistStats.fanbase + 1,
      songwritingSkill:
          (widget.artistStats.songwritingSkill +
                  (improvements['songwritingSkill'] ?? 0))
              .clamp(0, 100),
      lyricsSkill:
          (widget.artistStats.lyricsSkill + (improvements['lyricsSkill'] ?? 0))
              .clamp(0, 100),
      compositionSkill:
          (widget.artistStats.compositionSkill +
                  (improvements['compositionSkill'] ?? 0))
              .clamp(0, 100),
      inspirationLevel:
          (widget.artistStats.inspirationLevel +
                  (improvements['inspirationLevel'] ?? 0))
              .clamp(0, 100),
      experience:
          widget.artistStats.experience + (improvements['experience'] ?? 0),
    );

    widget.onStatsUpdated(updatedStats);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(option['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Practice Complete!',
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
              practiceMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Skill Gained', '+$skillGain', option['color']),
            _buildResultRow(
              'Experience',
              '+${improvements['experience']} XP',
              const Color(0xFF0A84FF),
            ),
            _buildResultRow('Creativity', '+3', const Color(0xFFFFD60A)),
            _buildResultRow('Fans', '+1', const Color(0xFF32D74B)),
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
                _selectedPractice = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39C12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Practice Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
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
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
