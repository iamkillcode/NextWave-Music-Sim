import 'package:cloud_firestore/cloud_firestore.dart';

class NextTubeChannel {
  final String ownerId;
  final int subscribers;
  final bool isMonetized;
  final int rpmCents; // revenue per 1000 views in cents
  final int last28DaysViews; // rolling summary placeholder
  final DateTime updatedAt;

  const NextTubeChannel({
    required this.ownerId,
    this.subscribers = 0,
    this.isMonetized = false,
    this.rpmCents = 250,
    this.last28DaysViews = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'subscribers': subscribers,
        'isMonetized': isMonetized,
        'rpmCents': rpmCents,
        'last28DaysViews': last28DaysViews,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory NextTubeChannel.fromJson(Map<String, dynamic> json) {
    return NextTubeChannel(
      ownerId: (json['ownerId'] ?? '').toString(),
      subscribers: (json['subscribers'] ?? 0) is int
          ? json['subscribers'] as int
          : int.tryParse(json['subscribers'].toString()) ?? 0,
      isMonetized: (json['isMonetized'] ?? false) == true,
      rpmCents: (json['rpmCents'] ?? 250) is int
          ? json['rpmCents'] as int
          : int.tryParse(json['rpmCents'].toString()) ?? 250,
      last28DaysViews: (json['last28DaysViews'] ?? 0) is int
          ? json['last28DaysViews'] as int
          : int.tryParse(json['last28DaysViews'].toString()) ?? 0,
      updatedAt: (json['updatedAt'] is Timestamp)
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}
