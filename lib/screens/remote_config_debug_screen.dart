import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';
import 'package:intl/intl.dart';

class RemoteConfigDebugScreen extends StatefulWidget {
  const RemoteConfigDebugScreen({super.key});

  @override
  State<RemoteConfigDebugScreen> createState() =>
      _RemoteConfigDebugScreenState();
}

class _RemoteConfigDebugScreenState extends State<RemoteConfigDebugScreen> {
  final _remoteConfig = RemoteConfigService();
  bool _isRefreshing = false;

  Future<void> _refreshConfig() async {
    setState(() => _isRefreshing = true);
    await _remoteConfig.refresh();
    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Remote Config refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('🔧 Remote Config'),
        backgroundColor: const Color(0xFF21262D),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshConfig,
            tooltip: 'Refresh Config',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            '🔐 App Control',
            [
              _buildConfigItem(
                  'Maintenance Mode', _remoteConfig.isMaintenanceMode),
              _buildConfigItem('Force Update', _remoteConfig.forceUpdate),
              _buildConfigItem(
                  'Min Required Version', _remoteConfig.minRequiredVersion),
              _buildConfigItem(
                  'Recommended Version', _remoteConfig.recommendedVersion),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '🎮 Feature Flags',
            [
              _buildConfigItem(
                  'Collaboration', _remoteConfig.isCollaborationEnabled),
              _buildConfigItem('Producers', _remoteConfig.isProducersEnabled),
              _buildConfigItem('Labels', _remoteConfig.isLabelsEnabled),
              _buildConfigItem('Concerts', _remoteConfig.isConcertsEnabled),
              _buildConfigItem(
                  'Merchandise', _remoteConfig.isMerchandiseEnabled),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '💰 Economy',
            [
              _buildConfigItem(
                  'Min Song Cost', '\$${_remoteConfig.minSongCost}'),
              _buildConfigItem(
                  'Max Song Cost', '\$${_remoteConfig.maxSongCost}'),
              _buildConfigItem(
                  'Starting Money', '\$${_remoteConfig.dailyStartingMoney}'),
              _buildConfigItem('Daily Energy', _remoteConfig.dailyEnergy),
              _buildConfigItem('Energy per Song', _remoteConfig.energyPerSong),
              _buildConfigItem('Base Streaming Rate',
                  '\$${_remoteConfig.baseStreamingRate}/stream'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '⭐ Fame & Growth',
            [
              _buildConfigItem(
                  'Fame Unlock Threshold', _remoteConfig.fameUnlockThreshold),
              _buildConfigItem(
                  'Base Daily Streams', _remoteConfig.baseDailyStreams),
              _buildConfigItem('Viral Threshold', _remoteConfig.viralThreshold),
              _buildConfigItem('Chart Position Multiplier',
                  '${_remoteConfig.chartPositionMultiplier}x'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '📱 Platforms',
            [
              _buildConfigItem('Tunify Royalty',
                  '\$${_remoteConfig.tunifyRoyaltyRate}/stream'),
              _buildConfigItem('Maple Royalty',
                  '\$${_remoteConfig.mapleRoyaltyRate}/stream'),
              _buildConfigItem(
                  'Tunify Unlock Fame', _remoteConfig.tunifyUnlockFame),
              _buildConfigItem(
                  'Maple Unlock Fame', _remoteConfig.mapleUnlockFame),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '🤖 NPC Difficulty',
            [
              _buildConfigItem('Competition Multiplier',
                  '${_remoteConfig.npcCompetitionMultiplier}x'),
              _buildConfigItem(
                  'Max Daily Releases', _remoteConfig.npcMaxDailyReleases),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            '🐛 Debug',
            [
              _buildConfigItem('Debug Mode', _remoteConfig.enableDebugMode),
              _buildConfigItem('Analytics', _remoteConfig.enableAnalytics),
              _buildConfigItem('Beta Features', _remoteConfig.showBetaFeatures),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Color(0xFF30363D), height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, dynamic value) {
    Color valueColor = Colors.white70;
    String displayValue = value.toString();

    // Color code based on value type
    if (value is bool) {
      valueColor = value ? Colors.green : Colors.red;
      displayValue = value ? '✅ Enabled' : '❌ Disabled';
    } else if (value is int || value is double) {
      valueColor = const Color(0xFF00D9FF);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'About Remote Config',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Remote Config allows instant updates without app rebuilds. '
            'Changes take effect within 1 hour or after manual refresh.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                'Auto-refresh: Every 1 hour',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.cloud_download, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                'Last fetch: ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
