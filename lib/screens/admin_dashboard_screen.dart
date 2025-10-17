import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _gameStats;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _errorLogs = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadData();
  }

  Future<void> _checkAdminAndLoadData() async {
    setState(() => _isLoading = true);

    final isAdmin = await _adminService.isAdmin();

    if (!isAdmin) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Access Denied', 'You do not have admin privileges.');
      }
      return;
    }

    await _loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    try {
      final stats = await _adminService.getGameStats();
      final admins = await _adminService.getAdminList();
      final logs = await _adminService.getErrorLogs(limit: 10);

      setState(() {
        _gameStats = stats;
        _admins = admins;
        _errorLogs = logs;
      });
    } catch (e) {
      print('Error loading admin data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFF00D9FF)),
            const SizedBox(width: 8),
            const Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF00D9FF),
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Game Statistics Section
            _buildSectionHeader('Game Statistics', Icons.analytics),
            _buildGameStatsCard(),
            const SizedBox(height: 24),

            // Quick Actions Section
            _buildSectionHeader('Quick Actions', Icons.bolt),
            _buildQuickActionsCard(),
            const SizedBox(height: 24),

            // Admin Management Section
            _buildSectionHeader(
                'Admin Management', Icons.supervised_user_circle),
            _buildAdminManagementCard(),
            const SizedBox(height: 24),

            // Error Logs Section
            _buildSectionHeader('Recent Error Logs', Icons.bug_report),
            _buildErrorLogsCard(),
            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('Danger Zone', Icons.warning),
            _buildDangerZoneCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00D9FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatsCard() {
    if (_gameStats == null) {
      return _buildLoadingCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '👥 Players',
                  _gameStats!['totalPlayers'].toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '🎵 Songs',
                  _gameStats!['totalSongs'].toString(),
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '🤖 NPCs',
                  _gameStats!['totalNPCs'].toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '📱 Posts',
                  _gameStats!['totalEchoXPosts'].toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            '💼 Active Hustles',
            _gameStats!['activeHustles'].toString(),
            Colors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.smart_toy,
            label: 'Initialize NPCs',
            description: 'Create 10 signature NPC artists',
            color: const Color(0xFF00D9FF),
            onPressed: _initializeNPCs,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.music_note,
            label: 'Force NPC Release',
            description: 'Make a specific NPC release a new song',
            color: Colors.purple,
            onPressed: _showForceNPCReleaseDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.update,
            label: 'Trigger Daily Update',
            description: 'Manually run daily game update',
            color: Colors.green,
            onPressed: _triggerDailyUpdate,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.notification_important,
            label: 'Send Global Notification',
            description: 'Broadcast message to all players',
            color: Colors.orange,
            onPressed: _showSendNotificationDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.card_giftcard,
            label: 'Send Gift to Player',
            description: 'Gift money, fame, or items to testers',
            color: Colors.pink,
            onPressed: _showSendGiftDialog,
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
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admin Users',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _showGrantAdminDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Admin'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_admins.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No admin users found',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._admins.map((admin) => _buildAdminTile(admin)).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00D9FF),
            child: Text(
              admin['name'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  admin['userId'],
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            color: Colors.white60,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: admin['userId']));
              _showSnackBar('User ID copied to clipboard');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLogsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          if (_errorLogs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent errors',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._errorLogs
                .take(5)
                .map((log) => _buildErrorLogTile(log))
                .toList(),
          if (_errorLogs.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Navigate to full error logs screen
              },
              child: const Text('View All Logs'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorLogTile(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log['error'] ?? 'Unknown error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Player: ${log['playerId'] ?? 'Unknown'}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildDangerButton(
            icon: Icons.delete_forever,
            label: 'Reset All Player Data',
            description: 'Delete all player progress (IRREVERSIBLE)',
            onPressed: _showResetDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.7),
                      fontSize: 12,
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

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
      ),
    );
  }

  // Action Methods

  Future<void> _initializeNPCs() async {
    _showLoadingDialog('Initializing NPCs...');

    try {
      final result = await _adminService.initializeNPCs();

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result['success'] == true) {
          _showSuccessDialog(
            'NPCs Initialized!',
            'Created ${result['count']} NPC artists:\n\n'
                '${result['signatureNPCs'] ?? 0} signature artists\n'
                'Total songs: ${result['totalSongs'] ?? 0}\n\n'
                'They will now appear in charts!',
          );
          await _loadData(); // Refresh stats
        } else {
          _showError(
              'Already Initialized', result['message'] ?? 'NPCs already exist');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error', e.toString());
      }
    }
  }

  Future<void> _triggerDailyUpdate() async {
    _showLoadingDialog('Triggering daily update...');

    try {
      final result = await _adminService.triggerDailyUpdate();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(
          'Update Complete!',
          'Daily update completed successfully.\n\n'
              'Players updated: ${result['playersUpdated'] ?? 0}',
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error', e.toString());
      }
    }
  }

  void _showForceNPCReleaseDialog() {
    String? selectedNpcId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.music_note, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Force NPC Release',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select an NPC to force a new song release:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedNpcId,
                  hint: const Text(
                    'Choose NPC...',
                    style: TextStyle(color: Colors.white60),
                  ),
                  dropdownColor: const Color(0xFF1A1A1A),
                  underline: const SizedBox(),
                  items: AdminService.AVAILABLE_NPCS.map((npc) {
                    return DropdownMenuItem<String>(
                      value: npc['id'],
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.purple,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  npc['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  npc['genre']!,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedNpcId = value;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedNpcId == null
                  ? null
                  : () async {
                      // Close the selection dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // Show loading dialog
                      _showLoadingDialog('Generating song for NPC...');

                      try {
                        final result =
                            await _adminService.forceNPCRelease(selectedNpcId!);

                        // Close loading dialog if still mounted
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (mounted) {
                          if (result['success'] == true) {
                            final data = result['data'];
                            _showSuccessDialog(
                              '🎵 Song Released!',
                              '${data['npcName']} released "${data['songTitle']}"\n\n'
                                  'Quality: ${data['quality']}\n'
                                  'Initial Streams: ${data['initialStreams']}\n'
                                  'Total Songs: ${data['totalSongs']}',
                            );
                          } else {
                            _showError(
                                'Error', result['error'] ?? 'Unknown error');
                          }
                        }
                      } catch (e) {
                        // Close loading dialog if still mounted
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (mounted) {
                          _showError('Error', e.toString());
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text(
                'Release Song',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Send Global Notification',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final title = titleController.text.trim();
              final message = messageController.text.trim();

              if (title.isEmpty || message.isEmpty) {
                _showError('Error', 'Title and message are required');
                return;
              }

              _showLoadingDialog('Sending notification...');

              try {
                await _adminService.sendGlobalNotification(title, message);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessDialog(
                    'Sent!',
                    'Notification sent to all players.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
            ),
            child: const Text(
              'Send',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showGrantAdminDialog() {
    final userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Grant Admin Access',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: userIdController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'User ID',
            labelStyle: TextStyle(color: Colors.white60),
            hintText: 'Enter Firebase User ID',
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              Navigator.pop(context);

              if (userId.isEmpty) {
                _showError('Error', 'User ID is required');
                return;
              }

              _showLoadingDialog('Granting admin access...');

              try {
                await _adminService.grantAdminAccess(userId);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessDialog(
                    'Success!',
                    'Admin access granted to user.',
                  );
                  await _loadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
            ),
            child: const Text(
              'Grant Access',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'WARNING',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        content: const Text(
          'This will DELETE ALL PLAYER DATA.\n\n'
          'This action is IRREVERSIBLE and cannot be undone.\n\n'
          'Are you absolutely sure?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Deleting all player data...');

              try {
                await _adminService.resetAllPlayerData();
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessDialog(
                    'Data Reset',
                    'All player data has been deleted.',
                  );
                  await _loadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE EVERYTHING'),
          ),
        ],
      ),
    );
  }

  // Dialog Helpers

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00D9FF)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  void _showSendGiftDialog() async {
    // Load player list
    _showLoadingDialog('Loading players...');

    try {
      final players = await _adminService.getAllPlayers();

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (players.isEmpty) {
        _showError('No Players', 'No players found in the database');
        return;
      }

      String? selectedPlayerId;
      String? selectedGiftType;
      final amountController = TextEditingController();
      final messageController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // Get selected gift info
            final selectedGift = AdminService.GIFT_TYPES.firstWhere(
              (g) => g['id'] == selectedGiftType,
              orElse: () => {},
            );

            // Auto-fill default amount when gift type changes
            if (selectedGiftType != null &&
                selectedGift['defaultAmount'] != null &&
                amountController.text.isEmpty) {
              amountController.text = selectedGift['defaultAmount'].toString();
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.pink),
                  SizedBox(width: 8),
                  Text(
                    'Send Gift to Player',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player Selection
                      const Text(
                        'Select Recipient:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedPlayerId,
                          hint: const Text(
                            'Choose player...',
                            style: TextStyle(color: Colors.white60),
                          ),
                          dropdownColor: const Color(0xFF1A1A1A),
                          underline: const SizedBox(),
                          items: players.map((player) {
                            return DropdownMenuItem<String>(
                              value: player['id'],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          player['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '⭐${player['fame']} | \$${player['money']} | 👥${player['fanbase']}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPlayerId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gift Type Selection
                      const Text(
                        'Gift Type:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedGiftType,
                          hint: const Text(
                            'Choose gift type...',
                            style: TextStyle(color: Colors.white60),
                          ),
                          dropdownColor: const Color(0xFF1A1A1A),
                          underline: const SizedBox(),
                          items: AdminService.GIFT_TYPES.map((gift) {
                            return DropdownMenuItem<String>(
                              value: gift['id'],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    gift['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    gift['description'],
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGiftType = value;
                              // Clear amount for pack types
                              final gift = AdminService.GIFT_TYPES
                                  .firstWhere((g) => g['id'] == value);
                              if (gift['defaultAmount'] != null) {
                                amountController.text =
                                    gift['defaultAmount'].toString();
                              } else {
                                amountController.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Amount (if applicable)
                      if (selectedGift['defaultAmount'] != null) ...[
                        const Text(
                          'Amount:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter amount...',
                            hintStyle: const TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Optional Message
                      const Text(
                        'Message (Optional):',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Add a personal message to the recipient...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selectedPlayerId == null ||
                          selectedGiftType == null)
                      ? null
                      : () async {
                          // Parse amount if needed
                          int? amount;
                          if (selectedGift['defaultAmount'] != null) {
                            amount = int.tryParse(amountController.text) ??
                                selectedGift['defaultAmount'];
                          }

                          final recipientName = players.firstWhere(
                              (p) => p['id'] == selectedPlayerId)['name'];

                          // Close gift selection dialog
                          Navigator.of(context, rootNavigator: true).pop();

                          // Show loading dialog
                          _showLoadingDialog(
                              'Sending gift to $recipientName...');

                          try {
                            final result = await _adminService.sendGiftToPlayer(
                              recipientId: selectedPlayerId!,
                              giftType: selectedGiftType!,
                              amount: amount,
                              message: messageController.text.trim().isEmpty
                                  ? null
                                  : messageController.text.trim(),
                            );

                            // Close loading dialog if still mounted
                            if (mounted && Navigator.canPop(context)) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }

                            if (mounted) {
                              if (result['success'] == true) {
                                final data = result['data'];
                                _showSuccessDialog(
                                  '🎁 Gift Sent!',
                                  'Successfully sent ${data['giftDescription']} to ${data['recipientName']}!\n\n'
                                      'They will receive a notification about the gift.',
                                );
                              } else {
                                _showError('Error',
                                    result['error'] ?? 'Unknown error');
                              }
                            }
                          } catch (e) {
                            // Close loading dialog if still mounted
                            if (mounted && Navigator.canPop(context)) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }

                            if (mounted) {
                              _showError('Error', e.toString());
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Send Gift',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      _showError('Error Loading Players', e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
