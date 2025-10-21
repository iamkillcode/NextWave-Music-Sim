import 'package:flutter_test/flutter_test.dart';
import 'package:nextwave/models/song.dart';

void main() {
  group('Song model basic getters', () {
    test('finalQuality uses recordingQuality when available', () {
      final song = Song(
        id: '1',
        title: 'Test',
        genre: 'Pop',
        quality: 40,
        createdDate: DateTime.now(),
        state: SongState.recorded,
        recordingQuality: 80,
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      expect(song.finalQuality, equals(((40 + 80) / 2).round()));
    });

    test('genreEmoji returns expected emoji for pop and unknown', () {
      final pop = Song(
        id: '1',
        title: 'Pop Song',
        genre: 'pop',
        quality: 50,
        createdDate: DateTime.now(),
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      final unknown = Song(
        id: '2',
        title: 'Other Song',
        genre: 'weirdgenre',
        quality: 50,
        createdDate: DateTime.now(),
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      expect(pop.genreEmoji, '⭐');
      expect(unknown.genreEmoji, '🎵');
    });

    test('qualityRating maps correct labels', () {
      final song = Song(
        id: 'x',
        title: 'Quality Song',
        genre: 'Pop',
        quality: 95,
        createdDate: DateTime.now(),
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      expect(song.qualityRating, equals('Legendary'));
    });

    test('estimatedStreams returns a number and increases with quality', () {
      final low = Song(
        id: 'low',
        title: 'LowQ',
        genre: 'pop',
        quality: 10,
        createdDate: DateTime.now(),
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      final high = Song(
        id: 'high',
        title: 'HighQ',
        genre: 'pop',
        quality: 90,
        createdDate: DateTime.now(),
        streams: 0,
        likes: 0,
        coverArtUrl: null,
        releasedDate: null,
        albumId: null,
        releaseType: 'single',
        streamingPlatforms: [],
      );

      expect(low.estimatedStreams, isA<int>());
      expect(high.estimatedStreams, isA<int>());
      expect(high.estimatedStreams >= low.estimatedStreams, isTrue);
    });
  });
}
