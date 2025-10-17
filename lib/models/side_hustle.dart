import 'package:cloud_firestore/cloud_firestore.dart';

/// Different types of side hustles available to players
enum SideHustleType {
  security('Security Personnel', '🛡️'),
  dogWalking('Dog Walking', '🐕'),
  babysitting('Babysitting', '👶'),
  foodDelivery('Food Delivery', '🍔'),
  rideshare('Rideshare Driver', '🚗'),
  retail('Retail Worker', '🏪'),
  tutoring('Tutoring', '📚'),
  bartending('Bartending', '🍸'),
  cleaning('Cleaning Service', '🧹'),
  waiter('Waiter/Waitress', '🍽️');

  final String displayName;
  final String emoji;
  const SideHustleType(this.displayName, this.emoji);
}

/// Represents a side hustle contract that players can accept
class SideHustle {
  final String id;
  final SideHustleType type;
  final int dailyPay; // Money earned per game day
  final int dailyEnergyCost; // Energy deducted per game day
  final int contractLengthDays; // Total contract length in game days
  final DateTime? startDate; // When player accepted the contract (game date)
  final DateTime? endDate; // When contract expires (game date)
  final bool isAvailable; // Whether contract is still in the shared pool
  final DateTime createdAt; // When contract was generated (real date)

  const SideHustle({
    required this.id,
    required this.type,
    required this.dailyPay,
    required this.dailyEnergyCost,
    required this.contractLengthDays,
    this.startDate,
    this.endDate,
    this.isAvailable = true,
    required this.createdAt,
  });

  /// Total money to be earned over the contract
  int get totalPay => dailyPay * contractLengthDays;

  /// Total energy cost over the contract
  int get totalEnergyCost => dailyEnergyCost * contractLengthDays;

  /// Days remaining in the contract
  int daysRemaining(DateTime currentGameDate) {
    if (endDate == null) return contractLengthDays;
    final remaining = endDate!.difference(currentGameDate).inDays;
    return remaining.clamp(0, contractLengthDays);
  }

  /// Whether the contract has expired
  bool isExpired(DateTime currentGameDate) {
    if (endDate == null) return false;
    return currentGameDate.isAfter(endDate!) ||
        currentGameDate.isAtSameMomentAs(endDate!);
  }

  /// Check if player can afford the energy cost
  bool canAfford(int currentEnergy) {
    return currentEnergy >= dailyEnergyCost;
  }

  /// Create a copy with updated fields
  SideHustle copyWith({
    String? id,
    SideHustleType? type,
    int? dailyPay,
    int? dailyEnergyCost,
    int? contractLengthDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return SideHustle(
      id: id ?? this.id,
      type: type ?? this.type,
      dailyPay: dailyPay ?? this.dailyPay,
      dailyEnergyCost: dailyEnergyCost ?? this.dailyEnergyCost,
      contractLengthDays: contractLengthDays ?? this.contractLengthDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'dailyPay': dailyPay,
      'dailyEnergyCost': dailyEnergyCost,
      'contractLengthDays': contractLengthDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore JSON
  factory SideHustle.fromJson(Map<String, dynamic> json) {
    return SideHustle(
      id: json['id'] as String,
      type: SideHustleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SideHustleType.security,
      ),
      dailyPay: json['dailyPay'] as int,
      dailyEnergyCost: json['dailyEnergyCost'] as int,
      contractLengthDays: json['contractLengthDays'] as int,
      startDate: json['startDate'] != null
          ? (json['startDate'] as Timestamp).toDate()
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Get quality rating based on pay and energy cost
  String get qualityRating {
    final payPerEnergy = dailyPay / dailyEnergyCost;
    if (payPerEnergy >= 20) return 'Excellent';
    if (payPerEnergy >= 15) return 'Great';
    if (payPerEnergy >= 10) return 'Good';
    if (payPerEnergy >= 7) return 'Fair';
    return 'Poor';
  }

  /// Get color based on quality
  int get qualityColor {
    final rating = qualityRating;
    switch (rating) {
      case 'Excellent':
        return 0xFF32D74B; // Green
      case 'Great':
        return 0xFF0A84FF; // Blue
      case 'Good':
        return 0xFFFFD60A; // Yellow
      case 'Fair':
        return 0xFFFF9F0A; // Orange
      default:
        return 0xFFFF453A; // Red
    }
  }
}
