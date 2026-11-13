import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../challenge/domain/challenge.dart';
import '../data/media_processor.dart';
import '../data/submission_repository.dart';
import '../domain/submission.dart';

/// The signed-in user's entry for a challenge, or null.
final mySubmissionProvider = FutureProvider.family<Submission?, String>((
  ref,
  challengeId,
) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  return ref
      .watch(submissionRepositoryProvider)
      .fetchMine(challengeId: challengeId, userId: userId);
});

sealed class UploadState {
  const UploadState();
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

/// [progress] is 0–1 across the whole job; [stage] is shown to the user.
class UploadWorking extends UploadState {
  const UploadWorking(this.stage, this.progress);
  final String stage;
  final double progress;
}

class UploadDone extends UploadState {
  const UploadDone(this.submission, {required this.badgeEarned});
  final Submission submission;
  final bool badgeEarned;
}

class UploadFailed extends UploadState {
  const UploadFailed(this.message);
  final String message;
}

final uploadControllerProvider =
    NotifierProvider.autoDispose<UploadController, UploadState>(
      UploadController.new,
    );

/// prepare (compress) → get upload URLs → PUT to R2 → save row → badge.
class UploadController extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadIdle();

  bool get busy => state is UploadWorking;

  void reset() => state = const UploadIdle();

  Future<void> submit({
    required Challenge challenge,
    required MediaKind kind,
    XFile? file,
    String? body,
    String? caption,
    required PostVisibility visibility,
  }) async {
    if (busy) return;
    final userId = ref.read(authStateProvider).value;
    if (userId == null) return;
    final repo = ref.read(submissionRepositoryProvider);

    try {
      String? mediaKey;
      String? thumbKey;

      if (kind != MediaKind.text) {
        if (file == null) throw const UploadException('Pick a file first.');

        // 0–30%: compress / validate
        state = const UploadWorking('Preparing…', 0);
        final media = await ref
            .read(mediaProcessorProvider)
            .prepare(
              file,
              kind,
              onProgress: (p) => _progress('Compressing…', p * 0.3),
            );

        state = const UploadWorking('Starting upload…', 0.3);
        final ticket = await repo.requestUpload(
          challengeId: challenge.id,
          media: media,
        );

        // 30–95%: media upload; 95–98%: thumbnail
        await repo.upload(
          url: ticket.mediaUrl,
          bytes: media.bytes,
          contentType: media.contentType,
          onProgress: (p) => _progress('Uploading…', 0.3 + p * 0.65),
        );
        if (media.thumbnail != null && ticket.thumbUrl != null) {
          await repo.upload(
            url: ticket.thumbUrl!,
            bytes: media.thumbnail!,
            contentType: 'image/jpeg',
            onProgress: (p) => _progress('Uploading…', 0.95 + p * 0.03),
          );
          thumbKey = ticket.thumbKey;
        }
        mediaKey = ticket.mediaKey;
      } else if (body == null || body.trim().isEmpty) {
        throw const UploadException('Write something first.');
      }

      state = const UploadWorking('Saving…', 0.98);
      final submission = await repo.create(
        userId: userId,
        challengeId: challenge.id,
        mediaType: kind,
        mediaKey: mediaKey,
        thumbKey: thumbKey,
        body: kind == MediaKind.text ? body!.trim() : null,
        caption: caption,
        visibility: visibility,
      );
      final badge = await repo.hasBadge(
        challengeId: challenge.id,
        userId: userId,
      );

      ref.invalidate(mySubmissionProvider(challenge.id));
      if (ref.mounted) {
        state = UploadDone(submission, badgeEarned: badge);
      }
    } on UploadException catch (e) {
      if (ref.mounted) state = UploadFailed(e.message);
    } catch (_) {
      if (ref.mounted) {
        state = const UploadFailed('Something went wrong. Please try again.');
      }
    }
  }

  void _progress(String stage, double p) {
    if (ref.mounted) state = UploadWorking(stage, p.clamp(0, 1));
  }
}
