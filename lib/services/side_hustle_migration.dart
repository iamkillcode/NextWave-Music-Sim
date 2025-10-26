import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time migration service to normalize side hustle contract IDs
/// Fixes contracts where data['id'] doesn't match the Firestore document ID
class SideHustleMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all contracts to use Firestore document ID as their 'id' field
  /// Returns the number of contracts updated
  Future<int> migrateContractIds() async {
    print('🔄 Starting side hustle contract ID migration...');
    int updatedCount = 0;
    int alreadyCorrectCount = 0;
    int errorCount = 0;

    try {
      // Get all contracts (available and claimed)
      final snapshot =
          await _firestore.collection('side_hustle_contracts').get();

      print('📊 Found ${snapshot.docs.length} contracts to check');

      final batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final currentId = data['id'] as String?;
          final docId = doc.id;

          if (currentId != docId) {
            // ID mismatch - needs migration
            print('  🔧 Migrating: docId=$docId, oldDataId=$currentId');
            batch.update(doc.reference, {'id': docId});
            batchCount++;
            updatedCount++;

            // Firestore batch limit is 500 operations
            if (batchCount >= 500) {
              await batch.commit();
              print('  💾 Committed batch of $batchCount updates');
              batchCount = 0;
            }
          } else {
            // Already correct
            alreadyCorrectCount++;
          }
        } catch (e) {
          print('  ❌ Error processing contract ${doc.id}: $e');
          errorCount++;
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        print('  💾 Committed final batch of $batchCount updates');
      }

      print('✅ Migration complete!');
      print('  📝 Updated: $updatedCount contracts');
      print('  ✓ Already correct: $alreadyCorrectCount contracts');
      if (errorCount > 0) {
        print('  ⚠️ Errors: $errorCount contracts');
      }

      return updatedCount;
    } catch (e, stackTrace) {
      print('❌ Migration failed: $e');
      print(stackTrace);
      rethrow;
    }
  }

  /// Verify all contracts have correct IDs
  /// Returns true if all contracts are correct, false if any mismatches found
  Future<bool> verifyContractIds() async {
    print('🔍 Verifying contract IDs...');
    int mismatchCount = 0;
    int totalCount = 0;

    try {
      final snapshot =
          await _firestore.collection('side_hustle_contracts').get();

      print('📊 Checking ${snapshot.docs.length} contracts');

      for (final doc in snapshot.docs) {
        totalCount++;
        final data = doc.data();
        final currentId = data['id'] as String?;
        final docId = doc.id;

        if (currentId != docId) {
          mismatchCount++;
          print('  ⚠️ Mismatch: docId=$docId, dataId=$currentId');
        }
      }

      if (mismatchCount == 0) {
        print('✅ All $totalCount contracts have correct IDs!');
        return true;
      } else {
        print('❌ Found $mismatchCount mismatches out of $totalCount contracts');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Verification failed: $e');
      print(stackTrace);
      return false;
    }
  }

  /// Clean up old/expired contracts from the pool
  /// Removes contracts older than the specified days
  Future<int> cleanupOldContracts({int daysOld = 7}) async {
    print('🧹 Cleaning up contracts older than $daysOld days...');
    int deletedCount = 0;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection('side_hustle_contracts')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      print('📊 Found ${snapshot.docs.length} old contracts to delete');

      if (snapshot.docs.isEmpty) {
        print('✅ No old contracts to clean up');
        return 0;
      }

      final batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final isAvailable = data['isAvailable'] as bool? ?? true;

        print(
            '  🗑️ Deleting: id=${doc.id}, created=${createdAt?.toLocal()}, available=$isAvailable');

        batch.delete(doc.reference);
        batchCount++;
        deletedCount++;

        if (batchCount >= 500) {
          await batch.commit();
          print('  💾 Committed batch of $batchCount deletions');
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        print('  💾 Committed final batch of $batchCount deletions');
      }

      print('✅ Cleanup complete! Deleted $deletedCount old contracts');
      return deletedCount;
    } catch (e, stackTrace) {
      print('❌ Cleanup failed: $e');
      print(stackTrace);
      rethrow;
    }
  }

  /// Get statistics about the contract pool
  Future<Map<String, int>> getPoolStats() async {
    print('📊 Getting contract pool statistics...');

    try {
      final allSnapshot =
          await _firestore.collection('side_hustle_contracts').get();

      final availableSnapshot = await _firestore
          .collection('side_hustle_contracts')
          .where('isAvailable', isEqualTo: true)
          .get();

      final claimedSnapshot = await _firestore
          .collection('side_hustle_contracts')
          .where('isAvailable', isEqualTo: false)
          .get();

      final stats = {
        'total': allSnapshot.docs.length,
        'available': availableSnapshot.docs.length,
        'claimed': claimedSnapshot.docs.length,
      };

      print('📈 Contract Pool Stats:');
      print('  Total: ${stats['total']}');
      print('  Available: ${stats['available']}');
      print('  Claimed: ${stats['claimed']}');

      return stats;
    } catch (e, stackTrace) {
      print('❌ Failed to get stats: $e');
      print(stackTrace);
      rethrow;
    }
  }
}
