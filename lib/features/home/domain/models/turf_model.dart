import 'package:json_annotation/json_annotation.dart';

part 'turf_model.g.dart';

@JsonSerializable()
class Turf {
  final String id;
  final String name;
  final String address;
  final String location;
  final double rating;
  final int reviews;
  final List<String> sports;
  final List<String> images;
  final List<String> amenities;
  final double price;

  Turf({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.sports,
    required this.images,
    required this.amenities,
    required this.price,
  });

  factory Turf.fromJson(Map<String, dynamic> json) => _$TurfFromJson(json);
  Map<String, dynamic> toJson() => _$TurfToJson(this);
}
