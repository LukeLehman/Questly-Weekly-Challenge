import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge.dart';

/// This week's challenge, or null between challenges.
final currentChallengeProvider = FutureProvider<Challenge?>((ref) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  return ref.watch(challengeRepositoryProvider).fetchCurrent();
});

/// The signed-in user's answer to a challenge.
final myStatusProvider = FutureProvider.family<ParticipationStatus?, String>((
  ref,
  challengeId,
) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  return ref
      .watch(challengeRepositoryProvider)
      .fetchMyStatus(challengeId: challengeId, userId: userId);
});

final acceptedCountProvider = FutureProvider.family<int, String>(
  (ref, challengeId) =>
      ref.watch(challengeRepositoryProvider).acceptedCount(challengeId),
);
