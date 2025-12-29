import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'media_service.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  final MediaService _mediaService = MediaService();

  String? get currentUserId => _supabaseService.currentUser?.id;

  // Helper method to fetch user profile
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Public method to fetch user profile (for use in UI)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _getUserProfile(userId);
  }

  // Get all group chat messages for a specific bin
  Future<List<Map<String, dynamic>>> getBinMessages(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get all messages for this bin (group chat - no receiver_id filter)
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    final messages = List<Map<String, dynamic>>.from(response);

    return _enrichMessages(messages);
  }

  // Get recent messages for a bin (for initial load - loads last N messages)
  Future<List<Map<String, dynamic>>> getRecentBinMessages(
    String binId, {
    int limit = 50,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get recent messages (last N messages, ordered by created_at descending)
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = List<Map<String, dynamic>>.from(response);
    
    // Reverse to get ascending order (oldest first)
    final reversedMessages = messages.reversed.toList();

    return _enrichMessages(reversedMessages);
  }

  // Get older messages before a certain timestamp (for pagination)
  Future<List<Map<String, dynamic>>> getOlderBinMessages(
    String binId,
    DateTime beforeTimestamp, {
    int limit = 50,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get messages before the given timestamp
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .eq('is_deleted', false)
        .lt('created_at', beforeTimestamp.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = List<Map<String, dynamic>>.from(response);
    
    // Reverse to get ascending order (oldest first)
    final reversedMessages = messages.reversed.toList();

    return _enrichMessages(reversedMessages);
  }

  // Helper method to enrich messages with profiles and replied-to messages
  Future<List<Map<String, dynamic>>> _enrichMessages(
    List<Map<String, dynamic>> messages,
  ) async {

    // Fetch profiles for all unique sender IDs
    final userIds = <String>{};
    for (var message in messages) {
      final senderId = message['sender_id'] as String?;
      if (senderId != null) userIds.add(senderId);
    }

    final profilesMap = <String, Map<String, dynamic>?>{};
    for (var userId in userIds) {
      profilesMap[userId] = await _getUserProfile(userId);
    }

    // Attach profiles to messages and fetch replied-to messages
    for (var message in messages) {
      final senderId = message['sender_id'] as String?;
      if (senderId != null) {
        message['sender_profile'] = profilesMap[senderId];
      }

      // Fetch replied-to message if present
      final replyToId = message['reply_to_message_id'] as String?;
      if (replyToId != null) {
        final repliedToMessage = await getRepliedToMessage(replyToId);
        if (repliedToMessage != null) {
          message['replied_to_message'] = repliedToMessage;
        }
      }
    }

    return messages;
  }

  // Send a message in a bin group chat
  Future<void> sendBinMessage(
    String binId,
    String message, {
    MediaAttachment? media,
    String? replyToMessageId,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Upload media FIRST if provided (fail early if upload fails)
    Map<String, dynamic>? mediaData;
    if (media != null) {
      try {
        mediaData = await _mediaService.uploadChatMedia(
          binId: binId,
          media: media,
        );
      } catch (e) {
        // Re-throw with context
        throw Exception('Failed to upload media: $e');
      }
    }

    // Prepare message data
    final messageData = <String, dynamic>{
      'bin_id': binId,
      'sender_id': user.id,
      'message': message,
      'is_deleted': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add media data if present
    if (mediaData != null) {
      messageData.addAll(mediaData);
  }

    // Add reply-to if present
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      messageData['reply_to_message_id'] = replyToMessageId;
    }

    // Insert message (only after successful media upload)
    try {
      await _supabaseService.client.from('bin_messages').insert(messageData);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get replied-to message details (for showing reply preview)
  Future<Map<String, dynamic>?> getRepliedToMessage(String messageId) async {
    try {
      final response = await _supabaseService.client
          .from('bin_messages')
          .select('id, message, sender_id, media_type, media_url, created_at, is_deleted')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return null;

      // Get sender profile
      final senderId = response['sender_id'] as String?;
      if (senderId != null) {
        response['sender_profile'] = await _getUserProfile(senderId);
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return null;
    }
  }

  // Edit a message (only by sender, within time limit)
  // Time limit: 15 minutes (900 seconds)
  Future<void> editMessage(String messageId, String newMessage) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // First, verify the message exists and belongs to the user
    final messageResponse = await _supabaseService.client
        .from('bin_messages')
        .select('sender_id, created_at')
        .eq('id', messageId)
        .single();

    if (messageResponse['sender_id'] != user.id) {
      throw Exception('You can only edit your own messages');
    }

    // Check time limit (15 minutes)
    final createdAt = DateTime.parse(messageResponse['created_at']);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes > 15) {
      throw Exception('Messages can only be edited within 15 minutes');
    }

    // Update the message
    await _supabaseService.client
        .from('bin_messages')
        .update({
          'message': newMessage,
          'edited_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', user.id);
  }

  // Delete a message (soft delete, only by sender, within time limit)
  // Time limit: 15 minutes (900 seconds)
  Future<void> deleteMessage(String messageId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // First, verify the message exists and belongs to the user
    final messageResponse = await _supabaseService.client
        .from('bin_messages')
        .select('sender_id, created_at')
        .eq('id', messageId)
        .single();

    if (messageResponse['sender_id'] != user.id) {
      throw Exception('You can only delete your own messages');
    }

    // Check time limit (15 minutes)
    final createdAt = DateTime.parse(messageResponse['created_at']);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes > 15) {
      throw Exception('Messages can only be deleted within 15 minutes');
    }

    // Soft delete the message
    await _supabaseService.client
        .from('bin_messages')
        .update({
          'is_deleted': true,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', user.id);
  }

  // Subscribe to new messages for a bin (group chat)
  RealtimeChannel subscribeToBinMessages(
      String binId, Function(Map<String, dynamic>) onNewMessage) {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channel = _supabaseService.client
        .channel('bin_messages_$binId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bin_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bin_id',
            value: binId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            // Only show non-deleted messages
            if (newMessage['is_deleted'] != true) {
              onNewMessage(newMessage);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bin_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bin_id',
            value: binId,
          ),
          callback: (payload) {
            // Handle message updates (edits/deletes)
            final updatedMessage = payload.newRecord;
            onNewMessage(updatedMessage);
          },
        )
        .subscribe();

    return channel;
  }
}
