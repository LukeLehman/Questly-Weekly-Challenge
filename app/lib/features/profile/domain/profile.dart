import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// A row of `public.profiles`.
@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    String? username,
    String? displayName,
    String? avatarKey,
    String? bio,
    @Default(false) bool isPrivate,
    @Default(false) bool ageConfirmed,
    required DateTime createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  /// Onboarding is done once a username is set (which requires 13+).
  bool get isOnboarded => username != null;
}
