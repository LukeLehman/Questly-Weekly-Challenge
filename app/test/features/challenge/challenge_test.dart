import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/challenge/domain/challenge.dart';

void main() {
  group('formatRemaining', () {
    test('days and hours', () {
      expect(formatRemaining(const Duration(days: 2, hours: 3)), '2d 3h left');
    });
    test('hours and minutes', () {
      expect(
        formatRemaining(const Duration(hours: 4, minutes: 12)),
        '4h 12m left',
      );
    });
    test('minutes and padded seconds', () {
      expect(
        formatRemaining(const Duration(minutes: 9, seconds: 5)),
        '9m 05s left',
      );
    });
    test('closed at zero or below', () {
      expect(formatRemaining(Duration.zero), 'Closed');
      expect(formatRemaining(const Duration(seconds: -5)), 'Closed');
    });
  });

  group('Challenge window is [opensAt, closesAt)', () {
    final c = Challenge(
      id: 'c',
      title: 'Test',
      description: 'd',
      category: 'baking',
      opensAt: DateTime.utc(2026, 11, 9),
      closesAt: DateTime.utc(2026, 11, 16),
    );

    test('open at the start instant', () {
      expect(c.isOpenAt(DateTime.utc(2026, 11, 9)), isTrue);
    });
    test('closed at the end instant', () {
      expect(c.isOpenAt(DateTime.utc(2026, 11, 16)), isFalse);
    });
    test('remaining never negative', () {
      expect(c.remainingAt(DateTime.utc(2026, 12)), Duration.zero);
    });
  });

  test('parses an RPC row', () {
    final c = Challenge.fromJson({
      'id': 'c1',
      'title': 'Bake',
      'description': 'd',
      'category': 'baking',
      'tips': ['a', 'b'],
      'cover_key': null,
      'opens_at': '2026-11-09T00:00:00+00:00',
      'closes_at': '2026-11-16T00:00:00+00:00',
      'created_at': '2026-11-01T00:00:00+00:00',
    });
    expect(c.tips, ['a', 'b']);
    expect(c.closesAt, DateTime.utc(2026, 11, 16));
  });

  test('ParticipationStatus.fromName', () {
    expect(
      ParticipationStatus.fromName('accepted'),
      ParticipationStatus.accepted,
    );
    expect(ParticipationStatus.fromName(null), isNull);
    expect(ParticipationStatus.fromName('bogus'), isNull);
  });
}
