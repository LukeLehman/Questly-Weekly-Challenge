import 'package:freezed_annotation/freezed_annotation.dart';

part 'submission.freezed.dart';
part 'submission.g.dart';

enum MediaKind { video, image, text }

/// Who can see an entry. (Not `Visibility`: that's a Flutter widget.)
enum PostVisibility {
  public('Everyone'),
  friends('Friends'),
  private('Only me');

  const PostVisibility(this.label);
  final String label;
}

/// A row of `public.submissions`.
@freezed
abstract class Submission with _$Submission {
  const factory Submission({
    required String id,
    required String userId,
    required String challengeId,
    required MediaKind mediaType,
    String? mediaKey,
    String? thumbKey,
    String? body,
    String? caption,
    @Default(PostVisibility.public) PostVisibility visibility,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    required DateTime createdAt,
  }) = _Submission;

  factory Submission.fromJson(Map<String, dynamic> json) =>
      _$SubmissionFromJson(json);
}

/// Limits shared with the create-upload-url function and the DB.
abstract final class UploadLimits {
  static const maxVideoDuration = Duration(seconds: 60);
  static const maxVideoBytes = 30 * 1024 * 1024;
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxThumbBytes = 1024 * 1024;
  static const maxCaption = 300;
  static const maxBody = 2000;
}

/// A user-facing upload problem (too long, too big, wrong type, closed…).
class UploadException implements Exception {
  const UploadException(this.message);
  final String message;

  @override
  String toString() => message;
}
