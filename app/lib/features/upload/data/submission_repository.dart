import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;

import '../../../core/providers.dart';
import '../domain/submission.dart';
import 'media_processor.dart';

/// Presigned upload URLs from the create-upload-url function.
class UploadTicket {
  const UploadTicket({
    required this.mediaKey,
    required this.mediaUrl,
    this.thumbKey,
    this.thumbUrl,
  });

  final String mediaKey;
  final String mediaUrl;
  final String? thumbKey;
  final String? thumbUrl;
}

abstract interface class SubmissionRepository {
  Future<UploadTicket> requestUpload({
    required String challengeId,
    required PreparedMedia media,
  });

  /// PUTs [bytes] to a presigned URL, reporting progress from 0 to 1.
  Future<void> upload({
    required String url,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  });

  Future<Submission> create({
    required String userId,
    required String challengeId,
    required MediaKind mediaType,
    String? mediaKey,
    String? thumbKey,
    String? body,
    String? caption,
    required PostVisibility visibility,
  });

  Future<Submission?> fetchMine({
    required String challengeId,
    required String userId,
  });

  Future<bool> hasBadge({required String challengeId, required String userId});
}

final submissionRepositoryProvider = Provider<SubmissionRepository>(
  (ref) => SupabaseSubmissionRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseSubmissionRepository implements SubmissionRepository {
  SupabaseSubmissionRepository(this._client, {Dio? dio}) : _dio = dio ?? Dio();

  final SupabaseClient _client;
  final Dio _dio;

  @override
  Future<UploadTicket> requestUpload({
    required String challengeId,
    required PreparedMedia media,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'create-upload-url',
        body: {
          'challenge_id': challengeId,
          'media_type': media.kind.name,
          'content_type': media.contentType,
          'size_bytes': media.size,
          if (media.thumbnail != null)
            'thumb': {
              'content_type': 'image/jpeg',
              'size_bytes': media.thumbnail!.length,
            },
        },
      );
      final data = res.data as Map<String, dynamic>;
      return UploadTicket(
        mediaKey: data['media_key'] as String,
        mediaUrl: data['media_upload_url'] as String,
        thumbKey: data['thumb_key'] as String?,
        thumbUrl: data['thumb_upload_url'] as String?,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['message'] as String? : null;
      throw UploadException(message ?? 'Couldn\'t start the upload.');
    }
  }

  @override
  Future<void> upload({
    required String url,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _dio.put<void>(
        url,
        data: Stream.value(bytes),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            // Browsers set Content-Length themselves and refuse it from code.
            if (!kIsWeb) Headers.contentLengthHeader: bytes.length,
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
    } on DioException {
      throw const UploadException(
        'Upload failed. Check your connection and try again.',
      );
    }
  }

  @override
  Future<Submission> create({
    required String userId,
    required String challengeId,
    required MediaKind mediaType,
    String? mediaKey,
    String? thumbKey,
    String? body,
    String? caption,
    required PostVisibility visibility,
  }) async {
    final trimmed = caption?.trim();
    try {
      final row = await _client
          .from('submissions')
          .insert({
            'user_id': userId,
            'challenge_id': challengeId,
            'media_type': mediaType.name,
            'media_key': mediaKey,
            'thumb_key': thumbKey,
            'body': body,
            'caption': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
            'visibility': visibility.name,
          })
          .select()
          .single();
      return Submission.fromJson(row);
    } on PostgrestException catch (e) {
      throw UploadException(switch (e.code) {
        '23505' => 'You already posted an entry this week.',
        '42501' => 'This quest has closed.',
        _ => 'Couldn\'t save your entry.',
      });
    }
  }

  @override
  Future<Submission?> fetchMine({
    required String challengeId,
    required String userId,
  }) async {
    final row = await _client
        .from('submissions')
        .select()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Submission.fromJson(row);
  }

  @override
  Future<bool> hasBadge({
    required String challengeId,
    required String userId,
  }) async {
    final row = await _client
        .from('badges')
        .select('challenge_id')
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }
}
