import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../widgets/song_writing_dialog.dart';

class WriteSongScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const WriteSongScreen({super.key, required this.artistStats});

  @override
  State<WriteSongScreen> createState() => _WriteSongScreenState();
}

class _WriteSongScreenState extends State<WriteSongScreen> {
  late ArtistStats artistStats;
  bool _songCreated = false;

  @override
  void initState() {
    super.initState();
    artistStats = widget.artistStats;
    // Show the song writing dialog immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSongWritingDialog();
    });
  }

  void _showSongWritingDialog() {
    SongWritingDialog.show(
      context: context,
      artistStats: artistStats,
      onSongCreated: (updatedStats) {
        // Mark that song was created
        _songCreated = true;
        // Return to previous screen with updated stats
        Navigator.of(context).pop(updatedStats);
      },
    ).then((_) {
      // Dialog was dismissed - if no song was created, go back
      if (mounted && !_songCreated) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Empty scaffold - dialog shows immediately on init
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
    );
  }
}
