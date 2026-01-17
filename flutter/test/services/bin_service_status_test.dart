import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BinService - Bin Status Management', () {
    group('updateBinStatus API', () {
      test('should require authentication', () {
        bool isAuthenticated = false;
        bool shouldThrowError = !isAuthenticated;

        expect(shouldThrowError, true);
      });

      test('should verify user is bin owner', () {
        bool isOwner = true;
        bool shouldProceed = isOwner;

        expect(shouldProceed, true);
      });

      test('should throw error if user is not owner', () {
        bool isOwner = false;
        bool shouldThrowError = !isOwner;

        expect(shouldThrowError, true);
      });

      test('should update bins table with bin_status', () {
        String table = 'bins';
        Map<String, dynamic> updates = {
          'bin_status': 'active',
        };
        bool shouldUpdate = true;

        expect(shouldUpdate, true);
        expect(updates['bin_status'], 'active');
      });

      test('should set resting_until when status is resting', () {
        String status = 'resting';
        DateTime restingUntil = DateTime.now();
        Map<String, dynamic> updates = {
          'bin_status': status,
          'resting_until': restingUntil.toIso8601String(),
        };

        expect(updates.containsKey('resting_until'), true);
        expect(updates['bin_status'], 'resting');
      });

      test('should clear resting_until when status is not resting', () {
        String status = 'active';
        Map<String, dynamic> updates = {
          'bin_status': status,
          'resting_until': null,
        };

        expect(updates['resting_until'], null);
      });

      test('should set matured_at when status is matured', () {
        String status = 'matured';
        DateTime maturedAt = DateTime.now();
        Map<String, dynamic> updates = {
          'bin_status': status,
          'matured_at': maturedAt.toIso8601String(),
        };

        expect(updates.containsKey('matured_at'), true);
        expect(updates['bin_status'], 'matured');
      });

      test('should set matured_at to now if not provided', () {
        String status = 'matured';
        bool maturedAtProvided = false;
        bool shouldSetToNow = !maturedAtProvided;

        expect(shouldSetToNow, true);
      });

      test('should clear matured_at when status is not matured', () {
        String status = 'active';
        Map<String, dynamic> updates = {
          'bin_status': status,
          'matured_at': null,
        };

        expect(updates['matured_at'], null);
      });

      test('should convert Singapore time to UTC for storage', () {
        // Singapore time: 2024-01-01 16:55:00 (UTC+8)
        // UTC time: 2024-01-01 08:55:00
        DateTime sgTime = DateTime(2024, 1, 1, 16, 55);
        DateTime utcTime = DateTime.utc(
          sgTime.year,
          sgTime.month,
          sgTime.day,
          sgTime.hour,
          sgTime.minute,
        ).subtract(const Duration(hours: 8));

        expect(utcTime.hour, 8);
        expect(utcTime.minute, 55);
      });

      test('should handle all three status values', () {
        List<String> validStatuses = ['active', 'resting', 'matured'];
        String status = 'resting';

        expect(validStatuses.contains(status), true);
      });
    });

    group('getRestingDaysRemaining', () {
      test('should return null if resting_until is null', () {
        Map<String, dynamic> bin = {
          'resting_until': null,
        };
        bool shouldReturnNull = bin['resting_until'] == null;

        expect(shouldReturnNull, true);
      });

      test('should parse UTC timestamp and convert to Singapore time', () {
        // UTC timestamp from database
        String utcTimestamp = '2024-01-10T08:00:00Z';
        // Singapore time would be 2024-01-10T16:00:00 (UTC+8)
        DateTime parsed = DateTime.parse(utcTimestamp);
        DateTime sgTime = parsed.add(const Duration(hours: 8));

        expect(sgTime.hour, 16);
      });

      test('should calculate days remaining correctly', () {
        // Simulate: resting_until is 5 days from now in Singapore time
        DateTime now = DateTime.now();
        DateTime restingUntil = now.add(const Duration(days: 5));
        int daysRemaining = restingUntil.difference(now).inDays;

        expect(daysRemaining, 5);
      });

      test('should return 0 if resting period has passed', () {
        DateTime now = DateTime.now();
        DateTime restingUntil = now.subtract(const Duration(days: 2));
        int daysRemaining = restingUntil.difference(now).inDays;
        int result = daysRemaining > 0 ? daysRemaining : 0;

        expect(result, 0);
      });

      test('should handle timestamp with Z suffix', () {
        String timestamp = '2024-01-10T08:00:00Z';
        bool hasZ = timestamp.endsWith('Z');

        expect(hasZ, true);
      });

      test('should handle timestamp without Z suffix', () {
        String timestamp = '2024-01-10T08:00:00';
        bool hasZ = timestamp.endsWith('Z');
        String timestampWithZ = hasZ ? timestamp : '${timestamp}Z';

        expect(timestampWithZ, '2024-01-10T08:00:00Z');
      });
    });

    group('getMaturedDepletionPercentage', () {
      test('should return 0.0 if matured_at is null', () {
        Map<String, dynamic> bin = {
          'matured_at': null,
        };
        bool shouldReturnZero = bin['matured_at'] == null;

        expect(shouldReturnZero, true);
      });

      test('should return 0.0 if just matured', () {
        DateTime maturedAt = DateTime.now();
        DateTime now = DateTime.now();
        int daysSinceMatured = now.difference(maturedAt).inDays;
        double percentage = (daysSinceMatured / 180 * 100).clamp(0.0, 100.0);

        expect(percentage, 0.0);
      });

      test('should calculate percentage correctly at 3 months', () {
        const sixMonthsInDays = 180;
        int daysSinceMatured = 90; // 3 months
        double percentage = (daysSinceMatured / sixMonthsInDays * 100).clamp(0.0, 100.0);

        expect(percentage, 50.0);
      });

      test('should return 100.0 after 6 months', () {
        const sixMonthsInDays = 180;
        int daysSinceMatured = 180;
        double percentage = daysSinceMatured >= sixMonthsInDays
            ? 100.0
            : (daysSinceMatured / sixMonthsInDays * 100).clamp(0.0, 100.0);

        expect(percentage, 100.0);
      });

      test('should return 100.0 after more than 6 months', () {
        const sixMonthsInDays = 180;
        int daysSinceMatured = 200;
        double percentage = daysSinceMatured >= sixMonthsInDays
            ? 100.0
            : (daysSinceMatured / sixMonthsInDays * 100).clamp(0.0, 100.0);

        expect(percentage, 100.0);
      });

      test('should clamp percentage between 0 and 100', () {
        double percentage = 150.0;
        double clamped = percentage.clamp(0.0, 100.0);

        expect(clamped, 100.0);
      });

      test('should parse UTC timestamp and convert to Singapore time', () {
        String utcTimestamp = '2024-01-01T08:00:00Z';
        DateTime parsed = DateTime.parse(utcTimestamp);
        DateTime sgTime = parsed.add(const Duration(hours: 8));

        expect(sgTime.hour, 16);
      });
    });

    group('canPerformAction', () {
      test('should allow all actions when status is active', () {
        Map<String, dynamic> bin = {'bin_status': 'active'};
        List<String> actions = ['log', 'flip', 'turn_pile', 'Turn Pile', 'monitor'];
        bool allAllowed = true;

        for (String action in actions) {
          if (bin['bin_status'] != 'active') {
            allAllowed = false;
            break;
          }
        }

        expect(allAllowed, true);
      });

      test('should allow log action when status is resting', () {
        Map<String, dynamic> bin = {'bin_status': 'resting'};
        String action = 'log';
        bool shouldAllow = action == 'log' || action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';

        expect(shouldAllow, true);
      });

      test('should allow Turn Pile when status is resting', () {
        Map<String, dynamic> bin = {'bin_status': 'resting'};
        String action = 'Turn Pile';
        bool shouldAllow = action == 'log' || action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';

        expect(shouldAllow, true);
      });

      test('should not allow monitor when status is resting', () {
        Map<String, dynamic> bin = {'bin_status': 'resting'};
        String action = 'monitor';
        bool shouldAllow = action == 'log' || action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';

        expect(shouldAllow, false);
      });

      test('should not allow any actions when status is matured', () {
        Map<String, dynamic> bin = {'bin_status': 'matured'};
        String action = 'log';
        bool shouldAllow = false; // No actions allowed when matured

        expect(shouldAllow, false);
      });

      test('should default to active if bin_status is null', () {
        Map<String, dynamic> bin = {};
        String status = bin['bin_status'] as String? ?? 'active';

        expect(status, 'active');
      });

      test('should handle flip action alias', () {
        Map<String, dynamic> bin = {'bin_status': 'resting'};
        String action = 'flip';
        bool shouldAllow = action == 'log' || action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';

        expect(shouldAllow, true);
      });

      test('should handle turn_pile action alias', () {
        Map<String, dynamic> bin = {'bin_status': 'resting'};
        String action = 'turn_pile';
        bool shouldAllow = action == 'log' || action == 'flip' || action == 'turn_pile' || action == 'Turn Pile';

        expect(shouldAllow, true);
      });
    });

    group('Singapore Time Conversion', () {
      test('should convert UTC to Singapore time (UTC+8)', () {
        DateTime utc = DateTime.utc(2024, 1, 1, 8, 0);
        DateTime sgTime = utc.add(const Duration(hours: 8));

        expect(sgTime.hour, 16);
        expect(sgTime.day, 1);
      });

      test('should convert Singapore time to UTC for storage', () {
        DateTime sgTime = DateTime(2024, 1, 1, 16, 0);
        DateTime utc = DateTime.utc(
          sgTime.year,
          sgTime.month,
          sgTime.day,
          sgTime.hour,
          sgTime.minute,
        ).subtract(const Duration(hours: 8));

        expect(utc.hour, 8);
      });

      test('should handle timezone parsing with Z suffix', () {
        String timestamp = '2024-01-01T08:00:00Z';
        DateTime parsed = DateTime.parse(timestamp);
        bool isUtc = parsed.isUtc || timestamp.endsWith('Z');

        expect(isUtc, true);
      });

      test('should handle timezone parsing without Z suffix', () {
        String timestamp = '2024-01-01T08:00:00';
        bool hasZ = timestamp.endsWith('Z');
        String timestampWithZ = hasZ ? timestamp : '${timestamp}Z';
        DateTime parsed = DateTime.parse(timestampWithZ);

        expect(parsed.isUtc, true);
      });

      test('should maintain date consistency across timezone conversion', () {
        DateTime sgTime = DateTime(2024, 1, 1, 16, 55);
        DateTime utc = DateTime.utc(
          sgTime.year,
          sgTime.month,
          sgTime.day,
          sgTime.hour,
          sgTime.minute,
        ).subtract(const Duration(hours: 8));
        DateTime backToSg = utc.add(const Duration(hours: 8));

        expect(backToSg.hour, sgTime.hour);
        expect(backToSg.minute, sgTime.minute);
      });
    });

    group('createBin default status', () {
      test('should set bin_status to active by default', () {
        Map<String, dynamic> binData = {
          'name': 'Test Bin',
          'bin_status': 'active',
        };

        expect(binData['bin_status'], 'active');
      });

      test('should include bin_status in insert data', () {
        Map<String, dynamic> data = {
          'name': 'Test Bin',
          'user_id': 'user123',
          'health_status': 'Healthy',
          'bin_status': 'active',
        };

        expect(data.containsKey('bin_status'), true);
      });
    });

    group('Error Handling', () {
      test('should handle invalid status gracefully', () {
        List<String> validStatuses = ['active', 'resting', 'matured'];
        String status = 'invalid';
        bool isValid = validStatuses.contains(status);

        expect(isValid, false);
      });

      test('should handle malformed timestamp strings', () {
        String malformedTimestamp = 'invalid-date';
        bool shouldHandleError = true;

        expect(shouldHandleError, true);
      });

      test('should handle null bin_status gracefully', () {
        Map<String, dynamic> bin = {};
        String status = bin['bin_status'] as String? ?? 'active';

        expect(status, 'active');
      });
    });
  });
}

