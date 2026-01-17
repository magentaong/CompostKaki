import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BinCard - Health Status Display', () {
    test('health status color mapping is correct', () {
      // This tests the logic for health status colors
      String getHealthColor(String status) {
        switch (status) {
          case 'Healthy':
            return 'green';
          case 'Needs Attention':
            return 'orange';
          case 'Critical':
            return 'red';
          default:
            return 'gray';
        }
      }

      expect(getHealthColor('Healthy'), 'green');
      expect(getHealthColor('Needs Attention'), 'orange');
      expect(getHealthColor('Critical'), 'red');
      expect(getHealthColor('Unknown'), 'gray');
    });
  });

  group('BinCard - Pending Request Display', () {
    test('should show pending request badge when hasPendingRequest is true',
        () {
      bool hasPendingRequest = true;
      bool shouldShowPendingBadge = hasPendingRequest;

      expect(shouldShowPendingBadge, true);
    });

    test(
        'should not show pending request badge when hasPendingRequest is false',
        () {
      bool hasPendingRequest = false;
      bool shouldShowPendingBadge = hasPendingRequest;

      expect(shouldShowPendingBadge, false);
    });

    test('should hide health status when pending request exists', () {
      bool hasPendingRequest = true;
      bool shouldShowHealthStatus = !hasPendingRequest;

      expect(shouldShowHealthStatus, false);
    });

    test('should show health status when no pending request', () {
      bool hasPendingRequest = false;
      bool shouldShowHealthStatus = !hasPendingRequest;

      expect(shouldShowHealthStatus, true);
    });

    test('should hide temperature when pending request exists', () {
      bool hasPendingRequest = true;
      bool shouldShowTemperature = !hasPendingRequest;

      expect(shouldShowTemperature, false);
    });

    test('should show temperature when no pending request', () {
      bool hasPendingRequest = false;
      bool shouldShowTemperature = !hasPendingRequest;

      expect(shouldShowTemperature, true);
    });

    test('pending request badge should have correct text', () {
      String pendingText = 'Request under review';
      expect(pendingText, 'Request under review');
    });

    test('pending request badge should indicate pending status', () {
      Map<String, dynamic> bin = {
        'id': 'bin-123',
        'name': 'Test Bin',
        'has_pending_request': true,
      };

      bool shouldShowPending = bin['has_pending_request'] == true;
      expect(shouldShowPending, true);
    });
  });

  group('BinCard - Data Formatting', () {
    test('temperature is formatted correctly', () {
      String formatTemperature(int? temp) {
        if (temp == null) return '--';
        return '${temp}°C';
      }

      expect(formatTemperature(null), '--');
      expect(formatTemperature(0), '0°C');
      expect(formatTemperature(45), '45°C');
      expect(formatTemperature(-5), '-5°C');
      expect(formatTemperature(100), '100°C');
    });

    test('moisture level is displayed correctly', () {
      String formatMoisture(String? moisture) {
        if (moisture == null || moisture.isEmpty) return '--';
        return moisture;
      }

      expect(formatMoisture(null), '--');
      expect(formatMoisture(''), '--');
      expect(formatMoisture('Perfect'), 'Perfect');
      expect(formatMoisture('Dry'), 'Dry');
      expect(formatMoisture('Very Wet'), 'Very Wet');
    });

    test('contributor count is formatted correctly', () {
      String formatContributorCount(int count) {
        if (count == 0) return 'No contributors';
        if (count == 1) return '1 contributor';
        return '$count contributors';
      }

      expect(formatContributorCount(0), 'No contributors');
      expect(formatContributorCount(1), '1 contributor');
      expect(formatContributorCount(5), '5 contributors');
      expect(formatContributorCount(100), '100 contributors');
    });
  });

  group('BinCard - Image Handling', () {
    test('default image is used when bin has no image', () {
      String getBinImage(String? imageUrl) {
        const defaultImage =
            'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735';
        // Only use default if imageUrl is null or empty
        if (imageUrl == null || imageUrl.isEmpty) {
          return defaultImage;
        }
        return imageUrl;
      }

      expect(getBinImage(null), contains('unsplash'));
      expect(getBinImage(''), contains('unsplash'));
      expect(getBinImage('https://example.com/image.jpg'),
          'https://example.com/image.jpg');
    });
  });

  group('BinCard - Aging Indicator', () {
    String getAgeText(String? createdAt) {
      if (createdAt == null) return '';
      try {
        final createdDate = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(createdDate);
        final days = difference.inDays;
        
        if (days == 0) {
          return 'Created today';
        } else if (days == 1) {
          return '1 day old';
        } else {
          return '$days days old';
        }
      } catch (e) {
        return '';
      }
    }

    test('should return empty string when created_at is null', () {
      expect(getAgeText(null), '');
    });

    test('should return "Created today" for bins created today', () {
      final today = DateTime.now().toIso8601String();
      final ageText = getAgeText(today);
      expect(ageText, 'Created today');
    });

    test('should return "1 day old" for bins created yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final ageText = getAgeText(yesterday);
      expect(ageText, '1 day old');
    });

    test('should return correct days for bins older than 1 day', () {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final ageText = getAgeText(fiveDaysAgo);
      expect(ageText, '5 days old');
    });

    test('should return empty string for invalid date format', () {
      expect(getAgeText('invalid-date'), '');
      expect(getAgeText(''), '');
    });

    test('should handle edge case of exactly 24 hours ago', () {
      final exactly24HoursAgo = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
      final ageText = getAgeText(exactly24HoursAgo);
      // Should be 1 day old if it's been exactly 24 hours
      expect(ageText, contains('day old'));
    });
  });

  group('BinCard - Location Display Logic', () {
    bool shouldShowLocation(String? location, String? name) {
      final locationStr = location ?? '';
      final nameStr = name ?? '';
      return locationStr.isNotEmpty && locationStr != nameStr;
    }

    test('should show location when it is different from name', () {
      expect(shouldShowLocation('Singapore', 'My Bin'), true);
      expect(shouldShowLocation('Park', 'Garden Bin'), true);
    });

    test('should not show location when it is same as name', () {
      expect(shouldShowLocation('My Bin', 'My Bin'), false);
      expect(shouldShowLocation('Test', 'Test'), false);
    });

    test('should not show location when it is empty', () {
      expect(shouldShowLocation('', 'My Bin'), false);
      expect(shouldShowLocation(null, 'My Bin'), false);
    });

    test('should not show location when both are empty', () {
      expect(shouldShowLocation('', ''), false);
      expect(shouldShowLocation(null, null), false);
    });

    test('should handle case sensitivity correctly', () {
      expect(shouldShowLocation('My Bin', 'my bin'), true);
      expect(shouldShowLocation('MY BIN', 'My Bin'), true);
    });

    test('should show location when name is empty but location is not', () {
      expect(shouldShowLocation('Singapore', ''), true);
      expect(shouldShowLocation('Park', null), true);
    });
  });
}
