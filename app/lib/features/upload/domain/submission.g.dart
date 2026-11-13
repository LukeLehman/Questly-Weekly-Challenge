// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Submission _$SubmissionFromJson(Map<String, dynamic> json) => _Submission(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  challengeId: json['challenge_id'] as String,
  mediaType: $enumDecode(_$MediaKindEnumMap, json['media_type']),
  mediaKey: json['media_key'] as String?,
  thumbKey: json['thumb_key'] as String?,
  body: json['body'] as String?,
  caption: json['caption'] as String?,
  visibility:
      $enumDecodeNullable(_$PostVisibilityEnumMap, json['visibility']) ??
      PostVisibility.public,
  likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
  commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SubmissionToJson(_Submission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'challenge_id': instance.challengeId,
      'media_type': _$MediaKindEnumMap[instance.mediaType]!,
      'media_key': instance.mediaKey,
      'thumb_key': instance.thumbKey,
      'body': instance.body,
      'caption': instance.caption,
      'visibility': _$PostVisibilityEnumMap[instance.visibility]!,
      'like_count': instance.likeCount,
      'comment_count': instance.commentCount,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MediaKindEnumMap = {
  MediaKind.video: 'video',
  MediaKind.image: 'image',
  MediaKind.text: 'text',
};

const _$PostVisibilityEnumMap = {
  PostVisibility.public: 'public',
  PostVisibility.friends: 'friends',
  PostVisibility.private: 'private',
};
