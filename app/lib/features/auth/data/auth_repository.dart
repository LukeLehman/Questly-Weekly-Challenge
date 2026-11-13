import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../core/providers.dart';

abstract interface class AuthRepository {
  /// The signed-in user's id, or null. Emits the current value first.
  Stream<String?> userIdChanges();

  /// Returns true if the user must confirm their email before signing in.
  Future<bool> signUpWithEmail(String email, String password);
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<String?> userIdChanges() async* {
    yield _client.auth.currentUser?.id;
    yield* _client.auth.onAuthStateChange.map((s) => s.session?.user.id);
  }

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: kIsWeb ? Uri.base.origin : Env.mobileAuthRedirect,
    );
    return res.session == null;
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : Env.mobileAuthRedirect,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
