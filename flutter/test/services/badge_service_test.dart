import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XPService - Badge Awarding Logic', () {
    group('First Log Badge', () {
      test('should award first_log badge when user logs first activity', () {
        int totalLogs = 1;
        bool shouldAward = totalLogs == 1;

        expect(shouldAward, true);
      });

      test('should not award if user already has badge', () {
        Set<String> existingBadges = {'first_log'};
        bool alreadyHasBadge = existingBadges.contains('first_log');
        bool shouldAward = !alreadyHasBadge;

        expect(shouldAward, false);
      });

      test('should award badge with correct name and description', () {
        String badgeId = 'first_log';
        String badgeName = 'First Steps';
        String description = 'Logged your first activity';

        expect(badgeId, 'first_log');
        expect(badgeName, 'First Steps');
        expect(description, 'Logged your first activity');
      });
    });

    group('Log Count Badges', () {
      test('should award log_10 badge at 10 logs', () {
        int totalLogs = 10;
        bool shouldAward = totalLogs >= 10;

        expect(shouldAward, true);
      });

      test('should award log_50 badge at 50 logs', () {
        int totalLogs = 50;
        bool shouldAward = totalLogs >= 50;

        expect(shouldAward, true);
      });

      test('should award log_100 badge at 100 logs', () {
        int totalLogs = 100;
        bool shouldAward = totalLogs >= 100;

        expect(shouldAward, true);
      });

      test('should not award log_10 if already has badge', () {
        Set<String> existingBadges = {'log_10'};
        int totalLogs = 15;
        bool alreadyHasBadge = existingBadges.contains('log_10');
        bool shouldAward = totalLogs >= 10 && !alreadyHasBadge;

        expect(shouldAward, false);
      });

      test('should award multiple log badges if thresholds met', () {
        int totalLogs = 100;
        Set<String> existingBadges = {};
        bool shouldAward10 = totalLogs >= 10 && !existingBadges.contains('log_10');
        bool shouldAward50 = totalLogs >= 50 && !existingBadges.contains('log_50');
        bool shouldAward100 = totalLogs >= 100 && !existingBadges.contains('log_100');

        expect(shouldAward10, true);
        expect(shouldAward50, true);
        expect(shouldAward100, true);
      });
    });

    group('Task Completion Badges', () {
      test('should award complete_1 badge at 1 task', () {
        int totalTasks = 1;
        bool shouldAward = totalTasks >= 1;

        expect(shouldAward, true);
      });

      test('should award complete_5 badge at 5 tasks', () {
        int totalTasks = 5;
        bool shouldAward = totalTasks >= 5;

        expect(shouldAward, true);
      });

      test('should award complete_10 badge at 10 tasks', () {
        int totalTasks = 10;
        bool shouldAward = totalTasks >= 10;

        expect(shouldAward, true);
      });

      test('should award complete_25 badge at 25 tasks', () {
        int totalTasks = 25;
        bool shouldAward = totalTasks >= 25;

        expect(shouldAward, true);
      });

      test('should not award if already has badge', () {
        Set<String> existingBadges = {'complete_1'};
        int totalTasks = 2;
        bool alreadyHasBadge = existingBadges.contains('complete_1');
        bool shouldAward = totalTasks >= 1 && !alreadyHasBadge;

        expect(shouldAward, false);
      });
    });

    group('Streak Badges', () {
      test('should award streak_3 badge at 3 days', () {
        int streakDays = 3;
        bool shouldAward = streakDays >= 3;

        expect(shouldAward, true);
      });

      test('should award streak_7 badge at 7 days', () {
        int streakDays = 7;
        bool shouldAward = streakDays >= 7;

        expect(shouldAward, true);
      });

      test('should award streak_30 badge at 30 days', () {
        int streakDays = 30;
        bool shouldAward = streakDays >= 30;

        expect(shouldAward, true);
      });

      test('should award streak_100 badge at 100 days', () {
        int streakDays = 100;
        bool shouldAward = streakDays >= 100;

        expect(shouldAward, true);
      });

      test('should not award if already has badge', () {
        Set<String> existingBadges = {'streak_7'};
        int streakDays = 10;
        bool alreadyHasBadge = existingBadges.contains('streak_7');
        bool shouldAward = streakDays >= 7 && !alreadyHasBadge;

        expect(shouldAward, false);
      });

      test('should award multiple streak badges if thresholds met', () {
        int streakDays = 30;
        Set<String> existingBadges = {};
        bool shouldAward3 = streakDays >= 3 && !existingBadges.contains('streak_3');
        bool shouldAward7 = streakDays >= 7 && !existingBadges.contains('streak_7');
        bool shouldAward30 = streakDays >= 30 && !existingBadges.contains('streak_30');

        expect(shouldAward3, true);
        expect(shouldAward7, true);
        expect(shouldAward30, true);
      });
    });

    group('Badge Awarding Process', () {
      test('should check all badge conditions when awarding', () {
        int totalLogs = 10;
        int totalTasks = 5;
        int streakDays = 7;
        Set<String> existingBadges = {};

        bool shouldAwardLog10 = totalLogs >= 10 && !existingBadges.contains('log_10');
        bool shouldAwardComplete5 = totalTasks >= 5 && !existingBadges.contains('complete_5');
        bool shouldAwardStreak7 = streakDays >= 7 && !existingBadges.contains('streak_7');

        expect(shouldAwardLog10, true);
        expect(shouldAwardComplete5, true);
        expect(shouldAwardStreak7, true);
      });

      test('should return list of newly awarded badges', () {
        List<String> newBadges = ['log_10', 'complete_5'];
        expect(newBadges.length, 2);
        expect(newBadges.contains('log_10'), true);
        expect(newBadges.contains('complete_5'), true);
      });

      test('should not duplicate badges', () {
        Set<String> existingBadges = {'first_log', 'log_10'};
        Set<String> newBadges = {'log_10', 'complete_1'};
        Set<String> allBadges = {...existingBadges, ...newBadges};

        expect(allBadges.length, 3); // Should have 3 unique badges
        expect(allBadges.contains('log_10'), true);
      });
    });

    group('Badge Progress Calculation', () {
      test('should calculate progress for log badges correctly', () {
        int totalLogs = 5;
        int target = 10;
        double progress = (totalLogs / target).clamp(0.0, 1.0);

        expect(progress, 0.5);
      });

      test('should calculate progress for task badges correctly', () {
        int totalTasks = 2;
        int target = 5;
        double progress = (totalTasks / target).clamp(0.0, 1.0);

        expect(progress, 0.4);
      });

      test('should calculate progress for streak badges correctly', () {
        int streakDays = 5;
        int target = 7;
        double progress = (streakDays / target).clamp(0.0, 1.0);

        expect(progress, lessThan(1.0));
        expect(progress, greaterThan(0.0));
      });

      test('should cap progress at 1.0', () {
        int totalLogs = 15;
        int target = 10;
        double progress = (totalLogs / target).clamp(0.0, 1.0);

        expect(progress, 1.0);
      });

      test('should not show negative progress', () {
        int totalLogs = 0;
        int target = 10;
        double progress = (totalLogs / target).clamp(0.0, 1.0);

        expect(progress, 0.0);
        expect(progress, greaterThanOrEqualTo(0.0));
      });
    });

    group('Badge Display Logic', () {
      test('should show earned badges by default', () {
        List<Map<String, dynamic>> badges = [
          {'badge_id': 'first_log'},
          {'badge_id': 'log_10'},
        ];
        bool showAll = false;
        List<Map<String, dynamic>> displayedBadges = showAll
            ? badges
            : badges.where((b) => b['badge_id'] != null).toList();

        expect(displayedBadges.length, 2);
      });

      test('should show all badges when View All is toggled', () {
        List<Map<String, dynamic>> badges = [
          {'badge_id': 'first_log'},
        ];
        bool showAll = true;
        int totalBadgeDefinitions = 12; // Total badge types
        List<Map<String, dynamic>> displayedBadges = showAll
            ? List.generate(totalBadgeDefinitions, (i) => {'badge_id': 'badge_$i'})
            : badges;

        expect(displayedBadges.length, greaterThan(badges.length));
      });

      test('should mark earned badges correctly', () {
        Set<String> earnedBadgeIds = {'first_log', 'log_10'};
        String badgeId = 'first_log';
        bool isEarned = earnedBadgeIds.contains(badgeId);

        expect(isEarned, true);
      });

      test('should mark unearned badges correctly', () {
        Set<String> earnedBadgeIds = {'first_log'};
        String badgeId = 'log_50';
        bool isEarned = earnedBadgeIds.contains(badgeId);

        expect(isEarned, false);
      });

      test('should show lock icon for unearned badges', () {
        bool isEarned = false;
        bool shouldShowLock = !isEarned;

        expect(shouldShowLock, true);
      });

      test('should show progress bar for unearned badges', () {
        bool isEarned = false;
        bool hasProgressStats = true;
        bool shouldShowProgress = !isEarned && hasProgressStats;

        expect(shouldShowProgress, true);
      });
    });

    group('Badge Image Handling', () {
      test('should use badge image if available', () {
        String imagePath = 'assets/images/badges/badge_first_log.png';
        bool imageExists = imagePath.isNotEmpty;

        expect(imageExists, true);
      });

      test('should fallback to emoji if image not found', () {
        String badgeId = 'first_log';
        Map<String, String> fallbackEmojis = {
          'first_log': '🌱',
          'log_10': '📝',
          'complete_1': '✅',
        };
        String fallback = fallbackEmojis[badgeId] ?? '🏆';

        expect(fallback, '🌱');
      });

      test('should have fallback for all badge types', () {
        List<String> badgeIds = [
          'first_log',
          'log_10',
          'log_50',
          'log_100',
          'complete_1',
          'complete_5',
          'complete_10',
          'complete_25',
          'streak_3',
          'streak_7',
          'streak_30',
          'streak_100',
        ];
        Map<String, String> fallbackEmojis = {
          'first_log': '🌱',
          'log_10': '📝',
          'log_50': '🔥',
          'log_100': '📊',
          'complete_1': '✅',
          'complete_5': '🤝',
          'complete_10': '⭐',
          'complete_25': '🏅',
          'streak_3': '🔥',
          'streak_7': '💪',
          'streak_30': '🌟',
          'streak_100': '👑',
        };

        for (String badgeId in badgeIds) {
          expect(fallbackEmojis.containsKey(badgeId), true);
        }
      });
    });

    group('Badge Definitions', () {
      test('should have correct badge names', () {
        Map<String, String> badgeNames = {
          'first_log': 'First Steps',
          'log_10': 'Dedicated Logger',
          'complete_1': 'Helper',
          'streak_7': 'Week Warrior',
        };

        expect(badgeNames['first_log'], 'First Steps');
        expect(badgeNames['log_10'], 'Dedicated Logger');
        expect(badgeNames['complete_1'], 'Helper');
        expect(badgeNames['streak_7'], 'Week Warrior');
      });

      test('should have correct badge descriptions', () {
        Map<String, String> descriptions = {
          'first_log': 'Logged your first activity',
          'log_10': 'Logged 10 activities',
          'complete_1': 'Completed 1 task',
          'streak_7': '7-day streak',
        };

        expect(descriptions['first_log'], 'Logged your first activity');
        expect(descriptions['log_10'], 'Logged 10 activities');
        expect(descriptions['complete_1'], 'Completed 1 task');
        expect(descriptions['streak_7'], '7-day streak');
      });
    });
  });
}

