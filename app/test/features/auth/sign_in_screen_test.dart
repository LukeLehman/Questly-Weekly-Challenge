import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/auth/presentation/sign_in_screen.dart';

import '../../fakes.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> pumpApp(WidgetTester tester) async {
    auth = FakeAuthRepository();
    await tester.pumpWidget(
      testApp(auth: auth, profiles: FakeProfileRepository()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('validates email and password before submitting', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('password')), 'short');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('shows the server error for wrong credentials', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('email')), 'alice@test.dev');
    await tester.enterText(find.byKey(const Key('password')), 'wrongpass');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('toggle switches between sign in and create account', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Sign in'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-mode')));
    await tester.pump();
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('Google button is hidden unless enabled', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('google')), findsNothing);
  });
}
