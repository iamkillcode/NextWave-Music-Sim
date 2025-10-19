# Over-The-Air (OTA) Updates Implementation Guide

## Overview

OTA updates allow you to push app updates without requiring users to download from app stores. This is crucial for:
- 🐛 Quick bug fixes
- 🎨 UI/content updates
- 📊 Configuration changes
- ⚡ Feature flags

## Implementation Options

### Option 1: Shorebird (Recommended for Flutter) ⭐

**Best for:** Flutter apps, native code + Dart updates

**Why Shorebird:**
- Built specifically for Flutter
- Updates both Dart code AND native code
- No JavaScript bridge needed
- 5GB free bandwidth/month
- Staging environments
- Rollback support

#### Setup Steps

1. **Install Shorebird CLI:**
```powershell
# Windows
iwr https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1 -useb | iex
```

2. **Initialize in Project:**
```bash
cd c:\Users\Manuel\Documents\GitHub\NextWave\nextwave
shorebird init
```

3. **Add to pubspec.yaml:**
```yaml
dependencies:
  shorebird_code_push: ^1.1.0
```

4. **Configure in main.dart:**
```dart
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Shorebird
  final shorebirdCodePush = ShorebirdCodePush();
  
  // Check for updates
  final isUpdateAvailable = await shorebirdCodePush.isNewPatchAvailableForDownload();
  
  if (isUpdateAvailable) {
    // Download update in background
    await shorebirdCodePush.downloadUpdateIfAvailable();
  }
  
  runApp(const MyApp());
}
```

5. **Create Release:**
```bash
# Create initial release
shorebird release android

# Push updates (no new build needed!)
shorebird patch android
```

**Pricing:** Free tier: 5GB bandwidth/month (enough for ~5000 updates)

---

### Option 2: Firebase Remote Config + Dynamic Updates

**Best for:** Configuration changes, feature flags, content updates

#### Setup Steps

1. **Add Dependencies:**
```yaml
dependencies:
  firebase_remote_config: ^4.3.8
```

2. **Create Remote Config Service:**
```dart
// lib/services/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  
  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Set defaults
    await _remoteConfig.setDefaults({
      'force_update_version': '1.0.0',
      'maintenance_mode': false,
      'feature_collaboration_enabled': false,
      'min_song_cost': 50,
      'max_song_cost': 500,
      'daily_energy': 100,
    });
    
    await _remoteConfig.fetchAndActivate();
  }
  
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');
  bool get isCollaborationEnabled => _remoteConfig.getBool('feature_collaboration_enabled');
  int get minSongCost => _remoteConfig.getInt('min_song_cost');
  int get maxSongCost => _remoteConfig.getInt('max_song_cost');
  int get dailyEnergy => _remoteConfig.getInt('daily_energy');
  String get forceUpdateVersion => _remoteConfig.getString('force_update_version');
  
  Future<void> refresh() async {
    await _remoteConfig.fetchAndActivate();
  }
}
```

3. **Use in main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Remote Config
  await RemoteConfigService().initialize();
  
  runApp(const MyApp());
}
```

4. **Check for Updates:**
```dart
// In your main screen
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkForConfigUpdates();
  }
  
  Future<void> _checkForConfigUpdates() async {
    await RemoteConfigService().refresh();
    
    if (RemoteConfigService().isMaintenanceMode) {
      _showMaintenanceDialog();
    }
    
    if (_shouldForceUpdate()) {
      _showForceUpdateDialog();
    }
  }
  
  bool _shouldForceUpdate() {
    final currentVersion = '1.0.0'; // Get from package_info_plus
    final requiredVersion = RemoteConfigService().forceUpdateVersion;
    return _isVersionLower(currentVersion, requiredVersion);
  }
}
```

---

### Option 3: Custom Asset Updates via Firebase Storage

**Best for:** Large assets (images, audio), game data

#### Implementation

1. **Create Asset Update Service:**
```dart
// lib/services/asset_update_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class AssetUpdateService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<void> checkForAssetUpdates() async {
    try {
      // Check manifest file for available updates
      final manifestRef = _storage.ref('updates/manifest.json');
      final manifestUrl = await manifestRef.getDownloadURL();
      
      // Download and parse manifest
      final response = await http.get(Uri.parse(manifestUrl));
      final manifest = jsonDecode(response.body);
      
      // Compare versions and download if needed
      for (var asset in manifest['assets']) {
        await _downloadAssetIfNewer(asset);
      }
    } catch (e) {
      print('Asset update check failed: $e');
    }
  }
  
  Future<void> _downloadAssetIfNewer(Map<String, dynamic> asset) async {
    final localVersion = await _getLocalAssetVersion(asset['name']);
    final remoteVersion = asset['version'];
    
    if (remoteVersion > localVersion) {
      final ref = _storage.ref(asset['path']);
      final file = await _getLocalAssetFile(asset['name']);
      await ref.writeToFile(file);
      await _saveAssetVersion(asset['name'], remoteVersion);
    }
  }
}
```

---

### Option 4: GitHub Releases + In-App Update Check

**Best for:** Full app updates (requires reinstall)

#### Implementation

1. **Add Dependencies:**
```yaml
dependencies:
  package_info_plus: ^5.0.1
  url_launcher: ^6.2.4
  http: ^1.1.0
