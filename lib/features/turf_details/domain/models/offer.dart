import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@JsonSerializable()
class Offer {
  final int id;
  @JsonKey(name: 'turf_id')
  final int? turfId;
  final String title;
  final String description;
  @JsonKey(name: 'discount_value')
  final double discountValue;
  @JsonKey(name: 'discount_type')
  final String discountType;
  @JsonKey(name: 'min_booking_amount')
  final double minBookingAmount;

  Offer({
    required this.id,
    this.turfId,
    required this.title,
    required this.description,
    required this.discountValue,
    this.discountType = 'flat',
    this.minBookingAmount = 0.0,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
  Map<String, dynamic> toJson() => _$OfferToJson(this);
}
