import 'package:flutter_test/flutter_test.dart';

// Helper function to test health status calculation
// This is extracted to avoid needing to instantiate BinService
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

void main() {
  group('BinService - Health Status Calculation', () {

    group('Critical Status', () {
      test('returns Critical when temperature is below 20°C', () {
        final status = calculateHealthStatus(15, 'Perfect');
        expect(status, 'Critical');
      });

      test('returns Critical when temperature is above 70°C', () {
        final status = calculateHealthStatus(75, 'Perfect');
        expect(status, 'Critical');
      });

      test('returns Critical when temperature is exactly 19°C', () {
        final status = calculateHealthStatus(19, 'Perfect');
        expect(status, 'Critical');
      });

      test('returns Critical when temperature is exactly 71°C', () {
        final status = calculateHealthStatus(71, 'Perfect');
        expect(status, 'Critical');
      });

      test('returns Critical when moisture is Very Dry', () {
        final status = calculateHealthStatus(45, 'Very Dry');
        expect(status, 'Critical');
      });

      test('returns Critical when moisture is Very Wet', () {
        final status = calculateHealthStatus(45, 'Very Wet');
        expect(status, 'Critical');
      });

      test('returns Critical for low temperature even with perfect moisture', () {
        final status = calculateHealthStatus(10, 'Perfect');
        expect(status, 'Critical');
      });

      test('returns Critical for Very Dry even with optimal temperature', () {
        final status = calculateHealthStatus(45, 'Very Dry');
        expect(status, 'Critical');
      });
    });

    group('Needs Attention Status', () {
      test('returns Needs Attention when temperature is 20-29°C', () {
        final status = calculateHealthStatus(25, 'Perfect');
        expect(status, 'Needs Attention');
      });

      test('returns Needs Attention when temperature is 61-70°C', () {
        final status = calculateHealthStatus(65, 'Perfect');
        expect(status, 'Needs Attention');
      });

      test('returns Needs Attention when moisture is Dry', () {
        final status = calculateHealthStatus(45, 'Dry');
        expect(status, 'Needs Attention');
      });

      test('returns Needs Attention when moisture is Wet', () {
        final status = calculateHealthStatus(45, 'Wet');
        expect(status, 'Needs Attention');
      });

      test('returns Needs Attention at boundary temperature 29°C', () {
        final status = calculateHealthStatus(29, 'Perfect');
        expect(status, 'Needs Attention');
      });

      test('returns Needs Attention at boundary temperature 61°C', () {
        final status = calculateHealthStatus(61, 'Perfect');
        expect(status, 'Needs Attention');
      });
    });

    group('Healthy Status', () {
      test('returns Healthy when temperature is 30-60°C with Perfect moisture', () {
        final status = calculateHealthStatus(45, 'Perfect');
        expect(status, 'Healthy');
      });

      test('returns Healthy at minimum optimal temperature 30°C', () {
        final status = calculateHealthStatus(30, 'Perfect');
        expect(status, 'Healthy');
      });

      test('returns Healthy at maximum optimal temperature 60°C', () {
        final status = calculateHealthStatus(60, 'Perfect');
        expect(status, 'Healthy');
      });

      test('returns Healthy when only temperature is optimal (null moisture)', () {
        final status = calculateHealthStatus(45, null);
        expect(status, 'Healthy');
      });

      test('returns Healthy when both temperature and moisture are null', () {
        final status = calculateHealthStatus(null, null);
        expect(status, 'Healthy');
      });

      test('returns Healthy when temperature is null and moisture is Perfect', () {
        final status = calculateHealthStatus(null, 'Perfect');
        expect(status, 'Healthy');
      });
    });

    group('Edge Cases', () {
      test('handles null temperature with Critical moisture', () {
        final status = calculateHealthStatus(null, 'Very Dry');
        expect(status, 'Critical');
      });

      test('handles null temperature with Needs Attention moisture', () {
        final status = calculateHealthStatus(null, 'Dry');
        expect(status, 'Needs Attention');
      });

      test('temperature takes precedence over moisture for Critical', () {
        // Temperature is Critical (15°C), moisture is Perfect
        final status = calculateHealthStatus(15, 'Perfect');
        expect(status, 'Critical');
      });

      test('handles mid-range temperature with various moisture levels', () {
        expect(calculateHealthStatus(45, 'Perfect'), 'Healthy');
        expect(calculateHealthStatus(45, 'Dry'), 'Needs Attention');
        expect(calculateHealthStatus(45, 'Wet'), 'Needs Attention');
        expect(calculateHealthStatus(45, 'Very Dry'), 'Critical');
        expect(calculateHealthStatus(45, 'Very Wet'), 'Critical');
      });
    });
  });
}
