// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Submission {

 String get id; String get userId; String get challengeId; MediaKind get mediaType; String? get mediaKey; String? get thumbKey; String? get body; String? get caption; PostVisibility get visibility; int get likeCount; int get commentCount; DateTime get createdAt;
/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionCopyWith<Submission> get copyWith => _$SubmissionCopyWithImpl<Submission>(this as Submission, _$identity);

  /// Serializes this Submission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Submission&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.mediaKey, mediaKey) || other.mediaKey == mediaKey)&&(identical(other.thumbKey, thumbKey) || other.thumbKey == thumbKey)&&(identical(other.body, body) || other.body == body)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,challengeId,mediaType,mediaKey,thumbKey,body,caption,visibility,likeCount,commentCount,createdAt);

@override
String toString() {
  return 'Submission(id: $id, userId: $userId, challengeId: $challengeId, mediaType: $mediaType, mediaKey: $mediaKey, thumbKey: $thumbKey, body: $body, caption: $caption, visibility: $visibility, likeCount: $likeCount, commentCount: $commentCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SubmissionCopyWith<$Res>  {
  factory $SubmissionCopyWith(Submission value, $Res Function(Submission) _then) = _$SubmissionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String challengeId, MediaKind mediaType, String? mediaKey, String? thumbKey, String? body, String? caption, PostVisibility visibility, int likeCount, int commentCount, DateTime createdAt
});




}
/// @nodoc
class _$SubmissionCopyWithImpl<$Res>
    implements $SubmissionCopyWith<$Res> {
  _$SubmissionCopyWithImpl(this._self, this._then);

  final Submission _self;
  final $Res Function(Submission) _then;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? challengeId = null,Object? mediaType = null,Object? mediaKey = freezed,Object? thumbKey = freezed,Object? body = freezed,Object? caption = freezed,Object? visibility = null,Object? likeCount = null,Object? commentCount = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as MediaKind,mediaKey: freezed == mediaKey ? _self.mediaKey : mediaKey // ignore: cast_nullable_to_non_nullable
as String?,thumbKey: freezed == thumbKey ? _self.thumbKey : thumbKey // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as PostVisibility,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Submission].
extension SubmissionPatterns on Submission {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Submission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Submission value)  $default,){
final _that = this;
switch (_that) {
case _Submission():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Submission value)?  $default,){
final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String challengeId,  MediaKind mediaType,  String? mediaKey,  String? thumbKey,  String? body,  String? caption,  PostVisibility visibility,  int likeCount,  int commentCount,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that.id,_that.userId,_that.challengeId,_that.mediaType,_that.mediaKey,_that.thumbKey,_that.body,_that.caption,_that.visibility,_that.likeCount,_that.commentCount,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String challengeId,  MediaKind mediaType,  String? mediaKey,  String? thumbKey,  String? body,  String? caption,  PostVisibility visibility,  int likeCount,  int commentCount,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Submission():
return $default(_that.id,_that.userId,_that.challengeId,_that.mediaType,_that.mediaKey,_that.thumbKey,_that.body,_that.caption,_that.visibility,_that.likeCount,_that.commentCount,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String challengeId,  MediaKind mediaType,  String? mediaKey,  String? thumbKey,  String? body,  String? caption,  PostVisibility visibility,  int likeCount,  int commentCount,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that.id,_that.userId,_that.challengeId,_that.mediaType,_that.mediaKey,_that.thumbKey,_that.body,_that.caption,_that.visibility,_that.likeCount,_that.commentCount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Submission implements Submission {
  const _Submission({required this.id, required this.userId, required this.challengeId, required this.mediaType, this.mediaKey, this.thumbKey, this.body, this.caption, this.visibility = PostVisibility.public, this.likeCount = 0, this.commentCount = 0, required this.createdAt});
  factory _Submission.fromJson(Map<String, dynamic> json) => _$SubmissionFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String challengeId;
@override final  MediaKind mediaType;
@override final  String? mediaKey;
@override final  String? thumbKey;
@override final  String? body;
@override final  String? caption;
@override@JsonKey() final  PostVisibility visibility;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int commentCount;
@override final  DateTime createdAt;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmissionCopyWith<_Submission> get copyWith => __$SubmissionCopyWithImpl<_Submission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Submission&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.mediaKey, mediaKey) || other.mediaKey == mediaKey)&&(identical(other.thumbKey, thumbKey) || other.thumbKey == thumbKey)&&(identical(other.body, body) || other.body == body)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,challengeId,mediaType,mediaKey,thumbKey,body,caption,visibility,likeCount,commentCount,createdAt);

@override
String toString() {
  return 'Submission(id: $id, userId: $userId, challengeId: $challengeId, mediaType: $mediaType, mediaKey: $mediaKey, thumbKey: $thumbKey, body: $body, caption: $caption, visibility: $visibility, likeCount: $likeCount, commentCount: $commentCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SubmissionCopyWith<$Res> implements $SubmissionCopyWith<$Res> {
  factory _$SubmissionCopyWith(_Submission value, $Res Function(_Submission) _then) = __$SubmissionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String challengeId, MediaKind mediaType, String? mediaKey, String? thumbKey, String? body, String? caption, PostVisibility visibility, int likeCount, int commentCount, DateTime createdAt
});




}
/// @nodoc
class __$SubmissionCopyWithImpl<$Res>
    implements _$SubmissionCopyWith<$Res> {
  __$SubmissionCopyWithImpl(this._self, this._then);

  final _Submission _self;
  final $Res Function(_Submission) _then;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? challengeId = null,Object? mediaType = null,Object? mediaKey = freezed,Object? thumbKey = freezed,Object? body = freezed,Object? caption = freezed,Object? visibility = null,Object? likeCount = null,Object? commentCount = null,Object? createdAt = null,}) {
  return _then(_Submission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as MediaKind,mediaKey: freezed == mediaKey ? _self.mediaKey : mediaKey // ignore: cast_nullable_to_non_nullable
as String?,thumbKey: freezed == thumbKey ? _self.thumbKey : thumbKey // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as PostVisibility,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
