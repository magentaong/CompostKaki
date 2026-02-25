import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/chat_service.dart';
import '../../services/bin_service.dart';
import '../../services/media_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_picker_widget.dart';
import '../../widgets/reply_preview_widget.dart';
import '../../widgets/media_message_widget.dart';

class BinChatConversationScreen extends StatefulWidget {
  final String binId;

  const BinChatConversationScreen({
    super.key,
    required this.binId,
  });

  @override
  State<BinChatConversationScreen> createState() =>
      _BinChatConversationScreenState();
}

class _BinChatConversationScreenState extends State<BinChatConversationScreen> {
  final ChatService _chatService = ChatService();
  final BinService _binService = BinService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _bin;
  bool _isLoading = true; // Show loading during initial load to prevent empty state flash
  bool _isInitialLoad = true;
  bool _isLoadingOlder = false; // Loading older messages
  bool _hasMoreMessages = true; // Whether there are more messages to load
  String? _error;
  bool _isSending = false;
  RealtimeChannel? _channel;
  bool _isDisposing = false;
  String? _editingMessageId;
  MediaAttachment? _selectedMedia;
  Map<String, dynamic>? _replyToMessage;
  String? _replyingToMessageId;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;

  @override
  void initState() {
    super.initState();
    _loadBin();
    _loadRecentMessages();
    _subscribeToMessages();
    _setupScrollListener();
    
    // Clear message badges when viewing chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = context.read<NotificationService>();
      notificationService.markAsRead(type: 'message', binId: widget.binId);
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      
      // In reverse ListView, scrolling to top means scrolling to maxScrollExtent
      // Load older messages when scrolling near the top (within 500px of maxScrollExtent)
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final distanceFromTop = maxScroll - currentScroll;
      
      // Load older messages when scrolling near the top
      if (distanceFromTop < 500 && 
          !_isLoadingOlder && 
          _hasMoreMessages &&
          !_isInitialLoad &&
          _messages.isNotEmpty) {
        _loadOlderMessages();
      }
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  Future<void> _loadBin() async {
    try {
      final bin = await _binService.getBin(widget.binId);
      if (mounted) {
        setState(() {
          _bin = bin;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // Load recent messages (for initial load - last 50 messages)
  Future<void> _loadRecentMessages() async {
    try {
      final messages = await _chatService.getRecentBinMessages(widget.binId, limit: 50);

      if (mounted && !_isDisposing) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _isInitialLoad = false;
          // If we got less than 50 messages, there are no more to load
          _hasMoreMessages = messages.length >= 50;
        });
        // No scrolling needed - ListView with reverse:true starts at bottom
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  // Load older messages (for pagination when scrolling up)
  Future<void> _loadOlderMessages() async {
    if (_messages.isEmpty || _isLoadingOlder || !_hasMoreMessages) return;

    setState(() {
      _isLoadingOlder = true;
    });

    try {
      // Get the oldest message timestamp
      final oldestMessage = _messages.first;
      final oldestTimestamp = DateTime.parse(oldestMessage['created_at'] as String);

      final olderMessages = await _chatService.getOlderBinMessages(
        widget.binId,
        oldestTimestamp,
        limit: 50,
      );

      if (mounted && !_isDisposing) {
        // Save current scroll position and maxScrollExtent before adding messages
        double? scrollPosition;
        double? maxScrollExtent;
        if (_scrollController.hasClients) {
          scrollPosition = _scrollController.position.pixels;
          maxScrollExtent = _scrollController.position.maxScrollExtent;
        }

        setState(() {
          // Prepend older messages to the beginning
          _messages.insertAll(0, olderMessages);
          _isLoadingOlder = false;
          _hasMoreMessages = olderMessages.length >= 50;
        });

        // Restore scroll position after adding messages
        // In reverse ListView, adding messages at index 0 (top) increases maxScrollExtent
        if (_scrollController.hasClients && scrollPosition != null && maxScrollExtent != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
              // Calculate how much the maxScrollExtent increased
              final scrollOffset = newMaxScrollExtent - maxScrollExtent!;
              
              // Adjust scroll position to maintain visual position
              // The new position should be the old position plus the offset
              final newScrollPosition = scrollPosition! + scrollOffset;
              _scrollController.jumpTo(newScrollPosition);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
        });
      }
    }
  }

  // Refresh all messages (pull-to-refresh)
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await _chatService.getBinMessages(widget.binId);

      if (mounted && !_isDisposing) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _hasMoreMessages = false; // All messages loaded
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

  void _subscribeToMessages() {
    try {
      _channel = _chatService.subscribeToBinMessages(
          widget.binId, (message) {
        if (mounted && !_isDisposing) {
          // Check if message already exists (update) or is new (insert)
          final existingIndex = _messages
              .indexWhere((m) => m['id'] == message['id']);

          if (existingIndex >= 0) {
            // Update existing message
            setState(() {
              if (message['is_deleted'] == true) {
                // Remove deleted message
                _messages.removeAt(existingIndex);
              } else {
                // Update edited message - merge with existing to preserve profile if missing
                final existingMessage = _messages[existingIndex];
                _messages[existingIndex] = {
                  ...existingMessage,
                  ...message,
                  // Preserve sender_profile if new message doesn't have it
                  'sender_profile': message['sender_profile'] ?? existingMessage['sender_profile'],
                };
              }
            });
          } else {
            // This is a new message - check if it's replacing an optimistic message
            final currentUserId = _chatService.currentUserId;
            final tempIndex = _messages.indexWhere((m) {
              final mId = m['id'].toString();
              final mSenderId = m['sender_id'] as String?;
              final mMessage = m['message'] as String? ?? '';
              final newMessage = message['message'] as String? ?? '';
              
              // Match optimistic message by:
              // 1. Temp ID prefix
              // 2. Same sender (current user)
              // 3. Same message text (or both empty if media message)
              return mId.startsWith('temp_') &&
                  mSenderId == currentUserId &&
                  (mMessage == newMessage || (mMessage.isEmpty && newMessage.isEmpty));
            });
            
            setState(() {
              if (tempIndex >= 0) {
                // Replace optimistic message with real one
                _messages[tempIndex] = message;
              } else {
                // Add new message at the end (will appear at bottom in reverse ListView)
                _messages.add(message);
              }
              
              // Ensure messages stay sorted by created_at (oldest to newest)
              _messages.sort((a, b) {
                final aTime = a['created_at'] as String?;
                final bTime = b['created_at'] as String?;
                if (aTime == null || bTime == null) return 0;
                try {
                  return DateTime.parse(aTime).compareTo(DateTime.parse(bTime));
                } catch (e) {
                  return 0;
                }
              });
            });
            
            // Fetch profile if missing (async, won't cause reload)
            if (message['sender_profile'] == null) {
              _fetchMessageProfile(message);
            }
            
            // With reverse ListView, new messages appear at bottom automatically
            // Only scroll if user is already near bottom (not reading old messages)
            // In reverse ListView, position 0 is at bottom, maxScrollExtent is at top
            if (_scrollController.hasClients) {
              final currentScroll = _scrollController.position.pixels;
              
              // Only auto-scroll if user is near bottom (within 300px of position 0)
              if (currentScroll < 300) {
                // Scroll to bottom (position 0) smoothly
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            }
          }
        }
      });
    } catch (e) {
      // Handle subscription error
    }
  }

  // Check if we should show a date separator before this message
  // Note: index is the actual index in _messages (0 = oldest, length-1 = newest)
  // In reverse ListView: ListView index 0 shows _messages[length-1] (newest, at bottom)
  //                     ListView index 1 shows _messages[length-2] (second newest, above)
  // So when showing _messages[index], we compare with _messages[index+1] (newer, appears below)
  bool _shouldShowDateSeparator(int index) {
    // Disable date separators - always return false
    return false;
  }

  // Build message widget (extracted for reuse)
  Widget _buildMessageWidget({
    required Map<String, dynamic> message,
    required String messageId,
    required String? senderId,
    required bool isCurrentUser,
    required bool canEditDelete,
    required bool isEditing,
    required bool isHighlighted,
    required String senderName,
    required bool isAdmin,
    required bool isEdited,
  }) {
    final mediaType = message['media_type'] as String?;
    final mediaUrl = message['media_url'] as String?;
    final localMediaPath = message['local_media_path'] as String?;
    final localThumbnailPath = message['local_thumbnail_path'] as String?;
    final thumbnailUrl = message['media_thumbnail_url'] as String?;
    final mediaDuration = message['media_duration'] as int?;
    final mediaFilename = message['media_filename'] as String?;
    final repliedToMessage = message['replied_to_message'] as Map<String, dynamic>?;
    final replyToMessageId = message['reply_to_message_id'] as String?;

    return Container(
      key: _messageKeys[messageId],
      decoration: isHighlighted
          ? BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: isHighlighted ? const EdgeInsets.all(4) : EdgeInsets.zero,
      child: _MessageBubble(
        message: message['message'] as String? ?? '',
        isUser: isCurrentUser,
        senderName: isCurrentUser ? 'You' : senderName,
        isAdmin: isAdmin,
        timestamp: message['created_at'] as String?,
        isEdited: isEdited,
        canEditDelete: canEditDelete,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        localMediaPath: localMediaPath,
        localThumbnailPath: localThumbnailPath,
        thumbnailUrl: thumbnailUrl,
        mediaDuration: mediaDuration,
        mediaFilename: mediaFilename,
        repliedToMessage: repliedToMessage,
        replyToMessageId: replyToMessageId,
        onEdit: () => _startEditing(messageId, message['message'] as String? ?? ''),
        onDelete: () => _deleteMessage(messageId),
        onMediaTap: mediaUrl != null && mediaType != null
            ? () => _showMediaViewer(mediaUrl, mediaType)
            : null,
        onReply: () => _setReplyTo(message),
        onReplyTap: replyToMessageId != null
            ? () => _scrollToMessage(replyToMessageId)
            : null,
      ),
    );
  }

  // Fetch profile for a message without reloading all messages
  Future<void> _fetchMessageProfile(Map<String, dynamic> message) async {
    try {
      final senderId = message['sender_id'] as String?;
      if (senderId == null) return;

      final profile = await _chatService.getUserProfile(senderId);
      if (profile != null && mounted && !_isDisposing) {
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == message['id']);
          if (index >= 0) {
            _messages[index] = {
              ..._messages[index],
              'sender_profile': profile,
            };
          }
        });
      }
    } catch (e) {
      // Silently fail - profile will be loaded on next full reload if needed
    }
  }

  void _scrollToBottom() {
    // With reverse ListView, bottom is at position 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final currentScroll = _scrollController.position.pixels;
        
        // If already near bottom (within 200px of position 0), scroll smoothly
        if (currentScroll < 200) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        } else {
          // If far from bottom, jump instantly to show new message immediately
          _scrollController.jumpTo(0);
        }
      }
    });
  }


  // Scroll to a specific message by ID (for reply navigation)
  Future<void> _scrollToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    if (key == null || !_scrollController.hasClients) return;

    // Wait for the next frame to ensure layout is complete
    await Future.delayed(const Duration(milliseconds: 100));

    final context = key.currentContext;
    if (context == null) return;

    // Highlight the message briefly
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Scroll to the message
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.3, // Show message in upper third of screen
    );

    // Remove highlight after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    // Allow sending if there's a message OR media
    if ((message.isEmpty && _selectedMedia == null) || _isSending) return;

    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

      // Create optimistic message (temporary ID, will be replaced by real one)
      // Always use UTC for timestamps to match database
      final nowUtc = DateTime.now().toUtc();
      final tempId = 'temp_${nowUtc.millisecondsSinceEpoch}';
      final optimisticMessage = <String, dynamic>{
        'id': tempId,
        'bin_id': widget.binId,
        'sender_id': currentUserId,
        'message': message,
        'is_deleted': false,
        'created_at': nowUtc.toIso8601String(),
        'updated_at': nowUtc.toIso8601String(),
      'sender_profile': {
        'id': currentUserId,
        'first_name': 'You',
        'last_name': '',
      },
    };

    // Add media data if present
    if (_selectedMedia != null) {
      // Show local media immediately while upload/realtime insert completes.
      optimisticMessage['media_type'] = _selectedMedia!.type.name;
      optimisticMessage['local_media_path'] = _selectedMedia!.file.path;
      optimisticMessage['local_thumbnail_path'] = _selectedMedia!.thumbnailPath;
    }

    // Add reply-to if present
    if (_replyingToMessageId != null) {
      optimisticMessage['reply_to_message_id'] = _replyingToMessageId;
      optimisticMessage['replied_to_message'] = _replyToMessage;
    }

    // Add optimistic message immediately to UI
    setState(() {
      _isSending = true;
      _messages.add(optimisticMessage);
    });

    // Immediately scroll to bottom to show the new message (reverse ListView: position 0 = bottom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0); // Jump instantly to bottom to show new message immediately
      }
    });

    try {
      await _chatService.sendBinMessage(
        widget.binId,
        message,
        media: _selectedMedia,
        replyToMessageId: _replyingToMessageId,
      );
      if (_isDisposing) return;
      
      // Clear input fields immediately
      _messageController.clear();
      setState(() {
        _selectedMedia = null;
        _replyToMessage = null;
        _replyingToMessageId = null;
        _isSending = false;
      });
      
      // Real-time subscription will replace the optimistic message with the real one
      // Scroll to bottom again to ensure we see the confirmed message
      _scrollToBottom();
    } catch (e) {
      // Remove optimistic message on error
      if (mounted && !_isDisposing) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _isSending = false;
        });
      }
      if (mounted) {
        // Log error for debugging
        print('Send message error: $e');
        
        // Show detailed error message
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to send message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  void _onMediaSelected(MediaAttachment media, String? caption) {
    if (_isDisposing) return;
    setState(() {
      _selectedMedia = media;
      // Set caption in message controller if provided
      if (caption != null && caption.isNotEmpty) {
        _messageController.text = caption;
      } else {
        // Clear message controller if no caption
        _messageController.clear();
      }
    });
  }

  // Send media directly from preview screen
  Future<void> _sendMediaDirectly(MediaAttachment media, String? caption) async {
    if (_isSending || _isDisposing) return;

    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    // Create optimistic message for media
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = <String, dynamic>{
      'id': tempId,
      'bin_id': widget.binId,
      'sender_id': currentUserId,
      'message': caption ?? '',
      'is_deleted': false,
      // Always use UTC for timestamps to match database
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'media_type': media.type.name,
      'local_media_path': media.file.path,
      'local_thumbnail_path': media.thumbnailPath,
      'sender_profile': {
        'id': currentUserId,
        'first_name': 'You',
        'last_name': '',
      },
    };

    // Add reply-to if present
    if (_replyingToMessageId != null) {
      optimisticMessage['reply_to_message_id'] = _replyingToMessageId;
      optimisticMessage['replied_to_message'] = _replyToMessage;
    }

    // Add optimistic message immediately
    setState(() {
      _isSending = true;
      _messages.add(optimisticMessage);
    });

    // Immediately scroll to bottom to show the new message (reverse ListView: position 0 = bottom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0); // Jump instantly to bottom to show new message immediately
      }
    });

    try {
      await _chatService.sendBinMessage(
        widget.binId,
        caption ?? '',
        media: media,
        replyToMessageId: _replyingToMessageId,
      );
      
      if (_isDisposing) return;
      
      setState(() {
        _selectedMedia = null;
        _replyToMessage = null;
        _replyingToMessageId = null;
        _isSending = false;
      });
      
      if (!_isDisposing) {
        _messageController.clear();
        // Real-time subscription will replace optimistic message
        _scrollToBottom();
      }
    } catch (e) {
      // Remove optimistic message on error
      if (mounted && !_isDisposing) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setReplyTo(Map<String, dynamic> message) {
    setState(() {
      _replyToMessage = message;
      _replyingToMessageId = message['id'] as String?;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
      _replyingToMessageId = null;
    });
  }

  void _cancelMedia() {
    setState(() {
      _selectedMedia = null;
    });
  }

  void _showMediaViewer(String mediaUrl, String mediaType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaViewerScreen(
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        ),
      ),
    );
  }

  Future<void> _startEditing(String messageId, String currentMessage) async {
    setState(() {
      _editingMessageId = messageId;
      _editMessageController.text = currentMessage;
    });
  }

  Future<void> _cancelEditing() async {
    setState(() {
      _editingMessageId = null;
      _editMessageController.clear();
    });
  }

  Future<void> _saveEdit() async {
    if (_editingMessageId == null) return;
    final newMessage = _editMessageController.text.trim();
    if (newMessage.isEmpty) return;

    try {
      await _chatService.editMessage(_editingMessageId!, newMessage);
      setState(() {
        _editingMessageId = null;
        _editMessageController.clear();
      });
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.deleteMessage(messageId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canEditOrDelete(Map<String, dynamic> message) {
    final senderId = message['sender_id'] as String?;
    final currentUserId = _chatService.currentUserId;
    if (senderId != currentUserId) return false;

    // Check time limit (15 minutes)
    final createdAt = message['created_at'] as String?;
    if (createdAt == null) return false;

    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      return difference.inMinutes <= 15;
    } catch (e) {
      return false;
    }
  }

  String _getChatTitle() {
    if (_isDisposing) return 'Group Chat';
    final binName = _bin?['name'] as String? ?? 'Bin';
    return '$binName Group Chat';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (mounted && !_isDisposing) {
              _isDisposing = true;
              final channel = _channel;
              _channel = null;
              if (context.canPop()) {
                context.pop();
              }
              Future.microtask(() {
                channel?.unsubscribe();
              });
            }
          },
        ),
        title: Text(_getChatTitle()),
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
                    : _messages.isEmpty && !_isInitialLoad
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 64, color: AppTheme.textGray),
                                const SizedBox(height: 16),
                                const Text(
                                  'No messages yet',
                                  style: TextStyle(color: AppTheme.textGray),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                      color: AppTheme.textGray, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                              reverse: true, // Start at bottom, scroll up for older messages
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length + (_isLoadingOlder ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at top when loading older messages
                                if (_isLoadingOlder && index == _messages.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                // Reverse index for reverse ListView (index 0 = newest message)
                                final reversedIndex = _messages.length - 1 - index;
                                final message = _messages[reversedIndex];
                                final messageId = message['id'] as String? ?? '';
                                
                                // Check if we need to show a date separator
                                // For reverse list, compare with next message (index + 1)
                                final shouldShowDateSeparator = _shouldShowDateSeparator(reversedIndex);
                                
                                // Create or get key for this message
                                if (!_messageKeys.containsKey(messageId)) {
                                  _messageKeys[messageId] = GlobalKey();
                                }
                                
                                final senderId =
                                    message['sender_id'] as String?;
                                final isCurrentUser =
                                    senderId == _chatService.currentUserId;
                                final canEditDelete = _canEditOrDelete(message);
                                final isEditing = _editingMessageId == messageId;
                                final isHighlighted = _highlightedMessageId == messageId;

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
                                final isEdited = message['edited_at'] != null;

                                // Build the message widget
                                final messageWidget = isEditing
                                    ? _EditMessageBubble(
                                        message: message['message'] as String? ?? '',
                                        controller: _editMessageController,
                                        onSave: _saveEdit,
                                        onCancel: _cancelEditing,
                                      )
                                    : _buildMessageWidget(
                                        message: message,
                                        messageId: messageId,
                                        senderId: senderId,
                                        isCurrentUser: isCurrentUser,
                                        canEditDelete: canEditDelete,
                                        isEditing: isEditing,
                                        isHighlighted: isHighlighted,
                                        senderName: senderName,
                                        isAdmin: isAdmin,
                                        isEdited: isEdited,
                                      );

                                // Show date separator if needed
                                if (shouldShowDateSeparator) {
                                  return Column(
                                    children: [
                                      _DateSeparator(
                                        timestamp: message['created_at'] as String?,
                                      ),
                                      const SizedBox(height: 8),
                                      messageWidget,
                                    ],
                                  );
                                }

                                return messageWidget;
                              },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply preview or selected media preview
                  if (_replyToMessage != null || _selectedMedia != null)
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _replyToMessage != null
                          ? ReplyPreviewWidget(
                              repliedToMessage: _replyToMessage!,
                              onCancel: _cancelReply,
                            )
                          : _selectedMedia != null
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedMedia!.type == MediaType.image
                                            ? Icons.image
                                            : _selectedMedia!.type == MediaType.video
                                                ? Icons.videocam
                                                : Icons.mic,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedMedia!.type == MediaType.image
                                              ? 'Image'
                                              : _selectedMedia!.type == MediaType.video
                                                  ? 'Video'
                                                  : 'Audio',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: _cancelMedia,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  Row(
                    children: [
                      MediaPickerWidget(
                        onMediaSelected: _onMediaSelected,
                        replyToMessage: _replyToMessage,
                        binId: widget.binId,
                        replyToMessageId: _replyingToMessageId,
                        onSendDirectly: _sendMediaDirectly,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Media viewer screen for full-screen image/video viewing
class _MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;

  const _MediaViewerScreen({
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl),
      );
      _videoController!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: widget.mediaType == 'image'
            ? InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.mediaUrl,
                  fit: BoxFit.contain,
                ),
              )
            : widget.mediaType == 'video'
                ? _videoController != null &&
                        _videoController!.value.isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 64,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator())
                : const Center(
                    child: Text(
                      'Unsupported media type',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
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
  final bool isEdited;
  final bool canEditDelete;
  final String? mediaType;
  final String? mediaUrl;
  final String? localMediaPath;
  final String? localThumbnailPath;
  final String? thumbnailUrl;
  final int? mediaDuration;
  final String? mediaFilename;
  final Map<String, dynamic>? repliedToMessage;
  final String? replyToMessageId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMediaTap;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.senderName,
    this.isAdmin = false,
    this.timestamp,
    this.isEdited = false,
    this.canEditDelete = false,
    this.mediaType,
    this.mediaUrl,
    this.localMediaPath,
    this.localThumbnailPath,
    this.thumbnailUrl,
    this.mediaDuration,
    this.mediaFilename,
    this.repliedToMessage,
    this.replyToMessageId,
    this.onEdit,
    this.onDelete,
    this.onMediaTap,
    this.onReply,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onReply != null)
                    ListTile(
                      leading: const Icon(Icons.reply),
                      title: const Text('Reply'),
                      onTap: () {
                        Navigator.pop(context);
                        onReply!();
                      },
                    ),
                  if (canEditDelete && onEdit != null)
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      onTap: () {
                        Navigator.pop(context);
                        onEdit!();
                      },
                    ),
                  if (canEditDelete && onDelete != null)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                    ),
                ],
              ),
            ),
          );
        },
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
              // Reply-to preview (clickable to navigate to original message)
              if (repliedToMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: onReplyTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isUser ? Colors.white70 : AppTheme.primaryGreen,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 12,
                                color: isUser ? Colors.white70 : AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  repliedToMessage!['sender_profile'] != null
                                      ? (repliedToMessage!['sender_profile'] as Map)['first_name'] as String? ?? 'User'
                                      : 'User',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUser ? Colors.white70 : AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            repliedToMessage!['is_deleted'] == true
                                ? 'This message was deleted'
                                : repliedToMessage!['message'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUser ? Colors.white70 : AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Media
              if (mediaType != null && (mediaUrl != null || localMediaPath != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: mediaUrl != null
                      ? MediaMessageWidget(
                          mediaUrl: mediaUrl,
                          thumbnailUrl: thumbnailUrl,
                          mediaType: mediaType!,
                          duration: mediaDuration,
                          filename: mediaFilename,
                          onTap: onMediaTap,
                        )
                      : _LocalMediaPreview(
                          mediaType: mediaType!,
                          localMediaPath: localMediaPath,
                          localThumbnailPath: localThumbnailPath,
                          isUser: isUser,
                        ),
                ),
              // Message text
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
              if (timestamp != null || isEdited)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      if (isEdited)
                        Text(
                          'Edited',
                          style: TextStyle(
                            color: isUser
                                ? Colors.white70
                                : AppTheme.textGray.withOpacity(0.7),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (isEdited && timestamp != null)
                        const SizedBox(width: 4),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp!),
                          style: TextStyle(
                            color: isUser
                                ? Colors.white70
                                : AppTheme.textGray.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      // Convert to Singapore timezone (UTC+8)
      final utcDateTime = DateTime.parse(timestamp).toUtc();
      final singaporeOffset = const Duration(hours: 8);
      final dateTime = utcDateTime.add(singaporeOffset);
      final now = DateTime.now().toUtc().add(singaporeOffset);

      // Same day - show time (e.g., "2:30 PM")
      if (dateTime.year == now.year && 
          dateTime.month == now.month && 
          dateTime.day == now.day) {
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      
      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      if (dateTime.year == yesterday.year && 
          dateTime.month == yesterday.month && 
          dateTime.day == yesterday.day) {
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return 'Yesterday $displayHour:$minute $period';
      }
      
      // Same year - show date and time (e.g., "Dec 25, 2:30 PM")
      if (dateTime.year == now.year) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '${months[dateTime.month - 1]} ${dateTime.day}, $displayHour:$minute $period';
      }
      
      // Different year - show full date (e.g., "12/25/2023")
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}

class _LocalMediaPreview extends StatelessWidget {
  final String mediaType;
  final String? localMediaPath;
  final String? localThumbnailPath;
  final bool isUser;

  const _LocalMediaPreview({
    required this.mediaType,
    required this.localMediaPath,
    required this.localThumbnailPath,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == 'image' && localMediaPath != null) {
      final imageFile = File(localMediaPath!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          imageFile,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCard(Icons.image_not_supported),
        ),
      );
    }

    if (mediaType == 'video') {
      if (localThumbnailPath != null) {
        final thumbFile = File(localThumbnailPath!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(
                thumbFile,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackCard(Icons.videocam),
              ),
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return _fallbackCard(Icons.videocam);
    }

    if (mediaType == 'audio') {
      return _fallbackCard(Icons.audiotrack);
    }

    return _fallbackCard(Icons.attachment);
  }

  Widget _fallbackCard(IconData icon) {
    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        color: isUser ? Colors.white24 : AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26),
          const SizedBox(height: 6),
          const Text('Uploading...', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EditMessageBubble extends StatelessWidget {
  final String message;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditMessageBubble({
    required this.message,
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editing message',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Date separator widget (like WhatsApp)
class _DateSeparator extends StatelessWidget {
  final String? timestamp;

  const _DateSeparator({this.timestamp});

  String _formatDateHeader(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now().toLocal();

      // Today
      if (dateTime.year == now.year && 
          dateTime.month == now.month && 
          dateTime.day == now.day) {
        return 'Today';
      }
      
      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      if (dateTime.year == yesterday.year && 
          dateTime.month == yesterday.month && 
          dateTime.day == yesterday.day) {
        return 'Yesterday';
      }
      
      // Within last 7 days - show day name
      final daysDiff = now.difference(dateTime).inDays;
      if (daysDiff < 7) {
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return days[dateTime.weekday - 1];
      }
      
      // Same year - show month and day
      if (dateTime.year == now.year) {
        final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                       'July', 'August', 'September', 'October', 'November', 'December'];
        return '${months[dateTime.month - 1]} ${dateTime.day}';
      }
      
      // Different year - show full date
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                     'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (timestamp == null) return const SizedBox.shrink();
    
    final dateText = _formatDateHeader(timestamp!);
    if (dateText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppTheme.textGray.withOpacity(0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppTheme.textGray.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

