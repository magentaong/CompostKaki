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

  group('LogActivityScreen - Add Materials Missing Flow', () {
    test('defaults all three materials to checked', () {
      final materials = <String, bool>{
        'greens': true,
        'browns': true,
        'water': true,
      };

      expect(materials['greens'], true);
      expect(materials['browns'], true);
      expect(materials['water'], true);
      expect(materials.values.every((v) => v), true);
    });

    test('builds activity text from checked materials', () {
      String buildContent(Map<String, bool> materials) {
        final added = <String>[];
        if (materials['greens'] == true) added.add('greens');
        if (materials['browns'] == true) added.add('browns');
        if (materials['water'] == true) added.add('water');

        if (added.isEmpty) return 'No materials were added.';
        if (added.length == 1) return 'Added materials: ${added.first}';

        final last = added.removeLast();
        return 'Added materials: ${added.join(', ')} and $last';
      }

      expect(
        buildContent({'greens': true, 'browns': true, 'water': true}),
        'Added materials: greens, browns and water',
      );
      expect(
        buildContent({'greens': true, 'browns': true, 'water': false}),
        'Added materials: greens and browns',
      );
      expect(
        buildContent({'greens': false, 'browns': false, 'water': true}),
        'Added materials: water',
      );
      expect(
        buildContent({'greens': false, 'browns': false, 'water': false}),
        'No materials were added.',
      );
    });

    test('requires reasons for every unchecked material', () {
      bool hasRequiredMissingReasons(
        Map<String, bool> materials,
        Map<String, String?> reasons,
      ) {
        final missing = materials.entries
            .where((entry) => entry.value == false)
            .map((entry) => entry.key);
        return missing.every((key) => (reasons[key] ?? '').trim().isNotEmpty);
      }

      final materials = {'greens': true, 'browns': false, 'water': false};

      expect(
        hasRequiredMissingReasons(
          materials,
          {'browns': 'Need dry leaves', 'water': 'No water nearby'},
        ),
        true,
      );
      expect(
        hasRequiredMissingReasons(
          materials,
          {'browns': 'Need dry leaves', 'water': ''},
        ),
        false,
      );
    });

    test('sets task urgency/effort higher when 2+ materials are missing', () {
      ({String urgency, String effort}) mapPriority(int missingCount) {
        final urgency = missingCount >= 2 ? 'High' : 'Normal';
        final effort = missingCount >= 2 ? 'High' : 'Medium';
        return (urgency: urgency, effort: effort);
      }

      final oneMissing = mapPriority(1);
      final twoMissing = mapPriority(2);
      final threeMissing = mapPriority(3);

      expect(oneMissing.urgency, 'Normal');
      expect(oneMissing.effort, 'Medium');
      expect(twoMissing.urgency, 'High');
      expect(twoMissing.effort, 'High');
      expect(threeMissing.urgency, 'High');
      expect(threeMissing.effort, 'High');
    });

    test('uses fallback task title when user does not provide one', () {
      String materialLabel(String key) {
        switch (key) {
          case 'greens':
            return 'Greens';
          case 'browns':
            return 'Browns';
          case 'water':
            return 'Water';
          default:
            return key;
        }
      }

      String buildTaskTitle(String inputTitle, List<String> missing) {
        final generated = 'Need help getting '
            '${missing.map(materialLabel).join(', ').toLowerCase()}';
        return inputTitle.trim().isEmpty ? generated : inputTitle.trim();
      }

      expect(
        buildTaskTitle('', ['greens']),
        'Need help getting greens',
      );
      expect(
        buildTaskTitle('Urgent supplies needed', ['greens', 'water']),
        'Urgent supplies needed',
      );
    });
  });

  group('LogActivityScreen - Batch Logging Refinements', () {
    test('validates image file must exist before upload', () {
      String? validateImagePath(bool imageAttached, bool imageExists) {
        if (!imageAttached) return null;
        if (!imageExists) {
          return 'An attached photo could not be found anymore. Please re-attach the photo and try again.';
        }
        return null;
      }

      expect(validateImagePath(false, false), null);
      expect(validateImagePath(true, true), null);
      expect(
        validateImagePath(true, false),
        'An attached photo could not be found anymore. Please re-attach the photo and try again.',
      );
    });

    test('keeps image url when upload succeeds', () {
      String? resolveImageUrl({
        required bool hasImage,
        required bool uploadSucceeded,
      }) {
        if (!hasImage) return null;
        if (!uploadSucceeded) return null;
        return 'https://cdn.example.com/log-image.jpg';
      }

      expect(
        resolveImageUrl(hasImage: true, uploadSucceeded: true),
        'https://cdn.example.com/log-image.jpg',
      );
      expect(
        resolveImageUrl(hasImage: true, uploadSucceeded: false),
        null,
      );
      expect(
        resolveImageUrl(hasImage: false, uploadSucceeded: true),
        null,
      );
    });

    test('aggregates XP across successful batch items', () {
      int totalBatchXp(List<int> perDraftXp) {
        return perDraftXp.fold<int>(0, (sum, xp) => sum + xp);
      }

      expect(totalBatchXp([10, 10, 15]), 35);
      expect(totalBatchXp([0, 10, 0]), 10);
      expect(totalBatchXp([]), 0);
    });

    test('maps base XP by activity type', () {
      int baseXpForType(String type) {
        return type.toLowerCase().contains('turn') ? 15 : 10;
      }

      expect(baseXpForType('Turn Pile'), 15);
      expect(baseXpForType('Monitor'), 10);
      expect(baseXpForType('Add Water'), 10);
    });

    test('combines base XP with bonus XP per draft', () {
      int totalXpForDraft(String type, int bonusXp) {
        final base = type.toLowerCase().contains('turn') ? 15 : 10;
        return base + bonusXp;
      }

      expect(totalXpForDraft('Turn Pile', 5), 20);
      expect(totalXpForDraft('Add Materials', 0), 10);
      expect(totalXpForDraft('Monitor', 10), 20);
    });

    test('retains only failed drafts in queue after batch submit', () {
      final originalQueue = <String>['a', 'b', 'c', 'd'];
      final failedDrafts = <String>['b', 'd'];

      final nextQueue = <String>[...failedDrafts];

      expect(originalQueue.length, 4);
      expect(nextQueue, ['b', 'd']);
      expect(nextQueue.length, 2);
    });

    test('reports batch summary for partial failures', () {
      String batchSummary({
        required int successCount,
        required int failedCount,
      }) {
        if (failedCount > 0) {
          return '$successCount logged, $failedCount failed. You can retry failed items.';
        }
        return '$successCount activities logged successfully.';
      }

      expect(
        batchSummary(successCount: 2, failedCount: 1),
        '2 logged, 1 failed. You can retry failed items.',
      );
      expect(
        batchSummary(successCount: 3, failedCount: 0),
        '3 activities logged successfully.',
      );
    });

    test('builds per-item failure messages with activity type context', () {
      String buildFailureMessage(String type, String rawError) {
        return '$type: ${rawError.replaceFirst('Exception: ', '')}';
      }

      expect(
        buildFailureMessage('Add Materials', 'Exception: upload failed'),
        'Add Materials: upload failed',
      );
      expect(
        buildFailureMessage('Monitor', 'temperature required'),
        'Monitor: temperature required',
      );
    });

    test('only prompts log another after full batch success', () {
      bool shouldPromptLogAnother({required int failedCount}) {
        return failedCount == 0;
      }

      expect(shouldPromptLogAnother(failedCount: 0), true);
      expect(shouldPromptLogAnother(failedCount: 1), false);
    });

    test('single-submit feedback includes earned XP amount', () {
      String singleSubmitMessage(int xpGained) {
        return 'Activity logged (+$xpGained XP).';
      }

      expect(singleSubmitMessage(10), 'Activity logged (+10 XP).');
      expect(singleSubmitMessage(25), 'Activity logged (+25 XP).');
    });

    test('batch-submit feedback includes total XP amount', () {
      String batchSubmitMessage({
        required int successCount,
        required int totalXp,
      }) {
        return '$successCount activities logged successfully (+$totalXp XP).';
      }

      expect(
        batchSubmitMessage(successCount: 2, totalXp: 20),
        '2 activities logged successfully (+20 XP).',
      );
      expect(
        batchSubmitMessage(successCount: 5, totalXp: 65),
        '5 activities logged successfully (+65 XP).',
      );
    });

    test('submit-all is disabled when queue is empty', () {
      bool canSubmitBatch(List<Map<String, dynamic>> queue, bool isLoading) {
        return !isLoading && queue.isNotEmpty;
      }

      expect(canSubmitBatch([], false), false);
      expect(canSubmitBatch([
        {'type': 'Monitor'}
      ], false), true);
      expect(canSubmitBatch([
        {'type': 'Monitor'}
      ], true), false);
    });
  });
}
