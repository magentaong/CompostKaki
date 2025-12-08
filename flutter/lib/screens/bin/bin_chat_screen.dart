import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_service.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';

class BinChatScreen extends StatefulWidget {
  final String binId;

  const BinChatScreen({super.key, required this.binId});

  @override
  State<BinChatScreen> createState() => _BinChatScreenState();
}

class _BinChatScreenState extends State<BinChatScreen> {
  final ChatService _chatService = ChatService();
  final BinService _binService = BinService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _bin;
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  RealtimeChannel? _channel;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadBin();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
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

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await _chatService.getBinMessages(widget.binId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
        // Mark messages as read when loading
        await _chatService.markMessagesAsRead(widget.binId);
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
      _channel = _chatService.subscribeToBinMessages(widget.binId, (newMessage) {
        if (mounted) {
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
      if (_scrollController.hasClients) {
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
      // Get bin owner as receiver if current user is not the owner
      String? receiverId;
      if (!_isOwner && _bin != null) {
        receiverId = _bin!['user_id'] as String?;
      }
      
      await _chatService.sendBinMessage(widget.binId, message, receiverId: receiverId);
      _messageController.clear();
      await _loadMessages(); // Reload to get the new message with profile data
      
      // Mark messages as read when sending
      await _chatService.markMessagesAsRead(widget.binId);
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

  @override
  Widget build(BuildContext context) {
    final binName = _bin?['name'] as String? ?? 'Bin';
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat - $binName'),
            if (_isOwner)
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
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
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
                                const Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textGray),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: const TextStyle(color: AppTheme.textGray),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isOwner
                                      ? 'Start a conversation with your bin members!'
                                      : 'Start a conversation with the bin admin!',
                                  style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
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
                                final senderId = message['sender_id'] as String?;
                                final isCurrentUser = senderId == _chatService.currentUserId;
                                
                                // Get sender profile
                                final senderProfile = message['sender_profile'] as Map<String, dynamic>?;
                                final senderFirstName = senderProfile?['first_name'] as String? ?? 'User';
                                final senderLastName = senderProfile?['last_name'] as String? ?? '';
                                final senderName = '$senderFirstName $senderLastName'.trim();
                                
                                // Check if sender is admin (bin owner)
                                final isAdmin = senderId == _bin?['user_id'];
                                
                                return _MessageBubble(
                                  message: message['message'] as String? ?? '',
                                  isUser: isCurrentUser,
                                  senderName: isCurrentUser ? 'You' : senderName,
                                  isAdmin: isAdmin,
                                  timestamp: message['created_at'] as String?,
                                );
                              },
                            ),
                          ),
          ),
          // Message input
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
                        hintText: _isOwner ? 'Message your bin members...' : 'Message the admin...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const Icon(Icons.admin_panel_settings, size: 12, color: Colors.white),
                    if (isAdmin) const SizedBox(width: 4),
                    Text(
                      senderName,
                      style: TextStyle(
                        color: isUser ? Colors.white70 : AppTheme.textGray.withOpacity(0.7),
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
                    color: isUser ? Colors.white70 : AppTheme.textGray.withOpacity(0.7),
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

