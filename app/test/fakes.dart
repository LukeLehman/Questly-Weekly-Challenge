import 'dart:async';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:questly/features/upload/data/media_picker.dart';
import 'package:questly/features/upload/data/media_processor.dart';
import 'package:questly/features/upload/data/submission_repository.dart';
import 'package:questly/features/upload/domain/submission.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questly/core/clock.dart';
import 'package:questly/core/providers.dart';
import 'package:questly/features/challenge/data/challenge_repository.dart';
import 'package:questly/features/challenge/domain/challenge.dart';
import 'package:questly/features/auth/data/auth_repository.dart';
import 'package:questly/features/profile/data/profile_repository.dart';
import 'package:questly/features/profile/domain/profile.dart';
import 'package:questly/features/profile/domain/username.dart';
import 'package:questly/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// In-memory auth: one known account (`alice@test.dev` / `password1`).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({String? signedInAs}) : _userId = signedInAs;

  final _changes = StreamController<String?>.broadcast();
  String? _userId;
  final accounts = <String, ({String password, String id})>{
    'alice@test.dev': (password: 'password1', id: 'alice-id'),
  };

  @override
  Stream<String?> userIdChanges() async* {
    yield _userId;
    yield* _changes.stream;
  }

  void _set(String? id) {
    _userId = id;
    _changes.add(id);
  }

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    if (accounts.containsKey(email)) {
      throw const AuthException('User already registered');
    }
    final id = 'user-${accounts.length}';
    accounts[email] = (password: password, id: id);
    _set(id);
    return false;
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final account = accounts[email];
    if (account == null || account.password != password) {
      throw const AuthException('Invalid login credentials');
    }
    _set(account.id);
  }

  @override
  Future<void> signInWithGoogle() async => _set('google-id');

  @override
  Future<void> signOut() async => _set(null);
}

/// In-memory profiles. A profile row exists for any user id requested,
/// mimicking the sign-up trigger.
class FakeProfileRepository implements ProfileRepository {
  final profiles = <String, Profile>{};

  /// Accounts that no longer exist (no profile row), e.g. after a DB reset.
  final deletedUsers = <String>{};

  Profile _row(String id) =>
      profiles[id] ??= Profile(id: id, createdAt: DateTime(2026, 11, 13));

  @override
  Future<Profile?> fetchProfile(String userId) async =>
      deletedUsers.contains(userId) ? null : _row(userId);

  @override
  Future<bool> isUsernameAvailable(String username) async =>
      !profiles.values.any((p) => p.username == normalizeUsername(username));

  @override
  Future<void> completeOnboarding({
    required String userId,
    required String username,
    String? displayName,
    required bool isPrivate,
  }) async {
    if (!await isUsernameAvailable(username)) {
      throw const UsernameTakenException();
    }
    if (deletedUsers.contains(userId)) {
      throw StateError('Profile $userId not found or not writable');
    }
    profiles[userId] = _row(userId).copyWith(
      username: normalizeUsername(username),
      displayName: displayName,
      isPrivate: isPrivate,
      ageConfirmed: true,
    );
  }
}

/// A challenge that is live at [now] and closes 2 days 3 hours later.
Challenge liveChallenge(DateTime now) => Challenge(
  id: 'c1',
  title: 'Write a four-line poem',
  description: 'Write a short poem about something you saw this week.',
  category: 'poetry',
  tips: const ['Start with one concrete image'],
  opensAt: now.subtract(const Duration(days: 4)),
  closesAt: now.add(const Duration(days: 2, hours: 3)),
);

/// In-memory challenges. [othersAccepted] counts other users who accepted.
class FakeChallengeRepository implements ChallengeRepository {
  FakeChallengeRepository({this.current, this.othersAccepted = 0});

  Challenge? current;
  int othersAccepted;
  bool closed = false;
  final statuses = <(String, String), ParticipationStatus>{};

  @override
  Future<Challenge?> fetchCurrent() async => current;

  @override
  Future<ParticipationStatus?> fetchMyStatus({
    required String challengeId,
    required String userId,
  }) async => statuses[(challengeId, userId)];

  @override
  Future<void> respond({
    required String challengeId,
    required String userId,
    required ParticipationStatus status,
  }) async {
    if (closed) throw const ChallengeClosedException();
    statuses[(challengeId, userId)] = status;
  }

