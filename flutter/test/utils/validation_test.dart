import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Form Validation Utilities', () {
    group('Email Validation', () {
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

      test('returns error for empty email', () {
        expect(validateEmail(''), 'Email is required');
        expect(validateEmail(null), 'Email is required');
      });

      test('returns error for invalid email format', () {
        expect(validateEmail('invalid'), 'Please enter a valid email');
        expect(validateEmail('test@'), 'Please enter a valid email');
        expect(validateEmail('@domain.com'), 'Please enter a valid email');
      });

      test('returns null for valid email', () {
        expect(validateEmail('test@example.com'), null);
        expect(validateEmail('user@domain.co.uk'), null);
      });
    });

    group('Password Validation', () {
      String? validatePassword(String? value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      }

      test('returns error for empty password', () {
        expect(validatePassword(''), 'Password is required');
        expect(validatePassword(null), 'Password is required');
      });

      test('returns error for short password', () {
        expect(validatePassword('12345'),
            'Password must be at least 6 characters');
        expect(
            validatePassword('abc'), 'Password must be at least 6 characters');
      });

      test('returns null for valid password', () {
        expect(validatePassword('123456'), null);
        expect(validatePassword('password'), null);
        expect(validatePassword('super_secure_password_123'), null);
      });
    });

    group('Name Validation', () {
      String? validateName(String? value, String fieldName) {
        if (value == null || value.trim().isEmpty) {
          return '$fieldName is required';
        }
        if (value.trim().length < 2) {
          return '$fieldName must be at least 2 characters';
        }
        return null;
      }

      test('returns error for empty name', () {
        expect(validateName('', 'First name'), 'First name is required');
        expect(validateName('   ', 'Last name'), 'Last name is required');
        expect(validateName(null, 'Name'), 'Name is required');
      });

      test('returns error for too short name', () {
        expect(validateName('A', 'First name'),
            'First name must be at least 2 characters');
      });

      test('returns null for valid name', () {
        expect(validateName('John', 'First name'), null);
        expect(validateName('Mary Jane', 'Full name'), null);
        expect(validateName('O\'Brien', 'Last name'), null);
      });
    });

    group('Bin Name Validation', () {
      String? validateBinName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bin name is required';
        }
        if (value.trim().length < 3) {
          return 'Bin name must be at least 3 characters';
        }
        if (value.length > 50) {
          return 'Bin name must be less than 50 characters';
        }
        return null;
      }

      test('returns error for empty bin name', () {
        expect(validateBinName(''), 'Bin name is required');
        expect(validateBinName('   '), 'Bin name is required');
      });

      test('returns error for too short bin name', () {
        expect(validateBinName('ab'), 'Bin name must be at least 3 characters');
      });

      test('returns error for too long bin name', () {
        final longName = 'a' * 51;
        expect(validateBinName(longName),
            'Bin name must be less than 50 characters');
      });

      test('returns null for valid bin name', () {
        expect(validateBinName('Home Bin'), null);
        expect(validateBinName('Community Garden'), null);
        expect(validateBinName('Yishun Block 123'), null);
      });
    });

    group('Temperature Validation', () {
      String? validateTemperature(String? value) {
        if (value == null || value.isEmpty) {
          return null; // Temperature is optional
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

      test('returns null for empty temperature (optional)', () {
        expect(validateTemperature(''), null);
        expect(validateTemperature(null), null);
      });

      test('returns error for invalid number', () {
        expect(validateTemperature('abc'), 'Please enter a valid number');
        expect(validateTemperature('12.5.3'), 'Please enter a valid number');
      });

      test('returns error for out of range temperature', () {
        expect(validateTemperature('-30'),
            'Temperature must be between -20°C and 100°C');
        expect(validateTemperature('150'),
            'Temperature must be between -20°C and 100°C');
      });

      test('returns null for valid temperature', () {
        expect(validateTemperature('0'), null);
        expect(validateTemperature('25'), null);
        expect(validateTemperature('45'), null);
        expect(validateTemperature('100'), null);
        expect(validateTemperature('-20'), null);
      });
    });

    group('Weight Validation', () {
      String? validateWeight(String? value) {
        if (value == null || value.isEmpty) {
          return null; // Weight is optional
        }
        final weight = double.tryParse(value);
        if (weight == null) {
          return 'Please enter a valid number';
        }
        if (weight < 0) {
          return 'Weight cannot be negative';
        }
        if (weight > 1000) {
          return 'Weight must be less than 1000 kg';
        }
        return null;
      }

      test('returns null for empty weight (optional)', () {
        expect(validateWeight(''), null);
        expect(validateWeight(null), null);
      });

      test('returns error for invalid number', () {
        expect(validateWeight('abc'), 'Please enter a valid number');
      });

      test('returns error for negative weight', () {
        expect(validateWeight('-5'), 'Weight cannot be negative');
      });

      test('returns error for excessive weight', () {
        expect(validateWeight('1001'), 'Weight must be less than 1000 kg');
      });

      test('returns null for valid weight', () {
        expect(validateWeight('0'), null);
        expect(validateWeight('1.5'), null);
        expect(validateWeight('25'), null);
        expect(validateWeight('999.99'), null);
      });
    });
  });
}
