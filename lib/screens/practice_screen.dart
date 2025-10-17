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
  final int _moneyCost = 50; // Cost for practice materials/studio time
  final int _timeHours = 3; // Practice takes 3 hours

  final List<Map<String, dynamic>> _practiceOptions = [
    {
      'id': 'songwriting',
      'name': 'Songwriting',
      'emoji': '🎼',
      'description': 'Improve your songwriting skills',
      'color': const Color(0xFF00D9FF),
      'xp': 8, // Reduced XP for gradual gains
      'skillGain': 2, // Small skill gain per session
    },
    {
      'id': 'lyrics',
      'name': 'Lyrics',
      'emoji': '📝',
      'description': 'Work on your lyrical abilities',
      'color': const Color(0xFFFF6B9D),
      'xp': 6,
      'skillGain': 2,
    },
    {
      'id': 'composition',
      'name': 'Composition',
      'emoji': '🎹',
      'description': 'Practice music composition',
      'color': const Color(0xFF9B59B6),
      'xp': 10,
      'skillGain': 3,
    },
    {
      'id': 'inspiration',
      'name': 'Inspiration',
      'emoji': '💡',
      'description': 'Gain creative inspiration',
      'color': const Color(0xFFFFD60A),
      'xp': 5,
      'skillGain': 4, // Higher inspiration gain
    },
  ];

  @override
  Widget build(BuildContext context) {
    final canPractice =
        widget.artistStats.energy >= _energyCost &&
        widget.artistStats.money >= _moneyCost;

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
                    // Costs indicators
                    Row(
                      children: [
                        // Energy cost
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Color(0xFFFF6B9D),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.artistStats.energy}/100',
                                style: TextStyle(
                                  color:
                                      widget.artistStats.energy >= _energyCost
                                      ? Colors.white
                                      : const Color(0xFFFF453A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Money cost
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: Color(0xFF32D74B),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '\$${widget.artistStats.money}',
                                style: TextStyle(
                                  color: widget.artistStats.money >= _moneyCost
                                      ? Colors.white
                                      : const Color(0xFFFF453A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Cost info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39C12).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF39C12).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Practice Cost:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_energyCost ⚡',
                            style: const TextStyle(
                              color: Color(0xFFFF6B9D),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$$_moneyCost 💵',
                            style: const TextStyle(
                              color: Color(0xFF32D74B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_timeHours hrs ⏰',
                            style: const TextStyle(
                              color: Color(0xFF0A84FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
                'Practice consistently for gradual improvement. Small gains lead to mastery!',
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
                        ? 'Start Practicing ($_timeHours hours)'
                        : widget.artistStats.energy < _energyCost
                        ? 'Not Enough Energy'
                        : 'Not Enough Money',
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
                          widget.artistStats.energy < _energyCost
                              ? 'You need at least $_energyCost energy to practice'
                              : 'You need at least \$$_moneyCost to practice',
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
                        '+${option['skillGain']}-${option['skillGain'] + 2} skill',
                        style: TextStyle(
                          color: option['color'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.stars,
                        color: Color(0xFFFFD60A),
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+${option['xp']} XP',
                        style: const TextStyle(
                          color: Color(0xFFFFD60A),
                          fontSize: 11,
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
    if (_selectedPractice == null ||
        widget.artistStats.energy < _energyCost ||
        widget.artistStats.money < _moneyCost) {
      return;
    }

    final option = _practiceOptions.firstWhere(
      (opt) => opt['id'] == _selectedPractice,
    );

    final random = Random();

    // Small, gradual skill gains (base from option, ±1 random)
    int baseSkillGain = option['skillGain'] as int;
    int skillGain = baseSkillGain + random.nextInt(3) - 1;
    skillGain = skillGain.clamp(1, baseSkillGain + 2);

    // Very small experience gains
    int xpGain = option['xp'] as int;

    // Tiny fame increase (1 in 3 chance to get +1 fame)
    int fameGain = random.nextInt(3) == 0 ? 1 : 0;

    Map<String, int> improvements = {};
    String practiceMessage = '';

    switch (_selectedPractice) {
      case 'songwriting':
        improvements['songwritingSkill'] = skillGain;
        improvements['experience'] = xpGain;
        practiceMessage =
            'You refined your songwriting techniques through focused practice.';
        break;
      case 'lyrics':
        improvements['lyricsSkill'] = skillGain;
        improvements['experience'] = xpGain;
        practiceMessage =
            'You developed your lyrical abilities with dedicated effort.';
        break;
      case 'composition':
        improvements['compositionSkill'] = skillGain;
        improvements['experience'] = xpGain;
        practiceMessage = 'You enhanced your musical composition skills.';
        break;
      case 'inspiration':
        improvements['inspirationLevel'] = skillGain;
        improvements['experience'] = xpGain;
        practiceMessage = 'You found creative inspiration through exploration.';
        break;
    }

    // Update stats with gradual gains and resource consumption
    final updatedStats = widget.artistStats.copyWith(
      energy: widget.artistStats.energy - _energyCost,
      money: widget.artistStats.money - _moneyCost,
      creativity: (widget.artistStats.creativity + 1).clamp(
        0,
        100,
      ), // Tiny creativity boost
      fanbase: widget.artistStats.fanbase + fameGain, // Sometimes gain a fan
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
                style: TextStyle(color: Colors.white, fontSize: 18),
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
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_timeHours hours of practice completed',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gains:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildResultRow('Skill', '+$skillGain', option['color']),
            _buildResultRow(
              'Experience',
              '+${improvements['experience']} XP',
              const Color(0xFFFFD60A),
            ),
            _buildResultRow('Creativity', '+1', const Color(0xFF9B59B6)),
            if (fameGain > 0)
              _buildResultRow('Fame', '+$fameGain', const Color(0xFF32D74B)),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Resources Used:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Energy',
              '-$_energyCost ⚡',
              const Color(0xFFFF6B9D),
            ),
            _buildResultRow(
              'Money',
              '-\$$_moneyCost 💵',
              const Color(0xFFFF9500),
            ),
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
