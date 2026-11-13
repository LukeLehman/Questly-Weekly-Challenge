import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/profile/domain/profile.dart';
import 'package:questly/features/profile/domain/username.dart';

void main() {
  group('validateUsername', () {
    test('accepts valid names (case-insensitive)', () {
      expect(validateUsername('alice_99'), isNull);
      expect(validateUsername('  Alice  '), isNull);
    });

    test('rejects bad names', () {
      expect(validateUsername(''), isNotNull);
      expect(validateUsername('ab'), isNotNull);
      expect(validateUsername('a' * 21), isNotNull);
      expect(validateUsername('has space'), isNotNull);
      expect(validateUsername('emoji🙂'), isNotNull);
    });
  });

  test('Profile parses a Supabase row', () {
    final p = Profile.fromJson({
      'id': 'u1',
      'username': 'alice',
      'display_name': 'Alice',
      'avatar_key': null,
      'bio': null,
      'is_private': true,
      'age_confirmed': true,
      'created_at': '2026-11-13T10:00:00+00:00',
    });
    expect(p.displayName, 'Alice');
    expect(p.isPrivate, isTrue);
    expect(p.isOnboarded, isTrue);
  });
}
