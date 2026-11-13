import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers.dart';
import '../domain/challenge.dart';

abstract interface class ChallengeRepository {
  /// The live challenge (by the server clock), or null between challenges.
  Future<Challenge?> fetchCurrent();

  Future<ParticipationStatus?> fetchMyStatus({
    required String challengeId,
    required String userId,
  });

  /// Accept or decline. Throws [ChallengeClosedException] after the deadline.
  Future<void> respond({
    required String challengeId,
    required String userId,
    required ParticipationStatus status,
  });

  Future<int> acceptedCount(String challengeId);
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => SupabaseChallengeRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseChallengeRepository implements ChallengeRepository {
  SupabaseChallengeRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Challenge?> fetchCurrent() async {
    final rows = await _client.rpc('current_challenge') as List<dynamic>;
    if (rows.isEmpty) return null;
    return Challenge.fromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<ParticipationStatus?> fetchMyStatus({
    required String challengeId,
    required String userId,
  }) async {
    final row = await _client
        .from('participations')
        .select('status')
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();
    return ParticipationStatus.fromName(row?['status'] as String?);
  }

  @override
  Future<void> respond({
    required String challengeId,
    required String userId,
    required ParticipationStatus status,
  }) async {
    try {
      // Update first (only `status` is client-updatable), insert if no row.
      final updated = await _client
          .from('participations')
          .update({'status': status.name})
          .eq('challenge_id', challengeId)
          .eq('user_id', userId)
          .select('status');
      if (updated.isEmpty) {
        await _client.from('participations').insert({
          'challenge_id': challengeId,
          'user_id': userId,
          'status': status.name,
        });
      }
    } on PostgrestException catch (e) {
      // RLS rejects responses outside the challenge window.
      if (e.code == '42501') throw const ChallengeClosedException();
      rethrow;
    }
  }

  @override
  Future<int> acceptedCount(String challengeId) async {
    final count = await _client.rpc(
      'challenge_accepted_count',
      params: {'cid': challengeId},
    );
    return count as int;
  }
}
