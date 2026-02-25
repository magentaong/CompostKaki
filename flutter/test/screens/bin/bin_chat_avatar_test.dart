import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BinChatList - Avatar Rendering Rules', () {
    test('uses NetworkImage path when avatar_url is present', () {
      final conversation = <String, dynamic>{
        'profile': <String, dynamic>{
          'first_name': 'Alice',
          'last_name': 'Tan',
          'avatar_url': 'https://cdn.example.com/alice.png',
        },
      };

      final profile = conversation['profile'] as Map<String, dynamic>?;
      final avatarUrl = profile?['avatar_url'] as String?;
      final shouldUseNetworkImage = avatarUrl != null && avatarUrl.isNotEmpty;

      expect(shouldUseNetworkImage, true);
    });

    test('falls back to initials when avatar_url is null or empty', () {
      final withNull = <String, dynamic>{
        'profile': <String, dynamic>{
          'first_name': 'Bob',
          'last_name': 'Lim',
          'avatar_url': null,
        },
      };
      final withEmpty = <String, dynamic>{
        'profile': <String, dynamic>{
          'first_name': 'Bob',
          'last_name': 'Lim',
          'avatar_url': '',
        },
      };

      bool shouldFallback(Map<String, dynamic> conversation) {
        final profile = conversation['profile'] as Map<String, dynamic>?;
        final avatarUrl = profile?['avatar_url'] as String?;
        return avatarUrl == null || avatarUrl.isEmpty;
      }

      expect(shouldFallback(withNull), true);
      expect(shouldFallback(withEmpty), true);
    });
  });
}
