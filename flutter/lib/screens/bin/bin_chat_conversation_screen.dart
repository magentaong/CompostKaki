import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_service.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';

class BinChatConversationScreen extends StatefulWidget {
  final String binId;
  final String?
      userId; // If null, user chats with admin. If set, admin chats with this user.

  const BinChatConversationScreen({
    super.key,
    required this.binId,
    this.userId,
  });

  @override
  State<BinChatConversationScreen> createState() =>
      _BinChatConversationScreenState();
}

class _BinChatConversationScreenState extends State<BinChatConversationScreen> {
  final ChatService _chatService = ChatService();
  final BinService _binService = BinService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _bin;
  Map<String, dynamic>? _otherUserProfile;
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  RealtimeChannel? _channel;
  bool _isOwner = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _loadBin();
    _loadMessages();
    _loadOtherUserProfile();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _isDisposing = true;
    // Cleanup controllers first (synchronous, fast)
    _messageController.dispose();
    _scrollController.dispose();
    // Unsubscribe asynchronously to avoid blocking (non-blocking)
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  Future<void> _loadBin() async {
    try {
      final bin = await _binService.getBin(widget.binId);
      final isOwner = bin['user_id'] == _binService.currentUserId;
      if (mounted) {
        setState(() {
          _bin = bin;
          _isOwner = isOwner;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadOtherUserProfile() async {
    if (widget.userId == null)
      return; // User chatting with admin, no need to load

    try {
      final profile = await _binService.getUserProfile(widget.userId!);
      if (mounted) {
        setState(() {
          _otherUserProfile = profile;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> messages;
      if (widget.userId != null) {
        // Admin chatting with specific user
        messages = await _chatService.getConversationWithUser(
            widget.binId, widget.userId!);
      } else {
        // User chatting with admin
        messages = await _chatService.getBinMessages(widget.binId);
      }

      if (mounted && !_isDisposing) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
        if (!_isDisposing) {
          await _chatService.markMessagesAsRead(widget.binId);
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

  void _subscribeToMessages() {
    try {
      _channel =
          _chatService.subscribeToBinMessages(widget.binId, (newMessage) {
        // Only show messages relevant to this conversation
        final senderId = newMessage['sender_id'] as String?;
        final receiverId = newMessage['receiver_id'] as String?;
        final currentUserId = _chatService.currentUserId;

        bool shouldShow = false;
        if (widget.userId != null) {
          // Admin conversation: show if message is between admin and this user
          shouldShow =
              (senderId == widget.userId && receiverId == currentUserId) ||
                  (senderId == currentUserId && receiverId == widget.userId);
        } else {
          // User conversation: show if message involves current user
          shouldShow = senderId == currentUserId || receiverId == currentUserId;
        }

        if (shouldShow && mounted && !_isDisposing) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      // Handle subscription error
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      String? receiverId;
      if (widget.userId != null) {
        // Admin sending to specific user
        receiverId = widget.userId;
      } else if (!_isOwner && _bin != null) {
        // User sending to admin
        receiverId = _bin!['user_id'] as String?;
      }

      await _chatService.sendBinMessage(widget.binId, message,
          receiverId: receiverId);
      if (_isDisposing) return;
      _messageController.clear();
      if (!_isDisposing) {
        await _loadMessages();
        if (!_isDisposing) {
          await _chatService.markMessagesAsRead(widget.binId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _getChatTitle() {
    if (_isDisposing) return 'Chat';
    if (widget.userId != null && _otherUserProfile != null) {
      final firstName = _otherUserProfile!['first_name'] as String? ?? 'User';
      final lastName = _otherUserProfile!['last_name'] as String? ?? '';
      return '$firstName $lastName'.trim();
    }
    final binName = _bin?['name'] as String? ?? 'Bin';
    return _isOwner ? 'Chat - $binName' : 'Chat with Admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Immediately navigate back without waiting for cleanup
            if (mounted && !_isDisposing) {
              _isDisposing = true;
              // Cancel channel immediately to prevent callbacks during navigation
              final channel = _channel;
              _channel = null;
              // Navigate immediately (synchronous but non-blocking for UI)
              if (context.canPop()) {
                context.pop();
              }
              // Cleanup channel after navigation (non-blocking)
              Future.microtask(() {
                channel?.unsubscribe();
              });
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getChatTitle()),
            if (_isOwner && widget.userId == null)
              const Text(
                'Admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 64, color: AppTheme.textGray),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style:
                                      const TextStyle(color: AppTheme.textGray),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isOwner
                                      ? 'Start a conversation!'
                                      : 'Start a conversation with the bin admin!',
                                  style: const TextStyle(
                                      color: AppTheme.textGray, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final senderId =
                                    message['sender_id'] as String?;
                                final isCurrentUser =
                                    senderId == _chatService.currentUserId;

                                final senderProfile = message['sender_profile']
                                    as Map<String, dynamic>?;
                                final senderFirstName =
                                    senderProfile?['first_name'] as String? ??
                                        'User';
                                final senderLastName =
                                    senderProfile?['last_name'] as String? ??
                                        '';
                                final senderName =
                                    '$senderFirstName $senderLastName'.trim();

                                final isAdmin = senderId == _bin?['user_id'];

                                return _MessageBubble(
                                  message: message['message'] as String? ?? '',
                                  isUser: isCurrentUser,
                                  senderName:
                                      isCurrentUser ? 'You' : senderName,
                                  isAdmin: isAdmin,
                                  timestamp: message['created_at'] as String?,
                                );
                              },
                            ),
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isOwner
                            ? 'Type a message...'
                            : 'Message the admin...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: AppTheme.primaryGreen,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String senderName;
  final bool isAdmin;
  final String? timestamp;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.senderName,
    this.isAdmin = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryGreen : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser || isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    if (isAdmin)
                      const Icon(Icons.admin_panel_settings,
                          size: 12, color: Colors.white),
                    if (isAdmin) const SizedBox(width: 4),
                    Text(
                      senderName,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white70
                            : AppTheme.textGray.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : AppTheme.textGray,
                fontSize: 14,
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTimestamp(timestamp!),
                  style: TextStyle(
                    color: isUser
                        ? Colors.white70
                        : AppTheme.textGray.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