```

2. **Create Update Checker:**
```dart
// lib/services/update_checker_service.dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class UpdateCheckerService {
  static const String githubApiUrl = 
    'https://api.github.com/repos/iamkillcode/NextWave-Music-Sim/releases/latest';
  
  Future<bool> isUpdateAvailable() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name'].replaceAll('v', '');
        
        return _isVersionNewer(latestVersion, currentVersion);
      }
    } catch (e) {
      print('Update check failed: $e');
    }
    return false;
  }
  
  Future<Map<String, dynamic>> getLatestRelease() async {
    final response = await http.get(Uri.parse(githubApiUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch latest release');
  }
  
  bool _isVersionNewer(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
```

3. **Show Update Dialog:**
```dart
Future<void> _checkForAppUpdate() async {
  final updateChecker = UpdateCheckerService();
  
  if (await updateChecker.isUpdateAvailable()) {
    final release = await updateChecker.getLatestRelease();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎵 Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${release['tag_name']} is now available!'),
            const SizedBox(height: 12),
            Text('What\'s New:\n${release['body']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = release['html_url'];
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
```

---

## Recommended Hybrid Approach

Combine multiple methods for best results:

### 1. **Shorebird for Code Updates** (quick fixes, UI tweaks)
- Push updates within minutes
- No app store approval needed
- Rollback if issues occur

### 2. **Firebase Remote Config for Feature Flags** (instant toggling)
- Enable/disable features remotely
- A/B testing
- Emergency kill switches
- Configuration changes

### 3. **Firebase Storage for Assets** (large files)
- Update cover art templates
- Add new NPC avatars
- Update game data

### 4. **GitHub Releases for Major Updates** (full rebuilds)
- Breaking changes
- Native code updates
- Major features

## Implementation Priority

**Phase 1 (Immediate - Beta):**
1. ✅ Firebase Remote Config (already have Firebase)
   - Feature flags
   - Maintenance mode
   - Force update version check

**Phase 2 (After Beta Success):**
2. 🚀 Shorebird for OTA code updates
   - Quick bug fixes
   - UI improvements

**Phase 3 (Production):**
3. 📦 Asset updates via Firebase Storage
   - Dynamic content
   - Large file updates

## Security Considerations

1. **Code Signing:**
   - Shorebird automatically signs patches
   - Verify patch signatures before applying

2. **Rollback Strategy:**
   - Always keep previous version available
   - Implement version pinning for critical users

3. **Testing:**
   - Test updates on staging environment first
   - Use staged rollouts (10% → 50% → 100%)

4. **User Control:**
   - Allow users to skip optional updates
   - Require updates only for critical security fixes

## Next Steps

Want me to implement any of these? I recommend starting with:

1. **Firebase Remote Config** (30 minutes setup)
   - No additional cost
   - Immediate value for feature flags
   - Already integrated with your Firebase

2. **Shorebird Setup** (1 hour setup)
   - Test with a simple update
   - Set up staging environment
   - Configure rollback policy

Let me know which approach you'd like to start with! 🚀
