import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Mark all notifications as read when inbox opens
    _markAllAsReadOnOpen();
  }

  Future<void> _markAllAsReadOnOpen() async {
    // Mark that user has visited notification inbox
    final notificationService = context.read<NotificationService>();
    await notificationService.markNotificationInboxVisited();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await _supabaseService.client
          .from('user_notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }


  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'join_request':
        return Icons.person_add;
      case 'activity':
        return Icons.eco;
      case 'help_request':
        return Icons.help_outline;
      case 'bin_health':
        return Icons.warning;
      case 'task_completed':
        return Icons.check_circle;
      case 'task_accepted':
        return Icons.assignment_turned_in;
      case 'task_reverted':
        return Icons.undo;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'join_request':
        return AppTheme.primaryGreen;
      case 'activity':
        return Colors.green;
      case 'help_request':
        return Colors.orange;
      case 'bin_health':
        return Colors.red;
      case 'task_completed':
        return AppTheme.primaryGreen;
      case 'task_accepted':
        return Colors.blue;
      case 'task_reverted':
        return Colors.red;
      default:
        return AppTheme.textGray;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, y').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = notification['type'] as String?;
    final binId = notification['bin_id']?.toString();

    // Route by notification type to the most relevant screen.
    switch (type) {
      case 'message':
        if (binId != null && binId.isNotEmpty) {
          await context.push('/bin/$binId/chat');
          return;
        }
        break;
      case 'join_request':
      case 'activity':
      case 'bin_health':
        if (binId != null && binId.isNotEmpty) {
          await context.push('/bin/$binId');
          return;
        }
        break;
      case 'help_request':
      case 'task_completed':
      case 'task_accepted':
      case 'task_reverted':
        // Force refresh token so tasks tab reloads latest state.
        final refreshToken = DateTime.now().millisecondsSinceEpoch;
        context.go('/main?tab=tasks&refresh=$refreshToken');
        return;
    }

    // Fallback: open home if notification doesn't include enough routing data.
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Back to Home',
        ),
        // Removed "Mark all read" button since notifications are auto-marked as read on open
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading notifications',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isRead = notification['is_read'] == true;
                          final type = notification['type'] as String?;
                          final title = notification['title'] as String? ?? '';
                          final body = notification['body'] as String? ?? '';
                          final createdAt = notification['created_at'] as String? ?? '';

                          return Material(
                            key: Key(notification['id'] as String),
                            color: isRead ? null : AppTheme.primaryGreen.withOpacity(0.05),
                            child: InkWell(
                              onTap: () => _handleNotificationTap(notification),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getNotificationColor(type).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getNotificationIcon(type),
                                        color: _getNotificationColor(type),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              color: isRead
                                                  ? AppTheme.textGray
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textGray,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatTimestamp(createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.textGray,
                                      size: 20,
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

