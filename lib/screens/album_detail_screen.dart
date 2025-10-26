import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/game_time_service.dart';

/// Screen showing detailed information about a released album
/// Displays tracklist with individual song streams
class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  final List<Song> songs;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.songs,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late final GameTimeService _gameTimeService;

  @override
  void initState() {
    super.initState();
    _gameTimeService = GameTimeService();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total streams from all songs
    final totalStreams =
        widget.songs.fold<int>(0, (sum, song) => sum + song.streams);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(widget.album.title),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Header with Cover Art
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF161B22),
                    const Color(0xFF0D1117),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Album Cover Art
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF1C2128),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: widget.album.coverArtUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: widget.album.coverArtUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  widget.album.typeEmoji,
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.album.typeEmoji,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Album Title
                  Text(
                    widget.album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Album Type
                  Text(
                    widget.album.typeDisplay,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(
                        icon: Icons.music_note,
                        label: '${widget.songs.length} songs',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        icon: Icons.bar_chart,
                        label: _formatNumber(totalStreams),
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Release Date
                  if (widget.album.releasedDate != null)
                    Text(
                      'Released ${_gameTimeService.formatGameDate(widget.album.releasedDate!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Streaming Platforms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (widget.album.streamingPlatforms.isNotEmpty
                            ? widget.album.streamingPlatforms
                            : <String>['tunify', 'maple_music'])
                        .map((platform) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                platform == 'tunify' ? '🎵 Tunify' : '🍁 Maple',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            // Tracklist Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tracklist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Song List
                  ...widget.songs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final song = entry.value;
                    return _buildSongTile(index + 1, song);
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int trackNumber, Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Track Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$trackNumber',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      song.genre,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Streams
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(song.streams),
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'streams',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
