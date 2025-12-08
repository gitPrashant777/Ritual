import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';

import '../model/NotificationModel.dart';
import '../model/NotificationService.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _recentNotifications = [];
  List<NotificationModel> _earlierNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    final notifications = await _notificationService.getNotifications();

    // Sort by date (newest first)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Split into Recent (last 24 hours) and Earlier
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    setState(() {
      _recentNotifications = notifications
          .where((n) => n.createdAt.isAfter(yesterday))
          .toList();

      _earlierNotifications = notifications
          .where((n) => n.createdAt.isBefore(yesterday))
          .toList();

      _isLoading = false;
    });
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read in backend
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);

      // 2. Refresh list to update UI
      _fetchNotifications();
    }

    // 3. Optional: Navigate based on type (e.g., to Order Details)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_recentNotifications.isEmpty && _earlierNotifications.isEmpty)
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView(
          padding: const EdgeInsets.all(defaultPadding),
          children: [
            // Recent Section
            if (_recentNotifications.isNotEmpty) ...[
              Text(
                "Recent",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: defaultPadding),
              ..._recentNotifications.map((n) => _buildNotificationCard(n)),
              const SizedBox(height: defaultPadding),
            ],

            // Earlier Section
            if (_earlierNotifications.isNotEmpty) ...[
              Text(
                "Earlier",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: defaultPadding),
              ..._earlierNotifications.map((n) => _buildNotificationCard(n)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).cardColor
            : primaryColor.withOpacity(0.05), // Highlight unread
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(defaultPadding),
        onTap: () => _handleNotificationTap(notification),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 24,
              ),
            ),
            if (!notification.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _timeAgo(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple "Time Ago" helper
  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
    } else if (diff.inMinutes >= 1) {
      return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }
}