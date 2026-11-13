import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../domain/submission.dart';

/// Media ready to upload: bytes, type, optional JPEG thumbnail.
class PreparedMedia {
  const PreparedMedia({
    required this.kind,
    required this.bytes,
    required this.contentType,
    this.thumbnail,
  });

  final MediaKind kind;
  final Uint8List bytes;
  final String contentType;
  final Uint8List? thumbnail;

  int get size => bytes.length;
}

abstract interface class MediaProcessor {
  /// Validates and shrinks [file]. Throws [UploadException] if it's too long,
  /// too big, or an unsupported type.
  Future<PreparedMedia> prepare(
    XFile file,
    MediaKind kind, {
    void Function(double progress)? onProgress,
  });
}

final mediaProcessorProvider = Provider<MediaProcessor>(
  (ref) => DeviceMediaProcessor(),
);

const _videoTypes = {
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
};
const _imageTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Picks the MIME type from the file's own type or its extension.
@visibleForTesting
String? contentTypeFor(XFile file, MediaKind kind) {
  final allowed = kind == MediaKind.video ? _videoTypes : _imageTypes;
  final mime = file.mimeType;
  if (mime != null && allowed.containsValue(mime)) return mime;
  final name = file.name.isNotEmpty ? file.name : file.path;
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return allowed[ext];
}

String _mb(int bytes) => '${bytes ~/ (1024 * 1024)} MB';

/// Mobile: checks duration, compresses video to 720p MP4 and grabs a
/// thumbnail. Web: no compression is available, so it enforces the size cap.
class DeviceMediaProcessor implements MediaProcessor {
  @override
  Future<PreparedMedia> prepare(
    XFile file,
    MediaKind kind, {
    void Function(double progress)? onProgress,
  }) async {
    return switch (kind) {
      MediaKind.image => _image(file),
      MediaKind.video =>
        kIsWeb ? _webVideo(file) : _mobileVideo(file, onProgress),
      MediaKind.text => throw ArgumentError('Text entries have no media'),
    };
  }

  Future<PreparedMedia> _image(XFile file) async {
    final type = contentTypeFor(file, MediaKind.image);
    if (type == null) {
      throw const UploadException('Use a JPEG, PNG or WebP photo.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > UploadLimits.maxImageBytes) {
      throw UploadException(
        'Photo is too big (max ${_mb(UploadLimits.maxImageBytes)}).',
      );
    }
    return PreparedMedia(
      kind: MediaKind.image,
      bytes: bytes,
      contentType: type,
    );
  }

  Future<PreparedMedia> _webVideo(XFile file) async {
    final type = contentTypeFor(file, MediaKind.video);
    if (type == null) {
      throw const UploadException('Use an MP4, MOV or WebM video.');
    }
    final size = await file.length();
    if (size > UploadLimits.maxVideoBytes) {
      throw UploadException(
        'Video is too big for web upload (max ${_mb(UploadLimits.maxVideoBytes)}). '
        'Trim it, or post from the Android app which compresses videos.',
      );
    }
    return PreparedMedia(
      kind: MediaKind.video,
      bytes: await file.readAsBytes(),
      contentType: type,
    );
  }

  Future<PreparedMedia> _mobileVideo(
    XFile file,
    void Function(double progress)? onProgress,
  ) async {
    final info = await VideoCompress.getMediaInfo(file.path);
    final ms = info.duration ?? 0;
    // Small tolerance: recorders often overshoot by a few frames.
    if (ms > UploadLimits.maxVideoDuration.inMilliseconds + 500) {
      throw const UploadException('Videos can be at most 60 seconds long.');
    }

    final sub = VideoCompress.compressProgress$.subscribe(
      (p) => onProgress?.call((p / 100).clamp(0, 1)),
    );
    try {
      final out = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.Res1280x720Quality,
        includeAudio: true,
      );
      if (out?.path == null) {
        throw const UploadException('Couldn\'t process that video.');
      }
      final bytes = await XFile(out!.path!).readAsBytes();
      if (bytes.length > UploadLimits.maxVideoBytes) {
        throw UploadException(
          'Video is too big even after compression (max ${_mb(UploadLimits.maxVideoBytes)}).',
        );
      }
      var thumb = await VideoCompress.getByteThumbnail(file.path, quality: 60);
      if (thumb != null && thumb.length > UploadLimits.maxThumbBytes) {
        thumb = null; // optional; skip rather than fail the upload
      }
      return PreparedMedia(
        kind: MediaKind.video,
        bytes: bytes,
        contentType: 'video/mp4',
        thumbnail: thumb,
      );
    } finally {
      sub.unsubscribe();
    }
  }
}
