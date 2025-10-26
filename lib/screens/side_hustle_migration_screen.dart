import 'package:flutter/material.dart';
import '../services/side_hustle_migration.dart';

/// Admin screen for side hustle contract management and migration
class SideHustleMigrationScreen extends StatefulWidget {
  const SideHustleMigrationScreen({super.key});

  @override
  State<SideHustleMigrationScreen> createState() =>
      _SideHustleMigrationScreenState();
}

class _SideHustleMigrationScreenState extends State<SideHustleMigrationScreen> {
  final _migration = SideHustleMigration();
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, int>? _poolStats;

  @override
  void initState() {
    super.initState();
    _loadPoolStats();
  }

  Future<void> _loadPoolStats() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading pool statistics...';
    });

    try {
      final stats = await _migration.getPoolStats();
      setState(() {
        _poolStats = stats;
        _statusMessage = 'Statistics loaded';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running ID migration...';
    });

    try {
      final updatedCount = await _migration.migrateContractIds();
      setState(() {
        _statusMessage = 'Migration complete! Updated $updatedCount contracts.';
        _isLoading = false;
      });

      // Reload stats after migration
      await _loadPoolStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Migrated $updatedCount contracts'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Migration failed: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyIds() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying contract IDs...';
    });

    try {
      final allCorrect = await _migration.verifyContractIds();
      setState(() {
        _statusMessage = allCorrect
            ? '✅ All contract IDs are correct!'
            : '⚠️ Some contracts have mismatched IDs';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: allCorrect ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Verification failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupOldContracts() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text(
          'Clean Up Old Contracts',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete contracts older than 7 days. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Old Contracts'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cleaning up old contracts...';
    });

    try {
      final deletedCount = await _migration.cleanupOldContracts(daysOld: 7);
      setState(() {
        _statusMessage = 'Cleanup complete! Deleted $deletedCount contracts.';
        _isLoading = false;
      });

      // Reload stats after cleanup
      await _loadPoolStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Deleted $deletedCount old contracts'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Cleanup failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Side Hustle Migration'),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isLoading ? Icons.hourglass_empty : Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Color(0xFF1C2128),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage.isEmpty ? 'Ready' : _statusMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pool Statistics Card
            if (_poolStats != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Colors.green,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Contract Pool Statistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                        'Total Contracts', _poolStats!['total'].toString()),
                    _buildStatRow('Available',
                        _poolStats!['available'].toString(), Colors.green),
                    _buildStatRow('Claimed', _poolStats!['claimed'].toString(),
                        Colors.orange),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Migration Actions
            const Text(
              'Migration Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildActionButton(
              icon: Icons.search,
              label: 'Verify Contract IDs',
              description: 'Check if all contracts have correct IDs',
              color: Colors.blue,
              onPressed: _isLoading ? null : _verifyIds,
            ),
            const SizedBox(height: 12),

            _buildActionButton(
              icon: Icons.sync,
              label: 'Migrate Contract IDs',
              description:
                  'Fix contracts where data ID doesn\'t match document ID',
              color: Colors.purple,
              onPressed: _isLoading ? null : _runMigration,
            ),
            const SizedBox(height: 12),

            _buildActionButton(
              icon: Icons.delete_sweep,
              label: 'Clean Up Old Contracts',
              description: 'Delete contracts older than 7 days',
              color: Colors.red,
              onPressed: _isLoading ? null : _cleanupOldContracts,
            ),
            const SizedBox(height: 12),

            _buildActionButton(
              icon: Icons.refresh,
              label: 'Refresh Statistics',
              description: 'Reload contract pool statistics',
              color: Colors.orange,
              onPressed: _isLoading ? null : _loadPoolStats,
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.yellow.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.yellow.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Migration Info',
                        style: TextStyle(
                          color: Colors.yellow.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Migration updates contracts to use Firestore document IDs\n'
                    '• This fixes "claimed by another player" errors\n'
                    '• New contracts are automatically created with correct IDs\n'
                    '• Safe to run multiple times (idempotent)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
