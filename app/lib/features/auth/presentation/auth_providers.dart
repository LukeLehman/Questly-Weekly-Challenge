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
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

/// Turns an error into something safe to show the user.
String friendlyError(Object error) => switch (error) {
  AuthException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
