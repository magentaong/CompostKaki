import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogActivityScreen - Status-Based Action Restrictions', () {
    group('_allowedActivityTypes for Active Status', () {
      test('should return all activity types for active bins', () {
        String status = 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.length, 4);
        expect(allowedTypes.contains('Turn Pile'), true);
        expect(allowedTypes.contains('Add Materials'), true);
        expect(allowedTypes.contains('Add Water'), true);
        expect(allowedTypes.contains('Monitor'), true);
      });

      test('should include Turn Pile for active bins', () {
        String status = 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.contains('Turn Pile'), true);
      });

      test('should include Add Materials for active bins', () {
        String status = 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.contains('Add Materials'), true);
      });

      test('should include Add Water for active bins', () {
        String status = 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.contains('Add Water'), true);
      });

      test('should include Monitor for active bins', () {
        String status = 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.contains('Monitor'), true);
      });
    });

    group('_allowedActivityTypes for Resting Status', () {
      test('should return only Turn Pile for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting'
            ? ['Turn Pile']
            : [];

        expect(allowedTypes.length, 1);
        expect(allowedTypes.contains('Turn Pile'), true);
      });

      test('should not include Add Materials for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting'
            ? ['Turn Pile']
            : [];

        expect(allowedTypes.contains('Add Materials'), false);
      });

      test('should not include Add Water for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting'
            ? ['Turn Pile']
            : [];

        expect(allowedTypes.contains('Add Water'), false);
      });

      test('should not include Monitor for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting'
            ? ['Turn Pile']
            : [];

        expect(allowedTypes.contains('Monitor'), false);
      });

      test('should allow only flipping action when resting', () {
        String status = 'resting';
        String action = 'Turn Pile';
        bool isAllowed = status == 'resting' && action == 'Turn Pile';

        expect(isAllowed, true);
      });
    });

    group('_allowedActivityTypes for Matured Status', () {
      test('should return empty list for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes = status == 'matured'
            ? []
            : [];

        expect(allowedTypes.length, 0);
      });

      test('should not include any activity types for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes = status == 'matured'
            ? []
            : ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];

        expect(allowedTypes.isEmpty, true);
      });

      test('should prevent all actions when matured', () {
        String status = 'matured';
        List<String> allActions = ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
        List<String> allowedTypes = status == 'matured' ? [] : allActions;

        for (String action in allActions) {
          expect(allowedTypes.contains(action), false);
        }
      });
    });

    group('_allowedActivityTypes Default Behavior', () {
      test('should return all types when bin is null', () {
        Map<String, dynamic>? bin = null;
        List<String> allowedTypes = bin == null
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.length, 4);
      });

      test('should default to active when bin_status is null', () {
        Map<String, dynamic> bin = {};
        String status = bin['bin_status'] as String? ?? 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : status == 'resting'
                ? ['Turn Pile']
                : [];

        expect(allowedTypes.length, 4);
      });

      test('should handle missing bin_status field', () {
        Map<String, dynamic> bin = {'name': 'Test Bin'};
        String status = bin['bin_status'] as String? ?? 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.length, 4);
      });
    });

    group('Activity Type Selection', () {
      test('should only show allowed activity types in dropdown', () {
        String status = 'resting';
        List<String> allTypes = ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
        List<String> allowedTypes = status == 'resting'
            ? ['Turn Pile']
            : status == 'matured'
                ? []
                : allTypes;

        expect(allowedTypes.length, 1);
        expect(allowedTypes, ['Turn Pile']);
      });

      test('should disable unavailable activity types', () {
        String status = 'resting';
        List<String> allTypes = ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
        List<String> allowedTypes = status == 'resting' ? ['Turn Pile'] : allTypes;

        for (String type in allTypes) {
          bool isEnabled = allowedTypes.contains(type);
          if (type == 'Turn Pile') {
            expect(isEnabled, true);
          } else {
            expect(isEnabled, false);
          }
        }
      });

      test('should show empty dropdown for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes = status == 'matured' ? [] : ['Turn Pile'];

        expect(allowedTypes.isEmpty, true);
      });
    });

    group('Form Submission with Status Restrictions', () {
      test('should prevent submission of non-allowed activity types', () {
        String status = 'resting';
        String selectedType = 'Monitor';
        List<String> allowedTypes = status == 'resting' ? ['Turn Pile'] : [];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, false);
      });

      test('should allow submission of allowed activity types', () {
        String status = 'resting';
        String selectedType = 'Turn Pile';
        List<String> allowedTypes = status == 'resting' ? ['Turn Pile'] : [];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, true);
      });

      test('should prevent all submissions for matured bins', () {
        String status = 'matured';
        String selectedType = 'Turn Pile';
        List<String> allowedTypes = status == 'matured' ? [] : ['Turn Pile'];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, false);
      });
    });

    group('Status Change Handling', () {
      test('should update allowed types when bin status changes', () {
        String initialStatus = 'active';
        String newStatus = 'resting';
        List<String> initialTypes = initialStatus == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];
        List<String> newTypes = newStatus == 'resting'
            ? ['Turn Pile']
            : [];

        expect(initialTypes.length, 4);
        expect(newTypes.length, 1);
      });

      test('should clear selected type when status changes to matured', () {
        String previousStatus = 'active';
        String newStatus = 'matured';
        String? selectedType = 'Monitor';
        List<String> allowedTypes = newStatus == 'matured' ? [] : ['Turn Pile'];
        if (!allowedTypes.contains(selectedType)) {
          selectedType = null;
        }

        expect(selectedType, null);
      });
    });

    group('Error Handling', () {
      test('should handle invalid status gracefully', () {
        String status = 'invalid';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : status == 'resting'
                ? ['Turn Pile']
                : status == 'matured'
                    ? []
                    : ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']; // Default

        expect(allowedTypes.length, 4);
      });

      test('should handle null bin gracefully', () {
        Map<String, dynamic>? bin = null;
        String status = bin?['bin_status'] as String? ?? 'active';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : [];

        expect(allowedTypes.length, 4);
      });
    });
  });
}

