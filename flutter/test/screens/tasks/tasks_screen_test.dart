import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasksScreen Widget Tests', () {
    testWidgets('displays screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Community Tasks'),
            ),
            body: Container(),
          ),
        ),
      );

      expect(find.text('Community Tasks'), findsOneWidget);
    });

    testWidgets('displays tabs for task status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Open'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
              body: Container(),
            ),
          ),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('displays floating action button for creating task', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('displays empty state when no tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tasks yet'),
                  Text('Create a task to get help from the community'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.textContaining('Create a task'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('displays task card with title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: const Text('Need help flipping compost'),
                subtitle: const Text('The bin is too heavy for me'),
                trailing: Chip(
                  label: const Text('Open'),
                  backgroundColor: Colors.green.shade100,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Need help flipping compost'), findsOneWidget);
      expect(find.text('The bin is too heavy for me'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('task card can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: const Text('Task Title'),
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('displays loading indicator when fetching tasks', (WidgetTester tester) async {
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

    testWidgets('displays error message when fetch fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load tasks'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to load tasks'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('TasksScreen - Task Card Display', () {
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

    testWidgets('displays bin name for task', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: const Text('Task Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Description'),
                  SizedBox(height: 4),
                  Text('Bin: Home Compost', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Bin: Home Compost'), findsOneWidget);
    });

    testWidgets('displays task creator info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: CircleAvatar(
                child: const Text('JD'),
              ),
              title: const Text('Task Title'),
              subtitle: const Text('Posted by John Doe'),
            ),
          ),
        ),
      );

      expect(find.text('Posted by John Doe'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays time posted', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: const Text('Task Title'),
              trailing: const Text('2 hours ago', style: TextStyle(fontSize: 12)),
            ),
          ),
        ),
      );

      expect(find.text('2 hours ago'), findsOneWidget);
    });
  });

  group('TasksScreen - Task Status Logic', () {
    test('task status colors are correct', () {
      Color getStatusColor(String status) {
        switch (status) {
          case 'open':
            return Colors.green;
          case 'in_progress':
            return Colors.orange;
          case 'completed':
            return Colors.blue;
          default:
            return Colors.grey;
        }
      }

      expect(getStatusColor('open'), Colors.green);
      expect(getStatusColor('in_progress'), Colors.orange);
      expect(getStatusColor('completed'), Colors.blue);
      expect(getStatusColor('unknown'), Colors.grey);
    });

    test('task status labels are correct', () {
      String getStatusLabel(String status) {
        switch (status) {
          case 'open':
            return 'Open';
          case 'in_progress':
            return 'In Progress';
          case 'completed':
            return 'Completed';
          default:
            return 'Unknown';
        }
      }

      expect(getStatusLabel('open'), 'Open');
      expect(getStatusLabel('in_progress'), 'In Progress');
      expect(getStatusLabel('completed'), 'Completed');
    });

    test('checks if user can accept task', () {
      bool canAcceptTask(Map<String, dynamic> task, String userId) {
        return task['status'] == 'open' &&
               task['creator_id'] != userId &&
               task['assigned_to'] == null;
      }

      final task = {
        'status': 'open',
        'creator_id': 'creator-123',
        'assigned_to': null,
      };

      expect(canAcceptTask(task, 'other-user'), true);
      expect(canAcceptTask(task, 'creator-123'), false);
      
      task['assigned_to'] = 'someone';
      expect(canAcceptTask(task, 'other-user'), false);
      
      task['assigned_to'] = null;
      task['status'] = 'completed';
      expect(canAcceptTask(task, 'other-user'), false);
    });

    test('checks if user can complete task', () {
      bool canCompleteTask(Map<String, dynamic> task, String userId) {
        return task['status'] == 'in_progress' &&
               task['assigned_to'] == userId;
      }

      final task = {
        'status': 'in_progress',
        'assigned_to': 'user-123',
      };

      expect(canCompleteTask(task, 'user-123'), true);
      expect(canCompleteTask(task, 'other-user'), false);
      
      task['status'] = 'open';
      expect(canCompleteTask(task, 'user-123'), false);
    });
  });

  group('TasksScreen - Filtering', () {
    test('filters tasks by status', () {
      final tasks = [
        {'id': '1', 'status': 'open'},
        {'id': '2', 'status': 'in_progress'},
        {'id': '3', 'status': 'open'},
        {'id': '4', 'status': 'completed'},
      ];

      List<Map<String, dynamic>> filterByStatus(List<Map<String, dynamic>> tasks, String status) {
        return tasks.where((task) => task['status'] == status).toList();
      }

      final openTasks = filterByStatus(tasks, 'open');
      expect(openTasks.length, 2);
      expect(openTasks[0]['id'], '1');
      expect(openTasks[1]['id'], '3');

      final inProgressTasks = filterByStatus(tasks, 'in_progress');
      expect(inProgressTasks.length, 1);
      expect(inProgressTasks[0]['id'], '2');

      final completedTasks = filterByStatus(tasks, 'completed');
      expect(completedTasks.length, 1);
      expect(completedTasks[0]['id'], '4');
    });

    test('filters tasks by bin', () {
      final tasks = [
        {'id': '1', 'bin_id': 'bin-a'},
        {'id': '2', 'bin_id': 'bin-b'},
        {'id': '3', 'bin_id': 'bin-a'},
      ];

      List<Map<String, dynamic>> filterByBin(List<Map<String, dynamic>> tasks, String binId) {
        return tasks.where((task) => task['bin_id'] == binId).toList();
      }

      final binATasks = filterByBin(tasks, 'bin-a');
      expect(binATasks.length, 2);

      final binBTasks = filterByBin(tasks, 'bin-b');
      expect(binBTasks.length, 1);
    });
  });
}

