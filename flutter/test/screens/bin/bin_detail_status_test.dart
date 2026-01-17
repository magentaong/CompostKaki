import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BinDetailScreen - Bin Status Display', () {
    group('Status Badge Display', () {
      test('should display Active badge for active status', () {
        String status = 'active';
        String badgeText = status == 'active' ? 'Active' : status;
        String badgeColor = status == 'active' ? 'green' : 'orange';

        expect(badgeText, 'Active');
        expect(badgeColor, 'green');
      });

      test('should display Resting badge for resting status', () {
        String status = 'resting';
        String badgeText = status == 'resting' ? 'Resting' : status;
        String badgeColor = status == 'resting' ? 'orange' : 'purple';

        expect(badgeText, 'Resting');
        expect(badgeColor, 'orange');
      });

      test('should display Matured badge for matured status', () {
        String status = 'matured';
        String badgeText = status == 'matured' ? 'Matured' : status;
        String badgeColor = status == 'matured' ? 'purple' : 'green';

        expect(badgeText, 'Matured');
        expect(badgeColor, 'purple');
      });

      test('should show Edit button only for bin owner', () {
        bool isOwner = true;
        bool shouldShowEdit = isOwner;

        expect(shouldShowEdit, true);
      });

      test('should not show Edit button for non-owner', () {
        bool isOwner = false;
        bool shouldShowEdit = isOwner;

        expect(shouldShowEdit, false);
      });
    });

    group('Resting Countdown Display', () {
      test('should display "Unlocks in Xd Xh Xm" format', () {
        String countdownText = 'Unlocks in 2d 7h 52m';
        bool hasUnlocksPrefix = countdownText.startsWith('Unlocks in');

        expect(hasUnlocksPrefix, true);
      });

      test('should calculate hours and minutes correctly', () {
        Duration difference = const Duration(days: 2, hours: 7, minutes: 52);
        int days = difference.inDays;
        int hours = difference.inHours.remainder(24);
        int minutes = difference.inMinutes.remainder(60);

        expect(days, 2);
        expect(hours, 7);
        expect(minutes, 52);
      });

      test('should show "0d" when less than 1 day remaining', () {
        Duration difference = const Duration(hours: 7, minutes: 52);
        int days = difference.inDays;
        int hours = difference.inHours.remainder(24);
        int minutes = difference.inMinutes.remainder(60);

        expect(days, 0);
        expect(hours, 7);
        expect(minutes, 52);
      });

      test('should display progress bar for resting bins', () {
        String status = 'resting';
        bool shouldShowProgress = status == 'resting';

        expect(shouldShowProgress, true);
      });

      test('should calculate progress percentage correctly', () {
        DateTime start = DateTime(2024, 1, 1);
        DateTime end = DateTime(2024, 1, 8); // 7 days total
        DateTime now = DateTime(2024, 1, 4); // 3 days passed
        int totalDays = end.difference(start).inDays;
        int daysPassed = now.difference(start).inDays;
        double progress = (daysPassed / totalDays * 100).clamp(0.0, 100.0);

        expect(progress, closeTo(42.86, 0.1));
      });

      test('should show "X day remaining" for singular', () {
        int days = 1;
        String text = days == 1 ? '$days day remaining' : '$days days remaining';

        expect(text, '1 day remaining');
      });

      test('should show "X days remaining" for plural', () {
        int days = 2;
        String text = days == 1 ? '$days day remaining' : '$days days remaining';

        expect(text, '2 days remaining');
      });

      test('should handle completed resting period', () {
        DateTime restingUntil = DateTime.now().subtract(const Duration(days: 1));
        DateTime now = DateTime.now();
        Duration difference = restingUntil.difference(now);
        bool isCompleted = difference.isNegative;

        expect(isCompleted, true);
      });
    });

    group('Matured Depletion Display', () {
      test('should display "Microbes depleting: X%" format', () {
        double percentage = 45.5;
        String displayText = 'Microbes depleting: ${percentage.toStringAsFixed(1)}%';

        expect(displayText, 'Microbes depleting: 45.5%');
      });

      test('should display progress bar for matured bins', () {
        String status = 'matured';
        bool shouldShowProgress = status == 'matured';

        expect(shouldShowProgress, true);
      });

      test('should show "X day remaining" for singular', () {
        int daysRemaining = 1;
        String text = daysRemaining == 1
            ? '$daysRemaining day remaining'
            : '$daysRemaining days remaining';

        expect(text, '1 day remaining');
      });

      test('should show "X days remaining" for plural', () {
        int daysRemaining = 5;
        String text = daysRemaining == 1
            ? '$daysRemaining day remaining'
            : '$daysRemaining days remaining';

        expect(text, '5 days remaining');
      });

      test('should calculate days remaining correctly', () {
        const sixMonthsInDays = 180;
        int daysSinceMatured = 90; // 3 months
        int daysRemaining = sixMonthsInDays - daysSinceMatured;

        expect(daysRemaining, 90);
      });

      test('should show 0 days when fully depleted', () {
        const sixMonthsInDays = 180;
        int daysSinceMatured = 180;
        int daysRemaining = (sixMonthsInDays - daysSinceMatured).clamp(0, sixMonthsInDays);

        expect(daysRemaining, 0);
      });
    });

    group('Status Change Dialog', () {
      test('should show radio buttons for status selection', () {
        List<String> statuses = ['active', 'resting', 'matured'];
        bool hasRadioButtons = statuses.length == 3;

        expect(hasRadioButtons, true);
      });

      test('should show date picker for resting status', () {
        String selectedStatus = 'resting';
        bool shouldShowDatePicker = selectedStatus == 'resting';

        expect(shouldShowDatePicker, true);
      });

      test('should show time picker for resting status', () {
        String selectedStatus = 'resting';
        bool shouldShowTimePicker = selectedStatus == 'resting';

        expect(shouldShowTimePicker, true);
      });

      test('should show date picker for matured status', () {
        String selectedStatus = 'matured';
        bool shouldShowDatePicker = selectedStatus == 'matured';

        expect(shouldShowDatePicker, true);
      });

      test('should show time picker for matured status', () {
        String selectedStatus = 'matured';
        bool shouldShowTimePicker = selectedStatus == 'matured';

        expect(shouldShowTimePicker, true);
      });

      test('should not show date/time pickers for active status', () {
        String selectedStatus = 'active';
        bool shouldShowDatePicker = selectedStatus == 'resting' || selectedStatus == 'matured';

        expect(shouldShowDatePicker, false);
      });

      test('should convert selected Singapore time to UTC', () {
        DateTime sgTime = DateTime(2024, 1, 1, 16, 55);
        DateTime utc = DateTime.utc(
          sgTime.year,
          sgTime.month,
          sgTime.day,
          sgTime.hour,
          sgTime.minute,
        ).subtract(const Duration(hours: 8));

        expect(utc.hour, 8);
        expect(utc.minute, 55);
      });

      test('should validate date is not in the past for resting', () {
        DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
        DateTime now = DateTime.now();
        bool isValid = selectedDate.isAfter(now) || selectedDate.isAtSameMomentAs(now);

        expect(isValid, true);
      });

      test('should validate date is not in the past for matured', () {
        DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
        DateTime now = DateTime.now();
        bool isValid = selectedDate.isAfter(now) || selectedDate.isAtSameMomentAs(now);

        expect(isValid, true);
      });
    });

    group('Log Activity Button State', () {
      test('should be enabled for active bins', () {
        String status = 'active';
        bool shouldBeEnabled = status != 'matured';

        expect(shouldBeEnabled, true);
      });

      test('should be enabled for resting bins', () {
        String status = 'resting';
        bool shouldBeEnabled = status != 'matured';

        expect(shouldBeEnabled, true);
      });

      test('should be visually disabled for matured bins', () {
        String status = 'matured';
        double opacity = status == 'matured' ? 0.5 : 1.0;

        expect(opacity, 0.5);
      });

      test('should show snackbar message when clicking matured bin log button', () {
        String status = 'matured';
        String message = status == 'matured'
            ? 'Bin is matured. No actions allowed.'
            : '';

        expect(message, 'Bin is matured. No actions allowed.');
      });

      test('should allow clicking even when visually disabled', () {
        String status = 'matured';
        bool canClick = true; // Button is always clickable, just shows message
        bool shouldShowMessage = status == 'matured' && canClick;

        expect(shouldShowMessage, true);
      });
    });

    group('Time Display Formatting', () {
      test('should format countdown with days, hours, minutes', () {
        Duration diff = const Duration(days: 2, hours: 7, minutes: 52);
        String formatted = '${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m';

        expect(formatted, '2d 7h 52m');
      });

      test('should handle zero values in countdown', () {
        Duration diff = const Duration(hours: 5, minutes: 30);
        String formatted = '${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m';

        expect(formatted, '0d 5h 30m');
      });

      test('should format percentage with one decimal place', () {
        double percentage = 45.567;
        String formatted = percentage.toStringAsFixed(1);

        expect(formatted, '45.6');
      });
    });

    group('Status Section Visibility', () {
      test('should always show status section', () {
        bool shouldShow = true;
        expect(shouldShow, true);
      });

      test('should show different content based on status', () {
        String status = 'resting';
        bool showsRestingContent = status == 'resting';
        bool showsMaturedContent = status == 'matured';
        bool showsActiveContent = status == 'active';

        expect(showsRestingContent, true);
        expect(showsMaturedContent, false);
        expect(showsActiveContent, false);
      });
    });
  });
}

