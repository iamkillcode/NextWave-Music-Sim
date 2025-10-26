import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/side_hustle.dart';
import '../services/side_hustle_service.dart';

class SideHustleScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdate;
  final DateTime currentGameDate;

  const SideHustleScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdate,
    required this.currentGameDate,
  });

  @override
  State<SideHustleScreen> createState() => _SideHustleScreenState();
}

class _SideHustleScreenState extends State<SideHustleScreen> {
  final SideHustleService _sideHustleService = SideHustleService();
  late ArtistStats _currentStats;

  @override
  void initState() {
    super.initState();
    _currentStats = widget.artistStats;
    // Initialize contract pool if needed
    _sideHustleService.initializeContractPool();
  }

  @override
  Widget build(BuildContext context) {
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
          '💼 Side Hustles',
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
              // Active contract section
              if (_currentStats.activeSideHustle != null)
                _buildActiveContractCard()
              else
                _buildNoActiveContractCard(),

              const SizedBox(height: 24),

              // Available contracts section
              _buildSectionHeader('Available Contracts', Icons.work_outline),
              const SizedBox(height: 8),
              Text(
                'First come, first served! Contracts claimed by other players disappear.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              _buildAvailableContracts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContractCard() {
    final hustle = _currentStats.activeSideHustle!;
    final daysRemaining = hustle.daysRemaining(widget.currentGameDate);
    final progress = 1.0 - (daysRemaining / hustle.contractLengthDays);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(hustle.qualityColor).withOpacity(0.3),
            Color(hustle.qualityColor).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(hustle.qualityColor), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(hustle.qualityColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hustle.type.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hustle.type.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF32D74B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Active Contract',
                        style: TextStyle(
                          color: const Color(0xFF32D74B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$daysRemaining days remaining',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(hustle.qualityColor),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                '💰 \$${hustle.dailyPay}/day',
                const Color(0xFF32D74B),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                '⚡ -${hustle.dailyEnergyCost}/day',
                const Color(0xFFFF6B9D),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Terminate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showTerminateDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Terminate Contract',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveContractCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_off_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Contract',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse available contracts below to start earning money!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableContracts() {
    return StreamBuilder<List<SideHustle>>(
      stream: _sideHustleService.getAvailableContracts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF453A),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading contracts: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          );
        }

        final contracts = snapshot.data ?? [];

        if (contracts.isEmpty) {
          print('⚠️ No contracts found in Firestore');
          print('📍 Connection state: ${snapshot.connectionState}');

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Contracts Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new opportunities!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    print('🔄 Manual refresh requested');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing contracts...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Re-initialize pool
                    await _sideHustleService.initializeContractPool();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: contracts
              .map((contract) => _buildContractCard(contract))
              .toList(),
        );
      },
    );
  }

  Widget _buildContractCard(SideHustle contract) {
    final canClaim = _currentStats.activeSideHustle == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canClaim
              ? Color(contract.qualityColor).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canClaim ? () => _showClaimDialog(contract) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(contract.qualityColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        contract.type.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.type.displayName,
                            style: TextStyle(
                              color: canClaim
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                contract.qualityColor,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contract.qualityRating,
                              style: TextStyle(
                                color: Color(contract.qualityColor),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildContractStat(
                      Icons.attach_money,
                      '\$${contract.dailyPay}/day',
                      const Color(0xFF32D74B),
                    ),
                    _buildContractStat(
                      Icons.bolt,
                      '-${contract.dailyEnergyCost}/day',
                      const Color(0xFFFF6B9D),
                    ),
                    _buildContractStat(
                      Icons.calendar_today,
                      '${contract.contractLengthDays} days',
                      const Color(0xFF0A84FF),
                    ),
                    _buildContractStat(
                      Icons.trending_up,
                      '\$${contract.totalPay} total',
                      const Color(0xFFFFD60A),
                    ),
                  ],
                ),

                if (!canClaim) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF9F0A),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Terminate your current contract to accept this one',
                            style: TextStyle(
                              color: const Color(0xFFFF9F0A),
                              fontSize: 12,
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
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContractStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0A84FF), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showClaimDialog(SideHustle contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(contract.type.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                contract.type.displayName,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contract Details:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogRow('💰 Daily Pay:', '\$${contract.dailyPay}'),
            _buildDialogRow(
              '⚡ Daily Energy Cost:',
              '-${contract.dailyEnergyCost}',
            ),
            _buildDialogRow(
              '📅 Contract Length:',
              '${contract.contractLengthDays} days',
            ),
            _buildDialogRow('💵 Total Earnings:', '\$${contract.totalPay}'),
            _buildDialogRow(
              '⚡ Total Energy Cost:',
              '-${contract.totalEnergyCost}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0A84FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Energy will be deducted automatically every game day',
                      style: TextStyle(
                        color: const Color(0xFF0A84FF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => _claimContract(contract),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF32D74B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Accept Contract',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog() {
    final hustle = widget.artistStats.activeSideHustle!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Terminate Contract?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to terminate your ${hustle.type.displayName} contract?',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFFF9F0A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have ${hustle.daysRemaining(widget.currentGameDate)} days remaining',
                      style: const TextStyle(
                        color: Color(0xFFFF9F0A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Contract',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => _terminateContract(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF453A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Terminate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimContract(SideHustle contract) async {
    Navigator.pop(context); // Close dialog

    print(
        '🎯 Claiming contract with ID: ${contract.id} (type: ${contract.type.displayName})');

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claiming contract...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final claimedContract = await _sideHustleService.claimContract(
        contract.id,
        widget.currentGameDate,
      );

      if (claimedContract != null) {
        print(
            '✅ Contract claimed successfully! ID: ${claimedContract.id}, Type: ${claimedContract.type.displayName}');

        // Update local state to show active contract immediately
        setState(() {
          _currentStats = _currentStats.copyWith(
            activeSideHustle: claimedContract,
          );
        });

        print(
            '📊 Updated local state with contract ID: ${_currentStats.activeSideHustle?.id}');

        // Also update parent stats
        widget.onStatsUpdate(_currentStats);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Contract accepted: ${contract.type.displayName}',
              ),
              backgroundColor: const Color(0xFF32D74B),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Contract already claimed by another player'),
              backgroundColor: Color(0xFFFF453A),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF453A),
          ),
        );
      }
    }
  }

  Future<void> _terminateContract() async {
    Navigator.pop(context); // Close dialog

    final active = _currentStats.activeSideHustle;
    if (active == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active contract to terminate'),
          backgroundColor: Color(0xFFFF453A),
        ),
      );
      return;
    }

    // Try to return the contract to the pool first
    final success = await _sideHustleService.terminateContract(active.id);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to terminate contract. Please try again.'),
            backgroundColor: Color(0xFFFF453A),
          ),
        );
      }
      return;
    }

    // Update local state to clear side hustle
    setState(() {
      _currentStats = _currentStats.copyWith(clearSideHustle: true);
    });

    // Also update parent stats (saves to Firestore via dashboard callback)
    widget.onStatsUpdate(_currentStats);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract terminated'),
          backgroundColor: Color(0xFFFF9F0A),
        ),
      );
    }
  }
}
