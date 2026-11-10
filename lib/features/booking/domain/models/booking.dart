import 'package:json_annotation/json_annotation.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'turf_id')
  final int turfId;
  @JsonKey(name: 'slot_id')
  final int slotId;
  @JsonKey(name: 'booking_date')
  final DateTime bookingDate;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  final String status;
  @JsonKey(name: 'booking_type')
  final String bookingType; // 'full' or 'join'
  final Turf? turf; // Optional, might be joined in backend or fetched separately

  Booking({
    required this.id,
    required this.userId,
    required this.turfId,
    required this.slotId,
    required this.bookingDate,
    required this.totalPrice,
    required this.status,
    this.bookingType = 'full',
    this.turf,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);
}
