import 'supabase_service.dart';

class EducationalService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Get all guides
  Future<List<Map<String, dynamic>>> getGuides() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await _supabaseService.client
        .from('guides')
        .select('*')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Get a single guide by ID
  Future<Map<String, dynamic>> getGuide(String guideId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await _supabaseService.client
        .from('guides')
        .select('*')
        .eq('id', guideId)
        .single();
    
    return Map<String, dynamic>.from(response);
  }
  
  // Get all tips
  Future<List<Map<String, dynamic>>> getTips() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await _supabaseService.client
        .from('tips')
        .select('*')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Like a guide
  Future<void> likeGuide(String guideId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Increment likes count (you may want to track individual likes in a separate table)
    final guide = await getGuide(guideId);
    final currentLikes = (guide['likes'] as int?) ?? 0;
    
    await _supabaseService.client
        .from('guides')
        .update({'likes': currentLikes + 1})
        .eq('id', guideId);
  }
  
  // Get bin-specific food waste guidelines
  Future<Map<String, dynamic>?> getBinFoodWasteGuide(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await _supabaseService.client
        .from('bin_food_waste_guides')
        .select('*')
        .eq('bin_id', binId)
        .maybeSingle();
    
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }
  
  // Admin: Create or update bin food waste guidelines
  Future<void> upsertBinFoodWasteGuide({
    required String binId,
    required List<String> canAdd,
    required List<String> cannotAdd,
    String? notes,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Check if user is bin owner
    final bin = await _supabaseService.client
        .from('bins')
        .select('user_id')
        .eq('id', binId)
        .single();
    
    if (bin['user_id'] != user.id) {
      throw Exception('Only bin owner can update food waste guidelines');
    }
    
    // Prepare data (don't include id, let database handle it)
    final data = {
      'bin_id': binId,
      'can_add': canAdd,
      'cannot_add': cannotAdd,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Check if guide already exists for this bin
    final existingGuide = await _supabaseService.client
        .from('bin_food_waste_guides')
        .select('bin_id')
        .eq('bin_id', binId)
        .maybeSingle();
    
    if (existingGuide != null) {
      // Update existing record using bin_id (since it's unique)
      await _supabaseService.client
          .from('bin_food_waste_guides')
          .update(data)
          .eq('bin_id', binId);
    } else {
      // Insert new record
      await _supabaseService.client
          .from('bin_food_waste_guides')
          .insert(data);
    }
  }
}

