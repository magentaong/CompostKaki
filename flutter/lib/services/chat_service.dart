import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  
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

  // Get chat messages for a specific bin
  Future<List<Map<String, dynamic>>> getBinMessages(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Get messages for this bin where user is sender or receiver
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: true);
    
    final messages = List<Map<String, dynamic>>.from(response);
    
    // Fetch profiles for all unique sender and receiver IDs
    final userIds = <String>{};
    for (var message in messages) {
      final senderId = message['sender_id'] as String?;
      final receiverId = message['receiver_id'] as String?;
      if (senderId != null) userIds.add(senderId);
      if (receiverId != null) userIds.add(receiverId);
    }
    
    final profilesMap = <String, Map<String, dynamic>?>{};
    for (var userId in userIds) {
      profilesMap[userId] = await _getUserProfile(userId);
    }
    
    // Attach profiles to messages
    for (var message in messages) {
      final senderId = message['sender_id'] as String?;
      final receiverId = message['receiver_id'] as String?;
      if (senderId != null) {
        message['sender_profile'] = profilesMap[senderId];
      }
      if (receiverId != null) {
        message['receiver_profile'] = profilesMap[receiverId];
      }
    }
    
    return messages;
  }
  
  // Send a message in a bin chat
  // For bin chat, receiver_id should be the bin owner/admin
  Future<void> sendBinMessage(String binId, String message, {String? receiverId}) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // If receiverId is not provided, we need to get the bin owner
    String? actualReceiverId = receiverId;
    if (actualReceiverId == null) {
      final bin = await _supabaseService.client
          .from('bins')
          .select('user_id')
          .eq('id', binId)
          .single();
      actualReceiverId = bin['user_id'] as String?;
    }
    
    await _supabaseService.client
        .from('bin_messages')
        .insert({
          'bin_id': binId,
          'sender_id': user.id,
          'receiver_id': actualReceiverId,
          'message': message,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _supabaseService.client
        .from('bin_messages')
        .update({
          'is_read': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('bin_id', binId)
        .eq('receiver_id', user.id)
        .eq('is_read', false);
  }
  
  // Admin: Get all conversations in a bin (list of users who have messaged)
  Future<List<Map<String, dynamic>>> getBinConversations(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Get bin to verify user is owner
    final bin = await _supabaseService.client
        .from('bins')
        .select('user_id')
        .eq('id', binId)
        .single();
    
    if (bin['user_id'] != user.id) {
      throw Exception('Only bin owner can view all conversations');
    }
    
    // Get distinct users who have sent messages to admin in this bin
    final messages = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .eq('receiver_id', user.id) // Messages sent to admin
        .order('created_at', ascending: false);
    
    // Group by sender_id and get latest message + unread count
    final Map<String, Map<String, dynamic>> conversationsMap = {};
    
    for (var message in messages) {
      final senderId = message['sender_id'] as String;
      if (!conversationsMap.containsKey(senderId)) {
        // Fetch profile for this sender
        final profile = await _getUserProfile(senderId);
        
        // Count unread messages
        final unreadResponse = await _supabaseService.client
            .from('bin_messages')
            .select('id')
            .eq('bin_id', binId)
            .eq('sender_id', senderId)
            .eq('receiver_id', user.id)
            .eq('is_read', false);
        
        conversationsMap[senderId] = {
          'user_id': senderId,
          'profile': profile,
          'last_message': message['message'],
          'last_message_time': message['created_at'],
          'unread_count': (unreadResponse as List).length,
        };
      }
    }
    
    return conversationsMap.values.toList()
      ..sort((a, b) {
        final timeA = a['last_message_time'] as String? ?? '';
        final timeB = b['last_message_time'] as String? ?? '';
        return timeB.compareTo(timeA); // Most recent first
      });
  }
  
  // Get conversation between admin and a specific user in a bin
  Future<List<Map<String, dynamic>>> getConversationWithUser(String binId, String userId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Get messages between current user and specified user in this bin
    // PostgREST doesn't support complex nested AND/OR, so we fetch messages where
    // either user is involved and filter in code
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .or('sender_id.eq.$userId,sender_id.eq.${user.id},receiver_id.eq.$userId,receiver_id.eq.${user.id}')
        .order('created_at', ascending: true);
    
    final allMessages = List<Map<String, dynamic>>.from(response);
    
    // Filter to only messages between these two users
    final messages = allMessages.where((message) {
      final senderId = message['sender_id'] as String?;
      final receiverId = message['receiver_id'] as String?;
      // Message is between user1 and user2 if:
      // (sender is user1 AND receiver is user2) OR (sender is user2 AND receiver is user1)
      return (senderId == userId && receiverId == user.id) ||
             (senderId == user.id && receiverId == userId);
    }).toList();
    
    // Fetch profiles for both users
    final currentUserProfile = await _getUserProfile(user.id);
    final otherUserProfile = await _getUserProfile(userId);
    
    // Attach profiles to messages
    for (var message in messages) {
      final senderId = message['sender_id'] as String?;
      final receiverId = message['receiver_id'] as String?;
      
      if (senderId == user.id) {
        message['sender_profile'] = currentUserProfile;
      } else if (senderId == userId) {
        message['sender_profile'] = otherUserProfile;
      }
      
      if (receiverId == user.id) {
        message['receiver_profile'] = currentUserProfile;
      } else if (receiverId == userId) {
        message['receiver_profile'] = otherUserProfile;
      }
    }
    
    return messages;
  }
  
  // Subscribe to new messages for a bin
  RealtimeChannel subscribeToBinMessages(String binId, Function(Map<String, dynamic>) onNewMessage) {
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
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe();
    
    return channel;
  }

  // Methods for AdminChatScreen (general admin chat)
  // Note: These require context - AdminChatScreen should be updated to accept binId/userId
  Future<List<Map<String, dynamic>>> getMessages() async {
    // Return empty list - AdminChatScreen needs binId/userId to work properly
    return [];
  }

  RealtimeChannel subscribeToMessages(Function(Map<String, dynamic>) onNewMessage) {
    // Return a dummy channel - AdminChatScreen needs binId to work properly
    return _supabaseService.client.channel('admin_chat_dummy');
  }

  Future<void> sendMessage(String message) async {
    // Throw error - AdminChatScreen needs binId to work properly
    throw Exception('AdminChatScreen requires binId. Use BinChatConversationScreen instead.');
  }
}

