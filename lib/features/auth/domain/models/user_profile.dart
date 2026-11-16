import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final int id;
  @JsonKey(name: 'firebase_uid')
  final String? firebaseUid;
  final String? email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? role;
  final String? phone;

  UserProfile({
    required this.id,
    this.firebaseUid,
    this.email,
    this.fullName,
    this.role,
    this.phone,
  });

  String? get name => fullName;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> json() => _$UserProfileToJson(this);
}
