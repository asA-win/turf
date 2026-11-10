import 'package:json_annotation/json_annotation.dart';

part 'turf.g.dart';

@JsonSerializable()
class Turf {
  final int id;
  final String name;
  final String location;
  @JsonKey(name: 'price_per_hour')
  final double pricePerHour;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? description;
  @JsonKey(name: 'sport_types')
  final String? sportTypes;
  final String? amenities;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'pitch_info')
  final String? pitchInfo;
  @JsonKey(name: 'equipment_provided')
  final String? equipmentProvided;
  @JsonKey(name: 'turf_type')
  final String? turfType;
  @JsonKey(name: 'average_rating', defaultValue: 0.0)
  final double averageRating;
  @JsonKey(name: 'total_reviews', defaultValue: 0)
  final int totalReviews;

  Turf({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerHour,
    this.imageUrl,
    this.description,
    this.sportTypes,
    this.amenities,
    this.latitude,
    this.longitude,
    this.pitchInfo,
    this.equipmentProvided,
    this.turfType,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  factory Turf.fromJson(Map<String, dynamic> json) => _$TurfFromJson(json);
  Map<String, dynamic> json() => _$TurfToJson(this);
}
