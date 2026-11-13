import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:questly/features/upload/data/media_processor.dart';
import 'package:questly/features/upload/domain/submission.dart';

XFile _file(String name, {String? mime, int size = 10}) =>
    XFile.fromData(Uint8List(size), name: name, path: name, mimeType: mime);

void main() {
  group('contentTypeFor', () {
    test('uses the file mime type when allowed', () {
      expect(
        contentTypeFor(_file('x', mime: 'video/webm'), MediaKind.video),
        'video/webm',
      );
    });
    test('falls back to the extension', () {
      expect(
        contentTypeFor(_file('clip.MOV'), MediaKind.video),
        'video/quicktime',
      );
      expect(contentTypeFor(_file('p.jpeg'), MediaKind.image), 'image/jpeg');
    });
    test('rejects unsupported types', () {
      expect(contentTypeFor(_file('doc.pdf'), MediaKind.image), isNull);
      expect(contentTypeFor(_file('a.heic'), MediaKind.image), isNull);
      expect(contentTypeFor(_file('photo.jpg'), MediaKind.video), isNull);
    });
  });

  group('DeviceMediaProcessor (image path, platform independent)', () {
    final processor = DeviceMediaProcessor();

    test('accepts a JPEG under the cap', () async {
      final media = await processor.prepare(
        _file('p.jpg', size: 2000),
        MediaKind.image,
      );
      expect(media.contentType, 'image/jpeg');
      expect(media.size, 2000);
    });

    test('rejects photos over 10 MB', () async {
      expect(
        processor.prepare(
          _file('p.png', size: UploadLimits.maxImageBytes + 1),
          MediaKind.image,
        ),
        throwsA(isA<UploadException>()),
      );
    });

    test('rejects unsupported photo types', () async {
      expect(
        processor.prepare(_file('p.heic'), MediaKind.image),
        throwsA(isA<UploadException>()),
      );
    });
  });

  test('Submission parses a row', () {
    final s = Submission.fromJson({
      'id': 's1',
      'user_id': 'u1',
      'challenge_id': 'c1',
      'media_type': 'video',
      'media_key': 'k',
      'thumb_key': null,
      'body': null,
      'caption': 'hi',
      'visibility': 'friends',
      'like_count': 2,
      'comment_count': 0,
      'is_hidden': false,
      'created_at': '2026-11-13T10:00:00+00:00',
    });
    expect(s.mediaType, MediaKind.video);
    expect(s.visibility, PostVisibility.friends);
    expect(s.likeCount, 2);
  });
}
