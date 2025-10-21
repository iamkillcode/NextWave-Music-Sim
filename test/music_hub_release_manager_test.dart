import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextwave/models/artist_stats.dart';
import 'package:nextwave/models/song.dart';
import 'package:nextwave/screens/music_hub_screen.dart';

void main() {
  testWidgets('Tapping Manage Releases opens Release Manager', (tester) async {
    final stats = ArtistStats(
      name: 'Test Artist',
      fame: 0,
      money: 0,
      energy: 100,
      creativity: 10,
      fanbase: 0,
      albumsSold: 0,
      songsWritten: 0,
      concertsPerformed: 0,
      songs: [
        Song(
          id: '1',
          title: 'Song 1',
          genre: 'Pop',
          quality: 55,
          createdDate: DateTime.now(),
          state: SongState.recorded,
          streams: 0,
          likes: 0,
          coverArtUrl: null,
          releasedDate: null,
          albumId: null,
          releaseType: 'single',
          streamingPlatforms: [],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: MusicHubScreen(
        artistStats: stats,
        onStatsUpdated: (s) {},
      ),
    ));

    // Ensure the Manage Releases card is present
    expect(find.text('Manage Releases'), findsOneWidget);

    // Tap the card
    await tester.tap(find.text('Manage Releases'));
    await tester.pumpAndSettle();

    // Verify Release Manager screen opened by checking title text
    expect(find.text('Release Manager'), findsOneWidget);
  });
}
