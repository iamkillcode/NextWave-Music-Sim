import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/side_hustle.dart';

/// Service to manage side hustle contracts in a shared pool
/// All players see the same contracts on a first-come, first-served basis
class SideHustleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Collection reference for side hustle contracts
  CollectionReference get _contractsRef =>
      _firestore.collection('side_hustle_contracts');

  /// Generate a random side hustle contract
  SideHustle _generateRandomContract() {
    // Pick random type
    final type =
        SideHustleType.values[_random.nextInt(SideHustleType.values.length)];

    // Generate contract parameters with some randomness
    final contractLength = 5 + _random.nextInt(21); // 5-25 days

    // Base pay varies by job type
    final basePay = _getBasePay(type);
    final payVariance = (basePay * 0.3).round(); // ±30%
    final dailyPay = basePay + _random.nextInt(payVariance * 2) - payVariance;

    // Energy cost varies by job type
    final baseEnergy = _getBaseEnergy(type);
    final energyVariance = (baseEnergy * 0.2).round(); // ±20%
    final dailyEnergyCost =
        (baseEnergy + _random.nextInt(energyVariance * 2) - energyVariance)
            .clamp(5, 40); // Min 5, max 40 energy per day

    return SideHustle(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      type: type,
      dailyPay: dailyPay,
      dailyEnergyCost: dailyEnergyCost,
      contractLengthDays: contractLength,
      createdAt: DateTime.now(),
    );
  }

  /// Get base daily pay for each job type
  int _getBasePay(SideHustleType type) {
    switch (type) {
      case SideHustleType.security:
        return 150; // Good pay, physical demands
      case SideHustleType.dogWalking:
        return 80; // Lower pay, flexible
      case SideHustleType.babysitting:
        return 120; // Moderate pay, demanding
      case SideHustleType.foodDelivery:
        return 100; // Moderate pay, tips included
      case SideHustleType.rideshare:
        return 130; // Good pay, own vehicle
      case SideHustleType.retail:
        return 90; // Lower pay, steady hours
      case SideHustleType.tutoring:
        return 140; // Good pay, skill-based
      case SideHustleType.bartending:
        return 110; // Moderate pay, tips included
      case SideHustleType.cleaning:
        return 95; // Moderate pay, physical
      case SideHustleType.waiter:
        return 105; // Moderate pay, tips included
    }
  }

  /// Get base energy cost for each job type
  int _getBaseEnergy(SideHustleType type) {
    switch (type) {
      case SideHustleType.security:
        return 15; // Moderate energy
      case SideHustleType.dogWalking:
        return 10; // Low energy
      case SideHustleType.babysitting:
        return 20; // High energy (exhausting!)
      case SideHustleType.foodDelivery:
        return 12; // Moderate energy
      case SideHustleType.rideshare:
        return 12; // Moderate energy
      case SideHustleType.retail:
        return 15; // Moderate energy
      case SideHustleType.tutoring:
        return 8; // Low energy
      case SideHustleType.bartending:
        return 18; // High energy
      case SideHustleType.cleaning:
        return 25; // Very high energy
      case SideHustleType.waiter:
        return 18; // High energy
    }
  }

  /// Generate new contracts for the shared pool
  /// Should be called periodically (e.g., every game day)
  Future<void> generateNewContracts(int count) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < count; i++) {
        final contract = _generateRandomContract();
        final docRef = _contractsRef.doc(contract.id);
        batch.set(docRef, contract.toJson());
      }

      await batch.commit();
      print('✅ Generated $count new side hustle contracts');
    } catch (e) {
      print('❌ Error generating contracts: $e');
    }
  }

  /// Get all available contracts from the shared pool
  Stream<List<SideHustle>> getAvailableContracts() {
    return _contractsRef
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20) // Show max 20 contracts
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    SideHustle.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Claim a contract (first-come, first-served)
  /// Returns the claimed contract with start/end dates, or null if already taken
  Future<SideHustle?> claimContract(
    String contractId,
    DateTime currentGameDate,
  ) async {
    try {
      final docRef = _contractsRef.doc(contractId);

      // Use transaction to ensure atomicity (prevent race conditions)
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          print('❌ Contract not found');
          return null;
        }

        final contract = SideHustle.fromJson(
          snapshot.data() as Map<String, dynamic>,
        );

        if (!contract.isAvailable) {
          print('❌ Contract already claimed by another player');
          return null;
        }

        // Calculate end date
        final endDate = currentGameDate.add(
          Duration(days: contract.contractLengthDays),
        );

        // Mark as unavailable (claimed)
        final claimedContract = contract.copyWith(
          startDate: currentGameDate,
          endDate: endDate,
          isAvailable: false,
        );

        // Update Firestore
        transaction.update(docRef, {
          'isAvailable': false,
          'startDate': Timestamp.fromDate(currentGameDate),
          'endDate': Timestamp.fromDate(endDate),
        });

        print(
          '✅ Contract claimed: ${contract.type.displayName} for ${contract.contractLengthDays} days',
        );
        return claimedContract;
      });
    } catch (e) {
      print('❌ Error claiming contract: $e');
      return null;
    }
  }

  /// Remove old contracts from the pool (cleanup)
  /// Should be called periodically to prevent database bloat
  Future<void> removeExpiredContracts() async {
    try {
      // Remove contracts older than 3 days (real time)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 3));

      final snapshot = await _contractsRef
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ No expired contracts to remove');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Removed ${snapshot.docs.length} expired contracts');
    } catch (e) {
      print('❌ Error removing expired contracts: $e');
    }
  }

  /// Initialize the contract pool with initial contracts
  Future<void> initializeContractPool() async {
    try {
      // Check if pool already has contracts
      final snapshot = await _contractsRef.limit(1).get();

      if (snapshot.docs.isEmpty) {
        // Generate initial batch of contracts
        await generateNewContracts(15);
        print('✅ Initialized contract pool with 15 contracts');
      } else {
        print('✅ Contract pool already initialized');
      }
    } catch (e) {
      print('❌ Error initializing contract pool: $e');
    }
  }

  /// Apply daily side hustle effects (called during daily update)
  /// Returns updated money and energy after deducting energy cost and adding pay
  Map<String, int> applyDailySideHustle({
    required SideHustle sideHustle,
    required int currentMoney,
    required int currentEnergy,
    required DateTime currentGameDate,
  }) {
    // Check if contract is expired
    if (sideHustle.isExpired(currentGameDate)) {
      print('⏰ Side hustle contract expired: ${sideHustle.type.displayName}');
      return {
        'money': currentMoney,
        'energy': currentEnergy,
        'expired': 1, // Flag to indicate expiration
      };
    }

    // Deduct energy cost
    final newEnergy = (currentEnergy - sideHustle.dailyEnergyCost).clamp(
      0,
      100,
    );

    // Add daily pay
    final newMoney = currentMoney + sideHustle.dailyPay;

    print(
      '💼 Side hustle applied: -${sideHustle.dailyEnergyCost} energy, +\$${sideHustle.dailyPay}',
    );

    return {'money': newMoney, 'energy': newEnergy, 'expired': 0};
  }
}
