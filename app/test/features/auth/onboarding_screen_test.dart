import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/auth/presentation/onboarding_screen.dart';
import 'package:questly/features/challenge/presentation/this_week_screen.dart';
import 'package:questly/features/profile/domain/profile.dart';

import '../../fakes.dart';

void main() {
  late FakeProfileRepository profiles;

  Future<void> pumpOnboarding(WidgetTester tester) async {
    profiles = FakeProfileRepository()
      ..profiles['taken-id'] = Profile(
        id: 'taken-id',
        username: 'alice',
        ageConfirmed: true,
        createdAt: DateTime(2026),
      );
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthRepository(signedInAs: 'me'),
        profiles: profiles,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  }

  testWidgets('rejects an invalid username', (tester) async {
    await pumpOnboarding(tester);
    await tester.enterText(find.byKey(const Key('username')), 'a!');
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pump();
    expect(find.text('At least 3 characters'), findsOneWidget);
  });

  testWidgets('requires the 13+ confirmation', (tester) async {
    await pumpOnboarding(tester);
    await tester.enterText(find.byKey(const Key('username')), 'newbie');
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();
    expect(
      find.text('You must be 13 or older to use Questly.'),
      findsOneWidget,
    );
    expect(profiles.profiles['me']?.username, isNull);
  });

  testWidgets('reports a taken username', (tester) async {
    await pumpOnboarding(tester);
    await tester.enterText(find.byKey(const Key('username')), 'Alice');
    await tester.tap(find.byKey(const Key('age')));
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();
    expect(find.text('That username is taken'), findsOneWidget);
  });

  testWidgets('saves profile and goes home', (tester) async {
    await pumpOnboarding(tester);
    await tester.enterText(find.byKey(const Key('username')), 'newbie');
    await tester.enterText(find.byKey(const Key('display-name')), 'New B');
    await tester.tap(find.byKey(const Key('private')));
    await tester.tap(find.byKey(const Key('age')));
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();

    final saved = profiles.profiles['me']!;
    expect(saved.username, 'newbie');
    expect(saved.displayName, 'New B');
    expect(saved.isPrivate, isTrue);
    expect(find.byType(ThisWeekScreen), findsOneWidget);
  });
}
