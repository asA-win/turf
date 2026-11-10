// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favorite _$FavoriteFromJson(Map<String, dynamic> json) => Favorite(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  turfId: (json['turf_id'] as num).toInt(),
  turf: Turf.fromJson(json['turf'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FavoriteToJson(Favorite instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'turf_id': instance.turfId,
  'turf': instance.turf,
};
