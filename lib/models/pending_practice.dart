class PendingPractice {
  final String
      practiceType; // 'songwriting', 'lyrics', 'composition', 'inspiration'
  final DateTime startDate;
  final int durationDays; // How many in-game days until complete
  final int skillGain; // How much skill will be gained
  final int xpGain; // How much XP will be gained
  final int moneyCost; // How much was paid upfront

  const PendingPractice({
    required this.practiceType,
    required this.startDate,
    required this.durationDays,
    required this.skillGain,
    required this.xpGain,
    required this.moneyCost,
  });

  // Check if practice is complete
  bool isComplete(DateTime currentDate) {
    final completionDate = startDate.add(Duration(days: durationDays));
    return currentDate.isAfter(completionDate) ||
        currentDate.isAtSameMomentAs(completionDate);
  }

  // Get remaining days
  int getRemainingDays(DateTime currentDate) {
    final completionDate = startDate.add(Duration(days: durationDays));
    final remaining = completionDate.difference(currentDate).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  // Get completion date
  DateTime get completionDate => startDate.add(Duration(days: durationDays));

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'practiceType': practiceType,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
      'skillGain': skillGain,
      'xpGain': xpGain,
      'moneyCost': moneyCost,
    };
  }

  // Create from map (Firestore)
  factory PendingPractice.fromMap(Map<String, dynamic> map) {
    return PendingPractice(
      practiceType: map['practiceType'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      durationDays: map['durationDays'] as int,
      skillGain: map['skillGain'] as int,
      xpGain: map['xpGain'] as int,
      moneyCost: map['moneyCost'] as int,
    );
  }

  // Get display name
  String get displayName {
    switch (practiceType) {
      case 'songwriting':
        return 'Songwriting';
      case 'lyrics':
        return 'Lyrics';
      case 'composition':
        return 'Composition';
      case 'inspiration':
        return 'Inspiration';
      default:
        return practiceType;
    }
  }

  // Get emoji
  String get emoji {
    switch (practiceType) {
      case 'songwriting':
        return '🎼';
      case 'lyrics':
        return '📝';
      case 'composition':
        return '🎹';
      case 'inspiration':
        return '💡';
      default:
        return '🎸';
    }
  }

  // Get color
  String get colorHex {
    switch (practiceType) {
      case 'songwriting':
        return '00D9FF';
      case 'lyrics':
        return 'FF6B9D';
      case 'composition':
        return '9B59B6';
      case 'inspiration':
        return 'FFD60A';
      default:
        return 'F39C12';
    }
  }
}
