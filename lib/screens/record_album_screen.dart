import 'package:flutter/material.dart';
import '../models/artist_stats.dart';

class RecordAlbumScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const RecordAlbumScreen({
    super.key,
    required this.artistStats,
  });

  @override
  State<RecordAlbumScreen> createState() => _RecordAlbumScreenState();
}

class _RecordAlbumScreenState extends State<RecordAlbumScreen> {
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
              'Record an Album',
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.album_rounded,
                size: 100,
                color: Color(0xFF9B59B6),
              ),
              const SizedBox(height: 24),
              const Text(
                'Album Recording',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create a full album with multiple tracks, album art, and promotional content.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withOpacity(0.5),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      '🚧 Coming Soon',
                      style: TextStyle(
                        color: Color(0xFF9B59B6),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This feature is under development',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Requirements:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRequirement('• Write at least 8-12 songs'),
              _buildRequirement('• Record all tracks in a studio'),
              _buildRequirement('• Design album artwork'),
              _buildRequirement('• Plan marketing campaign'),
              _buildRequirement('• Cost: \$50,000 - \$200,000'),
              _buildRequirement('• Energy: 40 per session'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 14,
        ),
      ),
    );
  }
}
