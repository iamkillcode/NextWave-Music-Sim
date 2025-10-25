import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../services/firebase_service.dart';
import '../services/cover_art_uploader.dart';

/// Screen for managing EP and Album releases
/// Players can bundle songs into EPs (3-6 songs) or Albums (7+ songs)
class ReleaseManagerScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const ReleaseManagerScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<ReleaseManagerScreen> createState() => _ReleaseManagerScreenState();
}

class _ReleaseManagerScreenState extends State<ReleaseManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _albumTitleController = TextEditingController();
  AlbumType _selectedType = AlbumType.ep;
  final List<String> _selectedSongIds = [];
  String? _uploadedCoverArtUrl; // Album/EP cover art URL
  late ArtistStats _currentStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentStats = widget.artistStats;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _albumTitleController.dispose();
    super.dispose();
  }

  Future<void> _uploadCoverArt() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate a temporary album ID if creating new album
      final albumId = const Uuid().v4();

      // Upload to Firebase Storage using the helper service
      final storageUrl = await CoverArtUploader.pickAndUploadCoverArt(
        userId: userId,
        songId: albumId, // Use album ID for album art
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (storageUrl == null) return; // User cancelled

      setState(() {
        _uploadedCoverArtUrl = storageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover art uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading cover art: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload cover art: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('💿', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Release Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF21262D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Create New'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Released'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildScheduledTab(),
          _buildReleasedTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    // Get available songs (recorded or already released)
    final availableSongs = _currentStats.songs.where((song) {
      // Can use recorded songs OR released singles
      if (song.state == SongState.recorded) return true;
      if (song.state == SongState.released && song.releaseType == 'single') {
        return true;
      }
      // Can't use unreleased songs or songs already in an album
      return false;
    }).toList();

    final recordedSongs =
        availableSongs.where((s) => s.state == SongState.recorded).toList();
    final releasedSingles = availableSongs
        .where(
            (s) => s.state == SongState.released && s.releaseType == 'single')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildTitleInput(),
          const SizedBox(height: 24),
          _buildCoverArtUploader(),
          const SizedBox(height: 24),
          _buildSongSelector(recordedSongs, releasedSingles),
          const SizedBox(height: 24),
          _buildSelectedSongs(),
          const SizedBox(height: 24),
          _buildCreateButton(),
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
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Release Types',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('💿 EP', '3-6 songs', 'Extended Play'),
          const SizedBox(height: 8),
          _buildInfoRow('💽 Album', '7+ songs', 'Full Length Album'),
          const SizedBox(height: 8),
          _buildInfoRow('🎵 Single', '1 song', 'Standalone release'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Text(
            '✅ You can use:\n• Recorded but unreleased songs\n• Already released singles\n• Songs from previous EPs\n\n❌ You cannot use:\n• Songs already in albums\n• Unreleased songs from scheduled albums',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String requirement, String description) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                requirement,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Release Type',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                AlbumType.ep,
                '💿 EP',
                '3-6 songs',
                const Color(0xFF9B59B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                AlbumType.album,
                '💽 Album',
                '7+ songs',
                const Color(0xFFE94560),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(
      AlbumType type, String title, String subtitle, Color color) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // Clear selection if switching types and count doesn't match
          final min = type == AlbumType.ep ? 3 : 7;
          final max = type == AlbumType.ep ? 6 : 999;
          if (_selectedSongIds.length < min || _selectedSongIds.length > max) {
            _selectedSongIds.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white30,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Album/EP Title',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _albumTitleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a title...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF30363D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverArtUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: Color(0xFF9B59B6), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Cover Art',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2128),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _uploadedCoverArtUrl != null
                  ? const Color(0xFF9B59B6)
                  : Colors.white24,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Preview or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _uploadedCoverArtUrl != null
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9B59B6).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                  image: _uploadedCoverArtUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_uploadedCoverArtUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _uploadedCoverArtUrl != null
                    ? null
                    : const Icon(
                        Icons.album,
                        color: Colors.white38,
                        size: 40,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadedCoverArtUrl != null
                          ? 'Cover Art Uploaded ✓'
                          : 'No Cover Art',
                      style: TextStyle(
                        color: _uploadedCoverArtUrl != null
                            ? const Color(0xFF9B59B6)
                            : Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _uploadedCoverArtUrl != null
                          ? 'Songs without cover art will use this'
                          : 'Optional - Upload custom album artwork',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _uploadCoverArt,
                icon: Icon(
                    _uploadedCoverArtUrl != null ? Icons.edit : Icons.upload),
                label: Text(_uploadedCoverArtUrl != null ? 'Change' : 'Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_uploadedCoverArtUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _uploadedCoverArtUrl = null;
                });
              },
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text(
                'Remove Cover Art',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSongSelector(List<Song> recorded, List<Song> released) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Songs (${_selectedSongIds.length}/${_selectedType == AlbumType.ep ? '3-6' : '7+'})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (recorded.isNotEmpty) ...[
          const Text(
            'Recorded Songs (unreleased)',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...recorded.map((song) => _buildSongCheckbox(song, Colors.blue)),
          const SizedBox(height: 16),
        ],
        if (released.isNotEmpty) ...[
          const Text(
            'Released Singles (can re-use)',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...released.map((song) => _buildSongCheckbox(song, Colors.green)),
        ],
        if (recorded.isEmpty && released.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No songs available.\nRecord some songs first!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSongCheckbox(Song song, Color accentColor) {
    final isSelected = _selectedSongIds.contains(song.id);
    final maxSongs = _selectedType == AlbumType.ep ? 6 : 999;

    // Disable if at max capacity and not selected
    final isDisabled = !isSelected && _selectedSongIds.length >= maxSongs;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedSongIds.remove(song.id);
                } else if (_selectedSongIds.length < maxSongs) {
                  _selectedSongIds.add(song.id);
                }
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.2)
              : (isDisabled
                  ? const Color(0xFF1C2128)
                  : const Color(0xFF30363D)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDisabled ? Colors.white12 : Colors.white30),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? accentColor
                  : (isDisabled ? Colors.white24 : Colors.white60),
            ),
            const SizedBox(width: 12),
            // Cover Art
            song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: song.coverArtUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            song.genreEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF30363D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        song.genreEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isDisabled ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(song.genreEmoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        song.genre,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${song.finalQuality}%',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (song.state == SongState.released)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Released',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSongs() {
    if (_selectedSongIds.isEmpty) return const SizedBox.shrink();

    final selectedSongs = _currentStats.songs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Tracklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...selectedSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedSongIds.remove(song.id);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final minSongs = _selectedType == AlbumType.ep ? 3 : 7;
    final maxSongs = _selectedType == AlbumType.ep ? 6 : 999;
    final canCreate = _albumTitleController.text.trim().isNotEmpty &&
        _selectedSongIds.length >= minSongs &&
        _selectedSongIds.length <= maxSongs;

    String statusText = '';
    if (_albumTitleController.text.trim().isEmpty) {
      statusText = 'Enter a title';
    } else if (_selectedSongIds.length < minSongs) {
      statusText = 'Select at least $minSongs songs';
    } else if (_selectedSongIds.length > maxSongs &&
        _selectedType == AlbumType.ep) {
      statusText = 'EP can only have 3-6 songs';
    } else {
      statusText = 'Ready to create!';
    }

    return Column(
      children: [
        if (!canCreate)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              statusText,
              style: const TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canCreate ? _createAlbum : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canCreate ? const Color(0xFF00D9FF) : const Color(0xFF30363D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: canCreate ? Colors.black : Colors.white38,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create ${_selectedType == AlbumType.ep ? 'EP' : 'Album'}',
                  style: TextStyle(
                    color: canCreate ? Colors.black : Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _createAlbum() {
    final newAlbum = Album(
      id: const Uuid().v4(),
      title: _albumTitleController.text.trim(),
      type: _selectedType,
      songIds: List.from(_selectedSongIds),
      state: AlbumState.planned,
      coverArtUrl: _uploadedCoverArtUrl, // Store album cover art
    );

    // Update songs to mark them as part of this album
    final updatedSongs = _currentStats.songs.map((song) {
      if (_selectedSongIds.contains(song.id)) {
        return song.copyWith(
          albumId: newAlbum.id,
          releaseType: _selectedType == AlbumType.ep ? 'ep' : 'album',
        );
      }
      return song;
    }).toList();

    // Add album to artist stats and update local state
    setState(() {
      _currentStats = _currentStats.copyWith(
        albums: [..._currentStats.albums, newAlbum],
        songs: updatedSongs,
      );
    });

    widget.onStatsUpdated(_currentStats);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(newAlbum.typeEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Created!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          '${newAlbum.typeDisplay} "${newAlbum.title}" created with ${newAlbum.songIds.length} songs.\n\nYou can now release it from the "Scheduled" tab!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear form
              setState(() {
                _albumTitleController.clear();
                _selectedSongIds.clear();
                _uploadedCoverArtUrl = null; // Clear cover art
              });
              // Switch to scheduled tab
              _tabController.animateTo(1);
            },
            child: const Text('View Scheduled'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab() {
    final scheduledAlbums = _currentStats.albums
        .where((album) =>
            album.state == AlbumState.planned ||
            album.state == AlbumState.scheduled)
        .toList();

    if (scheduledAlbums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.album, color: Colors.white24, size: 80),
            const SizedBox(height: 16),
            const Text(
              'No scheduled releases',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an EP or Album to get started',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: scheduledAlbums.length,
      itemBuilder: (context, index) {
        return _buildAlbumCard(scheduledAlbums[index]);
      },
    );
  }

  Widget _buildReleasedTab() {
    final releasedAlbums = _currentStats.albums
        .where((album) => album.state == AlbumState.released)
        .toList();

    if (releasedAlbums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, color: Colors.white24, size: 80),
            const SizedBox(height: 16),
            const Text(
              'No released albums yet',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: releasedAlbums.length,
      itemBuilder: (context, index) {
        return _buildAlbumCard(releasedAlbums[index], isReleased: true);
      },
    );
  }

  Widget _buildAlbumCard(Album album, {bool isReleased = false}) {
    final songs = _currentStats.songs
        .where((song) => album.songIds.contains(song.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReleased
              ? Colors.green.withOpacity(0.3)
              : const Color(0xFF00D9FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(album.typeEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            album.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Platform badges
                        Row(
                          children: (album.streamingPlatforms.isNotEmpty
                                  ? album.streamingPlatforms
                                  : <String>['tunify', 'maple_music'])
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(left: 6.0),
                                    child: _buildPlatformBadge(p),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                    Text(
                      '${album.typeDisplay} • ${album.songIds.length} songs',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isReleased)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent, width: 1),
                  ),
                  child: const Text(
                    'Released',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          ...songs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${index + 1}.',
                    style: const TextStyle(color: Colors.white38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (!isReleased) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmRelease(album),
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Release Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deleteAlbum(album),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    final name = platform == 'tunify'
        ? 'Tunify'
        : platform == 'maple_music'
            ? 'Maple'
            : platform;
    final color = platform == 'tunify'
        ? const Color(0xFF1DB954)
        : const Color(0xFFFF6B9D);
    final icon = platform == 'tunify' ? '🎵' : '🍁';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRelease(Album album) async {
    // Determine default platforms from album or its songs
    final albumPlatforms = Set<String>.from(album.streamingPlatforms);
    if (albumPlatforms.isEmpty) {
      // Look up songs in current stats
      for (final s in _currentStats.songs) {
        if (album.songIds.contains(s.id)) {
          albumPlatforms.addAll(s.streamingPlatforms);
        }
      }
    }
    if (albumPlatforms.isEmpty)
      albumPlatforms.addAll(['tunify', 'maple_music']);

    // Show confirmation dialog with ability to edit platforms
    final selected = Set<String>.from(albumPlatforms);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            title: const Text('Confirm Release',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This release will be available on:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: selected.contains('tunify'),
                      onChanged: (v) => setState(() => v!
                          ? selected.add('tunify')
                          : selected.remove('tunify')),
                    ),
                    const SizedBox(width: 4),
                    const Text('Tunify', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    Checkbox(
                      value: selected.contains('maple_music'),
                      onChanged: (v) => setState(() => v!
                          ? selected.add('maple_music')
                          : selected.remove('maple_music')),
                    ),
                    const SizedBox(width: 4),
                    const Text('Maple Music',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Release Now'),
              ),
            ],
          );
        });
      },
    );

    if (result == true) {
      // Call server to perform the release atomically
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🔄 Releasing...'), duration: Duration(seconds: 2)));
        final payload = await FirebaseService().releaseAlbumSecurely(
            albumId: album.id, overridePlatforms: selected.toList());

        if (payload != null && payload['success'] == true) {
          // Update local state to reflect server commit
          _releaseAlbum(album, overridePlatforms: selected.toList());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Released successfully'),
              backgroundColor: Color(0xFF32D74B)));
        } else {
          print('Server release returned unexpected payload: $payload');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('⚠️ Release incomplete, check logs'),
              backgroundColor: Colors.orange));
        }
      } catch (e) {
        print('Error releasing album on server: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('❌ Failed to release album (server error)'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _releaseAlbum(Album album, {List<String>? overridePlatforms}) {
    // Get the songs in this album
    final albumSongs = _currentStats.songs
        .where((song) => album.songIds.contains(song.id))
        .toList();

    // RULE: If a song was already released as a single with cover art, keep it
    // If a song has NO cover art, use the album's cover art
    final updatedSongs = _currentStats.songs.map((song) {
      if (album.songIds.contains(song.id)) {
        // This song is part of the album
        String? finalCoverArt = song.coverArtUrl; // Keep existing if it has one

        // If song has NO cover art AND album has cover art, use album's
        if (finalCoverArt == null && album.coverArtUrl != null) {
          finalCoverArt = album.coverArtUrl;
        }

        // CRITICAL: Only set releasedDate if song is NOT already released
        // This prevents overwriting the original release date of singles
        final DateTime releaseDate = song.state == SongState.released
            ? song.releasedDate! // Keep existing release date
            : DateTime.now(); // Set new release date

        // Ensure songs have streaming platforms for Tunify and Maple Music.
        // We merge (union) with any existing platforms so platforms aren't lost.
        final platformsSet = Set<String>.from(song.streamingPlatforms);
        if (overridePlatforms != null && overridePlatforms.isNotEmpty) {
          platformsSet.addAll(overridePlatforms);
        } else {
          platformsSet.addAll(['tunify', 'maple_music']);
        }
        final platforms = platformsSet.toList();

        return song.copyWith(
          state: SongState.released,
          releasedDate: releaseDate,
          coverArtUrl: finalCoverArt,
          streamingPlatforms: platforms,
          isAlbum: true,
          // Keep the albumId and releaseType already set
        );
      }
      return song;
    }).toList();

    // Determine album-level platforms as the union of its songs' platforms
    final albumSongIds = album.songIds.toSet();
    final albumPlatformsSet = <String>{};
    for (final s in updatedSongs) {
      if (albumSongIds.contains(s.id))
        albumPlatformsSet.addAll(s.streamingPlatforms);
    }
    if (albumPlatformsSet.isEmpty)
      albumPlatformsSet.addAll(['tunify', 'maple_music']);

    // Mark album as released and assign platforms
    final updatedAlbum = album.copyWith(
      state: AlbumState.released,
      releasedDate: DateTime.now(),
      streamingPlatforms: albumPlatformsSet.toList(),
    );

    // Update albums list
    final updatedAlbums = _currentStats.albums.map((a) {
      return a.id == album.id ? updatedAlbum : a;
    }).toList();

    // Calculate stats bonuses for album release
    final avgQuality = albumSongs.isEmpty
        ? 50
        : albumSongs.map((s) => s.finalQuality).reduce((a, b) => a + b) /
            albumSongs.length;

    final fameGain = 5 + (avgQuality ~/ 20); // 5-10 fame based on quality
    final fanbaseGain =
        100 + (fameGain * 20); // Larger fanbase boost for albums

    // Update local state and notify parent
    setState(() {
      _currentStats = _currentStats.copyWith(
        songs: updatedSongs,
        albums: updatedAlbums,
        fame: _currentStats.fame + fameGain,
        fanbase: _currentStats.fanbase + fanbaseGain,
      );
    });

    widget.onStatsUpdated(_currentStats);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(album.typeEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Released!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          '${album.typeDisplay} "${album.title}" is now live!\n\n'
          '✨ Fame +$fameGain\n'
          '👥 Fanbase +$fanbaseGain\n'
          '🎵 ${album.songIds.length} songs released\n\n'
          'Songs will earn streams and royalties daily!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to released tab
              _tabController.animateTo(2);
            },
            child: const Text('View Released'),
          ),
        ],
      ),
    );
  }

  void _deleteAlbum(Album album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Album?',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "${album.title}"?\n\nSongs will remain in your catalog and can be released individually or added to other albums.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove album reference from songs
              final updatedSongs = _currentStats.songs.map((song) {
                if (song.albumId == album.id) {
                  return song.copyWith(
                    albumId: null,
                    releaseType: 'single',
                  );
                }
                return song;
              }).toList();

              // Remove album
              final updatedAlbums =
                  _currentStats.albums.where((a) => a.id != album.id).toList();

              setState(() {
                _currentStats = _currentStats.copyWith(
                  albums: updatedAlbums,
                  songs: updatedSongs,
                );
              });

              widget.onStatsUpdated(_currentStats);

              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
