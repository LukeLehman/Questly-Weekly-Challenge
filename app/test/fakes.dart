import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questly/core/providers.dart';
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

  Profile _row(String id) =>
      profiles[id] ??= Profile(id: id, createdAt: DateTime(2026, 11, 13));

  @override
  Future<Profile?> fetchProfile(String userId) async => _row(userId);

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
    profiles[userId] = _row(userId).copyWith(
      username: normalizeUsername(username),
      displayName: displayName,
      isPrivate: isPrivate,
      ageConfirmed: true,
    );
  }
}

Widget testApp({
  required FakeAuthRepository auth,
  required FakeProfileRepository profiles,
}) {
  return ProviderScope(
    overrides: [
      backendConfiguredProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ],
    child: const QuestlyApp(),
  );
}
