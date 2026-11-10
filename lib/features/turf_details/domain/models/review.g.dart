// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  turfId: (json['turf_id'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'turf_id': instance.turfId,
  'rating': instance.rating,
  'comment': instance.comment,
  'created_at': instance.createdAt.toIso8601String(),
  'user': instance.user,
};
