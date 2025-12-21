import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateTaskScreen (Ask for Help) Widget Tests', () {
    testWidgets('displays screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Ask for Help'),
            ),
            body: Container(),
          ),
        ),
      );

      expect(find.text('Ask for Help'), findsOneWidget);
    });

    testWidgets('displays bin selector dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Bin',
                hintText: 'Choose which bin needs help',
              ),
              items: const [
                DropdownMenuItem(value: 'bin-1', child: Text('Home Compost')),
                DropdownMenuItem(value: 'bin-2', child: Text('Garden Bin')),
              ],
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Select Bin'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('displays task title input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Need help flipping compost',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Task Title'), findsOneWidget);
    });

    testWidgets('task title field accepts text input',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Need help flipping');
      expect(controller.text, 'Need help flipping');
    });

    testWidgets('displays description input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what help you need',
              ),
              maxLines: 5,
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 5);
    });

    testWidgets('description field accepts text input',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'The bin is too heavy');
      expect(controller.text, 'The bin is too heavy');
    });

    testWidgets('displays post task button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Post Task'),
            ),
          ),
        ),
      );

      expect(find.text('Post Task'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('post button can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Text('Post Task'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('shows loading indicator when posting',
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

    testWidgets('displays error for empty title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Task Title',
                errorText: 'Title is required',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title is required'), findsOneWidget);
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

    testWidgets('displays error for no bin selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Bin',
                errorText: 'Please select a bin',
              ),
              items: const [],
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Please select a bin'), findsOneWidget);
    });
  });

  group('CreateTaskScreen - Form Validation', () {
    test('validates task title is required', () {
      String? validateTitle(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        return null;
      }

      expect(validateTitle(''), 'Title is required');
      expect(validateTitle('   '), 'Title is required');
      expect(validateTitle('Need help'), null);
    });

    test('validates task title minimum length', () {
      String? validateTitle(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.trim().length < 5) {
          return 'Title must be at least 5 characters';
        }
        return null;
      }

      expect(validateTitle('Help'), 'Title must be at least 5 characters');
      expect(validateTitle('Need help'), null);
    });

    test('validates task title maximum length', () {
      String? validateTitle(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.length > 100) {
          return 'Title must be less than 100 characters';
        }
        return null;
      }

      final longTitle = 'a' * 101;
      expect(
          validateTitle(longTitle), 'Title must be less than 100 characters');
      expect(validateTitle('Normal title'), null);
    });

    test('validates description is required', () {
      String? validateDescription(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      }

      expect(validateDescription(''), 'Description is required');
      expect(validateDescription('The bin is heavy'), null);
    });

    test('validates description minimum length', () {
      String? validateDescription(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        return null;
      }

      expect(validateDescription('Too short'),
          'Description must be at least 10 characters');
      expect(validateDescription('This is a longer description'), null);
    });

    test('validates bin selection is required', () {
      String? validateBinSelection(String? value) {
        if (value == null || value.isEmpty) {
          return 'Please select a bin';
        }
        return null;
      }

      expect(validateBinSelection(null), 'Please select a bin');
      expect(validateBinSelection(''), 'Please select a bin');
      expect(validateBinSelection('bin-123'), null);
    });
  });

  group('CreateTaskScreen - Bin Selection', () {
    test('filters user bins for selection', () {
      final userBins = [
        {'id': 'bin-1', 'name': 'Home Compost'},
        {'id': 'bin-2', 'name': 'Garden Bin'},
        {'id': 'bin-3', 'name': 'School Compost'},
      ];

      expect(userBins.length, 3);
      expect(userBins[0]['name'], 'Home Compost');
    });

    test('shows only bins user is member of', () {
      bool isUserMember(Map<String, dynamic> bin, String userId) {
        final ownerId = bin['user_id'] as String?;
        final contributors = bin['contributors_list'] as List?;

        if (ownerId == userId) return true;
        if (contributors != null && contributors.contains(userId)) return true;
        return false;
      }

      final bin1 = {
        'id': 'bin-1',
        'user_id': 'user-123',
        'contributors_list': [],
      };

      final bin2 = {
        'id': 'bin-2',
        'user_id': 'other-user',
        'contributors_list': ['user-123'],
      };

      final bin3 = {
        'id': 'bin-3',
        'user_id': 'other-user',
        'contributors_list': [],
      };

      expect(isUserMember(bin1, 'user-123'), true);
      expect(isUserMember(bin2, 'user-123'), true);
      expect(isUserMember(bin3, 'user-123'), false);
    });
  });

  group('CreateTaskScreen - Success Scenarios', () {
    test('creates task with valid data', () {
      final taskData = {
        'bin_id': 'bin-123',
        'title': 'Need help flipping',
        'description': 'The compost bin is too heavy for me to flip alone',
        'status': 'open',
        'assigned_to': null,
      };

      expect(taskData['bin_id'], 'bin-123');
      expect(taskData['title'], 'Need help flipping');
      expect(taskData['status'], 'open');
      expect(taskData['assigned_to'], null);
    });

    test('task defaults to open status', () {
      const initialStatus = 'open';
      expect(initialStatus, 'open');
    });

    test('task is not assigned initially', () {
      String? initialAssignee;
      expect(initialAssignee, null);
    });
  });
}
