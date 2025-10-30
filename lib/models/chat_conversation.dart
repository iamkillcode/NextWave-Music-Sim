import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class ChatConversation {
  final String id;
  final List<String> participants; // [userId1, userId2]
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // userId: count
  final Map<String, bool> isTyping; // userId: isTyping
  final List<ChatMessage> recentMessages; // Last 20 messages cached
  final int totalMessageCount;
  final bool isBlocked;
  final String? blockedBy; // userId who blocked

  // Denormalized participant info for quick display
  final Map<String, String> participantNames; // userId: displayName
  final Map<String, String?> participantAvatars; // userId: avatarUrl

  const ChatConversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.isTyping = const {},
    this.recentMessages = const [],
    this.totalMessageCount = 0,
    this.isBlocked = false,
    this.blockedBy,
    this.participantNames = const {},
    this.participantAvatars = const {},
  });

  ChatConversation copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? isTyping,
    List<ChatMessage>? recentMessages,
    int? totalMessageCount,
    bool? isBlocked,
    String? blockedBy,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      recentMessages: recentMessages ?? this.recentMessages,
      totalMessageCount: totalMessageCount ?? this.totalMessageCount,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBy: blockedBy ?? this.blockedBy,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'recentMessages': recentMessages.map((m) => m.toJson()).toList(),
      'totalMessageCount': totalMessageCount,
      'isBlocked': isBlocked,
      'blockedBy': blockedBy,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final recentMsgs = (json['recentMessages'] as List?)
            ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return ChatConversation(
      id: json['id'] as String? ?? '',
      participants: List<String>.from(json['participants'] as List? ?? []),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: (json['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map? ?? {}),
      isTyping: Map<String, bool>.from(json['isTyping'] as Map? ?? {}),
      recentMessages: recentMsgs,
      totalMessageCount: json['totalMessageCount'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedBy: json['blockedBy'] as String?,
      participantNames:
          Map<String, String>.from(json['participantNames'] as Map? ?? {}),
      participantAvatars: Map<String, String?>.from(
          json['participantAvatars'] as Map? ?? {}),
    );
  }

  // Helper to get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Helper to get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  // Helper to get the other participant's avatar
  String? getOtherParticipantAvatar(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantAvatars[otherId];
  }

  // Helper to get unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  // Helper to check if other user is typing
  bool isOtherUserTyping(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return isTyping[otherId] ?? false;
  }

  // Generate conversation ID from two user IDs (always sorted for consistency)
  static String generateId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
