import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  String? get currentUserId => _supabaseService.currentUser?.id;

  // Get all messages for a bin
  Future<List<Map<String, dynamic>>> getBinMessages(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final messagesResponse = await _supabaseService.client
        .from('bin_messages')
        .select('*')
        .eq('bin_id', binId)
        .order('created_at', ascending: true);

    final messages = List<Map<String, dynamic>>.from(messagesResponse);

    // Manually fetch profile data for each message
    final List<Map<String, dynamic>> messagesWithProfiles = [];
    for (var message in messages) {
      final userId = message['user_id'] as String;
      final profileResponse = await _supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      messagesWithProfiles.add({
        ...message,
        'profiles': profileResponse,
      });
    }

    return messagesWithProfiles;
  }

  // Send a message to a bin
  Future<Map<String, dynamic>> sendMessage({
    required String binId,
    required String message,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final response = await _supabaseService.client
        .from('bin_messages')
        .insert({
          'bin_id': binId,
          'user_id': user.id,
          'message': message.trim(),
        })
        .select('*')
        .single();

    final messageData = response as Map<String, dynamic>;
    
    // Fetch profile data
    final profileResponse = await _supabaseService.client
        .from('profiles')
        .select('id, first_name, last_name')
        .eq('id', user.id)
        .maybeSingle();

    return {
      ...messageData,
      'profiles': profileResponse,
    };
  }

  // Delete a message (only own messages)
  Future<void> deleteMessage(String messageId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabaseService.client
        .from('bin_messages')
        .delete()
        .eq('id', messageId)
        .eq('user_id', user.id);
  }

  // Update a message (only own messages)
  Future<void> updateMessage({
    required String messageId,
    required String newMessage,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (newMessage.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    await _supabaseService.client
        .from('bin_messages')
        .update({
          'message': newMessage.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('user_id', user.id);
  }

  // Subscribe to real-time messages for a bin
  RealtimeChannel subscribeToBinMessages(
    String binId,
    void Function(Map<String, dynamic> message) onNewMessage,
  ) {
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
            if (payload.newRecord != null) {
              final messageData = payload.newRecord as Map<String, dynamic>;
              final userId = messageData['user_id'] as String;
              
              // Fetch profile data asynchronously
              _supabaseService.client
                  .from('profiles')
                  .select('id, first_name, last_name')
                  .eq('id', userId)
                  .maybeSingle()
                  .then((profileResponse) {
                    onNewMessage({
                      ...messageData,
                      'profiles': profileResponse,
                    });
                  })
                  .catchError((e) {
                    // If profile fetch fails, use the payload data without profile
                    onNewMessage(messageData);
                  });
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Unsubscribe from real-time messages
  void unsubscribe(RealtimeChannel channel) {
    _supabaseService.client.removeChannel(channel);
  }
}

