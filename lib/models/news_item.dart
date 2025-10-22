import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsCategory {
  chartMovement,
  newRelease,
  milestone,
  drama,
  collaboration,
  award,
  scandal,
}

class NewsItem {
  final String id;
  final String headline;
  final String body;
  final NewsCategory category;
  final DateTime timestamp;
  final String? relatedArtistId;
  final String? relatedArtistName;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  NewsItem({
    required this.id,
    required this.headline,
    required this.body,
    required this.category,
    required this.timestamp,
    this.relatedArtistId,
    this.relatedArtistName,
    this.imageUrl,
    this.metadata,
  });

  factory NewsItem.fromFirestore(Map<String, dynamic> data, String id) {
    return NewsItem(
      id: id,
      headline: data['headline'] ?? '',
      body: data['body'] ?? '',
      category: NewsCategory.values.firstWhere(
        (e) => e.toString() == 'NewsCategory.${data['category']}',
        orElse: () => NewsCategory.drama,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedArtistId: data['relatedArtistId'],
      relatedArtistName: data['relatedArtistName'],
      imageUrl: data['imageUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'body': body,
      'category': category.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      if (relatedArtistId != null) 'relatedArtistId': relatedArtistId,
      if (relatedArtistName != null) 'relatedArtistName': relatedArtistName,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }

  String getCategoryEmoji() {
    switch (category) {
      case NewsCategory.chartMovement:
        return '📊';
      case NewsCategory.newRelease:
        return '🎵';
      case NewsCategory.milestone:
        return '🎉';
      case NewsCategory.drama:
        return '🔥';
      case NewsCategory.collaboration:
        return '🤝';
      case NewsCategory.award:
        return '🏆';
      case NewsCategory.scandal:
        return '⚠️';
    }
  }

  int getCategoryColorValue() {
    switch (category) {
      case NewsCategory.chartMovement:
        return 0xFF4CAF50;
      case NewsCategory.newRelease:
        return 0xFF2196F3;
      case NewsCategory.milestone:
        return 0xFFFF9800;
      case NewsCategory.drama:
        return 0xFFF44336;
      case NewsCategory.collaboration:
        return 0xFF9C27B0;
      case NewsCategory.award:
        return 0xFFFFD700;
      case NewsCategory.scandal:
        return 0xFFFF5722;
    }
  }

  String getCategoryName() {
    switch (category) {
      case NewsCategory.chartMovement:
        return 'Chart Movement';
      case NewsCategory.newRelease:
        return 'New Release';
      case NewsCategory.milestone:
        return 'Milestone';
      case NewsCategory.drama:
        return 'Drama';
      case NewsCategory.collaboration:
        return 'Collaboration';
      case NewsCategory.award:
        return 'Award';
      case NewsCategory.scandal:
        return 'Scandal';
    }
  }
}
