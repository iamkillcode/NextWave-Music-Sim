import 'package:flutter/material.dart';
import '../models/nexttube_video.dart';

class NextTubeVideoDetailScreen extends StatelessWidget {
  final NextTubeVideo video;
  const NextTubeVideoDetailScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21262D),
        title: const Text('Video Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(8),
                  image: video.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(video.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: video.thumbnailUrl == null
                    ? const Icon(Icons.image, color: Colors.white38, size: 48)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(video.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${video.ownerName} • ${_typeLabel(video.type)}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _chip('${_viewsLabel(video.totalViews)}'),
                _chip(video.isMonetized ? 'Monetized' : 'Not monetized'),
              ],
            ),
            const SizedBox(height: 12),
            if (video.description != null && video.description!.isNotEmpty)
              Text(video.description!,
                  style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Chip(
        label: Text(label),
        backgroundColor: const Color(0xFF30363D),
        labelStyle: const TextStyle(color: Colors.white70),
      );

  static String _typeLabel(NextTubeVideoType t) {
    switch (t) {
      case NextTubeVideoType.official:
        return 'Official';
      case NextTubeVideoType.lyrics:
        return 'Lyrics';
      case NextTubeVideoType.live:
        return 'Live';
    }
  }

  static String _viewsLabel(int views) {
    if (views >= 1000000)
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K views';
    return '$views views';
  }
}
