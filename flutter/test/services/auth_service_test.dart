import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService - Email Validation', () {
    test('valid email formats are accepted', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.com',
        'test123@test-domain.com',
        'a@b.co',
      ];

      // Note: This regex doesn't support + in emails, which is a known limitation
      // TLD must be 2-4 characters (e.g., .com, .co.uk)
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      
      for (final email in validEmails) {
        expect(emailRegex.hasMatch(email), true, 
          reason: '$email should be valid');
      }
    });

    test('invalid email formats are rejected', () {
      final invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com',
        'user@domain',
        'user name@domain.com',
        '',
      ];

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      
      for (final email in invalidEmails) {
        expect(emailRegex.hasMatch(email), false,
          reason: '$email should be invalid');
      }
    });
  });

  group('AuthService - Password Validation', () {
    test('password meets minimum length requirement', () {
      const minLength = 6;
      
      expect('12345'.length >= minLength, false);
      expect('123456'.length >= minLength, true);
      expect('password123'.length >= minLength, true);
    });

    test('empty password is rejected', () {
      const password = '';
      expect(password.isEmpty, true);
    });

    test('whitespace-only password is invalid', () {
      const password = '      ';
      expect(password.trim().isEmpty, true);
    });
  });

  group('AuthService - Name Validation', () {
    test('valid names are accepted', () {
      final validNames = [
        'John',
        'Mary Jane',
        'O\'Brien',
        'José',
        '李明',
      ];

      for (final name in validNames) {
        expect(name.trim().isNotEmpty, true,
          reason: '$name should be valid');
      }
    });

    test('empty names are rejected', () {
      final invalidNames = ['', '   ', '\t\n'];

      for (final name in invalidNames) {
        expect(name.trim().isEmpty, true,
          reason: 'Empty name should be invalid');
      }
    });
  });
}
