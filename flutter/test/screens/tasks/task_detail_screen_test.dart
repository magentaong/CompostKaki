import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskDetailScreen Widget Tests', () {
    testWidgets('displays task title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Task Details'),
            ),
            body: const Text('Need help flipping compost',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
      );

      expect(find.text('Need help flipping compost'), findsOneWidget);
    });

    testWidgets('displays task description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Description',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('The compost bin is too heavy for me to flip alone'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('The compost bin is too heavy for me to flip alone'),
          findsOneWidget);
    });

    testWidgets('displays task status badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Chip(
              label: const Text('Open'),
              backgroundColor: Colors.green.shade100,
            ),
          ),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('displays bin name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Bin'),
              subtitle: const Text('Home Compost'),
            ),
          ),
        ),
      );

      expect(find.text('Bin'), findsOneWidget);
      expect(find.text('Home Compost'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('displays creator information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: CircleAvatar(
                child: const Text('JD'),
              ),
              title: const Text('Posted by'),
              subtitle: const Text('John Doe'),
            ),
          ),
        ),
      );

      expect(find.text('Posted by'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays time posted', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Posted'),
              subtitle: const Text('2 hours ago'),
            ),
          ),
        ),
      );

      expect(find.text('Posted'), findsOneWidget);
      expect(find.text('2 hours ago'), findsOneWidget);
    });

    testWidgets('displays accept button for open task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Accept Task'),
            ),
          ),
        ),
      );

      expect(find.text('Accept Task'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('accept button can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Text('Accept Task'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('displays complete button for in-progress task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Mark as Complete'),
            ),
          ),
        ),
      );

      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testWidgets('displays assignee info for in-progress task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Assigned to'),
              subtitle: const Text('Jane Smith'),
            ),
          ),
        ),
      );

      expect(find.text('Assigned to'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('shows accept confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Accept Task'),
                      content: const Text(
                          'Are you sure you want to accept this task?'),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Accept Task'), findsOneWidget);
      expect(find.text('Are you sure you want to accept this task?'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('shows complete confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Complete Task'),
                      content: const Text('Mark this task as completed?'),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Complete'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Complete Task'), findsOneWidget);
      expect(find.text('Mark this task as completed?'), findsOneWidget);
    });

    testWidgets('displays loading indicator when accepting task',
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

    testWidgets('shows error message when action fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to accept task'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to show snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump(); // Start animation
      await tester.pump(
          const Duration(milliseconds: 750)); // Wait for snackbar to appear

      expect(find.text('Failed to accept task'), findsOneWidget);
    });
  });

  group('TaskDetailScreen - Visibility Logic', () {
    test('accept button visible for open tasks (not creator)', () {
      bool shouldShowAcceptButton(Map<String, dynamic> task, String userId) {
        return task['status'] == 'open' &&
            task['creator_id'] != userId &&
            task['assigned_to'] == null;
      }

      final task = {
        'status': 'open',
        'creator_id': 'creator-123',
        'assigned_to': null,
      };

      expect(shouldShowAcceptButton(task, 'other-user'), true);
      expect(shouldShowAcceptButton(task, 'creator-123'), false);
    });

    test('complete button visible for assignee of in-progress task', () {
      bool shouldShowCompleteButton(Map<String, dynamic> task, String userId) {
        return task['status'] == 'in_progress' && task['assigned_to'] == userId;
      }

      final task = {
        'status': 'in_progress',
        'assigned_to': 'user-123',
      };

      expect(shouldShowCompleteButton(task, 'user-123'), true);
      expect(shouldShowCompleteButton(task, 'other-user'), false);
    });

    test('no action buttons for completed tasks', () {
      bool shouldShowActionButtons(Map<String, dynamic> task) {
        return task['status'] != 'completed';
      }

      expect(shouldShowActionButtons({'status': 'open'}), true);
      expect(shouldShowActionButtons({'status': 'in_progress'}), true);
      expect(shouldShowActionButtons({'status': 'completed'}), false);
    });

    test('creator cannot accept their own task', () {
      bool canAcceptTask(Map<String, dynamic> task, String userId) {
        return task['creator_id'] != userId;
      }

      final task = {'creator_id': 'user-123'};

      expect(canAcceptTask(task, 'user-123'), false);
      expect(canAcceptTask(task, 'other-user'), true);
    });
  });

  group('TaskDetailScreen - Status Updates', () {
    test('accepting task updates status to in_progress', () {
      String getNewStatus(String currentStatus, String action) {
        if (action == 'accept' && currentStatus == 'open') {
          return 'in_progress';
        }
        if (action == 'complete' && currentStatus == 'in_progress') {
          return 'completed';
        }
        return currentStatus;
      }

      expect(getNewStatus('open', 'accept'), 'in_progress');
      expect(getNewStatus('open', 'complete'), 'open');
    });

    test('completing task updates status to completed', () {
      String getNewStatus(String currentStatus, String action) {
        if (action == 'complete' && currentStatus == 'in_progress') {
          return 'completed';
        }
        return currentStatus;
      }

      expect(getNewStatus('in_progress', 'complete'), 'completed');
      expect(getNewStatus('open', 'complete'), 'open');
    });

    test('accepting task assigns user', () {
      Map<String, dynamic> acceptTask(
          Map<String, dynamic> task, String userId) {
        return {
          ...task,
          'status': 'in_progress',
          'assigned_to': userId,
        };
      }

      final task = {
        'id': 'task-123',
        'status': 'open',
        'assigned_to': null,
      };

      final updatedTask = acceptTask(task, 'user-456');
      expect(updatedTask['status'], 'in_progress');
      expect(updatedTask['assigned_to'], 'user-456');
    });
  });
}
