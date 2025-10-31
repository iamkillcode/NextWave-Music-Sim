import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

/// Real-time chat screen for DM conversations
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isLoadingOlder = false;
  DateTime? _oldestMessageTime;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening conversation
    _chatService.markAsRead(widget.conversationId);

    // Listen for scroll to load older messages
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Clear typing indicator on exit
    _chatService.setTyping(widget.conversationId, false);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || _oldestMessageTime == null) return;

    setState(() => _isLoadingOlder = true);

    final olderMessages = await _chatService.loadOlderMessages(
      conversationId: widget.conversationId,
      before: _oldestMessageTime!,
      limit: 50,
    );

    if (olderMessages.isNotEmpty) {
      setState(() {
        _oldestMessageTime = olderMessages.last.timestamp;
      });
    }

    setState(() => _isLoadingOlder = false);
  }

  void _onTyping() {
    // Cancel previous timer
    _typingTimer?.cancel();

    // Set typing indicator
    _chatService.setTyping(widget.conversationId, true);

    // Clear typing indicator after 2 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.setTyping(widget.conversationId, false);
    });
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately for responsiveness
    _messageController.clear();
    _chatService.setTyping(widget.conversationId, false);

    // Send message
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      content: content,
    );

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showOptionsMenu() async {
    // Get current conversation status
    final conversation =
        await _chatService.getConversation(widget.conversationId);

    if (conversation == null || !mounted) return;

    final currentUserId = _chatService.currentUserId;
    final isBlocked = conversation.isBlocked;
    final blockedByMe = isBlocked && conversation.blockedBy == currentUserId;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blockedByMe)
            ListTile(
              leading:
                  const Icon(Icons.check_circle, color: AppTheme.neonGreen),
              title: const Text('Unblock User',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Allow messages from ${widget.otherUserName}',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmUnblock();
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorRed),
              title: const Text('Block User',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmBlock();
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag, color: Colors.orange),
            title: const Text('Report User',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to block ${widget.otherUserName}? You won\'t receive messages from them.',
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
              await _chatService.blockUser(
                  widget.conversationId, widget.otherUserId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to conversation list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚫 Blocked ${widget.otherUserName}'),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child:
                const Text('Block', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _confirmUnblock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title:
            const Text('Unblock User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Unblock ${widget.otherUserName}? You will be able to receive messages from them again.',
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
              await _chatService.unblockUser(widget.conversationId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Unblocked ${widget.otherUserName}'),
                    backgroundColor: AppTheme.neonGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Unblock',
                style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Report User', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report ${widget.otherUserName} to moderators?',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(context);

              final success = await _chatService.reportUser(
                conversationId: widget.conversationId,
                reportedUserId: widget.otherUserId,
                reportedUserName: widget.otherUserName,
                reason: reason.isEmpty ? 'Inappropriate behavior' : reason,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '✅ Report submitted to moderators'
                        : '❌ Failed to submit report'),
                    backgroundColor:
                        success ? AppTheme.neonGreen : AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceDark,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: AppTheme.errorRed),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Update oldest message time for pagination
                if (messages.isNotEmpty && _oldestMessageTime == null) {
                  _oldestMessageTime = messages.last.timestamp;
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_isLoadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: AppTheme.neonGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (_) => _onTyping(),
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    final isMe = message.isFromUser(currentUserId);
    final hasReactions = message.reactions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surfaceDark,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Text(
                      message.senderName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.neonGreen : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.getFormattedTime(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                      if (hasReactions) ...[
                        const SizedBox(width: 8),
                        _buildReactions(message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildReactions(ChatMessage message) {
    final reactionCounts = <String, int>{};
    for (final emoji in message.reactions.values) {
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Wrap(
      spacing: 4,
      children: reactionCounts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 12)),
              if (entry.value > 1) ...[
                const SizedBox(width: 2),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('👍', style: TextStyle(fontSize: 24)),
            title: const Text('Like', style: TextStyle(color: Colors.white)),
            onTap: () {
              _chatService.addReaction(
                conversationId: widget.conversationId,
                messageId: message.id,
                emoji: '👍',
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('❤️', style: TextStyle(fontSize: 24)),
            title: const Text('Love', style: TextStyle(color: Colors.white)),
            onTap: () {
              _chatService.addReaction(
                conversationId: widget.conversationId,
                messageId: message.id,
                emoji: '❤️',
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🔥', style: TextStyle(fontSize: 24)),
            title: const Text('Fire', style: TextStyle(color: Colors.white)),
            onTap: () {
              _chatService.addReaction(
                conversationId: widget.conversationId,
                messageId: message.id,
                emoji: '🔥',
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.flag, color: Colors.orange),
            title: const Text('Report', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
