import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a comment on NexTube videos, EchoX posts, or chart discussions
class Comment {
  final String id;
  final String authorId;
  final String authorName; // Denormalized for performance
  final String? authorAvatar; // Denormalized for performance
  final String content;
  final DateTime timestamp;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;

  // Context - what this comment is attached to
  final String contextType; // 'video', 'post', 'chart', 'album'
  final String contextId; // ID of the video/post/chart/album

  // Engagement
  final Map<String, bool> likes; // userId -> true/false
  final int likeCount;
  final int replyCount;

  // Threading support (max 2 levels: comment -> reply)
  final String? parentCommentId; // null for top-level comments
  final bool isReply; // true if this is a reply to another comment

  // Moderation
  final bool isReported;
  final int reportCount;
  final bool isHidden; // Hidden by moderator
  final String? hiddenReason;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    required this.contextType,
    required this.contextId,
    this.likes = const {},
    this.likeCount = 0,
    this.replyCount = 0,
    this.parentCommentId,
    this.isReply = false,
    this.isReported = false,
    this.reportCount = 0,
    this.isHidden = false,
    this.hiddenReason,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'contextType': contextType,
      'contextId': contextId,
      'likes': likes,
      'likeCount': likeCount,
      'replyCount': replyCount,
      'parentCommentId': parentCommentId,
      'isReply': isReply,
      'isReported': isReported,
      'reportCount': reportCount,
      'isHidden': isHidden,
      'hiddenReason': hiddenReason,
    };
  }

  /// Create from Firestore JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Unknown',
      authorAvatar: json['authorAvatar'],
      content: json['content'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt: (json['editedAt'] as Timestamp?)?.toDate(),
      contextType: json['contextType'] ?? '',
      contextId: json['contextId'] ?? '',
      likes: Map<String, bool>.from(json['likes'] ?? {}),
      likeCount: json['likeCount'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      parentCommentId: json['parentCommentId'],
      isReply: json['isReply'] ?? false,
      isReported: json['isReported'] ?? false,
      reportCount: json['reportCount'] ?? 0,
      isHidden: json['isHidden'] ?? false,
      hiddenReason: json['hiddenReason'],
    );
  }

  /// Create a copy with updated fields
  Comment copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? timestamp,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAt,
    String? contextType,
    String? contextId,
    Map<String, bool>? likes,
    int? likeCount,
    int? replyCount,
    String? parentCommentId,
    bool? isReply,
    bool? isReported,
    int? reportCount,
    bool? isHidden,
    String? hiddenReason,
  }) {
    return Comment(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isReply: isReply ?? this.isReply,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
    );
  }

  /// Check if user liked this comment
  bool isLikedBy(String userId) {
    return likes[userId] == true;
  }

  /// Check if this comment is by the given user
  bool isAuthor(String userId) {
    return authorId == userId;
  }

  /// Get formatted time display (relative)
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Get content preview (for notifications)
  String getPreview({int maxLength = 50}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }
}
