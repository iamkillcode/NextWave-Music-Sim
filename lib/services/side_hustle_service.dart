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

    // Use placeholder ID - will be replaced by Firestore document ID
    return SideHustle(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
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
    print('🎯 Attempting to generate $count new contracts...');
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < count; i++) {
        final contract = _generateRandomContract();
        // Use auto-generated Firestore document ID
        final docRef = _contractsRef.doc();
        // Ensure stored data uses the Firestore document ID for 'id'
        final data = contract.toJson();
        data['id'] = docRef.id;
        batch.set(docRef, data);
        print(
          '  📝 Contract $i: ${contract.type.displayName} - \$${contract.dailyPay}/day for ${contract.contractLengthDays} days (docId: ${docRef.id})',
        );
      }

      await batch.commit();
      print('✅ Successfully generated $count new side hustle contracts');
    } catch (e, stackTrace) {
      print('❌ Error generating contracts: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw to see error in UI
    }
  }

  /// Get all available contracts from the shared pool
  Stream<List<SideHustle>> getAvailableContracts() {
    print('📡 Setting up stream for available contracts...');
    return _contractsRef
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20) // Show max 20 contracts
        .snapshots()
        .handleError((error) {
      print('❌ Error in contracts stream: $error');
      print('❌ Error details: ${error.toString()}');
    }).map((snapshot) {
      print(
          '📊 Received ${snapshot.docs.length} available contracts from Firestore');

      // Debug: log first few contracts
      if (snapshot.docs.isNotEmpty) {
        for (var i = 0; i < snapshot.docs.length && i < 3; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          print(
              '  🔍 Contract ${i + 1}: docId=${doc.id}, dataId=${data['id']}, type=${data['type']}, isAvailable=${data['isAvailable']}');
        }
      }

      return snapshot.docs
          .map(
            (doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                // IMPORTANT: Use Firestore document ID, not the 'id' field in data
                final oldId = data['id'];
                data['id'] = doc.id;
                print('🔄 Replacing contract ID: old=$oldId, new=${doc.id}');
                final contract = SideHustle.fromJson(data);
                print(
                    '✅ Parsed contract: id=${contract.id}, type=${contract.type.displayName}');
                return contract;
              } catch (e) {
                print('❌ Error parsing contract ${doc.id}: $e');
                return null;
              }
            },
          )
          .whereType<SideHustle>() // Filter out nulls
          .toList();
    });
  }

  /// Claim a contract (first-come, first-served)
  /// Returns the claimed contract with start/end dates, or null if already taken
  Future<SideHustle?> claimContract(
    String contractId,
    DateTime currentGameDate,
  ) async {
    print('🎯 Attempting to claim contract: $contractId');
    try {
      final docRef = _contractsRef.doc(contractId);

      // Use transaction to ensure atomicity (prevent race conditions)
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          print('❌ Contract document does not exist in Firestore: $contractId');
          return null;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        print(
            '📋 Contract data BEFORE: id=${data['id']}, type=${data['type']}, isAvailable=${data['isAvailable']}');

        // IMPORTANT: Replace with Firestore document ID (same as getAvailableContracts)
        data['id'] = contractId;
        print(
            '✅ Contract data AFTER: id=${data['id']} (replaced with Firestore doc ID)');

        final contract = SideHustle.fromJson(data);

        if (!contract.isAvailable) {
          print(
              '❌ Contract already claimed by another player (isAvailable=false)');
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

        print('🎉 Claimed contract has ID: ${claimedContract.id}');

        // Update Firestore
        transaction.update(docRef, {
          'isAvailable': false,
          'startDate': Timestamp.fromDate(currentGameDate),
          'endDate': Timestamp.fromDate(endDate),
        });

        print(
            '✅ Contract claimed successfully: ${contract.type.displayName} for ${contract.contractLengthDays} days');
        return claimedContract;
      });
    } catch (e, stackTrace) {
      print('❌ Error claiming contract: $e');
      print('Stack trace: $stackTrace');
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

  /// Initialize contract pool on first launch
  Future<void> initializeContractPool() async {
    try {
      print('🔍 Checking if contract pool needs initialization...');
      // Check if pool already has contracts (available or unavailable)
      final snapshot = await _contractsRef.limit(1).get();

      if (snapshot.docs.isEmpty) {
        print(
            '📋 Contract pool is completely empty, initializing with 15 contracts...');
        // Generate initial batch of contracts
        await generateNewContracts(15);
        print('✅ Initialized contract pool with 15 contracts');
      } else {
        print(
          '✅ Contract pool has documents (${snapshot.docs.length} found in sample)',
        );

        // Check how many are available
        final availableSnapshot = await _contractsRef
            .where('isAvailable', isEqualTo: true)
            .limit(5)
            .get();
        print(
            '📊 Available contracts in pool: ${availableSnapshot.docs.length}');

        if (availableSnapshot.docs.isEmpty) {
          print(
              '⚠️ No available contracts found! Generating 10 new contracts...');
          await generateNewContracts(10);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing contract pool: $e');
      print('Stack trace: $stackTrace');
      // Don't rethrow - this is called in initState, let app continue
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

  /// Terminate a claimed contract and return it to the pool
  /// Marks the contract as available and clears start/end dates
  Future<bool> terminateContract(String contractId) async {
    print('🛑 Terminating contract: $contractId');
    try {
      final docRef = _contractsRef.doc(contractId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) {
          throw Exception('Contract does not exist');
        }
        final data = snap.data() as Map<String, dynamic>;
        final wasAvailable = (data['isAvailable'] as bool?) ?? true;
        if (wasAvailable == true) {
          print('ℹ️ Contract $contractId already available in pool');
        }
        tx.update(docRef, {
          'isAvailable': true,
          'startDate': null,
          'endDate': null,
        });
      });
      print('✅ Contract $contractId returned to pool');
      return true;
    } catch (e, st) {
      print('❌ Error terminating contract $contractId: $e');
      print(st);
      return false;
    }
  }
}
