import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskCard - Time Left Label', () {
    ({String text, Color color}) getTimeLeft(String? dueDateRaw) {
      if (dueDateRaw == null || dueDateRaw.trim().isEmpty) {
        return (text: '', color: Colors.grey);
      }

      try {
        final due = DateTime.parse(dueDateRaw).toLocal();
        final now = DateTime.now();
        final diff = due.difference(now);
        final isOverdue = diff.isNegative;
        final absDiff = isOverdue ? now.difference(due) : diff;

        final days = absDiff.inDays;
        final hours = absDiff.inHours % 24;
        final minutes = absDiff.inMinutes % 60;

        String spanText;
        if (days > 0) {
          spanText = '${days}d ${hours}h';
        } else if (absDiff.inHours > 0) {
          spanText = '${absDiff.inHours}h ${minutes}m';
        } else {
          spanText = '${absDiff.inMinutes.clamp(0, 59)}m';
        }

        if (isOverdue) {
          return (text: 'Overdue by $spanText', color: Colors.red.shade700);
        }

        if (absDiff.inHours <= 24) {
          return (text: '$spanText left', color: Colors.orange.shade700);
        }

        return (text: '$spanText left', color: Colors.green);
      } catch (_) {
        return (text: '', color: Colors.grey);
      }
    }

    test('returns empty text for null due date', () {
      final result = getTimeLeft(null);
      expect(result.text, '');
    });

    test('returns empty text for invalid due date', () {
      final result = getTimeLeft('not-a-date');
      expect(result.text, '');
    });

    test('returns left text for future due date', () {
      final due = DateTime.now().add(const Duration(hours: 5)).toIso8601String();
      final result = getTimeLeft(due);
      expect(result.text.contains('left'), true);
    });

    test('returns overdue text for past due date', () {
      final due = DateTime.now().subtract(const Duration(hours: 3)).toIso8601String();
      final result = getTimeLeft(due);
      expect(result.text.contains('Overdue by'), true);
    });
  });

  group('TaskCard - Time Sensitive visibility', () {
    test('shows time left only for time-sensitive tasks with due date', () {
      bool isTimeSensitive = true;
      String? dueDate = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final shouldShow = isTimeSensitive && dueDate != null && dueDate.isNotEmpty;

      expect(shouldShow, true);
    });

    test('does not show time left for non-time-sensitive tasks', () {
      bool isTimeSensitive = false;
      String? dueDate = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final shouldShow = isTimeSensitive && dueDate != null && dueDate.isNotEmpty;

      expect(shouldShow, false);
    });
  });
}

