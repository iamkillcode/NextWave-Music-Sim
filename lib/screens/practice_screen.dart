import 'package:flutter/material.dart';
import 'dart:math';
import '../models/artist_stats.dart';
import '../models/pending_practice.dart';

class PracticeScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final List<PendingPractice> pendingPractices;
  final Function(PendingPractice) onPracticeStarted;
  final DateTime currentDate;

  const PracticeScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
    this.pendingPractices = const [],
    required this.onPracticeStarted,
    required this.currentDate,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String? _selectedPractice;

  // Training programs with energy costs as per updated specs
  final List<Map<String, dynamic>> _practiceOptions = [
    {
      'id': 'songwriting',
      'name': 'Songwriting Workshop',
      'emoji': '🎼',
      'description': 'Intensive 3-day songwriting course',
      'color': const Color(0xFF00D9FF),
      'xp': 25,
      'skillGain': 4,
      'moneyCost': 500,
      'energyCost': 10,
      'durationDays': 3,
    },
    {
      'id': 'lyrics',
      'name': 'Lyrics Masterclass',
      'emoji': '📝',
      'description': 'Week-long lyrical writing bootcamp',
      'color': const Color(0xFFFF6B9D),
      'xp': 35,
      'skillGain': 6,
      'moneyCost': 800,
      'energyCost': 15,
      'durationDays': 7,
    },
    {
      'id': 'composition',
      'name': 'Music Theory Course',
      'emoji': '🎹',
      'description': '5-day advanced composition training',
      'color': const Color(0xFF9B59B6),
      'xp': 40,
      'skillGain': 15,
      'moneyCost': 1000,
      'energyCost': 25,
      'durationDays': 5,
    },
    {
      'id': 'inspiration',
      'name': 'Creative Retreat',
      'emoji': '💡',
      'description': 'Weekend getaway for creative renewal',
      'color': const Color(0xFFFFD60A),
      'xp': 20,
      'skillGain': 20,
      'moneyCost': 600,
      'energyCost': 20,
      'durationDays': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedOption = _selectedPractice != null
        ? _practiceOptions.firstWhere((opt) => opt['id'] == _selectedPractice)
        : null;
    final canAfford = selectedOption != null
        ? widget.artistStats.money >= (selectedOption['moneyCost'] as int) &&
            widget.artistStats.energy >= (selectedOption['energyCost'] as int)
        : false;

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
          '🎓 Professional Training',
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
              // Show pending practices if any
              if (widget.pendingPractices.isNotEmpty) ...[
                const Text(
                  'Training in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.pendingPractices.map((practice) {
                  final remaining =
                      practice.getRemainingDays(widget.currentDate);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(int.parse('FF${practice.colorHex}', radix: 16))
                              .withOpacity(0.3),
                          Color(int.parse('FF${practice.colorHex}', radix: 16))
                              .withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(
                                int.parse('FF${practice.colorHex}', radix: 16))
                            .withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(practice.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                practice.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                remaining > 0
                                    ? '$remaining day${remaining == 1 ? '' : 's'} remaining'
                                    : 'Complete! Check your skills',
                                style: TextStyle(
                                  color: remaining > 0
                                      ? Colors.white70
                                      : const Color(0xFF32D74B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: remaining > 0
                                      ? 1 - (remaining / practice.durationDays)
                                      : 1.0,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(int.parse('FF${practice.colorHex}',
                                        radix: 16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 24),
              ],

              // Stats card
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
                      'Your Current Skills',
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
                    // Resources display
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF32D74B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${widget.artistStats.money}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.bolt,
                          color: Color(0xFFFF6B9D),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.artistStats.energy}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Training options title
              const Text(
                'Professional Training Programs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invest in professional courses. Pay upfront, wait for completion, then reap the rewards!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Training options
              ..._practiceOptions.map((option) {
                final isSelected = _selectedPractice == option['id'];
                final canAffordThis = widget.artistStats.money >=
                        (option['moneyCost'] as int) &&
                    widget.artistStats.energy >= (option['energyCost'] as int);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPracticeOption(
                    option: option,
                    isSelected: isSelected,
                    canAfford: canAffordThis,
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Enroll button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedPractice != null && canAfford)
                      ? _enrollInTraining
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPractice == null
                        ? 'Select a Training Program'
                        : canAfford
                            ? 'Enroll Now (\$${selectedOption['moneyCost']}, -${selectedOption['energyCost']} ⚡)'
                            : 'Cannot Afford',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              if (_selectedPractice != null &&
                  !canAfford &&
                  selectedOption != null) ...[
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
                          widget.artistStats.money <
                                  (selectedOption['moneyCost'] as int)
                              ? 'Need \$${selectedOption['moneyCost']} to enroll'
                              : 'Need ${selectedOption['energyCost']} energy to enroll',
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
    required bool canAfford,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPractice = option['id'];
        });
      },
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
                      color: canAfford
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
                      color: canAfford
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: option['color'], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${option['skillGain']} skill',
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: canAfford
                            ? const Color(0xFF32D74B)
                            : const Color(0xFFFF453A),
                        size: 14,
                      ),
                      Text(
                        '\$${option['moneyCost']}',
                        style: TextStyle(
                          color: canAfford
                              ? const Color(0xFF32D74B)
                              : const Color(0xFFFF453A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.bolt,
                        color: canAfford
                            ? const Color(0xFFFF6B9D)
                            : const Color(0xFFFF453A),
                        size: 14,
                      ),
                      Text(
                        '${option['energyCost']} ⚡',
                        style: TextStyle(
                          color: canAfford
                              ? const Color(0xFFFF6B9D)
                              : const Color(0xFFFF453A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0A84FF),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${option['durationDays']} days',
                        style: const TextStyle(
                          color: Color(0xFF0A84FF),
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

  void _enrollInTraining() {
    if (_selectedPractice == null) return;

    final option = _practiceOptions.firstWhere(
      (opt) => opt['id'] == _selectedPractice,
    );

    final moneyCost = option['moneyCost'] as int;
    final energyCost = option['energyCost'] as int;

    if (widget.artistStats.money < moneyCost ||
        widget.artistStats.energy < energyCost) {
      return;
    }

    final random = Random();

    // Small variance on gains (±20%)
    int skillGain = option['skillGain'] as int;
    int variance = (skillGain * 0.2).round();
    skillGain = skillGain + random.nextInt(variance * 2 + 1) - variance;

    // Create pending practice
    final pendingPractice = PendingPractice(
      practiceType: option['id'] as String,
      startDate: widget.currentDate,
      durationDays: option['durationDays'] as int,
      skillGain: skillGain,
      xpGain: option['xp'] as int,
      moneyCost: moneyCost,
    );

    // Deduct money and energy immediately
    final updatedStats = widget.artistStats.copyWith(
      money: widget.artistStats.money - moneyCost,
      energy: widget.artistStats.energy - energyCost,
    );

    widget.onStatsUpdated(updatedStats);
    widget.onPracticeStarted(pendingPractice);

    // Show enrollment confirmation
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
                'Enrolled!',
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
              'You\'ve enrolled in ${option['name']}!',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (option['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (option['color'] as Color).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  _buildResultRow(
                    'Duration',
                    '${option['durationDays']} in-game days',
                    const Color(0xFF0A84FF),
                  ),
                  const SizedBox(height: 8),
                  _buildResultRow(
                    'Completion',
                    pendingPractice.completionDate.toString().split(' ')[0],
                    const Color(0xFF32D74B),
                  ),
                  const SizedBox(height: 8),
                  _buildResultRow(
                    'Expected Gains',
                    '+$skillGain skill, +${option['xp']} XP',
                    option['color'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💰 Payment processed. Training will complete after the specified in-game days pass. Keep playing to advance time!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
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
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
