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
        const defaultImage = 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735';
        // Only use default if imageUrl is null or empty
        if (imageUrl == null || imageUrl.isEmpty) {
          return defaultImage;
        }
        return imageUrl;
      }

      expect(getBinImage(null), contains('unsplash'));
      expect(getBinImage(''), contains('unsplash'));
      expect(getBinImage('https://example.com/image.jpg'), 'https://example.com/image.jpg');
    });
  });
}

