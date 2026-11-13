import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/main.dart';

void main() {
  testWidgets('app boots to the placeholder without backend config', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuestlyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Questly'), findsOneWidget);
    expect(find.byKey(const Key('backend-status')), findsOneWidget);
    expect(find.text('Backend not configured'), findsOneWidget);
  });
}
