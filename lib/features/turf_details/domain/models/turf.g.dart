// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Turf _$TurfFromJson(Map<String, dynamic> json) => Turf(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  location: json['location'] as String,
  pricePerHour: (json['price_per_hour'] as num).toDouble(),
  imageUrl: json['image_url'] as String?,
  description: json['description'] as String?,
  sportTypes: json['sport_types'] as String?,
  amenities: json['amenities'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  pitchInfo: json['pitch_info'] as String?,
  equipmentProvided: json['equipment_provided'] as String?,
  turfType: json['turf_type'] as String?,
  averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
  totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TurfToJson(Turf instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'price_per_hour': instance.pricePerHour,
  'image_url': instance.imageUrl,
  'description': instance.description,
  'sport_types': instance.sportTypes,
  'amenities': instance.amenities,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'pitch_info': instance.pitchInfo,
  'equipment_provided': instance.equipmentProvided,
  'turf_type': instance.turfType,
  'average_rating': instance.averageRating,
  'total_reviews': instance.totalReviews,
};
