// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  avatarKey: json['avatar_key'] as String?,
  bio: json['bio'] as String?,
  isPrivate: json['is_private'] as bool? ?? false,
  ageConfirmed: json['age_confirmed'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': instance.displayName,
  'avatar_key': instance.avatarKey,
  'bio': instance.bio,
  'is_private': instance.isPrivate,
  'age_confirmed': instance.ageConfirmed,
  'created_at': instance.createdAt.toIso8601String(),
};
