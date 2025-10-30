import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../utils/firestore_sanitizer.dart';
import 'poke_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PokeService _pokeService = PokeService();

  // Maximum messages to store in conversation.recentMessages
  static const int _maxRecentMessages = 20;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Start or get existing conversation with another user
  /// Requires mutual pokes to create new conversations
  Future<ChatConversation?> startConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
    bool checkPokes = true, // Can bypass for admin or special cases
  }) async {
    if (currentUserId == null) return null;

    // Check for mutual pokes before allowing new conversations
    if (checkPokes) {
      final haveMutualPokes = await _pokeService.haveMutualPokes(
        currentUserId!,
        otherUserId,
      );
      
      if (!haveMutualPokes) {
        // No mutual pokes - return null to indicate conversation not allowed
        return null;
      }
    }

    final conversationId =
        ChatConversation.generateId(currentUserId!, otherUserId);
    final conversationRef =
        _firestore.collection('chat_conversations').doc(conversationId);

    final doc = await conversationRef.get();

    if (doc.exists) {
      // Conversation exists, return it
      return ChatConversation.fromJson(doc.data()!);
    } else {
      // Create new conversation
      final currentUser = _auth.currentUser;
      final newConversation = ChatConversation(
        id: conversationId,
        participants: [currentUserId!, otherUserId],
        participantNames: {
          currentUserId!: currentUser?.displayName ?? 'You',
          otherUserId: otherUserName,
        },
        participantAvatars: {
          currentUserId!: currentUser?.photoURL,
          otherUserId: otherUserAvatar,
        },
        unreadCount: {
          currentUserId!: 0,
          otherUserId: 0,
        },
        isTyping: {
          currentUserId!: false,
          otherUserId: false,
        },
      );

      await conversationRef.set(sanitizeForFirestore(newConversation.toJson()));
      return newConversation;
    }
  }

  /// Send a message in a conversation
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null || content.trim().isEmpty) return null;

    try {
      final currentUser = _auth.currentUser!;
      final conversationRef =
          _firestore.collection('chat_conversations').doc(conversationId);
      final messageRef = conversationRef.collection('messagesArchive').doc();

      final message = ChatMessage(
        id: messageRef.id,
        senderId: currentUserId!,
        senderName: currentUser.displayName ?? 'Unknown',
        senderAvatar: currentUser.photoURL,
        content: content.trim(),
        timestamp: DateTime.now(),
        type: type,
        metadata: metadata,
      );

      // Get current conversation to update
      final conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) return null;

      final conversation = ChatConversation.fromJson(conversationDoc.data()!);
      final otherUserId = conversation.getOtherParticipantId(currentUserId!);

      // Update recent messages list (keep last 20)
      final updatedRecentMessages = [
        message,
        ...conversation.recentMessages,
      ].take(_maxRecentMessages).toList();

      // Batch write for efficiency (single billable operation)
      final batch = _firestore.batch();

      // 1. Save message to archive
      batch.set(messageRef, sanitizeForFirestore(message.toJson()));

      // 2. Update conversation
      batch.update(conversationRef, sanitizeForFirestore({
        'lastMessage': content.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'recentMessages': updatedRecentMessages.map((m) => m.toJson()).toList(),
        'totalMessageCount': FieldValue.increment(1),
        'unreadCount.$otherUserId': FieldValue.increment(1),
        'isTyping.$currentUserId': false, // Stop typing indicator
      }));

      await batch.commit();
      return message;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Stream messages for a conversation (real-time)
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final conversation = ChatConversation.fromJson(doc.data()!);
      return conversation.recentMessages;
    });
  }

  /// Load older messages (pagination)
  Future<List<ChatMessage>> loadOlderMessages({
    required String conversationId,
    required DateTime before,
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .collection('messagesArchive')
        .where('timestamp', isLessThan: Timestamp.fromDate(before))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromJson(doc.data()))
        .toList();
  }

  /// Get all conversations for current user
  Stream<List<ChatConversation>> streamConversations() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('chat_conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatConversation.fromJson(doc.data()))
          .where((conv) => !conv.isBlocked) // Filter out blocked conversations
          .toList();
    });
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({
      'unreadCount.$currentUserId': 0,
    });
  }

  /// Set typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({
      'isTyping.$currentUserId': isTyping,
    });
  }

  /// Add reaction to message
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    if (currentUserId == null) return;

    // Update in conversation's recent messages
    final conversationRef =
        _firestore.collection('chat_conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) return;

    final conversation = ChatConversation.fromJson(conversationDoc.data()!);
    final updatedRecentMessages = conversation.recentMessages.map((msg) {
      if (msg.id == messageId) {
        final updatedReactions = {...msg.reactions};
        updatedReactions[currentUserId!] = emoji;
        return msg.copyWith(reactions: updatedReactions);
      }
      return msg;
    }).toList();

    await conversationRef.update({
      'recentMessages': updatedRecentMessages.map((m) => m.toJson()).toList(),
    });

    // Also update in archive
    await conversationRef.collection('messagesArchive').doc(messageId).update({
      'reactions.$currentUserId': emoji,
    });
  }

  /// Block user
  Future<void> blockUser(String conversationId, String userIdToBlock) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({
      'isBlocked': true,
      'blockedBy': currentUserId,
    });
  }

  /// Unblock user
  Future<void> unblockUser(String conversationId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({
      'isBlocked': false,
      'blockedBy': null,
    });
  }

  /// Delete conversation (soft delete - just hide from current user)
  Future<void> deleteConversation(String conversationId) async {
    if (currentUserId == null) return;

    // In a real implementation, you might want to add a 'deletedBy' array
    // For now, we'll just block it
    await blockUser(conversationId, currentUserId!);
  }

  /// Get total unread count across all conversations
  Stream<int> streamTotalUnreadCount() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('chat_conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final conv = ChatConversation.fromJson(doc.data());
        if (!conv.isBlocked) {
          total += conv.getUnreadCount(currentUserId!);
        }
      }
      return total;
    });
  }

  /// Search conversations by participant name
  Future<List<ChatConversation>> searchConversations(String query) async {
    if (currentUserId == null || query.trim().isEmpty) return [];

    final snapshot = await _firestore
        .collection('chat_conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    return snapshot.docs
        .map((doc) => ChatConversation.fromJson(doc.data()))
        .where((conv) {
      final otherName =
          conv.getOtherParticipantName(currentUserId!).toLowerCase();
      return otherName.contains(query.toLowerCase());
    }).toList();
  }
}
