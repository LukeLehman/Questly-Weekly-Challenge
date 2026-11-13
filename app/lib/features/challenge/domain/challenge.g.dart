// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Challenge _$ChallengeFromJson(Map<String, dynamic> json) => _Challenge(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  tips:
      (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  coverKey: json['cover_key'] as String?,
  opensAt: DateTime.parse(json['opens_at'] as String),
  closesAt: DateTime.parse(json['closes_at'] as String),
);

Map<String, dynamic> _$ChallengeToJson(_Challenge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'tips': instance.tips,
      'cover_key': instance.coverKey,
      'opens_at': instance.opensAt.toIso8601String(),
      'closes_at': instance.closesAt.toIso8601String(),
    };
