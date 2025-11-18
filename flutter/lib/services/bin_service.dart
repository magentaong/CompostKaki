import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BinNotFoundException implements Exception {
  final String message;
  BinNotFoundException(this.message);
  
  @override
  String toString() => message;
}

class BinService {
  final SupabaseService _supabaseService = SupabaseService();
  String? get currentUserId => _supabaseService.currentUser?.id;
  final SupabaseClient _storageClient = Supabase.instance.client;

  
  // Get all bins for current user
  Future<List<Map<String, dynamic>>> getUserBins() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    // Get owned bins
    final ownedBinsResponse = await _supabaseService.client
        .from('bins')
        .select('*')
        .eq('user_id', user.id);
    
    // Get member bins
    final membershipsResponse = await _supabaseService.client
        .from('bin_members')
        .select('bin_id')
        .eq('user_id', user.id);
    
    final memberBinIds = (membershipsResponse as List)
        .map((m) => m['bin_id'] as String)
        .toList();
    
    List<Map<String, dynamic>> memberBins = [];
    if (memberBinIds.isNotEmpty) {
      final memberBinsResponse = await _supabaseService.client
          .from('bins')
          .select('*')
          .inFilter('id', memberBinIds);
      memberBins = List<Map<String, dynamic>>.from(memberBinsResponse);
    }
    
    // Combine and deduplicate
    final ownedBins = List<Map<String, dynamic>>.from(ownedBinsResponse);
    final allBins = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    
    for (var bin in ownedBins) {
      if (!seenIds.contains(bin['id'])) {
        allBins.add(bin);
        seenIds.add(bin['id']);
      }
    }
    
    for (var bin in memberBins) {
      if (!seenIds.contains(bin['id'])) {
        allBins.add(bin);
        seenIds.add(bin['id']);
      }
    }
    
    return allBins;
  }
  
  // Get bin by ID
  Future<Map<String, dynamic>> getBin(String binId) async {
    final response = await _supabaseService.client
        .from('bins')
        .select('*')
        .eq('id', binId)
        .maybeSingle();
    
    if (response == null) {
      throw BinNotFoundException('This bin has been deleted or no longer exists.');
    }
    
    // Get contributors
    final membersResponse = await _supabaseService.client
        .from('bin_members')
        .select('user_id')
        .eq('bin_id', binId);
    
    final contributors = (membersResponse as List)
        .map((m) => m['user_id'] as String)
        .toList();
    
    return {
      ...response as Map<String, dynamic>,
      'contributors_list': contributors,
    };
  }
  
  // Create new bin
  Future<Map<String, dynamic>> createBin({
    required String name,
    String? location,
    String? image,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final data = <String, dynamic>{
      'name': name,
      'location': location ?? name,
      'user_id': user.id,
      'health_status': 'Healthy',
    };
    if (image != null && image.isNotEmpty) {
      data['image'] = image;
    }
    
    final response = await _supabaseService.client
        .from('bins')
        .insert(data)
        .select()
        .single();
    
    return response as Map<String, dynamic>;
  }

  Future<void> deleteBin(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Delete memberships and logs first (optional but keeps data clean)
    await _supabaseService.client.from('bin_members').delete().eq('bin_id', binId);
    await _supabaseService.client.from('bin_logs').delete().eq('bin_id', binId);

    final response = await _supabaseService.client
        .from('bins')
        .delete()
        .eq('id', binId)
        .eq('user_id', user.id)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to delete bin or you are not the owner.');
    }
  }
  
  // Join bin
  Future<void> joinBin(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _supabaseService.client
        .from('bin_members')
        .insert({
          'bin_id': binId,
          'user_id': user.id,
        });
  }

  // Leave bin
  Future<void> leaveBin(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _supabaseService.client
        .from('bin_members')
        .delete()
        .eq('bin_id', binId)
        .eq('user_id', user.id);
  }
  
  // Get bin logs
  Future<List<Map<String, dynamic>>> getBinLogs(String binId) async {
    final response = await _supabaseService.client
        .from('bin_logs')
        .select('*, profiles:user_id(id, first_name, last_name, avatar_url)')
        .eq('bin_id', binId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Create bin log
  Future<void> createBinLog({
    required String binId,
    required String type,
    required String content,
    int? temperature,
    String? moisture,
    double? weight,
    String? image,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _supabaseService.client
        .from('bin_logs')
        .insert({
          'bin_id': binId,
          'user_id': user.id,
          'type': type,
          'content': content,
          'temperature': temperature,
          'moisture': moisture,
          'weight': weight,
          'image': image,
        });
    
    // Update bin stats
    final updates = <String, dynamic>{};
    if (temperature != null) {
      updates['latest_temperature'] = temperature;
    }
    if (moisture != null) {
      updates['latest_moisture'] = moisture;
    }
    if (type == 'Turn Pile') {
      final bin = await getBin(binId);
      final currentFlips = (bin['latest_flips'] as int?) ?? 0;
      updates['latest_flips'] = currentFlips + 1;
    }
    
    if (updates.isNotEmpty) {
      await _supabaseService.client
          .from('bins')
          .update(updates)
          .eq('id', binId);
    }
  }

  Future<String> _uploadFileToBucket({
    required File file,
    required String objectName,
    required String bucket,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = path.extension(file.path).replaceFirst('.', '');
    final fileName =
        '$objectName.${ext.isEmpty ? 'jpg' : ext}';

    await _storageClient.storage
        .from(bucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext.isEmpty ? 'jpeg' : ext}',
          ),
        );

    return _storageClient.storage
        .from(bucket)
        .getPublicUrl(fileName);
  }

  Future<void> updateBinImage(String binId, File file) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final imageUrl = await _uploadFileToBucket(
      file: file,
      objectName:
          'bin_${binId}_${DateTime.now().millisecondsSinceEpoch}',
      bucket: 'bin-images',
    );

    await _supabaseService.client
        .from('bins')
        .update({'image': imageUrl})
        .eq('id', binId);
  }

  Future<String> uploadLogImage(File file, String binId) async {
    return _uploadFileToBucket(
      file: file,
      objectName:
          'log_${binId}_${DateTime.now().millisecondsSinceEpoch}',
      bucket: 'bin-logs',
    );
  }
}

