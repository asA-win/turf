// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  turfId: (json['turf_id'] as num).toInt(),
  slotId: (json['slot_id'] as num).toInt(),
  bookingDate: DateTime.parse(json['booking_date'] as String),
  totalPrice: (json['total_price'] as num).toDouble(),
  status: json['status'] as String,
  bookingType: json['booking_type'] as String? ?? 'full',
  turf:
      json['turf'] == null
          ? null
          : Turf.fromJson(json['turf'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'turf_id': instance.turfId,
  'slot_id': instance.slotId,
  'booking_date': instance.bookingDate.toIso8601String(),
  'total_price': instance.totalPrice,
  'status': instance.status,
  'booking_type': instance.bookingType,
  'turf': instance.turf,
};
