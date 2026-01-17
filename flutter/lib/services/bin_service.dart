import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'xp_service.dart';

// Helper function to get current time in Singapore (UTC+8)
DateTime _getSingaporeTime() {
  return DateTime.now().toUtc().add(const Duration(hours: 8));
}

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

  // Get all bins for current user (including bins with pending requests)
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

    // Get bins with pending requests
    final requestsResponse = await _supabaseService.client
        .from('bin_requests')
        .select('bin_id')
        .eq('user_id', user.id)
        .eq('status', 'pending');

    final requestedBinIds =
        (requestsResponse as List).map((r) => r['bin_id'] as String).toList();

    List<Map<String, dynamic>> requestedBins = [];
    if (requestedBinIds.isNotEmpty) {
      final requestedBinsResponse = await _supabaseService.client
          .from('bins')
          .select('*')
          .inFilter('id', requestedBinIds);
      requestedBins = List<Map<String, dynamic>>.from(requestedBinsResponse);
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

    for (var bin in requestedBins) {
      if (!seenIds.contains(bin['id'])) {
        bin['has_pending_request'] = true; // Mark bins with pending requests
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
      throw BinNotFoundException(
          'This bin has been deleted or no longer exists.');
    }

    // Get contributors
    final membersResponse = await _supabaseService.client
        .from('bin_members')
        .select('user_id')
        .eq('bin_id', binId);

    final contributors =
        (membersResponse as List).map((m) => m['user_id'] as String).toList();

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
      'location': location ?? '',
      'user_id': user.id,
      'health_status': 'Healthy',
      'bin_status': 'active', // Default to active
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
    await _supabaseService.client
        .from('bin_members')
        .delete()
        .eq('bin_id', binId);
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

  // Request to join bin (creates a request instead of direct join)
  Future<void> requestToJoinBin(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if already a member
    final existingMember = await _supabaseService.client
        .from('bin_members')
        .select('*')
        .eq('bin_id', binId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('You are already a member of this bin.');
    }

    // Check if already requested
    final existingRequest = await _supabaseService.client
        .from('bin_requests')
        .select('*')
        .eq('bin_id', binId)
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();

    if (existingRequest != null) {
      throw Exception('You already have a pending request for this bin.');
    }

    // Create request
    await _supabaseService.client.from('bin_requests').insert({
      'bin_id': binId,
      'user_id': user.id,
      'status': 'pending',
    });
  }

  // Check if user has pending request for a bin
  Future<bool> hasPendingRequest(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) return false;

    final request = await _supabaseService.client
        .from('bin_requests')
        .select('*')
        .eq('bin_id', binId)
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();

    return request != null;
  }

  // Check if user is admin (owner) of a bin
  Future<bool> isBinAdmin(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) return false;

    final bin = await _supabaseService.client
        .from('bins')
        .select('user_id')
        .eq('id', binId)
        .maybeSingle();

    return bin != null && bin['user_id'] == user.id;
  }

  // Admin: Get pending requests for a bin
  Future<List<Map<String, dynamic>>> getPendingRequests(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is admin
    final isAdmin = await isBinAdmin(binId);
    if (!isAdmin) {
      throw Exception('Only the bin owner can view requests.');
    }

    final requestsResponse = await _supabaseService.client
        .from('bin_requests')
        .select('*')
        .eq('bin_id', binId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final requests = List<Map<String, dynamic>>.from(requestsResponse);

    // Manually fetch profile data for each request
    final List<Map<String, dynamic>> requestsWithProfiles = [];
    for (var request in requests) {
      final userId = request['user_id'] as String;
      final profileResponse = await _supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      requestsWithProfiles.add({
        ...request,
        'profiles': profileResponse,
      });
    }

    return requestsWithProfiles;
  }

  // Admin: Approve a request (adds user to bin_members and deletes request)
  Future<void> approveRequest(String requestId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get request details
    final request = await _supabaseService.client
        .from('bin_requests')
        .select('bin_id, user_id')
        .eq('id', requestId)
        .maybeSingle();

    if (request == null) {
      throw Exception('Request not found.');
    }

    final binId = request['bin_id'] as String;
    final requestedUserId = request['user_id'] as String;

    // Verify user is admin
    final isAdmin = await isBinAdmin(binId);
    if (!isAdmin) {
      throw Exception('Only the bin owner can approve requests.');
    }

    // Add user to bin_members
    await _supabaseService.client.from('bin_members').insert({
      'bin_id': binId,
      'user_id': requestedUserId,
    });

    // Delete the request
    await _supabaseService.client
        .from('bin_requests')
        .delete()
        .eq('id', requestId);
  }

  // Admin: Reject a request (deletes request)
  Future<void> rejectRequest(String requestId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get request details
    final request = await _supabaseService.client
        .from('bin_requests')
        .select('bin_id')
        .eq('id', requestId)
        .maybeSingle();

    if (request == null) {
      throw Exception('Request not found.');
    }

    final binId = request['bin_id'] as String;

    // Verify user is admin
    final isAdmin = await isBinAdmin(binId);
    if (!isAdmin) {
      throw Exception('Only the bin owner can reject requests.');
    }

    // Delete the request
    await _supabaseService.client
        .from('bin_requests')
        .delete()
        .eq('id', requestId);
  }

  // Admin: Get all members of a bin
  Future<List<Map<String, dynamic>>> getBinMembers(String binId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is admin
    final isAdmin = await isBinAdmin(binId);
    if (!isAdmin) {
      throw Exception('Only the bin owner can view members.');
    }

    final membersResponse = await _supabaseService.client
        .from('bin_members')
        .select('*')
        .eq('bin_id', binId);

    final members = List<Map<String, dynamic>>.from(membersResponse);

    // Manually fetch profile data for each member
    final List<Map<String, dynamic>> membersWithProfiles = [];
    for (var member in members) {
      final userId = member['user_id'] as String;
      final profileResponse = await _supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      membersWithProfiles.add({
        ...member,
        'profiles': profileResponse,
      });
    }

    return membersWithProfiles;
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _supabaseService.client
        .from('profiles')
        .select('id, first_name, last_name')
        .eq('id', userId)
        .single();

    return Map<String, dynamic>.from(response);
  }

  // Admin: Remove a member from bin
  Future<void> removeMember(String binId, String memberUserId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is admin
    final isAdmin = await isBinAdmin(binId);
    if (!isAdmin) {
      throw Exception('Only the bin owner can remove members.');
    }

    // Don't allow removing the owner
    final bin = await getBin(binId);
    if (bin['user_id'] == memberUserId) {
      throw Exception('Cannot remove the bin owner.');
    }

    // Remove member
    await _supabaseService.client
        .from('bin_members')
        .delete()
        .eq('bin_id', binId)
        .eq('user_id', memberUserId);
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

  // Update bin status (admin only)
  Future<void> updateBinStatus({
    required String binId,
    required String status,
    DateTime? restingUntil,
    DateTime? maturedAt,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is owner
    final bin = await getBin(binId);
    if (bin['user_id'] != user.id) {
      throw Exception('Only the bin owner can update bin status');
    }

    final updates = <String, dynamic>{
      'bin_status': status,
    };

    if (status == 'resting' && restingUntil != null) {
      updates['resting_until'] = restingUntil.toIso8601String();
    } else if (status == 'resting') {
      // Clear resting_until if not provided
      updates['resting_until'] = null;
    }

    if (status == 'matured' && maturedAt != null) {
      // maturedAt should already be in UTC when passed from the UI
      updates['matured_at'] = maturedAt.toIso8601String();
    } else if (status == 'matured') {
      // Set matured_at to now in UTC if not provided
      updates['matured_at'] = DateTime.now().toUtc().toIso8601String();
    } else {
      // Clear matured_at if status is not matured
      updates['matured_at'] = null;
    }

    // Clear resting_until if status is not resting
    if (status != 'resting') {
      updates['resting_until'] = null;
    }

    await _supabaseService.client
        .from('bins')
        .update(updates)
        .eq('id', binId);
  }

  // Get resting time remaining (in days)
  int? getRestingDaysRemaining(Map<String, dynamic> bin) {
    final restingUntil = bin['resting_until'] as String?;
    if (restingUntil == null) return null;

    // Convert from UTC to Singapore time - handle timezone parsing
    final untilStr = restingUntil.toString();
    DateTime until;
    if (untilStr.endsWith('Z') || untilStr.contains('+') || untilStr.contains('-', 10)) {
      until = DateTime.parse(untilStr).toUtc().add(const Duration(hours: 8));
    } else {
      until = DateTime.parse('${untilStr}Z').toUtc().add(const Duration(hours: 8));
    }
    final now = _getSingaporeTime();
    final difference = until.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Get matured depletion percentage (0-100, over 6 months)
  double getMaturedDepletionPercentage(Map<String, dynamic> bin) {
    final maturedAt = bin['matured_at'] as String?;
    if (maturedAt == null) return 0.0;

    // Convert from UTC to Singapore time - handle timezone parsing
    final maturedStr = maturedAt.toString();
    DateTime matured;
    if (maturedStr.endsWith('Z') || maturedStr.contains('+') || maturedStr.contains('-', 10)) {
      matured = DateTime.parse(maturedStr).toUtc().add(const Duration(hours: 8));
    } else {
      matured = DateTime.parse('${maturedStr}Z').toUtc().add(const Duration(hours: 8));
    }
    final now = _getSingaporeTime();
    final daysSinceMatured = now.difference(matured).inDays;
    const sixMonthsInDays = 180; // ~6 months

    if (daysSinceMatured >= sixMonthsInDays) return 100.0;
    return (daysSinceMatured / sixMonthsInDays * 100).clamp(0.0, 100.0);
  }

  // Check if bin allows certain actions based on status
  bool canPerformAction(Map<String, dynamic> bin, String action) {
    final status = bin['bin_status'] as String? ?? 'active';

    if (status == 'active') return true;

    if (status == 'resting') {
      // Only allow flipping when resting
      // Allow 'log' action to open the screen, but only 'Turn Pile' will be available
      if (action == 'log') return true;
      return action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';
    }

    if (status == 'matured') {
      // No actions allowed when matured
      return false;
    }

    return false;
  }

  // Calculate health status based on temperature and moisture
  // Make this public for testing
  String calculateHealthStatus(int? temperature, String? moisture) {
    // Critical conditions
    if (temperature != null && (temperature < 20 || temperature > 70)) {
      return 'Critical';
    }
    if (moisture == 'Very Dry' || moisture == 'Very Wet') {
      return 'Critical';
    }

    // Needs Attention conditions
    if (temperature != null && (temperature < 30 || temperature > 60)) {
      return 'Needs Attention';
    }
    if (moisture == 'Dry' || moisture == 'Wet') {
      return 'Needs Attention';
    }

    // Healthy (temperature 30-60°C, moisture Perfect)
    return 'Healthy';
  }

  // Create bin log
  Future<Map<String, dynamic>?> createBinLog({
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

    await _supabaseService.client.from('bin_logs').insert({
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

    // Calculate and update health status if temperature or moisture are provided
    if (temperature != null || moisture != null) {
      final bin = await getBin(binId);
      final currentTemp = temperature ?? bin['latest_temperature'] as int?;
      final currentMoisture = moisture ?? bin['latest_moisture'] as String?;
      final healthStatus = calculateHealthStatus(currentTemp, currentMoisture);
      updates['health_status'] = healthStatus;
    }

    if (updates.isNotEmpty) {
      await _supabaseService.client
          .from('bins')
          .update(updates)
          .eq('id', binId);
    }

    // Award XP for logging activity
    Map<String, dynamic>? xpResult;
    try {
      final xpService = XPService();
      xpResult = await xpService.awardXPForLog(binId: binId, logType: type);
      // Check for badges after awarding XP
      final newBadges = await xpService.checkAndAwardBadges();
      if (xpResult != null && newBadges.isNotEmpty) {
        xpResult['badgesEarned'] = newBadges;
      }
    } catch (e) {
      // Don't fail log creation if XP awarding fails
      print('Error awarding XP: $e');
    }
    
    // Return XP result for celebration
    return xpResult;
  }

  Future<String> _uploadFileToBucket({
    required File file,
    required String objectName,
    required String bucket,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = path.extension(file.path).replaceFirst('.', '');
    final fileName = '$objectName.${ext.isEmpty ? 'jpg' : ext}';

    await _storageClient.storage.from(bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext.isEmpty ? 'jpeg' : ext}',
          ),
        );

    return _storageClient.storage.from(bucket).getPublicUrl(fileName);
  }

  Future<void> updateBinImage(String binId, File file) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final imageUrl = await _uploadFileToBucket(
      file: file,
      objectName: 'bin_${binId}_${DateTime.now().millisecondsSinceEpoch}',
      bucket: 'bin-images',
    );

    await _supabaseService.client
        .from('bins')
        .update({'image': imageUrl}).eq('id', binId);
  }

  Future<String> uploadLogImage(File file, String binId) async {
    return _uploadFileToBucket(
      file: file,
      objectName: 'log_${binId}_${DateTime.now().millisecondsSinceEpoch}',
      bucket: 'bin-logs',
    );
  }
}
