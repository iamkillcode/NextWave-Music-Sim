import 'package:flutter/material.dart';
import '../models/chat_conversation.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/// Main inbox screen showing all DM conversations
class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({super.key});

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'StarChat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Total unread count badge
          StreamBuilder<int>(
            stream: _chatService.streamTotalUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceDark,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Conversations list
          Expanded(
            child: StreamBuilder<List<ChatConversation>>(
              stream: _chatService.streamConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.neonGreen,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var conversations = snapshot.data ?? [];

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  conversations = conversations.where((conv) {
                    final otherName = conv
                        .getOtherParticipantName(
                            _chatService.currentUserId ?? '')
                        .toLowerCase();
                    return otherName.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.chat_bubble_outline,
                          color: Colors.white.withOpacity(0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No conversations found'
                              : 'No messages yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search'
                              : 'Start chatting with other artists!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _buildConversationTile(
                      conversation,
                      isSmallScreen,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    ChatConversation conversation,
    bool isSmallScreen,
  ) {
    final currentUserId = _chatService.currentUserId ?? '';
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final otherName = conversation.getOtherParticipantName(currentUserId);
    final otherAvatar = conversation.getOtherParticipantAvatar(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final isTyping = conversation.isOtherUserTyping(currentUserId);
    final isBlocked = conversation.isBlocked;
    final blockedByMe = conversation.blockedBy == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBlocked
            ? AppTheme.surfaceDark.withOpacity(0.5)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlocked
              ? AppTheme.errorRed.withOpacity(0.3)
              : (unreadCount > 0
                  ? AppTheme.neonGreen.withOpacity(0.3)
                  : Colors.transparent),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Stack(
          children: [
            // Avatar
            CircleAvatar(
              radius: isSmallScreen ? 24 : 28,
              backgroundColor: AppTheme.neonPurple.withOpacity(0.2),
              backgroundImage:
                  otherAvatar != null ? NetworkImage(otherAvatar) : null,
              child: otherAvatar == null
                  ? Icon(
                      Icons.person,
                      size: isSmallScreen ? 28 : 32,
                      color: AppTheme.neonPurple,
                    )
                  : null,
            ),
            // Unread badge
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.neonGreen,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherName,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: isTyping
            ? Row(
                children: [
                  Text(
                    'typing',
                    style: TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: isSmallScreen ? 13 : 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                ],
              )
            : Text(
                conversation.lastMessage ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.5),
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageTime != null)
              Text(
                _formatTime(conversation.lastMessageTime!),
                style: TextStyle(
                  color: unreadCount > 0
                      ? AppTheme.neonGreen
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.neonGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: isBlocked && !blockedByMe
            ? null // Can't open conversation if blocked by other user
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      conversationId: conversation.id,
                      otherUserId: otherUserId,
                      otherUserName: otherName,
                      otherUserAvatar: otherAvatar,
                    ),
                  ),
                );
              },
        onLongPress: () {
          _showConversationOptions(conversation, otherName);
        },
      ),
    );
  }

  void _showConversationOptions(
      ChatConversation conversation, String otherName) {
    final currentUserId = _chatService.currentUserId ?? '';
    final isBlocked = conversation.isBlocked;
    final blockedByMe = conversation.blockedBy == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (isBlocked && blockedByMe)
            ListTile(
              leading:
                  const Icon(Icons.check_circle, color: AppTheme.neonGreen),
              title: const Text('Unblock User',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Allow messages from $otherName again',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.unblockUser(conversation.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Unblocked $otherName'),
                      backgroundColor: AppTheme.neonGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          if (!isBlocked)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Delete Conversation',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Remove from your inbox',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation(conversation, otherName);
              },
            ),
          if (!isBlocked)
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorRed),
              title: const Text('Block User',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Stop receiving messages from $otherName',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.blockUser(conversation.id,
                    conversation.getOtherParticipantId(currentUserId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚫 Blocked $otherName'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDeleteConversation(
      ChatConversation conversation, String otherName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Conversation',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete conversation with $otherName? This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              await _chatService.deleteConversation(conversation.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Conversation deleted'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
