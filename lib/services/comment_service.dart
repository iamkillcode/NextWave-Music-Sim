import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../utils/firestore_sanitizer.dart';

/// Service for managing comments on NexTube videos and EchoX posts
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Post a comment
  Future<Comment?> postComment({
    required String contextType, // 'video', 'post', 'chart', 'album'
    required String contextId,
    required String content,
    String? parentCommentId, // For replies
  }) async {
    if (currentUserId == null || content.trim().isEmpty) return null;

    // Validate content length (max 500 chars)
    if (content.length > 500) {
      throw Exception('Comment too long (max 500 characters)');
    }

    try {
      final currentUser = _auth.currentUser!;
      final commentRef = _firestore.collection('comments').doc();

      final comment = Comment(
        id: commentRef.id,
        authorId: currentUserId!,
        authorName: currentUser.displayName ?? 'Unknown User',
        authorAvatar: currentUser.photoURL,
        content: content.trim(),
        timestamp: DateTime.now(),
        contextType: contextType,
        contextId: contextId,
        parentCommentId: parentCommentId,
        isReply: parentCommentId != null,
      );

      // Batch write for atomic operation
      final batch = _firestore.batch();

      // 1. Create comment
      batch.set(commentRef, sanitizeForFirestore(comment.toJson()));

      // 2. If this is a reply, increment parent's replyCount
      if (parentCommentId != null) {
        final parentRef =
            _firestore.collection('comments').doc(parentCommentId);
        batch.update(parentRef, {
          'replyCount': FieldValue.increment(1),
        });
      }

      // 3. Update context's comment count
      batch.update(
        _getContextRef(contextType, contextId),
        {
          'commentCount': FieldValue.increment(1),
        },
      );

      await batch.commit();
      return comment;
    } catch (e) {
      print('Error posting comment: $e');
      return null;
    }
  }

  /// Get comments for a specific context (video/post)
  Stream<List<Comment>> streamComments({
    required String contextType,
    required String contextId,
    bool topLevelOnly = true, // Only get comments, not replies
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('comments')
        .where('contextType', isEqualTo: contextType)
        .where('contextId', isEqualTo: contextId)
        .where('isDeleted', isEqualTo: false)
        .where('isHidden', isEqualTo: false);

    if (topLevelOnly) {
      query = query.where('isReply', isEqualTo: false);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get replies for a specific comment
  Stream<List<Comment>> streamReplies(String parentCommentId,
      {int limit = 20}) {
    return _firestore
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .where('isDeleted', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .orderBy('timestamp',
            descending: false) // Replies in chronological order
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Toggle like on a comment
  Future<void> toggleLike(String commentId) async {
    if (currentUserId == null) return;

    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) return;

      final comment = Comment.fromJson(commentDoc.data()!);
      final isLiked = comment.isLikedBy(currentUserId!);

      final updatedLikes = Map<String, bool>.from(comment.likes);
      if (isLiked) {
        updatedLikes.remove(currentUserId);
      } else {
        updatedLikes[currentUserId!] = true;
      }

      await commentRef.update({
        'likes': updatedLikes,
        'likeCount': updatedLikes.length,
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  /// Edit a comment
  Future<bool> editComment(String commentId, String newContent) async {
    if (currentUserId == null || newContent.trim().isEmpty) return false;

    if (newContent.length > 500) {
      throw Exception('Comment too long (max 500 characters)');
    }

    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) return false;

      final comment = Comment.fromJson(commentDoc.data()!);

      // Only author can edit
      if (comment.authorId != currentUserId) {
        throw Exception('Not authorized to edit this comment');
      }

      await commentRef.update({
        'content': newContent.trim(),
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error editing comment: $e');
      return false;
    }
  }

  /// Delete a comment (soft delete)
  Future<bool> deleteComment(String commentId) async {
    if (currentUserId == null) return false;

    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) return false;

      final comment = Comment.fromJson(commentDoc.data()!);

      // Only author can delete (unless admin)
      if (comment.authorId != currentUserId) {
        throw Exception('Not authorized to delete this comment');
      }

      await commentRef.update({
        'isDeleted': true,
        'content': '[Deleted]',
      });

      // Decrement context's comment count
      await _getContextRef(comment.contextType, comment.contextId).update({
        'commentCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Report a comment
  Future<bool> reportComment({
    required String commentId,
    required String reason,
  }) async {
    if (currentUserId == null) return false;

    try {
      final currentUser = _auth.currentUser!;

      // Add to reports collection
      await _firestore.collection('comment_reports').add({
        'commentId': commentId,
        'reportedBy': currentUserId,
        'reportedByName': currentUser.displayName ?? 'Unknown',
        'reason': reason,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Update comment's report count
      await _firestore.collection('comments').doc(commentId).update({
        'isReported': true,
        'reportCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error reporting comment: $e');
      return false;
    }
  }

  /// Get comment count for a context
  Future<int> getCommentCount({
    required String contextType,
    required String contextId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('contextType', isEqualTo: contextType)
          .where('contextId', isEqualTo: contextId)
          .where('isDeleted', isEqualTo: false)
          .where('isReply', isEqualTo: false) // Only count top-level comments
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  /// Helper to get the reference to the context document
  DocumentReference _getContextRef(String contextType, String contextId) {
    switch (contextType) {
      case 'video':
        return _firestore.collection('nexttube_videos').doc(contextId);
      case 'post':
        return _firestore.collection('echox_posts').doc(contextId);
      case 'chart':
        return _firestore.collection('charts').doc(contextId);
      case 'album':
        return _firestore.collection('albums').doc(contextId);
      default:
        throw Exception('Invalid context type: $contextType');
    }
  }

  /// Pin a comment (Admin only - to be implemented)
  Future<bool> pinComment(String commentId) async {
    // TODO: Check admin status
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isPinned': true,
      });
      return true;
    } catch (e) {
      print('Error pinning comment: $e');
      return false;
    }
  }
}
