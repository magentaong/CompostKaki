import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class XPService {
  final SupabaseService _supabaseService = SupabaseService();
  String? get currentUserId => _supabaseService.currentUser?.id;

  // XP values for different actions
  static const int xpLogActivity = 10;
  static const int xpTurnPile = 15;
  static const int xpCompleteTask = 25;
  static const int xpAcceptTask = 5;
  static const int xpPostTask = 5;
  static const int xpFirstLogOfDay = 5;
  static const int xpStreak7Days = 50;
  static const int xpStreak30Days = 200;
  static const int xpUnassignPenalty = -5;

  // Calculate level from total XP
  static int calculateLevel(int totalXP) {
    if (totalXP < 100) return 1;
    if (totalXP < 250) return 2;
    if (totalXP < 500) return 3;
    if (totalXP < 1000) return 4;
    if (totalXP < 2000) return 5;
    if (totalXP < 3500) return 6;
    if (totalXP < 5500) return 7;
    if (totalXP < 8000) return 8;
    if (totalXP < 12000) return 9;
    // Level 10+ requires exponential growth
    return 10 + ((totalXP - 12000) ~/ 5000);
  }

  // Get XP required for next level
  static int getXPForNextLevel(int currentLevel) {
    switch (currentLevel) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 500;
      case 4:
        return 1000;
      case 5:
        return 2000;
      case 6:
        return 3500;
      case 7:
        return 5500;
      case 8:
        return 8000;
      case 9:
        return 12000;
      default:
        return 12000 + ((currentLevel - 9) * 5000);
    }
  }

  // Get XP required for current level
  static int getXPForCurrentLevel(int currentLevel) {
    if (currentLevel == 1) return 0;
    return getXPForNextLevel(currentLevel - 1);
  }

  // Award XP to user
  Future<Map<String, dynamic>> awardXP({
    required int amount,
    required String source,
    String? binId,
    String? description,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get current user stats
    final profileResponse = await _supabaseService.client
        .from('profiles')
        .select('total_xp, current_level, last_log_date, streak_days')
        .eq('id', user.id)
        .single();

    final currentXP = (profileResponse['total_xp'] as int?) ?? 0;
    final currentLevel = (profileResponse['current_level'] as int?) ?? 1;
    final newXP = currentXP + amount;
    final newLevel = calculateLevel(newXP);

    // Update profile with new XP and level
    await _supabaseService.client.from('profiles').update({
      'total_xp': newXP,
      'current_level': newLevel,
    }).eq('id', user.id);

    // Update bin-level stats if binId is provided
    if (binId != null) {
      // Get or create user_bin_stats entry
      final binStatsResponse = await _supabaseService.client
          .from('user_bin_stats')
          .select('total_xp')
          .eq('user_id', user.id)
          .eq('bin_id', binId)
          .maybeSingle();

      final binXP = (binStatsResponse?['total_xp'] as int?) ?? 0;
      final newBinXP = binXP + amount;

      if (binStatsResponse != null) {
        // Update existing
        await _supabaseService.client
            .from('user_bin_stats')
            .update({
              'total_xp': newBinXP,
              'last_activity_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('bin_id', binId);
      } else {
        // Insert new
        await _supabaseService.client.from('user_bin_stats').insert({
          'user_id': user.id,
          'bin_id': binId,
          'total_xp': newBinXP,
          'last_activity_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // Record in XP history
    await _supabaseService.client.from('xp_history').insert({
      'user_id': user.id,
      'bin_id': binId,
      'xp_amount': amount,
      'source': source,
      'description': description,
    });

    return {
      'newXP': newXP,
      'newLevel': newLevel,
      'levelUp': newLevel > currentLevel,
      'xpGained': amount,
    };
  }

  // Award XP for logging activity
  Future<Map<String, dynamic>> awardXPForLog({
    required String binId,
    required String logType,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if this is first log of the day
    final today = DateTime.now();
    final profileResponse = await _supabaseService.client
        .from('profiles')
        .select('last_log_date, streak_days')
        .eq('id', user.id)
        .single();

    final lastLogDate = profileResponse['last_log_date'] != null
        ? DateTime.parse(profileResponse['last_log_date'])
        : null;
    final streakDays = (profileResponse['streak_days'] as int?) ?? 0;

    bool isFirstLogOfDay = false;
    int newStreakDays = streakDays;
    int bonusXP = 0;

    if (lastLogDate == null ||
        lastLogDate.year != today.year ||
        lastLogDate.month != today.month ||
        lastLogDate.day != today.day) {
      // First log of the day
      isFirstLogOfDay = true;
      bonusXP += xpFirstLogOfDay;

      // Check streak
      if (lastLogDate != null) {
        final daysDiff = today.difference(lastLogDate).inDays;
        if (daysDiff == 1) {
          // Continue streak
          newStreakDays = streakDays + 1;
        } else if (daysDiff > 1) {
          // Streak broken, reset
          newStreakDays = 1;
        } else {
          // Same day, don't change streak
          newStreakDays = streakDays;
        }
      } else {
        // First log ever
        newStreakDays = 1;
      }

      // Check for streak bonuses
      if (newStreakDays == 7) {
        bonusXP += xpStreak7Days;
      } else if (newStreakDays == 30) {
        bonusXP += xpStreak30Days;
      }

      // Update streak in profile
      await _supabaseService.client.from('profiles').update({
        'last_log_date': today.toIso8601String().split('T')[0],
        'streak_days': newStreakDays,
      }).eq('id', user.id);
    }

    // Calculate base XP based on log type
    int baseXP = logType.toLowerCase().contains('turn') ? xpTurnPile : xpLogActivity;
    int totalXP = baseXP + bonusXP;

    // Award XP
    final result = await awardXP(
      amount: totalXP,
      source: 'log_activity',
      binId: binId,
      description: isFirstLogOfDay
          ? 'Logged activity + streak bonus'
          : 'Logged activity',
    );

    // Update bin stats - increment logs count
    final binStatsResponse = await _supabaseService.client
        .from('user_bin_stats')
        .select('logs_count')
        .eq('user_id', user.id)
        .eq('bin_id', binId)
        .maybeSingle();

    final currentLogs = (binStatsResponse?['logs_count'] as int?) ?? 0;
    if (binStatsResponse != null) {
      // Update existing
      await _supabaseService.client
          .from('user_bin_stats')
          .update({'logs_count': currentLogs + 1})
          .eq('user_id', user.id)
          .eq('bin_id', binId);
    } else {
      // Insert new
      await _supabaseService.client.from('user_bin_stats').insert({
        'user_id': user.id,
        'bin_id': binId,
        'logs_count': 1,
      });
    }

    return {
      ...result,
      'streakDays': newStreakDays,
      'isFirstLogOfDay': isFirstLogOfDay,
      'bonusXP': bonusXP,
    };
  }

  // Award XP for completing a task
  Future<Map<String, dynamic>> awardXPForTaskCompletion({
    required String binId,
  }) async {
    final result = await awardXP(
      amount: xpCompleteTask,
      source: 'complete_task',
      binId: binId,
      description: 'Completed a task',
    );

    // Update bin stats - increment tasks completed
    final user = _supabaseService.currentUser;
    if (user != null) {
      final binStatsResponse = await _supabaseService.client
          .from('user_bin_stats')
          .select('tasks_completed')
          .eq('user_id', user.id)
          .eq('bin_id', binId)
          .maybeSingle();

      final currentTasks = (binStatsResponse?['tasks_completed'] as int?) ?? 0;
      if (binStatsResponse != null) {
        // Update existing
        await _supabaseService.client
            .from('user_bin_stats')
            .update({'tasks_completed': currentTasks + 1})
            .eq('user_id', user.id)
            .eq('bin_id', binId);
      } else {
        // Insert new
        await _supabaseService.client.from('user_bin_stats').insert({
          'user_id': user.id,
          'bin_id': binId,
          'tasks_completed': 1,
        });
      }
    }

    return result;
  }

  // Award XP for accepting a task
  Future<Map<String, dynamic>> awardXPForTaskAccept({
    required String binId,
  }) async {
    return await awardXP(
      amount: xpAcceptTask,
      source: 'accept_task',
      binId: binId,
      description: 'Accepted a task',
    );
  }

  // Award XP for posting a task
  Future<Map<String, dynamic>> awardXPForTaskPost({
    required String binId,
  }) async {
    return await awardXP(
      amount: xpPostTask,
      source: 'post_task',
      binId: binId,
      description: 'Posted a task',
    );
  }

  // Penalty for unassigning a task
  Future<Map<String, dynamic>> penaltyForUnassign({
    required String binId,
  }) async {
    return await awardXP(
      amount: xpUnassignPenalty,
      source: 'unassign_task',
      binId: binId,
      description: 'Unassigned a task',
    );
  }

  // Get user's XP and level
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabaseService.client
        .from('profiles')
        .select('total_xp, current_level, streak_days')
        .eq('id', user.id)
        .single();

    final totalXP = (response['total_xp'] as int?) ?? 0;
    final currentLevel = (response['current_level'] as int?) ?? 1;
    final streakDays = (response['streak_days'] as int?) ?? 0;

    final xpForCurrentLevel = getXPForCurrentLevel(currentLevel);
    final xpForNextLevel = getXPForNextLevel(currentLevel);
    final xpProgress = totalXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;

    return {
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'streakDays': streakDays,
      'xpProgress': xpProgress,
      'xpNeeded': xpNeeded,
      'xpForCurrentLevel': xpForCurrentLevel,
      'xpForNextLevel': xpForNextLevel,
    };
  }

  // Get bin leaderboard - shows all members ranked by XP
  Future<List<Map<String, dynamic>>> getBinLeaderboard(String binId) async {
    try {
      // Get bin owner
      final binResponse = await _supabaseService.client
          .from('bins')
          .select('user_id')
          .eq('id', binId)
          .maybeSingle();

      if (binResponse == null) {
        return [];
      }

      final ownerId = binResponse['user_id'] as String;

      // Get all bin members
      final membersResponse = await _supabaseService.client
          .from('bin_members')
          .select('user_id')
          .eq('bin_id', binId);

      // Collect all user IDs (owner + members)
      final userIds = <String>{ownerId};
      for (var member in membersResponse) {
        userIds.add(member['user_id'] as String);
      }

      if (userIds.isEmpty) {
        return [];
      }

      // Get profiles for all users
      final profilesResponse = await _supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .inFilter('id', userIds.toList());

      // Get XP stats for this bin
      final statsResponse = await _supabaseService.client
          .from('user_bin_stats')
          .select('user_id, total_xp, logs_count, tasks_completed')
          .eq('bin_id', binId)
          .inFilter('user_id', userIds.toList());

      // Create maps for quick lookup
      final profilesMap = <String, Map<String, dynamic>>{};
      for (var profile in profilesResponse) {
        profilesMap[profile['id'] as String] = profile;
      }

      final statsMap = <String, Map<String, dynamic>>{};
      for (var stat in statsResponse) {
        statsMap[stat['user_id'] as String] = stat;
      }

      // Build leaderboard entries for all members
      final leaderboard = <Map<String, dynamic>>[];
      for (var userId in userIds) {
        final profile = profilesMap[userId];
        final stat = statsMap[userId];
        
        final totalXP = (stat?['total_xp'] as int?) ?? 0;
        final logsCount = (stat?['logs_count'] as int?) ?? 0;
        final tasksCompleted = (stat?['tasks_completed'] as int?) ?? 0;
        
        final firstName = profile?['first_name'] as String? ?? '';
        final lastName = profile?['last_name'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        
        leaderboard.add({
          'user_id': userId,
          'total_xp': totalXP,
          'logs_count': logsCount,
          'tasks_completed': tasksCompleted,
          'profiles': profile,
          '_sort_name': fullName.toLowerCase(), // For alphabetical sorting
        });
      }

      // Sort by XP (descending), then alphabetically by name
      leaderboard.sort((a, b) {
        final xpA = a['total_xp'] as int;
        final xpB = b['total_xp'] as int;
        if (xpA != xpB) {
          return xpB.compareTo(xpA); // Descending by XP
        }
        // If XP is equal, sort alphabetically
        final nameA = a['_sort_name'] as String;
        final nameB = b['_sort_name'] as String;
        return nameA.compareTo(nameB);
      });

      // Remove the sort helper field
      for (var entry in leaderboard) {
        entry.remove('_sort_name');
      }

      return leaderboard;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Get user's badges
  Future<List<Map<String, dynamic>>> getUserBadges() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabaseService.client
        .from('user_badges')
        .select('*')
        .eq('user_id', user.id)
        .order('earned_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get badge progress stats (total logs, tasks, streak)
  Future<Map<String, int>> getBadgeProgressStats() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get streak from profile
    final profileResponse = await _supabaseService.client
        .from('profiles')
        .select('streak_days')
        .eq('id', user.id)
        .single();

    final streakDays = (profileResponse['streak_days'] as int?) ?? 0;

    // Get bin stats for activity badges
    final binStatsResponse = await _supabaseService.client
        .from('user_bin_stats')
        .select('logs_count, tasks_completed')
        .eq('user_id', user.id);

    int totalLogs = 0;
    int totalTasks = 0;
    for (var stat in binStatsResponse) {
      totalLogs += (stat['logs_count'] as int?) ?? 0;
      totalTasks += (stat['tasks_completed'] as int?) ?? 0;
    }

    return {
      'totalLogs': totalLogs,
      'totalTasks': totalTasks,
      'streakDays': streakDays,
    };
  }

  // Check and award badges (call this after XP is awarded)
  Future<List<String>> checkAndAwardBadges() async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get user stats
    final stats = await getUserStats();
    final totalXP = stats['totalXP'] as int;
    final currentLevel = stats['currentLevel'] as int;

    // Get bin stats for activity badges
    final binStatsResponse = await _supabaseService.client
        .from('user_bin_stats')
        .select('logs_count, tasks_completed')
        .eq('user_id', user.id);

    int totalLogs = 0;
    int totalTasks = 0;
    for (var stat in binStatsResponse) {
      totalLogs += (stat['logs_count'] as int?) ?? 0;
      totalTasks += (stat['tasks_completed'] as int?) ?? 0;
    }

    final streakDays = stats['streakDays'] as int;

    // Get existing badges
    final existingBadges = await getUserBadges();
    final existingBadgeIds = existingBadges.map((b) => b['badge_id'] as String).toSet();

    final newBadges = <String>[];

    // Check activity badges
    if (totalLogs >= 1 && !existingBadgeIds.contains('first_log')) {
      await _awardBadge('first_log', 'First Steps', 'Logged your first activity');
      newBadges.add('first_log');
    }
    if (totalLogs >= 10 && !existingBadgeIds.contains('log_10')) {
      await _awardBadge('log_10', 'Dedicated Logger', 'Logged 10 activities');
      newBadges.add('log_10');
    }
    if (totalLogs >= 50 && !existingBadgeIds.contains('log_50')) {
      await _awardBadge('log_50', 'On Fire', 'Logged 50 activities');
      newBadges.add('log_50');
    }
    if (totalLogs >= 100 && !existingBadgeIds.contains('log_100')) {
      await _awardBadge('log_100', 'Data Master', 'Logged 100 activities');
      newBadges.add('log_100');
    }

    // Check task badges
    if (totalTasks >= 1 && !existingBadgeIds.contains('complete_1')) {
      await _awardBadge('complete_1', 'Helper', 'Completed 1 task');
      newBadges.add('complete_1');
    }
    if (totalTasks >= 5 && !existingBadgeIds.contains('complete_5')) {
      await _awardBadge('complete_5', 'Team Player', 'Completed 5 tasks');
      newBadges.add('complete_5');
    }
    if (totalTasks >= 10 && !existingBadgeIds.contains('complete_10')) {
      await _awardBadge('complete_10', 'Task Master', 'Completed 10 tasks');
      newBadges.add('complete_10');
    }
    if (totalTasks >= 25 && !existingBadgeIds.contains('complete_25')) {
      await _awardBadge('complete_25', 'Community Hero', 'Completed 25 tasks');
      newBadges.add('complete_25');
    }

    // Check streak badges
    if (streakDays >= 3 && !existingBadgeIds.contains('streak_3')) {
      await _awardBadge('streak_3', '3-Day Streak', 'Logged 3 days in a row');
      newBadges.add('streak_3');
    }
    if (streakDays >= 7 && !existingBadgeIds.contains('streak_7')) {
      await _awardBadge('streak_7', 'Week Warrior', '7-day streak');
      newBadges.add('streak_7');
    }
    if (streakDays >= 30 && !existingBadgeIds.contains('streak_30')) {
      await _awardBadge('streak_30', 'Month Master', '30-day streak');
      newBadges.add('streak_30');
    }
    if (streakDays >= 100 && !existingBadgeIds.contains('streak_100')) {
      await _awardBadge('streak_100', 'Consistency King', '100-day streak');
      newBadges.add('streak_100');
    }

    return newBadges;
  }

  Future<void> _awardBadge(String badgeId, String badgeName, String description) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    await _supabaseService.client.from('user_badges').insert({
      'user_id': user.id,
      'badge_id': badgeId,
    });
  }
}

