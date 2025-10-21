import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _personalNotifications = [];
  List<Map<String, dynamic>> _globalNotifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final personal = await _notificationService.getNotifications();
      final global = await _notificationService.getGlobalNotifications();
      final unread = await _notificationService.getUnreadCount();

      setState(() {
        _personalNotifications = personal;
        _globalNotifications = global;
        _unreadCount = unread;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.notifications, color: Color(0xFF00D9FF)),
            const SizedBox(width: 8),
            const Text(
              'Notifications',
              style: TextStyle(color: Colors.white),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await _notificationService.markAllAsRead();
                  _loadNotifications();
                  _showSnackBar('All notifications marked as read');
                  break;
                case 'clear_read':
                  await _notificationService.clearReadNotifications();
                  _loadNotifications();
                  _showSnackBar('Read notifications cleared');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Mark All as Read', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear Read', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  const Text('Personal'),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign),
                  SizedBox(width: 8),
                  Text('Announcements'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFF00D9FF),
              backgroundColor: const Color(0xFF1A1A1A),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalNotificationsList(),
                  _buildGlobalNotificationsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalNotificationsList() {
    if (_personalNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        subtitle: 'You\'re all caught up!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personalNotifications.length,
      itemBuilder: (context, index) {
        final notification = _personalNotifications[index];
        return _buildNotificationCard(notification, isPersonal: true);
      },
    );
  }

  Widget _buildGlobalNotificationsList() {
    if (_globalNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.campaign,
        title: 'No Announcements',
        subtitle: 'Check back later for game updates!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _globalNotifications.length,
      itemBuilder: (context, index) {
        final notification = _globalNotifications[index];
        return _buildNotificationCard(notification, isPersonal: false);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification,
      {required bool isPersonal}) {
    final type = notification['type'] ?? 'info';
    final isRead = notification['read'] ?? false;
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final timestamp = notification['timestamp'] ?? notification['createdAt'];

    // Determine color and icon based on type
    Color accentColor;
    IconData icon;

    switch (type) {
      case 'admin_gift':
        accentColor = const Color(0xFFFFD700); // Gold
        icon = Icons.card_giftcard;
        break;
      case 'royalty_payment':
        accentColor = Colors.green;
        icon = Icons.attach_money;
        break;
      case 'achievement':
        accentColor = const Color(0xFF32D74B);
        icon = Icons.emoji_events;
        break;
      case 'warning':
        accentColor = const Color(0xFFFF9500); // Orange
        icon = Icons.warning;
        break;
      case 'global':
        accentColor = const Color(0xFF00D9FF);
        icon = Icons.campaign;
        break;
      default:
        accentColor = const Color(0xFF00D9FF);
        icon = Icons.notifications;
    }

    return Dismissible(
      key: Key(notification['id']),
      direction: isPersonal
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: isPersonal
          ? (direction) async {
              await _notificationService
                  .deleteNotification(notification['id']);
              _loadNotifications();
              _showSnackBar('Notification deleted');
            }
          : null,
      child: InkWell(
        onTap: isPersonal && !isRead
            ? () async {
                await _notificationService
                    .markAsRead(notification['id']);
                _loadNotifications();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? const Color(0xFF1A1A1A)
                : accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.white10 : accentColor.withOpacity(0.3),
              width: isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPersonal && !isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        color: isRead ? Colors.white54 : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, y').format(dateTime);
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
