import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/auth/presentation/onboarding_screen.dart';
import 'package:questly/features/auth/presentation/sign_in_screen.dart';
import 'package:questly/features/challenge/presentation/this_week_screen.dart';
import 'package:questly/main.dart';

import 'fakes.dart';

void main() {
  testWidgets('without backend config the app shows the offline screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuestlyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Backend not configured'), findsOneWidget);
  });

  testWidgets('full Phase 1 flow: sign up, set username, sign out, sign in', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    await tester.pumpWidget(testApp(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    // Signed out → sign-in screen.
    expect(find.byType(SignInScreen), findsOneWidget);

    // Create an account.
    await tester.tap(find.byKey(const Key('toggle-mode')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('email')), 'new@test.dev');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    // New user → onboarding.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('username')), 'NewUser');
    await tester.tap(find.byKey(const Key('age')));
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();

    // Onboarded → home, username normalised to lowercase.
    expect(find.byType(ThisWeekScreen), findsOneWidget);
    expect(find.text('Welcome, @newuser'), findsOneWidget);

    // Sign out → back to sign-in.
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    // Sign back in → straight to home (no onboarding again).
    await tester.enterText(find.byKey(const Key('email')), 'new@test.dev');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, @newuser'), findsOneWidget);
  });
}
