import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';
import '../screens/maintenance_mode_screen.dart';

/// Wrapper widget that checks Remote Config before showing child
/// Handles maintenance mode, force updates, etc.
class RemoteConfigGuard extends StatefulWidget {
  final Widget child;
  final String currentVersion;

  const RemoteConfigGuard({
    super.key,
    required this.child,
    this.currentVersion = '1.0.0',
  });

  @override
  State<RemoteConfigGuard> createState() => _RemoteConfigGuardState();
}

class _RemoteConfigGuardState extends State<RemoteConfigGuard> {
  final _remoteConfig = RemoteConfigService();
  bool _hasShownUpdateDialog = false;
  bool _configError = false;

  @override
  void initState() {
    super.initState();
    _checkConfigOnStart();
  }

  Future<void> _checkConfigOnStart() async {
    // Small delay to ensure config is loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Check for force update
      if (_remoteConfig.forceUpdate &&
          !_remoteConfig.isVersionSupported(widget.currentVersion)) {
        _showForceUpdateDialog();
      }
      // Check for recommended update
      else if (!_hasShownUpdateDialog &&
          _remoteConfig.isUpdateRecommended(widget.currentVersion)) {
        _hasShownUpdateDialog = true;
        _showRecommendedUpdateDialog();
      }
    } catch (e) {
      print('Remote Config check error: $e');
      setState(() => _configError = true);
    }
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFFFF6B6B)),
            SizedBox(width: 12),
            Text(
              'Update Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version of NextWave is required to continue.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Your version: ${widget.currentVersion}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Text(
              'Required version: ${_remoteConfig.minRequiredVersion}',
              style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Open GitHub releases or app store
              // For now, just close the app
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showRecommendedUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Color(0xFF00D9FF)),
            SizedBox(width: 12),
            Text(
              'Update Available',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version of NextWave is available with improvements and bug fixes.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Your version: ${widget.currentVersion}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Text(
              'Latest version: ${_remoteConfig.recommendedVersion}',
              style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Later',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open update link
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If config error, just show the child app normally
    if (_configError) {
      return widget.child;
    }

    try {
      // Check for maintenance mode
      if (_remoteConfig.isMaintenanceMode) {
        return MaintenanceModeScreen(
          message: _remoteConfig.maintenanceMessage,
        );
      }
    } catch (e) {
      print('Maintenance mode check error: $e');
      // Fall through to show normal app
    }

    // Show normal app
    return widget.child;
  }
}
