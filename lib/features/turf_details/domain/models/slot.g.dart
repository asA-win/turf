// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Slot _$SlotFromJson(Map<String, dynamic> json) => Slot(
  id: (json['id'] as num).toInt(),
  turfId: (json['turf_id'] as num).toInt(),
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: DateTime.parse(json['end_time'] as String),
  isBooked: json['is_booked'] as bool,
  capacity: (json['capacity'] as num?)?.toInt() ?? 1,
  currentBookings: (json['current_bookings'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SlotToJson(Slot instance) => <String, dynamic>{
  'id': instance.id,
  'turf_id': instance.turfId,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime.toIso8601String(),
  'is_booked': instance.isBooked,
  'capacity': instance.capacity,
  'current_bookings': instance.currentBookings,
};
