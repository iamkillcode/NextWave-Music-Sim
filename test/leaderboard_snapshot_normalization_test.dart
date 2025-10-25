import 'package:flutter_test/flutter_test.dart';
import 'package:nextwave/services/leaderboard_snapshot_service.dart';

void main() {
  group('Snapshot normalization - songs', () {
    test('modern rankings shape is normalized', () {
      final raw = [
        {
          'position': 1,
          'songId': 's1',
          'title': 'Hit Song',
          'artist': 'The Artist',
          'artistId': 'a1',
          'streams': 12345,
          'totalStreams': 12345,
          'movement': 2,
          'lastWeekPosition': 3,
          'weeksOnChart': 4,
        }
      ];

      final normalized = normalizeSongSnapshotEntries(raw, limit: 10);

      expect(normalized, isA<List<Map<String, dynamic>>>());
      expect(normalized.length, 1);
      final item = normalized.first;
      expect(item['position'], 1);
      expect(item['songId'], 's1');
      expect(item['title'], 'Hit Song');
      expect(item['artist'], 'The Artist');
      expect(item['streams'], 12345);
      expect(item['movement'], 2);
      expect(item['lastWeekPosition'], 3);
      expect(item['weeksOnChart'], 4);
    });

    test('legacy entries shape is normalized', () {
      final raw = [
        {
          'rank': 5,
          'id': 's2',
          'songName': 'Old Song',
          'artistName': 'Old Artist',
          'weeklyStreams': 500,
          'movementValue': -1,
          'lastWeekPos': 4,
          'weeks': 2,
        }
      ];

      final normalized =
          normalizeSongSnapshotEntries(raw, limit: 10, usedField: 'entries');
      expect(normalized.length, 1);
      final item = normalized.first;
      expect(item['position'], 5);
      expect(item['songId'], 's2');
      expect(item['title'], 'Old Song');
      expect(item['artist'], 'Old Artist');
      expect(item['streams'], 500);
      expect(item['movement'], -1);
      expect(item['lastWeekPosition'], 4);
      expect(item['weeksOnChart'], 2);
    });

    test('missing optional fields are defaulted', () {
      final raw = [
        {
          // minimal legacy shape
          'id': 's3',
        }
      ];

      final normalized =
          normalizeSongSnapshotEntries(raw, limit: 10, usedField: 'entries');
      final item = normalized.first;
      expect(item['position'], isNotNull);
      expect(item['songId'], 's3');
      expect(item['title'], 'Untitled');
      expect(item['artist'], 'Unknown Artist');
      expect(item['streams'], 0);
    });
  });

  group('Snapshot normalization - artists', () {
    test('modern artist rankings are normalized', () {
      final raw = [
        {
          'position': 1,
          'artistId': 'a1',
          'artistName': 'Top Artist',
          'streams': 9999,
          'songCount': 12,
          'movement': 3,
          'lastWeekPosition': 4,
          'weeksOnChart': 10,
        }
      ];

      final normalized = normalizeArtistSnapshotEntries(raw, limit: 10);
      final item = normalized.first;
      expect(item['position'], 1);
      expect(item['artistId'], 'a1');
      expect(item['artistName'], 'Top Artist');
      expect(item['streams'], 9999);
      expect(item['songCount'], 12);
      expect(item['movement'], 3);
      expect(item['lastWeekPosition'], 4);
      expect(item['weeksOnChart'], 10);
    });

    test('legacy artist entries are normalized', () {
      final raw = [
        {
          'rank': 7,
          'artist_id': 'a2',
          'name': 'Old Artist',
          'weeklyStreams': 700,
          'releasedSongs': 3,
          'movement': -2,
          'lastWeekPos': 5,
          'weeks': 1,
        }
      ];

      final normalized =
          normalizeArtistSnapshotEntries(raw, limit: 10, usedField: 'entries');
      final item = normalized.first;
      expect(item['position'], 7);
      expect(item['artistId'], 'a2');
      expect(item['artistName'], 'Old Artist');
      expect(item['streams'], 700);
      expect(item['songCount'], 3);
      expect(item['movement'], -2);
      expect(item['lastWeekPosition'], 5);
      expect(item['weeksOnChart'], 1);
    });
  });
}
