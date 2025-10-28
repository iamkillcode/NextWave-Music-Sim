import 'package:cloud_functions/cloud_functions.dart';

class CertificationsService {
  final _functions = FirebaseFunctions.instance;

  Future<List<AlbumEligibility>> listAlbumEligibility() async {
    final res = await _functions
        .httpsCallable('listAlbumCertificationEligibility')
        .call();
    final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
    final albums = ((data['albums'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from((e as Map?) ?? {}))
        .toList();
    return albums.map((m) => AlbumEligibility.fromJson(m)).toList();
  }

  Future<SubmitResult> submitAlbum(String albumId) async {
    final res = await _functions
        .httpsCallable('submitAlbumForCertification')
        .call({'albumId': albumId});
    final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
    return SubmitResult.fromJson(data);
  }

  Future<MigrationResult> runMigrationForPlayer(String playerId) async {
    final res = await _functions
        .httpsCallable('runCertificationsMigrationAdmin')
        .call({'playerId': playerId});
    final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
    return MigrationResult.fromJson(data);
  }
}

class AlbumEligibility {
  final String id;
  final String title;
  final int units;
  final String currentTier;
  final int currentLevel;
  final String nextTier;
  final int nextLevel;
  final bool eligibleNow;

  AlbumEligibility({
    required this.id,
    required this.title,
    required this.units,
    required this.currentTier,
    required this.currentLevel,
    required this.nextTier,
    required this.nextLevel,
    required this.eligibleNow,
  });

  factory AlbumEligibility.fromJson(Map<String, dynamic> json) {
    return AlbumEligibility(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      units: (json['units'] as num?)?.toInt() ?? 0,
      currentTier: json['currentTier'] as String? ?? 'none',
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 0,
      nextTier: json['nextTier'] as String? ?? 'none',
      nextLevel: (json['nextLevel'] as num?)?.toInt() ?? 0,
      eligibleNow: json['eligibleNow'] as bool? ?? false,
    );
  }
}

class SubmitResult {
  final bool awarded;
  final String? tier;
  final int? level;
  final int? units;
  final String? message;

  SubmitResult(
      {required this.awarded, this.tier, this.level, this.units, this.message});

  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    return SubmitResult(
      awarded: json['awarded'] as bool? ?? false,
      tier: json['tier'] as String?,
      level: (json['level'] as num?)?.toInt(),
      units: (json['units'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}

class MigrationResult {
  final bool migrated;
  final int changed;
  final int awarded;

  MigrationResult(
      {required this.migrated, required this.changed, required this.awarded});

  factory MigrationResult.fromJson(Map<String, dynamic> json) {
    return MigrationResult(
      migrated: json['migrated'] as bool? ?? false,
      changed: (json['changed'] as num?)?.toInt() ?? 0,
      awarded: (json['awarded'] as num?)?.toInt() ?? 0,
    );
  }
}
