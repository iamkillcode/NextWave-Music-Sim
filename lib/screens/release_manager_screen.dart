import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _albumTitleController.dispose();
    super.dispose();
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
    final availableSongs = widget.artistStats.songs.where((song) {
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
    final minSongs = _selectedType == AlbumType.ep ? 3 : 7;
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

    final selectedSongs = widget.artistStats.songs
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
          }).toList(),
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
    );

    // Update songs to mark them as part of this album
    final updatedSongs = widget.artistStats.songs.map((song) {
      if (_selectedSongIds.contains(song.id)) {
        return song.copyWith(
          albumId: newAlbum.id,
          releaseType: _selectedType == AlbumType.ep ? 'ep' : 'album',
        );
      }
      return song;
    }).toList();

    // Add album to artist stats
    final updatedStats = widget.artistStats.copyWith(
      albums: [...widget.artistStats.albums, newAlbum],
      songs: updatedSongs,
    );

    widget.onStatsUpdated(updatedStats);

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
    final scheduledAlbums = widget.artistStats.albums
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
    final releasedAlbums = widget.artistStats.albums
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
    final songs = widget.artistStats.songs
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
                    Text(
                      album.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
          }).toList(),
          if (!isReleased) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open release screen for this album
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Release feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
              final updatedSongs = widget.artistStats.songs.map((song) {
                if (song.albumId == album.id) {
                  return song.copyWith(
                    albumId: null,
                    releaseType: 'single',
                  );
                }
                return song;
              }).toList();

              // Remove album
              final updatedAlbums = widget.artistStats.albums
                  .where((a) => a.id != album.id)
                  .toList();

              widget.onStatsUpdated(widget.artistStats.copyWith(
                albums: updatedAlbums,
                songs: updatedSongs,
              ));

              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
