import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'xp_service.dart';

class TaskService {
  final SupabaseService _supabaseService = SupabaseService();

  String? get currentUserId => _supabaseService.currentUser?.id;

  // Get community tasks
  Future<List<Map<String, dynamic>>> getCommunityTasks() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get bins user is a member of
    final membershipsResponse = await _supabaseService.client
        .from('bin_members')
        .select('bin_id')
        .eq('user_id', user.id);

    final memberBinIds = (membershipsResponse as List)
        .map((m) => m['bin_id'] as String)
        .toList();

    // Get bins user owns
    final ownedBinsResponse = await _supabaseService.client
        .from('bins')
        .select('id')
        .eq('user_id', user.id);

    final ownedBinIds =
        (ownedBinsResponse as List).map((b) => b['id'] as String).toList();

    // Combine bin IDs
    final allBinIds = [...memberBinIds, ...ownedBinIds].toSet().toList();

    List<Map<String, dynamic>> tasks = [];
    if (allBinIds.isNotEmpty) {
      final tasksResponse = await _supabaseService.client
          .from('tasks')
          .select(
              '*, profiles:user_id(id, first_name, last_name), accepted_by_profile:accepted_by(id, first_name, last_name)')
          .inFilter('bin_id', allBinIds)
          .order('created_at', ascending: false);
      tasks = List<Map<String, dynamic>>.from(tasksResponse);
    }

    // Also get tasks posted by user
    final myTasksResponse = await _supabaseService.client
        .from('tasks')
        .select(
            '*, profiles:user_id(id, first_name, last_name), accepted_by_profile:accepted_by(id, first_name, last_name)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final myTasks = List<Map<String, dynamic>>.from(myTasksResponse);

    // Merge and deduplicate
    final allTasks = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var task in tasks) {
      if (!seenIds.contains(task['id'])) {
        allTasks.add(task);
        seenIds.add(task['id']);
      }
    }

    for (var task in myTasks) {
      if (!seenIds.contains(task['id'])) {
        allTasks.add(task);
        seenIds.add(task['id']);
      }
    }

