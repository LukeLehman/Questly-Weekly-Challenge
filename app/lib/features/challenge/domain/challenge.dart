import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

/// A row of `public.challenges`. The window is half-open: [opensAt, closesAt).
@freezed
abstract class Challenge with _$Challenge {
  const Challenge._();

  const factory Challenge({
    required String id,
    required String title,
    required String description,
    required String category,
    @Default(<String>[]) List<String> tips,
    String? coverKey,
    required DateTime opensAt,
    required DateTime closesAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);

  bool isOpenAt(DateTime now) =>
      !now.isBefore(opensAt) && now.isBefore(closesAt);

  Duration remainingAt(DateTime now) {
    final left = closesAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// The user's answer to a challenge; null means they haven't answered.
enum ParticipationStatus {
  accepted,
  declined;

  static ParticipationStatus? fromName(String? name) =>
      values.where((s) => s.name == name).firstOrNull;
}

class ChallengeClosedException implements Exception {
  const ChallengeClosedException();
}

/// "2d 3h left", "4h 12m left", "9m 05s left", or "Closed".
String formatRemaining(Duration d) {
  if (d <= Duration.zero) return 'Closed';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (days > 0) return '${days}d ${hours}h left';
  if (d.inHours > 0) return '${hours}h ${minutes}m left';
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s left';
}
