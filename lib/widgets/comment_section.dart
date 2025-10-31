import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../theme/app_theme.dart';

/// Reusable comment section widget for videos, posts, etc.
class CommentSection extends StatefulWidget {
  final String contextType; // 'video', 'post', etc.
  final String contextId;
  final String contextTitle; // For display

  const CommentSection({
    super.key,
    required this.contextType,
    required this.contextId,
    required this.contextTitle,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.comment, color: AppTheme.neonGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              StreamBuilder<List<Comment>>(
                stream: _commentService.streamComments(
                  contextType: widget.contextType,
                  contextId: widget.contextId,
                ),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Text(
                    '($count)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Comment input
        _buildCommentInput(),

        const Divider(color: Colors.white24, height: 1),

        // Comments list
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: _commentService.streamComments(
              contextType: widget.contextType,
              contextId: widget.contextId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonGreen),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading comments',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
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
                        'No comments yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment!',
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentTile(comments[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToUserName != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    color: AppTheme.neonGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Replying to $_replyingToUserName',
                    style: const TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.white54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _replyingToUserName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToUserName != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  maxLength: 500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _postComment,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final currentUserId = _commentService.currentUserId;
    final isLiked = currentUserId != null && comment.isLikedBy(currentUserId);
    final isAuthor = currentUserId != null && comment.isAuthor(currentUserId);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.neonPurple.withOpacity(0.2),
                backgroundImage: comment.authorAvatar != null
                    ? NetworkImage(comment.authorAvatar!)
                    : null,
                child: comment.authorAvatar == null
                    ? const Icon(Icons.person, color: AppTheme.neonPurple)
                    : null,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.getFormattedTime(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: () => _commentService.toggleLike(comment.id),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: isLiked ? Colors.red : Colors.white54,
                              ),
                              if (comment.likeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likeCount}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reply button
                        InkWell(
                          onTap: () => _startReply(comment),
                          child: Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              if (comment.replyCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${comment.replyCount})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        // More options
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 16),
                          color: Colors.white54,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              _showCommentOptions(comment, isAuthor),
                        ),
                      ],
                    ),
                    // Replies
                    if (comment.replyCount > 0) _buildRepliesSection(comment),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),
      ],
    );
  }

  Widget _buildRepliesSection(Comment parentComment) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 12),
      child: StreamBuilder<List<Comment>>(
        stream: _commentService.streamReplies(parentComment.id),
        builder: (context, snapshot) {
          final replies = snapshot.data ?? [];

          if (replies.isEmpty) return const SizedBox.shrink();

          return Column(
            children: replies.map((reply) => _buildReplyTile(reply)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildReplyTile(Comment reply) {
    final currentUserId = _commentService.currentUserId;
    final isLiked = currentUserId != null && reply.isLikedBy(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.neonPurple.withOpacity(0.2),
            backgroundImage: reply.authorAvatar != null
                ? NetworkImage(reply.authorAvatar!)
                : null,
            child: reply.authorAvatar == null
                ? const Icon(Icons.person, size: 16, color: AppTheme.neonPurple)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reply.getFormattedTime(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _commentService.toggleLike(reply.id),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isLiked ? Colors.red : Colors.white54,
                      ),
                      if (reply.likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${reply.likeCount}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.authorName;
    });
    _focusNode.requestFocus();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final comment = await _commentService.postComment(
      contextType: widget.contextType,
      contextId: widget.contextId,
      content: content,
      parentCommentId: _replyingToCommentId,
    );

    if (comment != null) {
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_replyingToUserName != null
                ? '✅ Reply posted'
                : '✅ Comment posted'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to post comment'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCommentOptions(Comment comment, bool isAuthor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthor) ...[
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.neonGreen),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(comment);
              },
            ),
          ],
          if (!isAuthor)
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title:
                  const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _reportComment(comment);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog(Comment comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title:
            const Text('Edit Comment', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _commentService.editComment(
                comment.id,
                controller.text,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? '✅ Comment updated' : '❌ Failed to update'),
                    backgroundColor:
                        success ? AppTheme.neonGreen : AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title:
            const Text('Delete Comment', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _commentService.deleteComment(comment.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? '✅ Comment deleted' : '❌ Failed to delete'),
                    backgroundColor:
                        success ? AppTheme.neonGreen : AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportComment(Comment comment) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title:
            const Text('Report Comment', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Why are you reporting this comment?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _commentService.reportComment(
                commentId: comment.id,
                reason: controller.text.isEmpty
                    ? 'Inappropriate content'
                    : controller.text,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? '✅ Comment reported' : '❌ Failed to report'),
                    backgroundColor:
                        success ? AppTheme.neonGreen : AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
