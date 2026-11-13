import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/challenge/domain/challenge.dart';
import 'package:questly/features/profile/domain/profile.dart';

import '../../fakes.dart';

void main() {
  final now = DateTime.utc(2026, 11, 13, 12);
  late FakeChallengeRepository challenges;

  Future<void> pumpHome(
    WidgetTester tester, {
    Challenge? current,
    ParticipationStatus? existingAnswer,
  }) async {
    challenges = FakeChallengeRepository(current: current, othersAccepted: 2);
    if (existingAnswer != null) {
      challenges.statuses[('c1', 'me')] = existingAnswer;
    }
    final profiles = FakeProfileRepository()
      ..profiles['me'] = Profile(
        id: 'me',
        username: 'me',
        ageConfirmed: true,
        createdAt: now,
      );
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthRepository(signedInAs: 'me'),
        profiles: profiles,
        challenges: challenges,
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the current challenge with countdown and tips', (
    tester,
  ) async {
    await pumpHome(tester, current: liveChallenge(now));

    expect(find.text('Write a four-line poem'), findsOneWidget);
    expect(find.text('Poetry'), findsOneWidget);
    expect(find.text('2d 3h left'), findsOneWidget);
    expect(find.text('Start with one concrete image'), findsOneWidget);
    expect(find.text('2 questers have accepted'), findsOneWidget);
    expect(find.byKey(const Key('accept')), findsOneWidget);
    expect(find.byKey(const Key('decline')), findsOneWidget);
  });

  testWidgets('accepting persists and updates the count', (tester) async {
    await pumpHome(tester, current: liveChallenge(now));

    await tester.tap(find.byKey(const Key('accept')));
    await tester.pumpAndSettle();

    expect(challenges.statuses[('c1', 'me')], ParticipationStatus.accepted);
    expect(find.byKey(const Key('status-accepted')), findsOneWidget);
    expect(find.text('3 questers have accepted'), findsOneWidget);
  });

  testWidgets('decline, then change to accept', (tester) async {
    await pumpHome(tester, current: liveChallenge(now));

    await tester.tap(find.byKey(const Key('decline')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status-declined')), findsOneWidget);
    expect(challenges.statuses[('c1', 'me')], ParticipationStatus.declined);

    await tester.tap(find.byKey(const Key('accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status-accepted')), findsOneWidget);
    expect(challenges.statuses[('c1', 'me')], ParticipationStatus.accepted);
  });

  testWidgets('existing answer is shown on load', (tester) async {
    await pumpHome(
      tester,
      current: liveChallenge(now),
      existingAnswer: ParticipationStatus.accepted,
    );
    expect(find.byKey(const Key('status-accepted')), findsOneWidget);
    expect(find.byKey(const Key('accept')), findsNothing);
  });

  testWidgets('closed challenge shows a message', (tester) async {
    await pumpHome(tester, current: liveChallenge(now));
    challenges.closed = true;

    await tester.tap(find.byKey(const Key('accept')));
    await tester.pumpAndSettle();
    expect(find.text('This quest has closed.'), findsOneWidget);
  });

  testWidgets('empty state between challenges', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('no-quest')), findsOneWidget);
  });
}
