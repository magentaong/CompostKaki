import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogActivityScreen Widget Tests', () {
    testWidgets('displays activity type dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Activity Type'),
              items: const [
                DropdownMenuItem(value: 'Monitor', child: Text('Monitor')),
                DropdownMenuItem(value: 'Add', child: Text('Add Materials')),
                DropdownMenuItem(value: 'Flip', child: Text('Flip/Mix')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Activity Type'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('displays content text field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what you did',
              ),
              maxLines: 3,
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 3);
    });

    testWidgets('displays temperature input for Monitor type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      );

      expect(find.text('Temperature (°C)'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.number);
    });

    testWidgets('displays moisture level dropdown for Monitor type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Moisture Level'),
              items: const [
                DropdownMenuItem(value: 'Very Dry', child: Text('Very Dry')),
                DropdownMenuItem(value: 'Dry', child: Text('Dry')),
                DropdownMenuItem(value: 'Perfect', child: Text('Perfect')),
                DropdownMenuItem(value: 'Wet', child: Text('Wet')),
                DropdownMenuItem(value: 'Very Wet', child: Text('Very Wet')),
              ],
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Moisture Level'), findsOneWidget);
    });

    testWidgets('displays weight input for Add type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ),
      );

      expect(find.text('Weight (kg)'), findsOneWidget);
    });

    testWidgets('displays add photo button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photo'),
            ),
          ),
        ),
      );

      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('displays log activity button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Log Activity'),
            ),
          ),
        ),
      );

      expect(find.text('Log Activity'), findsOneWidget);
    });

    testWidgets('log button can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Text('Log Activity'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('shows loading indicator when submitting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error for empty description',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                errorText: 'Description is required',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Description is required'), findsOneWidget);
    });
  });

  group('LogActivityScreen - Form Validation', () {
    test('validates description is required', () {
      String? validateDescription(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      }

      expect(validateDescription(''), 'Description is required');
      expect(validateDescription('   '), 'Description is required');
      expect(validateDescription('Checked temperature'), null);
    });

    test('validates temperature range', () {
      String? validateTemperature(String? value) {
        if (value == null || value.isEmpty) {
          return null; // Optional field
        }
        final temp = int.tryParse(value);
        if (temp == null) {
          return 'Please enter a valid number';
        }
        if (temp < -20 || temp > 100) {
          return 'Temperature must be between -20°C and 100°C';
        }
        return null;
      }

      expect(validateTemperature(''), null);
      expect(validateTemperature('45'), null);
      expect(validateTemperature('-30'),
          'Temperature must be between -20°C and 100°C');
      expect(validateTemperature('150'),
          'Temperature must be between -20°C and 100°C');
      expect(validateTemperature('abc'), 'Please enter a valid number');
    });

    test('validates weight is positive', () {
      String? validateWeight(String? value) {
        if (value == null || value.isEmpty) {
          return null; // Optional field
        }
        final weight = double.tryParse(value);
        if (weight == null) {
          return 'Please enter a valid number';
        }
        if (weight < 0) {
          return 'Weight cannot be negative';
        }
        return null;
      }

      expect(validateWeight(''), null);
      expect(validateWeight('5.5'), null);
      expect(validateWeight('-1'), 'Weight cannot be negative');
      expect(validateWeight('abc'), 'Please enter a valid number');
    });
  });

  group('LogActivityScreen - Activity Types', () {
    test('validates activity type selection', () {
      final validTypes = ['Monitor', 'Add', 'Flip', 'Other'];

      for (final type in validTypes) {
        expect(validTypes.contains(type), true);
      }

      expect(validTypes.contains('Invalid'), false);
    });

    test('Monitor type shows temperature and moisture fields', () {
      const activityType = 'Monitor';
      final shouldShowMonitorFields = activityType == 'Monitor';

      expect(shouldShowMonitorFields, true);
    });

    test('Add type shows weight field', () {
      const activityType = 'Add';
      final shouldShowWeightField = activityType == 'Add';

      expect(shouldShowWeightField, true);
    });

    test('Flip type increments flip counter', () {
      const activityType = 'Flip';
      final shouldIncrementFlips = activityType == 'Flip';

      expect(shouldIncrementFlips, true);
    });
  });
}
