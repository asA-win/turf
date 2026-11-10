import 'package:json_annotation/json_annotation.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

part 'favorite.g.dart';

@JsonSerializable()
class Favorite {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'turf_id')
  final int turfId;
  final Turf turf;

  Favorite({
    required this.id,
    required this.userId,
    required this.turfId,
    required this.turf,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
  Map<String, dynamic> json() => _$FavoriteToJson(this);
}
