import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/firestore_sanitizer.dart';
import '../services/admin_service.dart';
import '../services/remote_config_service.dart';
import 'side_hustle_migration_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _gameStats;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _errorLogs = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadData();
  }

  // Safe navigation helper
  void _safePopNavigator() {
    if (mounted) {
      try {
        Navigator.of(context).pop();
      } catch (e) {
        // Silently catch navigation errors
        print('Navigation error: $e');
      }
    }
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

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

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

            // Stream Analytics & Debugging Section
            _buildSectionHeader(
                'Stream Analytics & Debugging', Icons.trending_up),
            _buildStreamAnalyticsCard(),
            const SizedBox(height: 24),

            // Admin Management Section
            _buildSectionHeader(
                'Admin Management', Icons.supervised_user_circle),
            _buildAdminManagementCard(),
            const SizedBox(height: 24),

            // NexTube Configuration Section
            _buildSectionHeader('NexTube Configuration', Icons.ondemand_video),
            _buildNexTubeConfigCard(),
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

  Future<void> _runNexTubeNowSelf() async {
    _showLoadingDialog('Simulating NexTube for your account...');
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('runNextTubeNow');
      final result = await callable.call({});
      _safePopNavigator();
      final data = Map<String, dynamic>.from(result.data as Map);
      final views = data['totalViewsAdded'] ?? 0;
      final earningsCents = data['totalEarningsCents'] ?? 0;
      final dollars = (earningsCents is num)
          ? (earningsCents / 100).toStringAsFixed(2)
          : '0.00';
      final subs = data['subscribersAdded'] ?? 0;
      final processed = data['processed'] ?? 0;
      _showSuccessDialog(
        'NexTube Simulated',
        'Processed videos: $processed\n+Views: +$views\n+Earnings: +\$$dollars\n+Subscribers: +$subs',
      );
    } catch (e) {
      _safePopNavigator();
      _showError('Failed to run NexTube', e.toString());
    }
  }

  Future<void> _runNexTubeForAllAdmin() async {
    _showLoadingDialog('Simulating NexTube for all players...');
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('runNextTubeForAllAdmin');
      final result = await callable.call({});
      _safePopNavigator();
      final data = Map<String, dynamic>.from(result.data as Map);
      final views = data['totalViewsAdded'] ?? 0;
      final earningsCents = data['totalEarningsCents'] ?? 0;
      final dollars = (earningsCents is num)
          ? (earningsCents / 100).toStringAsFixed(2)
          : '0.00';
      final pages = data['pages'] ?? 0;
      final processed = data['processed'] ?? 0;
      _showSuccessDialog(
        'NexTube Simulated (All Players)',
        'Processed videos: $processed\nPages: $pages\nViews: +$views\nEarnings: +\$$dollars',
      );
    } catch (e) {
      _safePopNavigator();
      _showError('Failed to run NexTube (All)', e.toString());
    }
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
            icon: Icons.leaderboard,
            label: 'Trigger Weekly Charts Update',
            description: 'Regenerate weekly leaderboard snapshots',
            color: Colors.cyan,
            onPressed: _showTriggerWeeklyChartsDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.fire_extinguisher,
            label: 'Trigger Gandalf The Black Post',
            description: 'Generate controversial music critic post',
            color: Colors.red,
            onPressed: _triggerGandalfPost,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.work,
            label: 'Generate Side Hustle Contracts',
            description: 'Create new job contracts for players',
            color: Colors.deepPurple,
            onPressed: _showGenerateContractsDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.construction,
            label: 'Side Hustle Migration Tools',
            description: 'Fix contract IDs, cleanup, and view stats',
            color: Colors.deepOrange,
            onPressed: _navigateToMigrationScreen,
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
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.search,
            label: 'Search & Manage Players',
            description: 'View, edit, or delete player accounts',
            color: Colors.blue,
            onPressed: _showPlayerManagementDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.access_time,
            label: 'Adjust Game Time',
            description: 'Fast forward or rewind game date',
            color: Colors.teal,
            onPressed: _showGameTimeAdjustDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.bar_chart,
            label: 'View Analytics Dashboard',
            description: 'Detailed stats and player activity',
            color: Colors.indigo,
            onPressed: _showAnalyticsDashboard,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.sync,
            label: 'Sync Player Streams',
            description: 'Update all player stream counts from songs',
            color: Colors.blue,
            onPressed: _syncPlayerStreams,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.chat,
            label: 'Chat Moderation',
            description: 'View reported messages and manage chat',
            color: const Color(0xFF00D9FF),
            onPressed: _showChatModeration,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.comment,
            label: 'Comment Moderation',
            description: 'View reported comments and manage content',
            color: const Color(0xFF7C3AED),
            onPressed: _showCommentModeration,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.cleaning_services,
            label: 'Clear Old Notifications',
            description: 'Delete notifications older than 30 days',
            color: Colors.amber,
            onPressed: _clearOldNotifications,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.bug_report,
            label: 'Test Error System',
            description: 'Trigger test error for monitoring',
            color: Colors.deepOrange,
            onPressed: _testErrorSystem,
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

  Widget _buildStreamAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              const Text(
                'Real-Time Stream Debugger',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter a song ID to see real-time stream calculations and debug why it\'s getting specific stream counts.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.search,
            label: 'Debug Song Streams',
            description: 'Analyze stream calculation for any song',
            color: const Color(0xFF00D9FF),
            onPressed: _showStreamDebugDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.analytics,
            label: 'View Top Streaming Songs',
            description: 'See songs with highest daily streams',
            color: Colors.purple,
            onPressed: _showTopStreamingSongs,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.person,
            label: 'Debug Player Streams',
            description: 'View all streams for a specific player',
            color: Colors.green,
            onPressed: _showPlayerStreamsDebug,
          ),
        ],
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
            ..._admins.map((admin) => _buildAdminTile(admin)),
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

  Widget _buildNexTubeConfigCard() {
    final config = RemoteConfigService();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ondemand_video, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 8),
              const Text(
                'Upload Limits & Anti-Abuse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Current NexTube upload restrictions (from Remote Config):',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigRow(
            '⏱️ Cooldown Period',
            '${config.nexTubeCooldownMinutes} minutes',
            'Minimum time between uploads',
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '📊 Daily Upload Limit',
            '${config.nexTubeDailyUploadLimit} uploads per 24h',
            'Maximum videos per player per day',
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '🔍 Duplicate Window',
            '${config.nexTubeDuplicateWindowDays} days',
            'Period to check for duplicate titles',
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '🎯 Similarity Threshold',
            '${(config.nexTubeSimilarityThreshold * 100).toStringAsFixed(0)}%',
            'Near-duplicate detection sensitivity',
          ),
          const Divider(height: 32, color: Colors.white10),
          const Text(
            'Backend Simulation Parameters:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '💰 RPM Range',
            '\$${(config.nexRPMMinCents / 100).toStringAsFixed(2)} - \$${(config.nexRPMMaxCents / 100).toStringAsFixed(2)}',
            'Revenue per 1000 views (cents)',
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '📈 Daily View Cap',
            '${config.nexDailyViewCap ~/ 1000}K views',
            'Maximum views per video per day',
          ),
          const SizedBox(height: 12),
          _buildConfigRow(
            '👥 Subscriber Threshold',
            '${config.nexSubsMonetize} subs',
            'Minimum for monetization',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/remote-config-debug');
                  },
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('View Full Config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                    foregroundColor: const Color(0xFFFF6B6B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await config.refresh();
                      _showSnackBar('Remote Config refreshed successfully');
                      setState(() {});
                    } catch (e) {
                      _showSnackBar('Failed to refresh: $e');
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF).withOpacity(0.2),
                    foregroundColor: const Color(0xFF00D9FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To modify these values, update Remote Config in Firebase Console. Changes take effect on next app fetch (up to 1 hour).',
                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runNexTubeNowSelf,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Run NexTube Now (You)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF).withOpacity(0.15),
                    foregroundColor: const Color(0xFF00D9FF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runNexTubeForAllAdmin,
                  icon: const Icon(Icons.public, size: 18),
                  label: const Text('Run NexTube Now (All Players)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.15),
                    foregroundColor: const Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            ..._errorLogs.take(5).map((log) => _buildErrorLogTile(log)),
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

      _safePopNavigator(); // Close loading

      if (mounted) {
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
      _safePopNavigator();
      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  Future<void> _triggerDailyUpdate() async {
    // ⚠️ WARNING: Prevent duplicate processing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('⚠️ WARNING', style: TextStyle(color: Colors.orange)),
          ],
        ),
        content: const Text(
          'This will process ALL players and add streams/money/stats.\n\n'
          '⚠️ If the scheduled function already ran this hour, this will be IGNORED (duplicate protection is active).\n\n'
          'Only use if:\n'
          '• The scheduled function failed\n'
          '• You need to manually advance the game\n'
          '• You\'re testing with duplicate protection\n\n'
          'Players already processed today will be automatically skipped.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'I Understand - Proceed',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Triggering daily update...');

    try {
      final result = await _adminService.triggerDailyUpdate();

      _safePopNavigator();

      if (mounted) {
        final processed = result['playersProcessed'] ?? 0;
        final skipped = (result['totalPlayers'] ?? 0) - processed;
        
        _showSuccessDialog(
          'Update Complete!',
          'Daily update completed successfully.\n\n'
              'Players processed: $processed\n'
              'Players skipped (duplicate): $skipped',
        );
        await _loadData();
      }
    } catch (e) {
      _safePopNavigator();
      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  Future<void> _triggerGandalfPost() async {
    _showLoadingDialog('🧙‍♂️ Gandalf The Black is stirring up drama...');

    try {
      final result = await _adminService.triggerGandalfPost();

      _safePopNavigator();

      if (mounted) {
        _showSuccessDialog(
          '🔥 Drama Unleashed!',
          result['message'] ?? 'Gandalf The Black has posted!',
        );
      }
    } catch (e) {
      _safePopNavigator();
      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  void _showTriggerWeeklyChartsDialog() {
    int weeksAhead = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.cyan),
              SizedBox(width: 8),
              Text(
                'Trigger Weekly Charts Update',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will regenerate weekly leaderboard snapshots for multiple weeks.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Number of weeks to generate:',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: () {
                      if (weeksAhead > 1) {
                        setState(() => weeksAhead--);
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan),
                    ),
                    child: Text(
                      '$weeksAhead',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      if (weeksAhead < 10) {
                        setState(() => weeksAhead++);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Will generate snapshots for weeks ${DateTime.now().year}W${((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + DateTime(DateTime.now().year, 1, 1).weekday) / 7).ceil()} to ${DateTime.now().year}W${((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + DateTime(DateTime.now().year, 1, 1).weekday) / 7).ceil() + weeksAhead - 1}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                _triggerWeeklyChartsUpdate(weeksAhead);
              },
              child: const Text('Generate Snapshots'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerWeeklyChartsUpdate(int weeksAhead) async {
    _showLoadingDialog(
        'Generating weekly chart snapshots for $weeksAhead week(s)...');

    try {
      final result = await _adminService.triggerWeeklyLeaderboardUpdate(
        weeksAhead: weeksAhead,
      );

      _safePopNavigator();

      if (mounted) {
        final results = result['results'] as List<dynamic>? ?? [];
        final weeksList =
            results.map((r) => '${r['weekId']} (${r['date']})').join('\n');

        _showSuccessDialog(
          'Weekly Charts Updated!',
          'Successfully generated ${results.length} weekly snapshots:\n\n'
              '$weeksList\n\n'
              'Check the Weekly Charts tab to see updated data.',
        );
        await _loadData();
      }
    } catch (e) {
      _safePopNavigator();
      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  void _showGenerateContractsDialog() {
    int contractCount = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.work, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Generate Side Hustle Contracts',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will create new side hustle job contracts for players to claim.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Number of contracts to generate:',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: () {
                      if (contractCount > 5) {
                        setState(() => contractCount -= 5);
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Text(
                      '$contractCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      if (contractCount < 50) {
                        setState(() => contractCount += 5);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Contracts will be added to the shared pool for all players',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _generateContracts(contractCount);
              },
              child: const Text('Generate Contracts'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateContracts(int count) async {
    _showLoadingDialog('💼 Generating $count side hustle contracts...');

    try {
      final result = await _adminService.triggerSideHustleGeneration();

      _safePopNavigator();

      if (mounted) {
        final generated = result['generated'] ?? 0;
        final poolSize = result['currentPool'] ?? 0;
        _showSuccessDialog(
          '✅ Contracts Generated!',
          'Successfully generated $generated new contracts.\n'
              'Current pool size: $poolSize contracts\n\n'
              'Players can now see and claim these contracts in the Side Hustle screen.',
        );
      }
    } catch (e) {
      _safePopNavigator();
      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  void _navigateToMigrationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SideHustleMigrationScreen(),
      ),
    );
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

                        // Close loading dialog safely FIRST
                        if (mounted) {
                          try {
                            Navigator.of(context, rootNavigator: true).pop();
                          } catch (e) {
                            // Context invalid, dialog already closed
                          }
                        }

                        // Small delay to ensure loading dialog closes
                        await Future.delayed(const Duration(milliseconds: 100));

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
                        // Close loading dialog safely
                        if (mounted) {
                          try {
                            Navigator.of(context, rootNavigator: true).pop();
                          } catch (navError) {
                            // Context invalid, dialog already closed
                          }
                        }

                        // Small delay to ensure loading dialog closes
                        await Future.delayed(const Duration(milliseconds: 100));

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
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Sent!',
                    'Notification sent to all players.',
                  );
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
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
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Success!',
                    'Admin access granted to user.',
                  );
                  await _loadData();
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
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
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Data Reset',
                    'All player data has been deleted.',
                  );
                  await _loadData();
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
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

      _safePopNavigator(); // Close loading

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

                            // Close loading dialog safely FIRST
                            if (mounted) {
                              try {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              } catch (e) {
                                // Context invalid, dialog already closed
                              }
                            }

                            // Small delay to ensure loading dialog closes
                            await Future.delayed(
                                const Duration(milliseconds: 100));

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
                            // Close loading dialog safely
                            if (mounted) {
                              try {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              } catch (navError) {
                                // Context invalid, dialog already closed
                              }
                            }

                            // Small delay to ensure loading dialog closes
                            await Future.delayed(
                                const Duration(milliseconds: 100));

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
      _safePopNavigator(); // Close loading dialog

      if (mounted) {
        _showError('Error Loading Players', e.toString());
      }
    }
  }

  // ============================================================================
  // NEW ADMIN FEATURES
  // ============================================================================

  void _showPlayerManagementDialog() async {
    _showLoadingDialog('Loading players...');

    try {
      final players = await _adminService.getAllPlayers();

      _safePopNavigator(); // Close loading

      if (players.isEmpty) {
        _showError('No Players', 'No players found in the database');
        return;
      }

      String? selectedPlayerId;
      final searchController = TextEditingController();
      List<Map<String, dynamic>> filteredPlayers = players;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Row(
                children: [
                  Icon(Icons.search, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Player Management',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 600,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredPlayers = players
                              .where((p) => p['name']
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Player list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selectedPlayerId == player['id']
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedPlayerId == player['id']
                                    ? Colors.blue
                                    : Colors.white10,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  player['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                player['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '⭐${player['fame']} | \$${player['money']} | 👥${player['fanbase']} | 🎵${player['songCount']}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white60,
                                ),
                                color: const Color(0xFF1A1A1A),
                                onSelected: (value) async {
                                  Navigator.pop(context); // Close main dialog

                                  switch (value) {
                                    case 'edit':
                                      _showEditPlayerDialog(player);
                                      break;
                                    case 'reset':
                                      _showResetPlayerDialog(player);
                                      break;
                                    case 'delete':
                                      _showDeletePlayerDialog(player);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit Stats',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reset',
                                    child: Row(
                                      children: [
                                        Icon(Icons.refresh,
                                            color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text(
                                          'Reset Progress',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Account',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  selectedPlayerId = player['id'];
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      _safePopNavigator(); // Close loading dialog

      if (mounted) {
        _showError('Error Loading Players', e.toString());
      }
    }
  }

  void _showEditPlayerDialog(Map<String, dynamic> player) {
    final moneyController =
        TextEditingController(text: player['money'].toString());
    final fameController =
        TextEditingController(text: player['fame'].toString());
    final fanbaseController =
        TextEditingController(text: player['fanbase'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Edit ${player['name']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '💰 Money',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fameController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '⭐ Fame',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fanbaseController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '👥 Fanbase',
                labelStyle: TextStyle(color: Colors.white60),
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
              _showLoadingDialog('Updating player...');

              try {
                // Use secure server-side validation for admin stat updates
                final callable =
                    FirebaseFunctions.instanceFor(region: 'us-central1')
                        .httpsCallable('secureStatUpdate');

                final result = await callable.call({
                  'playerId': player['id'], // Specify which player to update
                  'updates': {
                    'currentMoney': int.parse(moneyController.text),
                    'fame': int.parse(fameController.text),
                    'fanbase': int.parse(fanbaseController.text),
                  },
                  'action': 'admin_stat_update',
                  'context': {
                    'timestamp': DateTime.now().toIso8601String(),
                    'reason': 'Admin manual adjustment',
                  },
                });

                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  if (result.data['success'] == true) {
                    _showSuccessDialog(
                      'Updated!',
                      'Player stats updated successfully.',
                    );
                    await _loadData();
                  } else {
                    _showError(
                      'Error',
                      'Failed to update player: ${result.data['error'] ?? 'Unknown error'}',
                    );
                  }
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetPlayerDialog(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Player?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Reset ${player['name']}\'s progress to starting values?\n\n'
          'This will:\n'
          '• Clear all songs\n'
          '• Reset money to \$5,000\n'
          '• Reset fame and fanbase to 0\n'
          '• Keep their account active',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Resetting player...');

              try {
                await _firestore
                    .collection('players')
                    .doc(player['id'])
                    .update(sanitizeForFirestore({
                      'currentMoney': 5000,
                      'fame': 0,
                      'level': 0,
                      'loyalFanbase': 0,
                      'songs': [],
                    }));

                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Reset Complete!',
                    '${player['name']} has been reset to starting values.',
                  );
                  await _loadData();
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset Progress'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlayerDialog(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Player?', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Permanently delete ${player['name']}\'s account?\n\n'
          'This action CANNOT be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Deleting player...');

              try {
                await _firestore
                    .collection('players')
                    .doc(player['id'])
                    .delete();

                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Deleted!',
                    '${player['name']}\'s account has been permanently deleted.',
                  );
                  await _loadData();
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );
  }

  void _showGameTimeAdjustDialog() async {
    _showLoadingDialog('Loading game time...');

    try {
      // Get the correct game settings document
      final gameSettingsDoc =
          await _firestore.collection('gameSettings').doc('globalTime').get();

      _safePopNavigator();

      if (!gameSettingsDoc.exists) {
        _showError('Error',
            'Game time not initialized. Please restart the app to initialize.');
        return;
      }

      final data = gameSettingsDoc.data()!;
      final realWorldStartDate =
          (data['realWorldStartDate'] as Timestamp).toDate();
      final gameWorldStartDate =
          (data['gameWorldStartDate'] as Timestamp).toDate();

      // Calculate current game date based on hours elapsed
      final now = DateTime.now();
      final realHoursElapsed = now.difference(realWorldStartDate).inHours;
      final gameDaysElapsed = realHoursElapsed; // 1 hour = 1 day

      final calculatedDate =
          gameWorldStartDate.add(Duration(days: gameDaysElapsed));
      final currentDate = DateTime(
        calculatedDate.year,
        calculatedDate.month,
        calculatedDate.day,
      );

      int daysToAdjust = 0;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Adjust Game Time',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Game Date:',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          daysToAdjust -= 7;
                        });
                      },
                      icon: const Icon(Icons.fast_rewind),
                      color: Colors.red,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          daysToAdjust--;
                        });
                      },
                      icon: const Icon(Icons.remove),
                      color: Colors.orange,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${daysToAdjust > 0 ? '+' : ''}$daysToAdjust days',
                        style: TextStyle(
                          color: daysToAdjust == 0
                              ? Colors.white
                              : (daysToAdjust > 0 ? Colors.green : Colors.red),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          daysToAdjust++;
                        });
                      },
                      icon: const Icon(Icons.add),
                      color: Colors.green,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          daysToAdjust += 7;
                        });
                      },
                      icon: const Icon(Icons.fast_forward),
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'New Date: ${DateTime(currentDate.year, currentDate.month, currentDate.day + daysToAdjust).toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: daysToAdjust == 0
                    ? null
                    : () async {
                        Navigator.pop(context);
                        _showLoadingDialog('Adjusting game time...');

                        try {
                          // Adjust the realWorldStartDate to simulate time travel
                          // Moving days BACKWARD in real time = moving FORWARD in game time
                          // Example: If we want to add 7 game days, we subtract 7 hours from realWorldStartDate
                          final adjustedRealWorldStart =
                              realWorldStartDate.subtract(
                            Duration(
                                hours: daysToAdjust), // 1 hour per game day
                          );

                          await _firestore
                              .collection('gameSettings')
                              .doc('globalTime')
                              .update(sanitizeForFirestore({
                                'realWorldStartDate':
                                    Timestamp.fromDate(adjustedRealWorldStart),
                                'lastUpdated': FieldValue.serverTimestamp(),
                              }));

                          final newDate = DateTime(
                            currentDate.year,
                            currentDate.month,
                            currentDate.day + daysToAdjust,
                          );

                          _safePopNavigator(); // Close loading dialog

                          if (mounted) {
                            _showSuccessDialog(
                              'Time Adjusted!',
                              'Game date changed by $daysToAdjust days.\n\n'
                                  'New date: ${newDate.toString().split(' ')[0]}\n\n'
                                  'Note: All players will see this change immediately.',
                            );
                            await _loadData();
                          }
                        } catch (e) {
                          _safePopNavigator(); // Close loading dialog

                          if (mounted) {
                            _showError('Error', e.toString());
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _safePopNavigator(); // Close loading dialog safely

      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  void _showAnalyticsDashboard() async {
    _showLoadingDialog('Loading analytics...');

    try {
      final playersSnapshot = await _firestore.collection('players').get();

      int totalMoney = 0;
      int totalStreams = 0;
      int activePlayers = 0;
      Map<String, int> genreDistribution = {};

      for (var playerDoc in playersSnapshot.docs) {
        final data = playerDoc.data();
        totalMoney += (data['currentMoney'] as int? ?? 0);

        // Count active players (played in last 7 days)
        if (data['lastActivityDate'] != null) {
          final lastActivity = (data['lastActivityDate'] as Timestamp).toDate();
          if (DateTime.now().difference(lastActivity).inDays < 7) {
            activePlayers++;
          }
        }

        // Count songs and streams from player data
        final songs = data['songs'] as List<dynamic>? ?? [];
        for (var song in songs) {
          totalStreams += (song['streams'] as int? ?? 0);

          final genre = song['genre'] as String? ?? 'Unknown';
          genreDistribution[genre] = (genreDistribution[genre] ?? 0) + 1;
        }
      }

      _safePopNavigator(); // Close loading

      // Sort genres by popularity
      final sortedGenres = genreDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Analytics Dashboard',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnalyticCard(
                    'Total Players',
                    playersSnapshot.size.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildAnalyticCard(
                    'Active (7 days)',
                    activePlayers.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildAnalyticCard(
                    'Total Songs',
                    _gameStats?['totalSongs'].toString() ?? '0',
                    Icons.music_note,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildAnalyticCard(
                    'Total Streams',
                    totalStreams.toString(),
                    Icons.play_arrow,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildAnalyticCard(
                    'Total Money',
                    '\$$totalMoney',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Genre Distribution (Top 5):',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedGenres.take(5).map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${entry.value} songs',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _safePopNavigator(); // Close loading dialog

      if (mounted) {
        _showError('Error', e.toString());
      }
    }
  }

  Widget _buildAnalyticCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncPlayerStreams() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sync Player Streams?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will update all players\' stream counts from their actual song data.\n\n'
          'This may take a few moments for many players.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Syncing player streams...');

              try {
                final callable = FirebaseFunctions.instance
                    .httpsCallable('syncAllPlayerStreams');
                final result = await callable.call();

                _safePopNavigator(); // Close loading dialog

                if (mounted && result.data['success']) {
                  _showSuccessDialog(
                    'Sync Complete!',
                    'Updated ${result.data['updated']} players\n'
                        'Errors: ${result.data['errors']}\n'
                        'Total: ${result.data['total']}',
                  );
                }
              } catch (e) {
                _safePopNavigator();
                if (mounted) {
                  _showError('Sync Failed', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearOldNotifications() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.amber),
            SizedBox(width: 8),
            Text('Clear Old Notifications?',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Delete all notifications older than 30 days?\n\n'
          'This will free up database space.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Clearing old notifications...');

              try {
                final thirtyDaysAgo =
                    DateTime.now().subtract(const Duration(days: 30));
                final notificationsSnapshot = await _firestore
                    .collection('notifications')
                    .where('timestamp',
                        isLessThan: Timestamp.fromDate(thirtyDaysAgo))
                    .get();

                final batch = _firestore.batch();
                for (var doc in notificationsSnapshot.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();

                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Cleared!',
                    'Deleted ${notificationsSnapshot.size} old notifications.',
                  );
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Clear Old Notifications'),
          ),
        ],
      ),
    );
  }

  Future<void> _testErrorSystem() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Test Error System?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will create a test error in the error log.\n\n'
          'Useful for testing error monitoring and alerting.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Creating test error...');

              try {
                await _firestore.collection('error_logs').add({
                  'error': 'TEST ERROR - This is a test error for monitoring',
                  'playerId': _auth.currentUser?.uid ?? 'admin',
                  'timestamp': FieldValue.serverTimestamp(),
                  'severity': 'test',
                  'context': 'Admin Dashboard Test',
                });

                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showSuccessDialog(
                    'Test Error Created!',
                    'Check the error logs section to verify.',
                  );
                  await _loadData();
                }
              } catch (e) {
                _safePopNavigator(); // Close loading dialog
                if (mounted) {
                  _showError('Error', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
            child: const Text('Create Test Error'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 📊 STREAM ANALYTICS & DEBUGGING METHODS
  // ════════════════════════════════════════════════════════════════

  Future<void> _showStreamDebugDialog() async {
    final TextEditingController songIdController = TextEditingController();
    final TextEditingController playerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF00D9FF)),
            const SizedBox(width: 8),
            const Text(
              'Debug Song Streams',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter song and player details to see real-time stream calculations:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: playerIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Player ID (User ID)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'Enter player/user ID',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: songIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Song ID',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'Enter song ID to analyze',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final playerId = playerIdController.text.trim();
              final songId = songIdController.text.trim();

              if (playerId.isEmpty || songId.isEmpty) {
                _showError('Error', 'Please enter both Player ID and Song ID');
                return;
              }

              Navigator.pop(context);
              await _analyzeStreamCalculation(playerId, songId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeStreamCalculation(String playerId, String songId) async {
    _showLoadingDialog('Analyzing stream calculation...');

    try {
      // Fetch player data
      final playerDoc =
          await _firestore.collection('players').doc(playerId).get();

      if (!playerDoc.exists) {
        _safePopNavigator();
        _showError('Error', 'Player not found');
        return;
      }

      final playerData = playerDoc.data()!;
      final songs = List<Map<String, dynamic>>.from(playerData['songs'] ?? []);

      // Find the specific song
      final song = songs.firstWhere(
        (s) => s['id'] == songId,
        orElse: () => {},
      );

      if (song.isEmpty) {
        _safePopNavigator();
        _showError('Error', 'Song not found for this player');
        return;
      }

      _safePopNavigator();

      // Show detailed analysis dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Icon(Icons.analytics, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stream Analysis: ${song['title'] ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisSection('📌 SONG DETAILS', [
                  'Song ID: $songId',
                  'Title: ${song['title'] ?? 'N/A'}',
                  'Artist: ${playerData['artistName'] ?? 'Unknown'}',
                  'Genre: ${song['genre'] ?? 'N/A'}',
                  'State: ${song['state'] ?? 'N/A'}',
                  'Release Date: ${song['releaseDate'] ?? 'Not released'}',
                ]),
                const SizedBox(height: 16),
                _buildAnalysisSection('📊 CURRENT STREAM DATA', [
                  'Total Streams: ${song['streams'] ?? 0}',
                  'Last Day Streams: ${song['lastDayStreams'] ?? 0}',
                  'Last 7 Days: ${song['last7DaysStreams'] ?? 0}',
                  'Peak Daily: ${song['peakDailyStreams'] ?? 0}',
                  'Days on Chart: ${song['daysOnChart'] ?? 0}',
                ]),
                const SizedBox(height: 16),
                _buildAnalysisSection('🎯 QUALITY MULTIPLIERS', [
                  'Quality Score: ${song['quality'] ?? 0}/100',
                  'Creativity: ${song['creativity'] ?? 0}',
                  'Songwriting Skill: ${playerData['songwritingSkill'] ?? 0}',
                  'Lyrics Skill: ${playerData['lyricsSkill'] ?? 0}',
                  'Composition Skill: ${playerData['compositionSkill'] ?? 0}',
                ]),
                const SizedBox(height: 16),
                _buildAnalysisSection('🌟 FAME & PLATFORM', [
                  'Artist Fame: ${playerData['fame'] ?? 0}',
                  'Fanbase: ${playerData['fanbase'] ?? 0}',
                  'Platform: ${song['platform'] ?? 'N/A'}',
                  'Studio: ${song['studioUsed'] ?? 'N/A'}',
                ]),
                const SizedBox(height: 16),
                _buildAnalysisSection('🔧 STREAM CALCULATION FORMULA', [
                  'Base Streams = Fame × Quality × Platform Multiplier',
                  'Daily Growth = Previous Streams × (1 + Quality/100)',
                  'Decay Factor = Streams × 0.85 (if no new release)',
                  '',
                  '📌 Estimated Next Day Streams:',
                  _calculateEstimatedStreams(song, playerData),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'TIPS TO INCREASE STREAMS:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Increase artist fame (EchoX posts, releases)\n'
                        '• Improve song quality (better studio, skills)\n'
                        '• Unlock better platforms (Tunify, Maple)\n'
                        '• Release consistently to maintain momentum\n'
                        '• Build fanbase through engagement',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF00D9FF))),
            ),
          ],
        ),
      );
    } catch (e) {
      _safePopNavigator();
      _showError('Error', 'Failed to analyze streams: $e');
    }
  }

  Widget _buildAnalysisSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            )),
      ],
    );
  }

  String _calculateEstimatedStreams(
      Map<String, dynamic> song, Map<String, dynamic> playerData) {
    try {
      final currentStreams = (song['lastDayStreams'] ?? 0) as int;
      final quality = (song['quality'] ?? 50) as int;
      final fame = (playerData['fame'] ?? 0) as int;

      // Simplified estimation
      final growthFactor = 1 + (quality / 200.0);
      final fameFactor = 1 + (fame / 1000.0);
      final estimated = (currentStreams * growthFactor * fameFactor).round();

      return '~${estimated.toString()} streams (${((growthFactor - 1) * 100).toStringAsFixed(1)}% growth)';
    } catch (e) {
      return 'Unable to calculate (missing data)';
    }
  }

  Future<void> _showTopStreamingSongs() async {
    _showLoadingDialog('Loading top streaming songs...');

    try {
      final playersSnapshot = await _firestore.collection('players').get();

      List<Map<String, dynamic>> allSongs = [];

      for (var doc in playersSnapshot.docs) {
        final playerData = doc.data();
        final songs =
            List<Map<String, dynamic>>.from(playerData['songs'] ?? []);

        for (var song in songs) {
          if (song['state'] == 'released') {
            allSongs.add({
              'title': song['title'] ?? 'Unknown',
              'artistName': playerData['artistName'] ?? 'Unknown',
              'playerId': doc.id,
              'songId': song['id'],
              'streams': song['streams'] ?? 0,
              'lastDayStreams': song['lastDayStreams'] ?? 0,
              'genre': song['genre'] ?? 'Unknown',
              'quality': song['quality'] ?? 0,
            });
          }
        }
      }

      // Sort by last day streams
      allSongs.sort((a, b) =>
          (b['lastDayStreams'] as int).compareTo(a['lastDayStreams'] as int));

      final topSongs = allSongs.take(20).toList();

      _safePopNavigator();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF00D9FF)),
              SizedBox(width: 8),
              Text(
                'Top 20 Streaming Songs',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: topSongs.length,
              itemBuilder: (context, index) {
                final song = topSongs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index < 3
                          ? const Color(0xFF00D9FF).withOpacity(0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? const Color(0xFF00D9FF).withOpacity(0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index < 3
                                  ? const Color(0xFF00D9FF)
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${song['artistName']} • ${song['genre']}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${song['lastDayStreams']}',
                            style: const TextStyle(
                              color: Color(0xFF00D9FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'daily streams',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.search,
                            color: Colors.white60, size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                          _analyzeStreamCalculation(
                              song['playerId'], song['songId']);
                        },
                        tooltip: 'Analyze',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF00D9FF))),
            ),
          ],
        ),
      );
    } catch (e) {
      _safePopNavigator();
      _showError('Error', 'Failed to load top songs: $e');
    }
  }

  Future<void> _showPlayerStreamsDebug() async {
    final TextEditingController playerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF00D9FF)),
            SizedBox(width: 8),
            Text(
              'Debug Player Streams',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a player ID to view all their songs and stream data:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: playerIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Player ID',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'Enter player/user ID',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final playerId = playerIdController.text.trim();

              if (playerId.isEmpty) {
                _showError('Error', 'Please enter a Player ID');
                return;
              }

              Navigator.pop(context);
              await _showPlayerSongsAnalysis(playerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlayerSongsAnalysis(String playerId) async {
    _showLoadingDialog('Loading player songs...');

    try {
      final playerDoc =
          await _firestore.collection('players').doc(playerId).get();

      if (!playerDoc.exists) {
        _safePopNavigator();
        _showError('Error', 'Player not found');
        return;
      }

      final playerData = playerDoc.data()!;
      final songs = List<Map<String, dynamic>>.from(playerData['songs'] ?? []);

      // Sort by streams
      songs.sort((a, b) => (b['streams'] ?? 0).compareTo(a['streams'] ?? 0));

      final totalStreams = songs.fold<int>(
          0, (sum, song) => sum + ((song['streams'] ?? 0) as int));
      final releasedSongs = songs.where((s) => s['state'] == 'released').length;

      _safePopNavigator();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${playerData['artistName'] ?? 'Unknown Artist'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPlayerStat('Songs', songs.length.toString()),
                          _buildPlayerStat(
                              'Released', releasedSongs.toString()),
                          _buildPlayerStat(
                              'Total Streams', totalStreams.toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPlayerStat(
                              'Fame', playerData['fame']?.toString() ?? '0'),
                          _buildPlayerStat('Fanbase',
                              playerData['fanbase']?.toString() ?? '0'),
                          _buildPlayerStat('Money',
                              '\$${playerData['currentMoney']?.toString() ?? '0'}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SONGS:',
                  style: TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isReleased = song['state'] == 'released';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isReleased
                                ? Colors.green.withOpacity(0.3)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${song['genre'] ?? 'Unknown'} • Q${song['quality'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isReleased) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${song['streams'] ?? 0} streams (${song['lastDayStreams'] ?? 0}/day)',
                                      style: const TextStyle(
                                        color: Color(0xFF00D9FF),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isReleased)
                              IconButton(
                                icon: const Icon(Icons.analytics,
                                    color: Colors.white60, size: 20),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _analyzeStreamCalculation(
                                      playerId, song['id']);
                                },
                                tooltip: 'Analyze',
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF00D9FF))),
            ),
          ],
        ),
      );
    } catch (e) {
      _safePopNavigator();
      _showError('Error', 'Failed to load player data: $e');
    }
  }

  Widget _buildPlayerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CHAT MODERATION
  // ════════════════════════════════════════════════════════════════

  void _showChatModeration() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat, color: Color(0xFF00D9FF), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Chat Moderation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF00D9FF),
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: Color(0xFF00D9FF),
                        tabs: [
                          Tab(text: 'Reported'),
                          Tab(text: 'Stats'),
                          Tab(text: 'Banned Users'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildReportedMessagesTab(),
                            _buildChatStatsTab(),
                            _buildBannedUsersTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportedMessagesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getReportedMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'No reported messages',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final reportedAt = report['reportedAt'] as Timestamp?;
            final timeAgo = reportedAt != null
                ? _formatTimeAgo(reportedAt.toDate())
                : 'Unknown';

            return Card(
              color: const Color(0xFF16213E),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reported by ${report['reportedByName']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Text(
                      'Reported user: ${report['reportedUserName']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (report['messageContent'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report['messageContent'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    if (report['reason'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${report['reason']}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _banUserFromChat(
                              report['reportedUser'],
                              report['reportedUserName']),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text('Ban User'),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () =>
                              _deleteConversation(report['conversationId']),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete Chat'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatStatsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminService.getChatStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Total Conversations',
              '${stats['totalConversations'] ?? 0}',
              Icons.chat_bubble,
              const Color(0xFF00D9FF),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Blocked Conversations',
              '${stats['blockedConversations'] ?? 0}',
              Icons.block,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Messages',
              '${stats['totalMessages'] ?? 0}',
              Icons.message,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Reported Messages',
              '${stats['reportedMessages'] ?? 0}',
              Icons.flag,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Banned Users',
              '${stats['bannedUsers'] ?? 0}',
              Icons.person_off,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannedUsersTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('players')
          .where('chatBanned', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final bannedUsers = snapshot.data?.docs ?? [];

        if (bannedUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'No banned users',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bannedUsers.length,
          itemBuilder: (context, index) {
            final user = bannedUsers[index].data() as Map<String, dynamic>;
            final userId = bannedUsers[index].id;
            final bannedAt = user['chatBannedAt'] as Timestamp?;
            final timeAgo = bannedAt != null
                ? _formatTimeAgo(bannedAt.toDate())
                : 'Unknown';

            return Card(
              color: const Color(0xFF16213E),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.person_off, color: Colors.red),
                title: Text(
                  user['displayName'] ?? 'Unknown User',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banned $timeAgo',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    if (user['chatBanReason'] != null)
                      Text(
                        'Reason: ${user['chatBanReason']}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
                trailing: TextButton(
                  onPressed: () =>
                      _unbanUserFromChat(userId, user['displayName']),
                  child: const Text('Unban',
                      style: TextStyle(color: Color(0xFF00D9FF))),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _banUserFromChat(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Ban User from Chat',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Ban $userName from using chat?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Banning user...');

              final success = await _adminService.banUserFromChat(userId);

              _safePopNavigator();
              if (success) {
                _showSuccessDialog(
                    'Banned', '$userName has been banned from chat');
              } else {
                _showError('Error', 'Failed to ban user');
              }
            },
            child: const Text('Ban', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _unbanUserFromChat(String userId, String? userName) async {
    _showLoadingDialog('Unbanning user...');

    final success = await _adminService.unbanUserFromChat(userId);

    _safePopNavigator();
    if (success) {
      _showSuccessDialog(
          'Unbanned', '${userName ?? 'User'} can now use chat again');
    } else {
      _showError('Error', 'Failed to unban user');
    }
  }

  void _deleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Conversation',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Permanently delete this conversation and all messages?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Deleting conversation...');

              final success =
                  await _adminService.deleteConversation(conversationId);

              _safePopNavigator();
              if (success) {
                _showSuccessDialog('Deleted', 'Conversation has been deleted');
              } else {
                _showError('Error', 'Failed to delete conversation');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // COMMENT MODERATION
  // ════════════════════════════════════════════════════════════════

  void _showCommentModeration() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.comment, color: Color(0xFF7C3AED), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Comment Moderation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildReportedCommentsTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportedCommentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final comments = snapshot.data?.docs ?? [];

        if (comments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'No reported comments',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final doc = comments[index];
            final data = doc.data() as Map<String, dynamic>;
            final commentId = doc.id;
            final content = data['content'] ?? '';
            final authorName = data['authorName'] ?? 'Unknown';
            final reportCount = data['reportCount'] ?? 0;
            final contextType = data['contextType'] ?? '';
            final contextId = data['contextId'] ?? '';
            final isHidden = data['isHidden'] ?? false;
            final createdAt = data['createdAt'] as Timestamp?;
            final timeAgo = createdAt != null
                ? _formatTimeAgo(createdAt.toDate())
                : 'Unknown';

            return Card(
              color:
                  isHidden ? const Color(0xFF2E1616) : const Color(0xFF16213E),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHidden ? Icons.visibility_off : Icons.flag,
                          color: isHidden ? Colors.grey : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$reportCount ${reportCount == 1 ? 'report' : 'reports'}',
                            style: TextStyle(
                              color: isHidden ? Colors.grey : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isHidden)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HIDDEN',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Text(
                      'By: $authorName',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: isHidden ? Colors.grey : Colors.white,
                          decoration:
                              isHidden ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'On $contextType',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isHidden) ...[
                          TextButton.icon(
                            onPressed: () => _hideComment(commentId, content),
                            icon: const Icon(Icons.visibility_off, size: 18),
                            label: const Text('Hide'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.orange),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          TextButton.icon(
                            onPressed: () => _unhideComment(commentId),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('Unhide'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.green),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton.icon(
                          onPressed: () =>
                              _deleteComment(commentId, contextType, contextId),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _hideComment(String commentId, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('Hide Comment', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will hide the comment from public view but keep it in the database.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Hiding comment...');

              try {
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(commentId)
                    .update({'isHidden': true});

                _safePopNavigator();
                _showSuccessDialog(
                    'Hidden', 'Comment has been hidden from public view');
              } catch (e) {
                _safePopNavigator();
                _showError('Error', 'Failed to hide comment: $e');
              }
            },
            child: const Text('Hide', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _unhideComment(String commentId) async {
    _showLoadingDialog('Unhiding comment...');

    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .update({'isHidden': false});

      _safePopNavigator();
      _showSuccessDialog('Unhidden', 'Comment is now visible again');
    } catch (e) {
      _safePopNavigator();
      _showError('Error', 'Failed to unhide comment: $e');
    }
  }

  void _deleteComment(String commentId, String contextType, String contextId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('Delete Comment', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Permanently delete this comment? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Deleting comment...');

              try {
                // Delete the comment
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(commentId)
                    .delete();

                // Update comment count on parent (video or post)
                if (contextType == 'video') {
                  await FirebaseFirestore.instance
                      .collection('nexttube_videos')
                      .doc(contextId)
                      .update({'comments': FieldValue.increment(-1)});
                } else if (contextType == 'post') {
                  await FirebaseFirestore.instance
                      .collection('echox_posts')
                      .doc(contextId)
                      .update({'comments': FieldValue.increment(-1)});
                }

                _safePopNavigator();
                _showSuccessDialog(
                    'Deleted', 'Comment has been permanently deleted');
              } catch (e) {
                _safePopNavigator();
                _showError('Error', 'Failed to delete comment: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════

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
