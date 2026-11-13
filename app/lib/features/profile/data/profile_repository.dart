import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers.dart';
import '../domain/profile.dart';
import '../domain/username.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchProfile(String userId);
  Future<bool> isUsernameAvailable(String username);

  /// Sets the username and confirms 13+. Throws [UsernameTakenException].
  Future<void> completeOnboarding({
    required String userId,
    required String username,
    String? displayName,
    required bool isPrivate,
  });
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _client.rpc(
      'username_available',
      params: {'name': normalizeUsername(username)},
    );
    return result as bool;
  }

  @override
  Future<void> completeOnboarding({
    required String userId,
    required String username,
    String? displayName,
    required bool isPrivate,
  }) async {
    final name = displayName?.trim();
    try {
      await _client
          .from('profiles')
          .update({
            'username': normalizeUsername(username),
            'display_name': (name == null || name.isEmpty) ? null : name,
            'is_private': isPrivate,
            'age_confirmed': true,
          })
          .eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }
}
