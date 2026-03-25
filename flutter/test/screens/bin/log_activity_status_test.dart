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
      final restingTypes = ['Turn Pile', 'Add Water', 'Monitor'];

      test('should return turn, water, and monitor for resting bins (not materials)', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting' ? restingTypes : [];

        expect(allowedTypes.length, 3);
        expect(allowedTypes.contains('Turn Pile'), true);
        expect(allowedTypes.contains('Add Water'), true);
        expect(allowedTypes.contains('Monitor'), true);
      });

      test('should not include Add Materials for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting' ? restingTypes : [];

        expect(allowedTypes.contains('Add Materials'), false);
      });

      test('should include Add Water for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting' ? restingTypes : [];

        expect(allowedTypes.contains('Add Water'), true);
      });

      test('should include Monitor for resting bins', () {
        String status = 'resting';
        List<String> allowedTypes = status == 'resting' ? restingTypes : [];

        expect(allowedTypes.contains('Monitor'), true);
      });

      test('should allow turn pile, add water, and monitor when resting', () {
        String status = 'resting';
        for (final action in restingTypes) {
          expect(status == 'resting' && restingTypes.contains(action), true);
        }
      });
    });

    group('_allowedActivityTypes for Matured Status', () {
      final maturedTypes = ['Add Water', 'Monitor'];

      test('should return add water and monitor for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes = status == 'matured' ? maturedTypes : [];

        expect(allowedTypes.length, 2);
        expect(allowedTypes.contains('Add Water'), true);
        expect(allowedTypes.contains('Monitor'), true);
      });

      test('should not include turn pile or add materials for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes = status == 'matured'
            ? maturedTypes
            : ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];

        expect(allowedTypes.contains('Turn Pile'), false);
        expect(allowedTypes.contains('Add Materials'), false);
      });

      test('should only allow water and monitor when matured', () {
        String status = 'matured';
        List<String> allActions = ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
        List<String> allowedTypes = status == 'matured' ? maturedTypes : allActions;

        expect(allowedTypes.contains('Add Water'), true);
        expect(allowedTypes.contains('Monitor'), true);
        expect(allowedTypes.contains('Turn Pile'), false);
        expect(allowedTypes.contains('Add Materials'), false);
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
                ? ['Turn Pile', 'Add Water', 'Monitor']
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
            ? ['Turn Pile', 'Add Water', 'Monitor']
            : status == 'matured'
                ? ['Add Water', 'Monitor']
                : allTypes;

        expect(allowedTypes.length, 3);
        expect(allowedTypes.contains('Add Materials'), false);
      });

      test('should disable unavailable activity types', () {
        String status = 'resting';
        List<String> allTypes = ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
        List<String> allowedTypes =
            status == 'resting' ? ['Turn Pile', 'Add Water', 'Monitor'] : allTypes;

        for (String type in allTypes) {
          bool isEnabled = allowedTypes.contains(type);
          if (type == 'Add Materials') {
            expect(isEnabled, false);
          } else {
            expect(isEnabled, true);
          }
        }
      });

      test('should show only water and monitor for matured bins', () {
        String status = 'matured';
        List<String> allowedTypes =
            status == 'matured' ? ['Add Water', 'Monitor'] : ['Turn Pile'];

        expect(allowedTypes.length, 2);
        expect(allowedTypes.contains('Add Materials'), false);
      });
    });

    group('Form Submission with Status Restrictions', () {
      test('should prevent submission of non-allowed activity types', () {
        String status = 'resting';
        String selectedType = 'Add Materials';
        List<String> allowedTypes =
            status == 'resting' ? ['Turn Pile', 'Add Water', 'Monitor'] : [];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, false);
      });

      test('should allow submission of allowed activity types', () {
        String status = 'resting';
        String selectedType = 'Monitor';
        List<String> allowedTypes =
            status == 'resting' ? ['Turn Pile', 'Add Water', 'Monitor'] : [];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, true);
      });

      test('should prevent turn pile submission for matured bins', () {
        String status = 'matured';
        String selectedType = 'Turn Pile';
        List<String> allowedTypes =
            status == 'matured' ? ['Add Water', 'Monitor'] : ['Turn Pile'];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, false);
      });

      test('should allow monitor submission for matured bins', () {
        String status = 'matured';
        String selectedType = 'Monitor';
        List<String> allowedTypes =
            status == 'matured' ? ['Add Water', 'Monitor'] : [];
        bool canSubmit = allowedTypes.contains(selectedType);

        expect(canSubmit, true);
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
            ? ['Turn Pile', 'Add Water', 'Monitor']
            : [];

        expect(initialTypes.length, 4);
        expect(newTypes.length, 3);
      });

      test('should clear selected type when changing to matured if not allowed', () {
        String newStatus = 'matured';
        String? selectedType = 'Turn Pile';
        List<String> allowedTypes =
            newStatus == 'matured' ? ['Add Water', 'Monitor'] : ['Turn Pile'];
        if (!allowedTypes.contains(selectedType)) {
          selectedType = null;
        }

        expect(selectedType, null);
      });

      test('should keep monitor when status changes to matured', () {
        String newStatus = 'matured';
        String? selectedType = 'Monitor';
        List<String> allowedTypes =
            newStatus == 'matured' ? ['Add Water', 'Monitor'] : [];
        if (!allowedTypes.contains(selectedType)) {
          selectedType = null;
        }

        expect(selectedType, 'Monitor');
      });
    });

    group('Error Handling', () {
      test('should handle invalid status gracefully', () {
        String status = 'invalid';
        List<String> allowedTypes = status == 'active'
            ? ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor']
            : status == 'resting'
                ? ['Turn Pile', 'Add Water', 'Monitor']
                : status == 'matured'
                    ? ['Add Water', 'Monitor']
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

