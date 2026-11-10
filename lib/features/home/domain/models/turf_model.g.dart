// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Turf _$TurfFromJson(Map<String, dynamic> json) => Turf(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  location: json['location'] as String,
  rating: (json['rating'] as num).toDouble(),
  reviews: (json['reviews'] as num).toInt(),
  sports: (json['sports'] as List<dynamic>).map((e) => e as String).toList(),
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  amenities:
      (json['amenities'] as List<dynamic>).map((e) => e as String).toList(),
  price: (json['price'] as num).toDouble(),
);

Map<String, dynamic> _$TurfToJson(Turf instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'location': instance.location,
  'rating': instance.rating,
  'reviews': instance.reviews,
  'sports': instance.sports,
  'images': instance.images,
  'amenities': instance.amenities,
  'price': instance.price,
};
