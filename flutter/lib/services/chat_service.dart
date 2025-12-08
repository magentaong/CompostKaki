import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  
  String? get currentUserId => _supabaseService.currentUser?.id;
  
  // Get chat messages for a specific bin
  Future<List<Map<String, dynamic>>> getBinMessages(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Get messages for this bin where user is sender or receiver
    final response = await _supabaseService.client
        .from('bin_messages')
        .select('*, sender_profile:sender_id(id, first_name, last_name), receiver_profile:receiver_id(id, first_name, last_name)')
        .eq('bin_id', binId)
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
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
}