    return allTasks;
  }

  // Accept task
  Future<Map<String, dynamic>?> acceptTask(String taskId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get task to find bin_id
    final taskResponse = await _supabaseService.client
        .from('tasks')
        .select('bin_id')
        .eq('id', taskId)
        .single();
    final binId = taskResponse['bin_id'] as String?;

    await _supabaseService.client.from('tasks').update({
      'status': 'accepted',
      'accepted_by': user.id,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);

    // Award XP for accepting task
    Map<String, dynamic>? xpResult;
    if (binId != null) {
      try {
        final xpService = XPService();
        xpResult = await xpService.awardXPForTaskAccept(binId: binId);
      } catch (e) {
        print('Error awarding XP: $e');
      }
    }
    return xpResult;
  }

  // Complete task
  Future<Map<String, dynamic>?> completeTask(String taskId) async {
    // Get task to find bin_id
    final taskResponse = await _supabaseService.client
        .from('tasks')
        .select('bin_id')
        .eq('id', taskId)
        .single();
    final binId = taskResponse['bin_id'] as String?;

    // Update task status and set completion_status to pending_check
    final nowUtc = DateTime.now().toUtc();
    await _supabaseService.client.from('tasks').update({
      'status': 'completed',
      'completion_status': 'pending_check',
      'completed_at': nowUtc.toIso8601String(),
    }).eq('id', taskId);

    // Award XP for completing task
    Map<String, dynamic>? xpResult;
    if (binId != null) {
      try {
        final xpService = XPService();
        xpResult = await xpService.awardXPForTaskCompletion(binId: binId);
        // Check for badges after awarding XP
        final newBadges = await xpService.checkAndAwardBadges();
        if (xpResult != null && newBadges.isNotEmpty) {
          xpResult['badgesEarned'] = newBadges;
        }
      } catch (e) {
        print('Error awarding XP: $e');
      }
    }
    return xpResult;
  }

  // Unassign task (release task back to open status)
  Future<Map<String, dynamic>?> unassignTask(String taskId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get task to find bin_id
    final taskResponse = await _supabaseService.client
        .from('tasks')
        .select('bin_id')
        .eq('id', taskId)
        .single();
    final binId = taskResponse['bin_id'] as String?;

    await _supabaseService.client.from('tasks').update({
      'status': 'open',
      'accepted_by': null,
      'accepted_at': null,
    }).eq('id', taskId);

    // Apply penalty for unassigning
    Map<String, dynamic>? xpResult;
    if (binId != null) {
      try {
        final xpService = XPService();
        xpResult = await xpService.penaltyForUnassign(binId: binId);
      } catch (e) {
        print('Error applying penalty: $e');
      }
    }
    return xpResult;
  }

  // Create task
  Future<void> createTask({
    required String binId,
    required String description,
    required String urgency,
    required String effort,
    bool? isTimeSensitive,
    String? dueDate,
    String? photoUrl,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabaseService.client.from('tasks').insert({
      'bin_id': binId,
      'user_id': user.id,
      'description': description,
      'urgency': urgency,
      'effort': effort,
      'is_time_sensitive': isTimeSensitive ?? false,
      'due_date': dueDate,
      'photo_url': photoUrl,
      'status': 'open',
    });

    // Award XP for posting a task
    try {
      final xpService = XPService();
      await xpService.awardXPForTaskPost(binId: binId);
    } catch (e) {
      print('Error awarding XP: $e');
    }
  }

  // Check task (owner confirms completion)
  Future<void> checkTask(String taskId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is the task owner
    final taskResponse = await _supabaseService.client
        .from('tasks')
        .select('user_id, status, completion_status')
        .eq('id', taskId)
        .single();

    if (taskResponse['user_id'] != user.id) {
      throw Exception('Only the task owner can check completion');
    }

    if (taskResponse['status'] != 'completed') {
      throw Exception('Task must be completed before checking');
    }

    if (taskResponse['completion_status'] != 'pending_check') {
      throw Exception('Task completion has already been processed');
    }

    // Update completion_status to checked
    final nowUtc = DateTime.now().toUtc();
    await _supabaseService.client.from('tasks').update({
      'completion_status': 'checked',
      'checked_at': nowUtc.toIso8601String(),
    }).eq('id', taskId);
  }

  // Revert task (owner rejects completion, subtracts XP from completer)
  Future<Map<String, dynamic>?> revertTask(String taskId) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get task details
    final taskResponse = await _supabaseService.client
        .from('tasks')
        .select('user_id, status, completion_status, accepted_by, bin_id')
        .eq('id', taskId)
        .single();

    if (taskResponse['user_id'] != user.id) {
      throw Exception('Only the task owner can revert completion');
    }

    if (taskResponse['status'] != 'completed') {
      throw Exception('Task must be completed before reverting');
    }

    if (taskResponse['completion_status'] != 'pending_check') {
      throw Exception('Task completion has already been processed');
    }

    final binId = taskResponse['bin_id'] as String?;
    final completerId = taskResponse['accepted_by'] as String?;

    // Subtract XP from completer (same amount they earned: 25 XP)
    Map<String, dynamic>? xpResult;
    if (binId != null && completerId != null) {
      try {
        final xpService = XPService();
        // Subtract 25 XP (same as task completion reward)
        xpResult = await xpService.subtractXPForTaskRevert(
          userId: completerId,
          binId: binId,
          amount: 25,
        );
      } catch (e) {
        print('Error subtracting XP: $e');
      }
    }

    // Update task: revert to open status, set completion_status to reverted
    final nowUtc = DateTime.now().toUtc();
    await _supabaseService.client.from('tasks').update({
      'status': 'open',
      'completion_status': 'reverted',
      'reverted_at': nowUtc.toIso8601String(),
      'accepted_by': null, // Clear accepted_by so task can be taken again
      'accepted_at': null,
    }).eq('id', taskId);

    return xpResult;
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _supabaseService.client.from('tasks').delete().eq('id', taskId);
  }
}
