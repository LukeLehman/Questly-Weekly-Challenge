import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questly/features/challenge/domain/challenge.dart';
import 'package:questly/features/challenge/presentation/this_week_screen.dart';
import 'package:questly/features/profile/domain/profile.dart';
import 'package:questly/features/upload/domain/submission.dart';

import '../../fakes.dart';

/// The Post button is below the fold in the 800x600 test window.
Future<void> tapPost(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('post')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('post')));
}

void main() {
  final now = DateTime.utc(2026, 11, 13, 12);
  late FakeSubmissionRepository submissions;
  late FakeMediaProcessor processor;

  /// Signed-in user who has [status] for the live challenge; opens Upload.
  Future<void> pumpUpload(
    WidgetTester tester, {
    ParticipationStatus? status = ParticipationStatus.accepted,
    bool privateAccount = false,
  }) async {
    submissions = FakeSubmissionRepository();
    processor = FakeMediaProcessor();
    final challenges = FakeChallengeRepository(current: liveChallenge(now));
    if (status != null) challenges.statuses[('c1', 'me')] = status;
    final profiles = FakeProfileRepository()
      ..profiles['me'] = Profile(
        id: 'me',
        username: 'me',
        ageConfirmed: true,
        isPrivate: privateAccount,
        createdAt: now,
      );
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthRepository(signedInAs: 'me'),
        profiles: profiles,
        challenges: challenges,
        submissions: submissions,
        processor: processor,
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
    if (status == ParticipationStatus.accepted) {
      await tester.tap(find.byKey(const Key('post-entry')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('video: pick, upload with progress, save, badge', (tester) async {
    await pumpUpload(tester);
    expect(find.byKey(const Key('post')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pick-gallery')));
    await tester.pumpAndSettle();
    expect(find.text('clip.mp4'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('caption')), 'first try!');
    submissions.uploadGate = Completer<void>();
    await tapPost(tester);
    await tester.pump();
    await tester.pump();

    // Mid-upload: progress bar visible, post button gone.
    expect(find.byKey(const Key('progress')), findsOneWidget);
    expect(find.byKey(const Key('post')), findsNothing);

    submissions.uploadGate!.complete();
    await tester.pumpAndSettle();

    final saved = submissions.submissions[('c1', 'me')]!;
    expect(saved.mediaType, MediaKind.video);
    expect(saved.mediaKey, 'submissions/c1/me/x.mp4');
    expect(saved.thumbKey, 'submissions/c1/me/x.jpg');
    expect(saved.caption, 'first try!');
    expect(
      submissions.uploads.keys,
      containsAll(['https://r2.test/media', 'https://r2.test/thumb']),
    );
    expect(find.byKey(const Key('badge')), findsOneWidget);
    expect(find.text('Badge earned!'), findsOneWidget);

    // Back home: posted state, no "change my mind".
    await tester.tap(find.byKey(const Key('done')));
    await tester.pumpAndSettle();
    expect(find.byType(ThisWeekScreen), findsOneWidget);
    expect(find.byKey(const Key('status-posted')), findsOneWidget);
    expect(find.byKey(const Key('change-to-decline')), findsNothing);
  });

  testWidgets('text entry posts without any upload', (tester) async {
    await pumpUpload(tester);
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('body')),
      'Roses are red,\nquests are new',
    );
    await tester.pump();
    await tapPost(tester);
    await tester.pumpAndSettle();

    final saved = submissions.submissions[('c1', 'me')]!;
    expect(saved.mediaType, MediaKind.text);
    expect(saved.body, 'Roses are red,\nquests are new');
    expect(submissions.uploads, isEmpty);
    expect(find.text('Badge earned!'), findsOneWidget);
  });

  testWidgets('post is disabled until something is picked', (tester) async {
    await pumpUpload(tester);
    final post = tester.widget<FilledButton>(find.byKey(const Key('post')));
    expect(post.onPressed, isNull);
  });

  testWidgets('shows processing errors and allows retry', (tester) async {
    await pumpUpload(tester);
    processor.error = const UploadException(
      'Videos can be at most 60 seconds long.',
    );
    await tester.tap(find.byKey(const Key('pick-gallery')));
    await tester.pumpAndSettle();
    await tapPost(tester);
    await tester.pumpAndSettle();

    expect(find.text('Videos can be at most 60 seconds long.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(submissions.submissions, isEmpty);
  });

  testWidgets('shows server refusals', (tester) async {
    await pumpUpload(tester);
    submissions.requestError = const UploadException(
      'video must be under 30 MB',
    );
    await tester.tap(find.byKey(const Key('pick-gallery')));
    await tester.pumpAndSettle();
    await tapPost(tester);
    await tester.pumpAndSettle();
    expect(find.text('video must be under 30 MB'), findsOneWidget);
  });

  testWidgets('private accounts default to friends-only', (tester) async {
    await pumpUpload(tester, privateAccount: true);
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body')), 'hello');
    await tester.pump();
    await tapPost(tester);
    await tester.pumpAndSettle();
    expect(
      submissions.submissions[('c1', 'me')]!.visibility,
      PostVisibility.friends,
    );
  });

  testWidgets('no Post button until the quest is accepted', (tester) async {
    await pumpUpload(tester, status: null);
    expect(find.byKey(const Key('post-entry')), findsNothing);
  });
}
