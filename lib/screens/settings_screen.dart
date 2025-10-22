import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/artist_stats.dart';
import '../services/admin_service.dart';
import 'admin_dashboard_screen.dart';
import '../utils/firestore_sanitizer.dart';
import '../utils/genres.dart';

class SettingsScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const SettingsScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminService _adminService = AdminService();

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showOnlineStatus = true;
  bool _isAdmin = false;
  String? _currentGender;
  bool _hasSetGender = false;
  String? _currentGenre;
  bool _hasResetGenre = false;

  final TextEditingController _artistNameController = TextEditingController();
  bool _isCheckingName = false;
  bool _isNameAvailable = true;
  String _nameCheckMessage = '';

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _artistNameController.text = widget.artistStats.name;
    _loadSettings();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _loadSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('players').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _soundEnabled = data['soundEnabled'] ?? true;
            _vibrationEnabled = data['vibrationEnabled'] ?? true;
            _showOnlineStatus = data['showOnlineStatus'] ?? true;
            _avatarUrl = data['avatarUrl'];
            _currentGender = data['gender'] as String?;
            _hasSetGender = data['gender'] != null;
            _currentGenre = data['primaryGenre'] as String?;
            _hasResetGenre = data['hasResetGenre'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _resetGenre(String newGenre) async {
    if (_hasResetGenre) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ You can only reset your genre once'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Reset genre mastery for the new genre
        await _firestore.collection('players').doc(userId).update(
          sanitizeForFirestore({
            'primaryGenre': newGenre,
            'hasResetGenre': true,
            'genreMastery': {newGenre: 0},
            'unlockedGenres': [newGenre],
          }),
        );

        setState(() {
          _currentGenre = newGenre;
          _hasResetGenre = true;
        });

        // Update artist stats
        final updatedStats = widget.artistStats.copyWith(
          primaryGenre: newGenre,
          genreMastery: {newGenre: 0},
          unlockedGenres: [newGenre],
        );
        widget.onStatsUpdated(updatedStats);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Primary genre reset to: $newGenre'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error resetting genre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _setGender(String? gender) async {
    if (_hasSetGender) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ You can only set your gender once'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
          final userId = _auth.currentUser?.uid;
          if (userId != null) {
            await _firestore.collection('players').doc(userId).update(
              sanitizeForFirestore({
                'gender': gender,
              }),
            );

        setState(() {
          _currentGender = gender;
          _hasSetGender = true;
        });

        final displayGender = gender == null
            ? 'Prefer not to say'
            : gender[0].toUpperCase() + gender.substring(1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Gender set to: $displayGender'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error setting gender: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to set gender: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
            await _firestore.collection('players').doc(userId).update(
              sanitizeForFirestore({
                'notificationsEnabled': _notificationsEnabled,
                'soundEnabled': _soundEnabled,
                'vibrationEnabled': _vibrationEnabled,
                'showOnlineStatus': _showOnlineStatus,
              }),
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> _checkArtistNameAvailability(String name) async {
    if (name.isEmpty || name == widget.artistStats.name) {
      setState(() {
        _isNameAvailable = true;
        _nameCheckMessage = '';
      });
      return;
    }

    setState(() {
      _isCheckingName = true;
      _nameCheckMessage = 'Checking availability...';
    });

    try {
      // Check if name already exists (correct field name: artistName)
      final querySnapshot = await _firestore
          .collection('players')
          .where('artistName', isEqualTo: name)
          .limit(1)
          .get();

      setState(() {
        _isCheckingName = false;
        _isNameAvailable = querySnapshot.docs.isEmpty;
        _nameCheckMessage = _isNameAvailable
            ? '✓ "$name" is available!'
            : '✗ "$name" is already taken';
      });
    } catch (e) {
      setState(() {
        _isCheckingName = false;
        _nameCheckMessage = 'Error checking name';
      });
    }
  }

  Future<void> _updateArtistName() async {
    final newName = _artistNameController.text.trim();

    if (newName.isEmpty) {
      _showError('Artist name cannot be empty');
      return;
    }

    if (newName == widget.artistStats.name) {
      _showError('This is already your artist name');
      return;
    }

    if (!_isNameAvailable) {
      _showError('This name is not available');
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Change Artist Name?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to change your artist name to "$newName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
            ),
            child: const Text('CHANGE NAME'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = _auth.currentUser?.uid;
        if (userId != null) {
        await _firestore.collection('players').doc(userId).update(
          sanitizeForFirestore({
            'artistName': newName,
          }),
        );

        // Update the artist stats and notify parent
        final updatedStats = widget.artistStats.copyWith(name: newName);
        widget.onStatsUpdated(updatedStats);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artist name changed to "$newName"!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update artist name: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _uploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      // Read image as bytes and convert to base64
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      setState(() {
        _avatarUrl = dataUrl;
      });

      // Save avatar URL to Firestore
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
            await _firestore.collection('players').doc(userId).update(
              sanitizeForFirestore({
                'avatarUrl': _avatarUrl,
              }),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload avatar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, including artist stats, songs, and progress will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE FOREVER'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Get password for re-authentication
      final password = await _showPasswordDialog();
      if (password == null) return;

      try {
        final user = _auth.currentUser;
        final userId = user?.uid;

        if (user != null && userId != null) {
          // Re-authenticate user (required by Firebase before account deletion)
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          await user.reauthenticateWithCredential(credential);

          // Delete user data from Firestore
          await _firestore.collection('players').doc(userId).delete();

          // Delete Firebase Auth account
          await user.delete();

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'wrong-password':
            message = '❌ Incorrect password. Account deletion cancelled.';
            break;
          case 'requires-recent-login':
            message =
                '❌ Session expired. Please log out and log back in, then try again.';
            break;
          case 'user-mismatch':
            message = '❌ Credential mismatch. Please try again.';
            break;
          case 'invalid-credential':
            message = '❌ Invalid password. Please try again.';
            break;
          default:
            message = '❌ Failed to delete account: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        print('Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to delete account: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Confirm Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For security, please enter your password to confirm account deletion:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF00D9FF),
                ),
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00D9FF),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context, null);
            },
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text;
              passwordController.dispose();
              Navigator.pop(context, password);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Logout?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildAccountCard(),
          const SizedBox(height: 24),

          // Gender Section (show if not set yet)
          if (!_hasSetGender) ...[
            _buildSectionHeader('Gender (One-Time Setting)'),
            _buildGenderCard(),
            const SizedBox(height: 24),
          ],

          // Genre Reset Section (show if not reset yet or to display current genre)
          _buildSectionHeader('Music Genre'),
          _buildGenreResetCard(),
          const SizedBox(height: 24),

          // Artist Name Section
          _buildSectionHeader('Artist Identity'),
          _buildArtistNameCard(),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationCard(),
          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader('Privacy'),
          _buildPrivacyCard(),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Account Actions'),
          _buildDangerZoneCard(),
          const SizedBox(height: 24),

          // Admin Section (only show if user is admin)
          if (_isAdmin) ...[
            _buildSectionHeader('Admin Dashboard'),
            _buildAdminAccessCard(),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00D9FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
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
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF00D9FF),
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? Text(
                            widget.artistStats.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1A1A1A),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.artistStats.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _auth.currentUser?.email ?? 'No email',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard() {
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
            children: [
              const Icon(Icons.person, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Choose Your Gender',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFFFB800), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can only set this once. Choose carefully!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gender options
          _buildGenderButton(
              'male', 'Male', Icons.male, const Color(0xFF00D9FF)),
          const SizedBox(height: 8),
          _buildGenderButton(
              'female', 'Female', Icons.female, const Color(0xFFFF6B9D)),
          const SizedBox(height: 8),
          _buildGenderButton(
              'other', 'Other', Icons.person_outline, const Color(0xFF9D4EDD)),
          const SizedBox(height: 8),
          _buildGenderButton(
              null, 'Prefer not to say', Icons.lock_outline, Colors.white60),
        ],
      ),
    );
  }

  Widget _buildGenreResetCard() {
    final genres = Genres.all;

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
            children: [
              const Icon(Icons.music_note, color: Color(0xFF9D4EDD), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Primary Genre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentGenre != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF9D4EDD)),
              ),
              child: Text(
                'Current: $_currentGenre',
                style: const TextStyle(
                  color: Color(0xFF9D4EDD),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!_hasResetGenre) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD60A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFFFD60A), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'One-Time Genre Reset Available!',
                        style: TextStyle(
                          color: Color(0xFFFFD60A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can reset your primary genre once. This will reset your genre mastery and unlocked genres.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a new genre:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map((genre) {
                return InkWell(
                  onTap: () => _showGenreResetConfirmation(genre),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: genre == _currentGenre
                          ? const Color(0xFF9D4EDD).withOpacity(0.3)
                          : const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: genre == _currentGenre
                            ? const Color(0xFF9D4EDD)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: genre == _currentGenre
                            ? const Color(0xFF9D4EDD)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: genre == _currentGenre
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have already used your one-time genre reset.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showGenreResetConfirmation(String newGenre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '⚠️ Confirm Genre Reset',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset your primary genre to $newGenre?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Reset your genre mastery to 0',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const Text(
              '• Unlock only this genre',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const Text(
              '• Cannot be undone (one-time only)',
              style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGenre(newGenre);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD),
            ),
            child: const Text('Confirm Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(
      String? gender, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => _setGender(gender),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistNameCard() {
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
          const Text(
            'Change Artist Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a unique name that represents you. Artist names must be unique across all players.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _artistNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new artist name',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isCheckingName
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: (value) {
              _checkArtistNameAvailability(value);
            },
          ),
          if (_nameCheckMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _nameCheckMessage,
                style: TextStyle(
                  color: _isNameAvailable ? Colors.green : Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isNameAvailable &&
                      _artistNameController.text.trim() !=
                          widget.artistStats.name
                  ? _updateArtistName
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'UPDATE NAME',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Push Notifications',
            'Get notified about new releases and events',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildSwitchTile(
            'Sound Effects',
            'Play sounds for actions and events',
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildSwitchTile(
            'Vibration',
            'Vibrate on important notifications',
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'SAVE SETTINGS',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Show Online Status',
            'Let other players see when you\'re online',
            _showOnlineStatus,
            (value) => setState(() => _showOnlineStatus = value),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'DELETE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF00D9FF)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF0A84FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.admin_panel_settings,
            color: Colors.black,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Admin Access',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have administrative privileges.\nAccess powerful game management tools.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard, color: Color(0xFF00D9FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'OPEN ADMIN DASHBOARD',
                    style: TextStyle(
                      color: Color(0xFF00D9FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _artistNameController.dispose();
    super.dispose();
  }
}
