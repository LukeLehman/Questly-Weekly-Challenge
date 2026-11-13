import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/submission.dart';

/// Thin wrapper over image_picker so tests can supply files.
abstract interface class MediaPicker {
  Future<XFile?> pick(MediaKind kind, {required bool camera});
}

final mediaPickerProvider = Provider<MediaPicker>((ref) => DeviceMediaPicker());

class DeviceMediaPicker implements MediaPicker {
  final _picker = ImagePicker();

  @override
  Future<XFile?> pick(MediaKind kind, {required bool camera}) {
    final source = camera ? ImageSource.camera : ImageSource.gallery;
    return switch (kind) {
      MediaKind.video => _picker.pickVideo(
        source: source,
        maxDuration: UploadLimits.maxVideoDuration,
      ),
      // Downscale on pick: keeps photos well under the size cap.
      MediaKind.image => _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      ),
      MediaKind.text => Future.value(null),
    };
  }
}
