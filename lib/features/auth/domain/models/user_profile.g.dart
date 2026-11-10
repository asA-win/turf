// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: (json['id'] as num).toInt(),
  firebaseUid: json['firebase_uid'] as String?,
  email: json['email'] as String?,
  fullName: json['full_name'] as String?,
  role: json['role'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firebase_uid': instance.firebaseUid,
      'email': instance.email,
      'full_name': instance.fullName,
      'role': instance.role,
      'phone': instance.phone,
    };