  @override
  Future<int> acceptedCount(String challengeId) async =>
      othersAccepted +
      statuses.entries
          .where(
            (e) =>
                e.key.$1 == challengeId &&
                e.value == ParticipationStatus.accepted,
          )
          .length;
}

/// Returns a fixed file for any pick.
class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker([XFile? file])
    : file =
          file ??
          XFile.fromData(
            Uint8List.fromList(List.filled(1000, 1)),
            name: 'clip.mp4',
            path: 'clip.mp4',
            mimeType: 'video/mp4',
          );

  XFile? file;

  @override
  Future<XFile?> pick(MediaKind kind, {required bool camera}) async => file;
}

/// Passes files through unchanged, or throws [error].
class FakeMediaProcessor implements MediaProcessor {
  UploadException? error;

  @override
  Future<PreparedMedia> prepare(
    XFile file,
    MediaKind kind, {
    void Function(double progress)? onProgress,
  }) async {
    if (error != null) throw error!;
    onProgress?.call(1);
    return PreparedMedia(
      kind: kind,
      bytes: await file.readAsBytes(),
      contentType: kind == MediaKind.video ? 'video/mp4' : 'image/jpeg',
      thumbnail: kind == MediaKind.video ? Uint8List(10) : null,
    );
  }
}

/// In-memory submissions. Set [uploadGate] to pause an upload mid-way.
class FakeSubmissionRepository implements SubmissionRepository {
  final submissions = <(String, String), Submission>{};
  final uploads = <String, int>{}; // url -> bytes
  Completer<void>? uploadGate;
  UploadException? requestError;

  @override
  Future<UploadTicket> requestUpload({
    required String challengeId,
    required PreparedMedia media,
  }) async {
    if (requestError != null) throw requestError!;
    return UploadTicket(
      mediaKey: 'submissions/$challengeId/me/x.mp4',
      mediaUrl: 'https://r2.test/media',
      thumbKey: media.thumbnail != null
          ? 'submissions/$challengeId/me/x.jpg'
          : null,
      thumbUrl: media.thumbnail != null ? 'https://r2.test/thumb' : null,
    );
  }

  @override
  Future<void> upload({
    required String url,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    if (uploadGate != null) await uploadGate!.future;
    onProgress?.call(1);
    uploads[url] = bytes.length;
  }

  @override
  Future<Submission> create({
    required String userId,
    required String challengeId,
    required MediaKind mediaType,
    String? mediaKey,
    String? thumbKey,
    String? body,
    String? caption,
    required PostVisibility visibility,
  }) async {
    final s = Submission(
      id: 's${submissions.length}',
      userId: userId,
      challengeId: challengeId,
      mediaType: mediaType,
      mediaKey: mediaKey,
      thumbKey: thumbKey,
      body: body,
      caption: caption,
      visibility: visibility,
      createdAt: DateTime(2026, 11, 13),
    );
    submissions[(challengeId, userId)] = s;
    return s;
  }

  @override
  Future<Submission?> fetchMine({
    required String challengeId,
    required String userId,
  }) async => submissions[(challengeId, userId)];

  @override
  Future<bool> hasBadge({
    required String challengeId,
    required String userId,
  }) async => submissions.containsKey((challengeId, userId));
}

Widget testApp({
  required FakeAuthRepository auth,
  required FakeProfileRepository profiles,
  FakeChallengeRepository? challenges,
  FakeSubmissionRepository? submissions,
  FakeMediaPicker? picker,
  FakeMediaProcessor? processor,
  DateTime Function()? clock,
}) {
  return ProviderScope(
    overrides: [
      backendConfiguredProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
      challengeRepositoryProvider.overrideWithValue(
        challenges ?? FakeChallengeRepository(),
      ),
      submissionRepositoryProvider.overrideWithValue(
        submissions ?? FakeSubmissionRepository(),
      ),
      mediaPickerProvider.overrideWithValue(picker ?? FakeMediaPicker()),
      mediaProcessorProvider.overrideWithValue(
        processor ?? FakeMediaProcessor(),
      ),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
    child: const QuestlyApp(),
  );
}
