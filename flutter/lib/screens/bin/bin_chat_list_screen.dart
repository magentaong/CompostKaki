import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';

class BinChatListScreen extends StatefulWidget {
  final String binId;
  final bool isOwner;

  const BinChatListScreen({
    super.key,
    required this.binId,
    required this.isOwner,
  });

  @override
  State<BinChatListScreen> createState() => _BinChatListScreenState();
}

class _BinChatListScreenState extends State<BinChatListScreen> {
  final ChatService _chatService = ChatService();
  final BinService _binService = BinService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    try {
      final bin = await _binService.getBin(widget.binId);
      final isOwner = bin['user_id'] == _binService.currentUserId;
      if (mounted) {
        setState(() {
          _isOwner = isOwner;
        });
        if (isOwner) {
          _loadConversations();
        } else {
          // User: Just navigate to their conversation with admin
          context.push('/bin/${widget.binId}/chat');
        }
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

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Admin: Get all unique users who have sent messages in this bin
      final conversations = await _chatService.getBinConversations(widget.binId);
      if (mounted) {
        setState(() {
          _conversations = conversations;
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

  @override
  Widget build(BuildContext context) {
    if (!_isOwner) {
      // For non-admin users, show loading while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Messages'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textGray),
                              const SizedBox(height: 16),
                              const Text(
                                'No conversations yet',
                                style: TextStyle(color: AppTheme.textGray),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Users will appear here when they send messages',
                                style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final userId = conversation['user_id'] as String;
                            final profile = conversation['profile'] as Map<String, dynamic>?;
                            final firstName = profile?['first_name'] as String? ?? 'User';
                            final lastName = profile?['last_name'] as String? ?? '';
                            final userName = '$firstName $lastName'.trim();
                            final lastMessage = conversation['last_message'] as String? ?? '';
                            final lastMessageTime = conversation['last_message_time'] as String?;
                            final unreadCount = conversation['unread_count'] as int? ?? 0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen,
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (lastMessageTime != null)
                                    Text(
                                      _formatTime(lastMessageTime),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                context.push('/bin/${widget.binId}/chat/$userId');
                              },
                            );
                          },
                        ),
                ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }
}

