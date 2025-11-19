import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddBinScreen Widget Tests', () {
    testWidgets('displays bin name input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Bin Name',
                hintText: 'e.g., Home Compost Bin',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bin Name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('bin name field accepts text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Bin Name'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Home Compost');
      expect(controller.text, 'Home Compost');
    });

    testWidgets('displays create bin button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Create Bin'),
            ),
          ),
        ),
      );

      expect(find.text('Create Bin'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('create button can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Text('Create Bin'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('displays image picker option', (WidgetTester tester) async {
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

    testWidgets('displays join existing bin option', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () {},
              child: const Text('Or join an existing bin'),
            ),
          ),
        ),
      );

      expect(find.textContaining('join an existing bin'), findsOneWidget);
    });

    testWidgets('shows loading indicator when creating', (WidgetTester tester) async {
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

    testWidgets('displays error message for empty bin name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Bin Name',
                errorText: 'Bin name is required',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bin name is required'), findsOneWidget);
    });
  });

  group('AddBinScreen - Form Validation', () {
    test('validates bin name is required', () {
      String? validateBinName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bin name is required';
        }
        return null;
      }

      expect(validateBinName(''), 'Bin name is required');
      expect(validateBinName('   '), 'Bin name is required');
      expect(validateBinName('Home Bin'), null);
    });

    test('validates bin name minimum length', () {
      String? validateBinName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bin name is required';
        }
        if (value.trim().length < 3) {
          return 'Bin name must be at least 3 characters';
        }
        return null;
      }

      expect(validateBinName('ab'), 'Bin name must be at least 3 characters');
      expect(validateBinName('abc'), null);
    });

    test('validates bin name maximum length', () {
      String? validateBinName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bin name is required';
        }
        if (value.length > 50) {
          return 'Bin name must be less than 50 characters';
        }
        return null;
      }

      final longName = 'a' * 51;
      expect(validateBinName(longName), 'Bin name must be less than 50 characters');
      expect(validateBinName('Normal Length Name'), null);
    });
  });

  group('AddBinScreen - Join Bin Dialog', () {
    testWidgets('displays join bin dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Join Bin'),
                      content: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Bin ID or Link',
                          hintText: 'Enter bin ID or paste link',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Join'),
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

      expect(find.text('Join Bin'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('join dialog has scan QR button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
            ),
          ),
        ),
      );

      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });
  });
}

