import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date Formatting Utilities', () {
    test('formats relative time correctly', () {
      String getRelativeTime(DateTime dateTime) {
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inSeconds < 60) {
          return 'just now';
        } else if (difference.inMinutes < 60) {
          final minutes = difference.inMinutes;
          return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
        } else if (difference.inHours < 24) {
          final hours = difference.inHours;
          return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
        } else if (difference.inDays < 7) {
          final days = difference.inDays;
          return '$days ${days == 1 ? 'day' : 'days'} ago';
        } else if (difference.inDays < 30) {
          final weeks = (difference.inDays / 7).floor();
          return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
        } else if (difference.inDays < 365) {
          final months = (difference.inDays / 30).floor();
          return '$months ${months == 1 ? 'month' : 'months'} ago';
        } else {
          final years = (difference.inDays / 365).floor();
          return '$years ${years == 1 ? 'year' : 'years'} ago';
        }
      }

      final now = DateTime.now();

      // Just now
      expect(getRelativeTime(now.subtract(const Duration(seconds: 30))),
          'just now');

      // Minutes ago
      expect(getRelativeTime(now.subtract(const Duration(minutes: 1))),
          '1 minute ago');
      expect(getRelativeTime(now.subtract(const Duration(minutes: 5))),
          '5 minutes ago');

      // Hours ago
      expect(getRelativeTime(now.subtract(const Duration(hours: 1))),
          '1 hour ago');
      expect(getRelativeTime(now.subtract(const Duration(hours: 3))),
          '3 hours ago');

      // Days ago
      expect(
          getRelativeTime(now.subtract(const Duration(days: 1))), '1 day ago');
      expect(
          getRelativeTime(now.subtract(const Duration(days: 5))), '5 days ago');

      // Weeks ago
      expect(
          getRelativeTime(now.subtract(const Duration(days: 7))), '1 week ago');
      expect(getRelativeTime(now.subtract(const Duration(days: 14))),
          '2 weeks ago');

      // Months ago
      expect(getRelativeTime(now.subtract(const Duration(days: 30))),
          '1 month ago');
      expect(getRelativeTime(now.subtract(const Duration(days: 60))),
          '2 months ago');

      // Years ago
      expect(getRelativeTime(now.subtract(const Duration(days: 365))),
          '1 year ago');
      expect(getRelativeTime(now.subtract(const Duration(days: 730))),
          '2 years ago');
    });

    test('formats date to string correctly', () {
      String formatDate(DateTime date) {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }

      expect(formatDate(DateTime(2025, 1, 15)), 'Jan 15, 2025');
      expect(formatDate(DateTime(2025, 12, 25)), 'Dec 25, 2025');
      expect(formatDate(DateTime(2024, 6, 1)), 'Jun 1, 2024');
    });

    test('formats time to string correctly', () {
      String formatTime(DateTime time) {
        final hour = time.hour;
        final minute = time.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }

      expect(formatTime(DateTime(2025, 1, 1, 0, 0)), '12:00 AM');
      expect(formatTime(DateTime(2025, 1, 1, 9, 30)), '9:30 AM');
      expect(formatTime(DateTime(2025, 1, 1, 12, 0)), '12:00 PM');
      expect(formatTime(DateTime(2025, 1, 1, 15, 45)), '3:45 PM');
      expect(formatTime(DateTime(2025, 1, 1, 23, 59)), '11:59 PM');
    });
  });
}
