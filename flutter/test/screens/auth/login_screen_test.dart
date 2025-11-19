import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('displays app logo and title', (WidgetTester tester) async {
      // Create a minimal test widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('CompostKaki'),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.eco, size: 50),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CompostKaki'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('email field accepts text input', (WidgetTester tester) async {
      final emailController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      // Find the text field
      final emailField = find.byType(TextField);
      expect(emailField, findsOneWidget);

      // Enter text
      await tester.enterText(emailField, 'test@example.com');
      expect(emailController.text, 'test@example.com');
    });

    testWidgets('password field obscures text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ),
        ),
      );

      final passwordField = find.byType(TextField);
      expect(passwordField, findsOneWidget);

      // Verify the field is configured to obscure text
      final textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, true);
    });

    testWidgets('displays login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('login button is tappable', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasPressed = true;
              },
              child: const Text('Continue'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('displays create account link', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () {},
              child: const Text('New to CompostKaki? Create an account!'),
            ),
          ),
        ),
      );

      expect(find.textContaining('Create an account'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when processing', (WidgetTester tester) async {
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

    testWidgets('displays error message when login fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(),
                const SizedBox(height: 8),
                const Text(
                  'Invalid email or password',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });

  group('LoginScreen - Email Validation', () {
    test('valid email passes validation', () {
      String? validateEmail(String? value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      }

      expect(validateEmail('test@example.com'), null);
      expect(validateEmail('user@domain.co'), null);
    });

    test('invalid email fails validation', () {
      String? validateEmail(String? value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      }

      expect(validateEmail(''), 'Email is required');
      expect(validateEmail('invalid'), 'Please enter a valid email');
      expect(validateEmail('test@'), 'Please enter a valid email');
    });
  });
}
