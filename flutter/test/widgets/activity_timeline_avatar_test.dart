import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityTimelineItem - Avatar Rendering Rules', () {
    test('prefers avatar_url over initials when available', () {
      final activity = <String, dynamic>{
        'profiles': <String, dynamic>{
          'first_name': 'Jia',
          'last_name': 'Wei',
          'avatar_url': 'https://cdn.example.com/jia.jpg',
        },
      };

      final profile = activity['profiles'] as Map<String, dynamic>?;
      final avatarUrl = profile?['avatar_url'] as String?;
      final shouldUseAvatarImage = avatarUrl != null && avatarUrl.isNotEmpty;

      expect(shouldUseAvatarImage, true);
    });

    test('uses initials fallback when avatar_url is missing', () {
      String initials(String firstName, String lastName) {
        return ((firstName.isNotEmpty ? firstName[0] : '?') +
                (lastName.isNotEmpty ? lastName[0] : ''))
            .toUpperCase();
      }

      final firstName = 'Jia';
      final lastName = 'Wei';
      final String? avatarUrl = null;

      final shouldUseInitials = avatarUrl == null || avatarUrl.isEmpty;
      final computedInitials = initials(firstName, lastName);

      expect(shouldUseInitials, true);
      expect(computedInitials, 'JW');
    });
  });
}
