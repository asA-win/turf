import 'package:json_annotation/json_annotation.dart';

part 'slot.g.dart';

@JsonSerializable()
class Slot {
  final int id;
  @JsonKey(name: 'turf_id')
  final int turfId;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  @JsonKey(name: 'is_booked')
  final bool isBooked;
  final int capacity;
  @JsonKey(name: 'current_bookings')
  final int currentBookings;

  Slot({
    required this.id,
    required this.turfId,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.capacity = 1,
    this.currentBookings = 0,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);
  Map<String, dynamic> json() => _$SlotToJson(this);

  Slot copyWith({
    int? id,
    int? turfId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isBooked,
    int? capacity,
    int? currentBookings,
  }) {
    return Slot(
      id: id ?? this.id,
      turfId: turfId ?? this.turfId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBooked: isBooked ?? this.isBooked,
      capacity: capacity ?? this.capacity,
      currentBookings: currentBookings ?? this.currentBookings,
    );
  }
}
