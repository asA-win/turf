// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
  id: (json['id'] as num).toInt(),
  turfId: (json['turf_id'] as num?)?.toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  discountValue: (json['discount_value'] as num).toDouble(),
  discountType: json['discount_type'] as String? ?? 'flat',
  minBookingAmount: (json['min_booking_amount'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
  'id': instance.id,
  'turf_id': instance.turfId,
  'title': instance.title,
  'description': instance.description,
  'discount_value': instance.discountValue,
  'discount_type': instance.discountType,
  'min_booking_amount': instance.minBookingAmount,
};
