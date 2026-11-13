import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../data/auth_repository.dart';

/// Signed-in user id, or null when signed out.
final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).userIdChanges().distinct(),
);

/// The signed-in user's profile, or null when signed out.
///
/// Every account has a profile row (created by the sign-up trigger), so a
/// missing row means the stored session belongs to an account that no longer
/// exists (e.g. deleted, or the local DB was reset). Sign out so the user
/// isn't stuck on onboarding with a session that can't save anything.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  final profile = await ref
      .watch(profileRepositoryProvider)
      .fetchProfile(userId);
  if (profile == null) {
    await ref.read(authRepositoryProvider).signOut();
  }
  return profile;
});

/// Turns an error into something safe to show the user.
String friendlyError(Object error) => switch (error) {
  AuthException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
