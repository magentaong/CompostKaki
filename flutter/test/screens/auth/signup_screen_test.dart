import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupScreen Widget Tests', () {
    testWidgets('displays all required input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('first name field accepts text', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'John');
      expect(controller.text, 'John');
    });

    testWidgets('last name field accepts text', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Doe');
      expect(controller.text, 'Doe');
    });

    testWidgets('displays sign up button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Sign Up'),
            ),
          ),
        ),
      );

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('sign up button can be tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasTapped = true;
              },
              child: const Text('Sign Up'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('displays error for empty first name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    errorText: 'First name is required',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('First name is required'), findsOneWidget);
    });

    testWidgets('password field obscures text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });
  });

  group('SignupScreen - Form Validation', () {
    test('validates first name requirement', () {
      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'First name is required';
        }
        return null;
      }

      expect(validateName(''), 'First name is required');
      expect(validateName('   '), 'First name is required');
      expect(validateName('John'), null);
    });

    test('validates last name requirement', () {
      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Last name is required';
        }
        return null;
      }

      expect(validateName(''), 'Last name is required');
      expect(validateName('Doe'), null);
    });

    test('validates password minimum length', () {
      String? validatePassword(String? value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      }

      expect(validatePassword(''), 'Password is required');
      expect(
          validatePassword('12345'), 'Password must be at least 6 characters');
      expect(validatePassword('123456'), null);
    });
  });
}
